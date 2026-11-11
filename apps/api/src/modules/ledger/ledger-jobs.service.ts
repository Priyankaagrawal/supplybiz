import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PinoLogger } from '../../common/logging/pino.logger';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { PrismaService } from '../../prisma/prisma.service';
import { LedgerReconciliationService } from './ledger-reconciliation.service';

export const LEDGER_RECONCILE = 'LEDGER_RECONCILE';
@Injectable()
export class LedgerJobsService implements OnModuleInit, OnModuleDestroy {
  private timer: NodeJS.Timeout | null = null;
  private active: Promise<void> | null = null;
  constructor(private readonly db: PrismaService, private readonly dispatcher: OutboxDispatcherService,
    private readonly reconciliation: LedgerReconciliationService, private readonly logger: PinoLogger) {}
  onModuleInit() {
    this.dispatcher.register(LEDGER_RECONCILE, async (event, tx) => {
      const payload = event.payload as { date?: unknown; cursor?: unknown; rootId?: unknown };
      if (typeof payload.date !== 'string' || (payload.cursor !== null && typeof payload.cursor !== 'string') ||
        (payload.rootId !== undefined && (typeof payload.rootId !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(payload.rootId)))) throw new Error('Invalid ledger job');
      const rootId = typeof payload.rootId === 'string' ? payload.rootId : event.id;
      const counts = await this.reconciliation.batch(tx, payload.date, payload.cursor);
      const nextEventId = counts.nextCursor ? await this.followup(tx, payload.date, counts.nextCursor, rootId) : null;
      return { ...counts, nextEventId };
    });
  }
  /** Worker-only. API initialization registers a handler but creates no timers/jobs. */
  start() {
    if (this.timer) return;
    void this.poll();
    this.timer = setInterval(() => { void this.poll(); }, 60000);
  }
  async onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    await this.active;
  }
  private poll(): Promise<void> {
    return this.active ??= this.ensureScheduled().then(() => undefined).catch(() => {
      this.logger.error('LEDGER_RECONCILIATION_SCHEDULE_FAILED', undefined, 'Ledger');
    }).finally(() => { this.active = null; });
  }
  async ensureScheduled() {
    const [clock] = await this.db.$queryRaw<{ day: string; now: Date }[]>`
      SELECT to_char(clock_timestamp() AT TIME ZONE 'Asia/Kolkata','YYYY-MM-DD') AS day, clock_timestamp() AS now`;
    if (!clock) throw new Error('Database clock unavailable');
    const due = new Date(`${clock.day}T00:15:00+05:30`);
    const latestDate = clock.now >= due ? clock.day : new Date(new Date(clock.day).getTime() - 86400000).toISOString().slice(0,10);
    await this.dispatcher.schedule(LEDGER_RECONCILE, clock.day, 'GLOBAL', due, { date: clock.day, cursor: null });
    // On restart, run the most recent due cumulative check; persisted older jobs
    // still use the dispatcher's ordinary lease/retry/catch-up behavior.
    const eventId = await this.dispatcher.schedule(LEDGER_RECONCILE, latestDate, 'GLOBAL',
      new Date(`${latestDate}T00:15:00+05:30`), { date: latestDate, cursor: null });
    return { date: latestDate, eventId };
  }
  private async followup(tx: Prisma.TransactionClient, date: string, cursor: string, rootId: string) {
    const scope = `AFTER:${rootId}:${cursor}`;
    const known = await tx.job_runs.findUnique({ where: { job_type_business_date_scope_id: {
      job_type: LEDGER_RECONCILE, business_date: new Date(date), scope_id: scope } } });
    if (known) return known.event_id;
    const event = await tx.outbox_events.create({ data: { aggregate_type: 'JOB', event_type: LEDGER_RECONCILE,
      payload: { date, cursor, rootId } } });
    await tx.job_runs.create({ data: { job_type: LEDGER_RECONCILE, business_date: new Date(date), scope_id: scope, event_id: event.id } });
    return event.id;
  }
}
