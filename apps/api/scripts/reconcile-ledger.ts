import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { LedgerJobsService } from '../src/modules/ledger/ledger-jobs.service';
import { OutboxDispatcherService } from '../src/outbox/outbox-dispatcher.service';
import { PrismaService } from '../src/prisma/prisma.service';

async function main() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  try {
    const db = app.get(PrismaService), worker = app.get(OutboxDispatcherService);
    let eventId: string | null = (await app.get(LedgerJobsService).ensureScheduled()).eventId;
    let batches = 0;
    while (eventId && batches < 1000) {
      await worker.dispatchPendingBatch(1, eventId);
      const run = await db.job_runs.findUniqueOrThrow({ where: { event_id: eventId }, include: { event: true } });
      if (run.event.status !== 'DISPATCHED') throw new Error('Reconciliation pending or failed');
      const counts = run.counts as { nextEventId?: string | null };
      eventId = counts.nextEventId ?? null;
      batches++;
    }
    if (eventId) throw new Error('Reconciliation batch bound reached');
    console.log(`Ledger reconciliation completed: ${batches} durable batches. Review findings and operational alerts.`);
  } finally { await app.close(); }
}
main().catch(() => { console.error('Ledger reconciliation failed; check native DB, ledger grants and worker status.'); process.exitCode = 1; });
