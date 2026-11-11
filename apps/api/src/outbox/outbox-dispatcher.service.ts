import { Injectable, OnModuleDestroy } from "@nestjs/common";
import { outbox_events, Prisma } from "@prisma/client";
import { randomUUID } from "node:crypto";
import { PrismaService } from "../prisma/prisma.service";
import { PinoLogger } from "../common/logging/pino.logger";

type Handler = (event: outbox_events, tx: Prisma.TransactionClient) => Promise<Prisma.InputJsonObject | void>;
const MAX_ATTEMPTS = 5;
const LEASE_SECONDS = 60;

@Injectable()
export class OutboxDispatcherService implements OnModuleDestroy {
  private interval: NodeJS.Timeout | null = null;
  private running: Promise<number> | null = null;
  private readonly handlers = new Map<string, Handler>();

  constructor(private readonly prisma: PrismaService, private readonly logger: PinoLogger) {}

  /** Register real consumers before start. Unknown events fail rather than disappear.
   * External consumers must deduplicate by event.id; DB effects use this transaction.
   */
  register(eventType: string, handler: Handler): void {
    if (this.handlers.has(eventType)) throw new Error("Duplicate outbox handler");
    this.handlers.set(eventType, handler);
  }

  start(): void {
    if (this.interval) return;
    void this.poll(); // Catch up persisted due work immediately on restart.
    this.interval = setInterval(() => { void this.poll(); }, 5000);
  }

  stop(): void {
    if (this.interval) clearInterval(this.interval);
    this.interval = null;
  }

  async onModuleDestroy(): Promise<void> {
    this.stop();
    await this.running;
  }

  private poll(): Promise<number> {
    if (this.running) return this.running;
    this.running = this.dispatchPendingBatch().catch(() => {
      this.logger.error("WORKER_POLL_FAILED", undefined, "OutboxDispatcher");
      return 0;
    }).finally(() => { this.running = null; });
    return this.running;
  }

  /** Persist a one-shot due job atomically. Repeat scheduling preserves its original payload/time.
   * Recurrence/cutoff policy and generation alerts are supplied by T-073, not device time.
   */
  async schedule(jobType: string, businessDate: string, scopeId: string, dueAt: Date,
    payload: Prisma.InputJsonObject): Promise<string> {
    if (!/^[A-Z][A-Z0-9_]{0,99}$/.test(jobType) || !scopeId || scopeId.length > 120 ||
        !/^\d{4}-\d{2}-\d{2}$/.test(businessDate) ||
        !Number.isFinite(Date.parse(businessDate)) ||
        new Date(businessDate).toISOString().slice(0, 10) !== businessDate ||
        !Number.isFinite(dueAt.getTime())) throw new Error("Invalid scheduled job");
    return this.prisma.$transaction(async tx => {
      const key = JSON.stringify([jobType, businessDate, scopeId]);
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${key}, 0))::text`;
      const business_date = new Date(businessDate);
      const existing = await tx.job_runs.findUnique({ where: {
        job_type_business_date_scope_id: { job_type: jobType, business_date, scope_id: scopeId },
      } });
      if (existing) return existing.event_id;
      const event = await tx.outbox_events.create({ data: {
        aggregate_type: "JOB", event_type: jobType, payload, available_at: dueAt,
      } });
      await tx.job_runs.create({ data: { job_type: jobType, business_date,
        scope_id: scopeId, event_id: event.id } });
      return event.id;
    });
  }

  // Optional target supports isolated task checks/manual job drills with identical lease/retry rules.
  async dispatchPendingBatch(batchSize = 50, eventId?: string): Promise<number> {
    if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > 100) throw new Error("Invalid batch size");
    if (eventId !== undefined && !/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(eventId)) throw new Error('Invalid event ID');
    const targetId = eventId ?? null;
    let completed = 0;
    // Claim only one row per handler execution so queued rows do not age under a batch lease.
    for (let i = 0; i < batchSize; i++) {
      const token = randomUUID();
      const [event] = await this.prisma.$queryRaw<outbox_events[]>`
        WITH candidate AS (
          SELECT id FROM outbox_events WHERE status = 'PENDING'
            AND (${targetId}::uuid IS NULL OR id = ${targetId}::uuid)
            AND available_at <= clock_timestamp()
            AND (lease_until IS NULL OR lease_until <= clock_timestamp())
          ORDER BY available_at, created_at, id FOR UPDATE SKIP LOCKED LIMIT 1
        ) UPDATE outbox_events e SET lease_token = ${token}::uuid,
          lease_until = clock_timestamp() + ${LEASE_SECONDS} * interval '1 second',
          attempt_count = attempt_count + 1, updated_at = clock_timestamp()
        FROM candidate c WHERE e.id = c.id RETURNING e.*`;
      if (!event) break;
      if (event.attempt_count > MAX_ATTEMPTS) {
        await this.fail(event, token, "WORKER_LEASE_EXHAUSTED");
        continue;
      }
      try {
        const done = await this.prisma.$transaction(async tx => {
          const [owned] = await tx.$queryRaw<outbox_events[]>`
            SELECT * FROM outbox_events WHERE id = ${event.id}::uuid
              AND lease_token = ${token}::uuid AND status = 'PENDING'
              AND lease_until > clock_timestamp() FOR UPDATE`;
          if (!owned) return false;
          const handler = this.handlers.get(owned.event_type);
          if (!handler) throw new Error("Missing handler");
          const counts = await handler(owned, tx);
          await tx.$executeRaw`UPDATE outbox_events SET status = 'DISPATCHED',
            dispatched_at = clock_timestamp(), lease_token = NULL, lease_until = NULL,
            last_error = NULL, updated_at = clock_timestamp() WHERE id = ${event.id}::uuid`;
          await tx.job_runs.updateMany({ where: { event_id: event.id }, data: {
            counts: counts ?? {}, finished_at: new Date(),
          } });
          return true;
        }, { timeout: 45000 });
        if (done) completed++;
      } catch {
        await this.fail(event, token, this.handlers.has(event.event_type) ? "WORKER_HANDLER_FAILED" : "WORKER_HANDLER_MISSING");
      }
    }
    return completed;
  }

  private async fail(event: outbox_events, token: string, code: string): Promise<void> {
    const terminal = event.attempt_count >= MAX_ATTEMPTS;
    const delay = Math.min(3600, 5 * 2 ** Math.min(event.attempt_count - 1, 10));
    const changed = await this.prisma.$executeRaw`UPDATE outbox_events
      SET status = ${terminal ? "FAILED" : "PENDING"}::outbox_event_status,
        available_at = clock_timestamp() + ${delay} * interval '1 second',
        lease_token = NULL, lease_until = NULL, last_error = ${code}, updated_at = clock_timestamp()
      WHERE id = ${event.id}::uuid AND lease_token = ${token}::uuid AND status = 'PENDING'`;
    if (changed && terminal) this.logger.error("WORKER_DELIVERY_EXHAUSTED", undefined, "OutboxDispatcher");
    else if (changed) this.logger.warn(code, "OutboxDispatcher");
  }
}
