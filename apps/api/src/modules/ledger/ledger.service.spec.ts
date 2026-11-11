import { Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { LedgerService, LedgerPost } from './ledger.service';
import { LedgerReconciliationService } from './ledger-reconciliation.service';
import { PinoLogger } from '../../common/logging/pino.logger';
import { LedgerJobsService, LEDGER_RECONCILE } from './ledger-jobs.service';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';

describe('T-070 fail-closed financial boundary checks (no DB substitution claim)', () => {
  const db = {} as PrismaService;
  const ledger = new LedgerService(db, new IdempotencyService(db));
  const input: LedgerPost = { actorId: randomUUID(), vendorId: randomUUID(), customerId: randomUUID(),
    type: 'DEBIT', amountPaise: 50000n, refType: 'ORDER', refId: randomUUID() };
  it('permits the intended insert-only runtime permission shape', async () => {
    const tx = { $queryRaw: jest.fn().mockResolvedValue([{ can_insert: true, unsafe: false }]) } as unknown as Prisma.TransactionClient;
    await expect(ledger.assertPrivileges(tx)).resolves.toBeUndefined();
  });
  it('rejects missing insert privileges, owner/admin privileges and unavailable permission results', async () => {
    for (const rows of [[], [{ can_insert: false, unsafe: false }], [{ can_insert: true, unsafe: true }]]) {
      const tx = { $queryRaw: jest.fn().mockResolvedValue(rows) } as unknown as Prisma.TransactionClient;
      await expect(ledger.assertPrivileges(tx)).rejects.toMatchObject({ response: { code: 'LEDGER_GRANTS_NOT_APPLIED' } });
    }
  });
  it('rejects non-integer, non-positive, oversized and forged source fields before touching storage', async () => {
    const tx = {} as Prisma.TransactionClient;
    for (const invalid of [{ amountPaise: 0n }, { amountPaise: -1n }, { amountPaise: 9223372036854775808n },
      { amountPaise: 1.5 }, { actorId: 'forged' }, { refId: 'forged' }, { type: 'INVALID' }, { note: null }]) {
      await expect(ledger.post(tx, { ...input, ...invalid } as LedgerPost)).rejects.toMatchObject({ response: { code: 'INVALID_LEDGER_ENTRY' } });
    }
  });
  it('rejects impossible dates and empty date strings without silently using another business date', async () => {
    for (const entryDate of ['', '2026-02-30', '2026-13-01', 'not-a-date']) {
      await expect(ledger.post({} as Prisma.TransactionClient, { ...input, entryDate })).rejects.toMatchObject({ response: { code: 'INVALID_LEDGER_DATE' } });
    }
  });
  it('bounds reconciliation pages and rejects invalid business dates/cursors before querying', async () => {
    const reconciliation = new LedgerReconciliationService(ledger, {} as PinoLogger);
    for (const [date,cursor,limit] of [['bad',null,100], ['2026-02-30',null,100], ['2026-11-11','-'.repeat(36),100], ['2026-11-11',null,101]] as const) {
      await expect(reconciliation.batch({} as Prisma.TransactionClient, date, cursor, limit)).rejects.toThrow('Invalid reconciliation batch');
    }
  });
  it('uses the database IST day around midnight and catches up the most recent due check', async () => {
    const clockDb = { $queryRaw: jest.fn().mockResolvedValue([{ day: '2026-11-11', now: new Date('2026-11-10T18:40:00Z') }]) } as unknown as PrismaService;
    const schedule = jest.fn().mockResolvedValue('synthetic-event');
    const jobs = new LedgerJobsService(clockDb, { schedule } as unknown as OutboxDispatcherService,
      {} as LedgerReconciliationService, {} as PinoLogger);
    expect((await jobs.ensureScheduled()).date).toBe('2026-11-10');
    expect(schedule.mock.calls[0]).toEqual([LEDGER_RECONCILE,'2026-11-11','GLOBAL',new Date('2026-11-10T18:45:00Z'),{ date: '2026-11-11', cursor: null }]);
    expect(schedule.mock.calls[1]).toEqual([LEDGER_RECONCILE,'2026-11-10','GLOBAL',new Date('2026-11-09T18:45:00Z'),{ date: '2026-11-10', cursor: null }]);
    schedule.mockClear();
    (clockDb.$queryRaw as jest.Mock).mockResolvedValue([{ day: '2026-11-11', now: new Date('2026-11-10T18:50:00Z') }]);
    expect((await jobs.ensureScheduled()).date).toBe('2026-11-11');
  });
});
