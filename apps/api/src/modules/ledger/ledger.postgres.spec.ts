import { TestingModule, Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { LedgerService, LedgerPost } from './ledger.service';
import { LedgerReconciliationService } from './ledger-reconciliation.service';
import { LedgerJobsService, LEDGER_RECONCILE } from './ledger-jobs.service';

const url = process.env.LEDGER_TEST_DATABASE_URL ?? process.env.NATIVE_TEST_DATABASE_URL;
const native = url ? describe : describe.skip;
native('T-070 TC-110/112/115/116 native financial integrity (requires applied operator grants)', () => {
  const db = new PrismaService({ datasources: { db: { url } } });
  let admin: PrismaService, app: TestingModule, ledger: LedgerService, reconciliation: LedgerReconciliationService, worker: OutboxDispatcherService;
  const before = { ...process.env }, logger = { log: jest.fn(), error: jest.fn(), warn: jest.fn() };
  let owner: string, vendorId: string, customerId: string, foreignUser: string, foreignCustomer: string;
  let serial = 0;
  const jobIds: string[] = [];
  async function fixture() {
    const user = await db.users.create({ data: { mobile: `synthetic-ledger-${randomUUID()}`, active_role: 'VENDOR', roles: { create: { role: 'VENDOR' } } } });
    const category = await db.categories.create({ data: { code: `LEDGER-${randomUUID()}`, name_en: 'Synthetic Ledger', name_hi: '', type: 'SUPPLY' } });
    const vendor = await db.vendors.create({ data: { user_id: user.id, category_id: category.id } });
    const customer = await db.vendor_customers.create({ data: { vendor_id: vendor.id, name: 'Synthetic Ledger Customer', mobile: `+91${9000000000 + ++serial}` } });
    return { userId: user.id, vendorId: vendor.id, customerId: customer.id };
  }
  function source(overrides: Partial<LedgerPost> = {}): LedgerPost {
    return { actorId: owner, vendorId, customerId, refType: 'ORDER', refId: randomUUID(), type: 'DEBIT', amountPaise: 50000n, ...overrides };
  }
  function post(input: LedgerPost) { return db.$transaction(tx => ledger.post(tx, input), { timeout: 15000 }); }
  beforeAll(async () => {
    if (!url || !process.env.LEDGER_TEST_ADMIN_URL) throw new Error('Dedicated ledger runtime/admin test URLs required; native checks must not silently skip grants');
    const connection = new URL(url), operator = new URL(process.env.LEDGER_TEST_ADMIN_URL);
    for (const endpoint of [connection,operator]) {
      if (!endpoint.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(endpoint.hostname)) throw new Error('Dedicated local _test database required');
    }
    if (connection.pathname !== operator.pathname || (connection.port || '5432') !== (operator.port || '5432')) throw new Error('Runtime/admin URLs must target the same isolated test database');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url, OTP_DELIVERY_MODE: 'disabled' });
    admin = new PrismaService({ datasources: { db: { url: operator.toString() } } });
    await db.$connect(); await admin.$connect();
    const { AppModule } = await import('../../app.module');
    app = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PinoLogger).useValue(logger).compile();
    await app.init();
    ledger = app.get(LedgerService); reconciliation = app.get(LedgerReconciliationService); worker = app.get(OutboxDispatcherService);
    await ledger.assertPrivileges(db);
  });
  beforeEach(async () => {
    const a = await fixture(), b = await fixture();
    owner = a.userId; vendorId = a.vendorId; customerId = a.customerId;
    foreignUser = b.userId; foreignCustomer = b.customerId;
    jest.clearAllMocks();
  });
  afterAll(async () => {
    await app?.close();
    if (jobIds.length) {
      await db.job_runs.deleteMany({ where: { event_id: { in: jobIds } } });
      await db.outbox_events.deleteMany({ where: { id: { in: jobIds } } });
    }
    // Append-only synthetic ledger/audit fixtures remain in this isolated DB.
    await db.$disconnect(); await admin?.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in before)) delete process.env[key]; Object.assign(process.env, before);
  });
  it('TC-110 posts one source across concurrent retries/reconnect and rolls back source/entry/balance/audit together', async () => {
    const input = source(), results = await Promise.all([post(input),post(input)]);
    expect(results[0]!.id).toBe(results[1]!.id);
    await db.$disconnect(); await db.$connect(); expect((await post(input)).id).toBe(results[0]!.id);
    expect(await ledger.balance(owner, customerId)).toMatchObject({ totalDebitPaise: '50000', totalCreditPaise: '0', duePaise: '50000' });
    expect(await db.audit_logs.count({ where: { entity_id: results[0]!.id, action: 'LEDGER_APPENDED' } })).toBe(1);
    await expect(post({ ...input, amountPaise: 50001n })).rejects.toMatchObject({ response: { code: 'LEDGER_REFERENCE_MISMATCH' } });
    const rolled = source(), marker = randomUUID();
    await expect(db.$transaction(async tx => {
      await tx.outbox_events.create({ data: { id: marker, aggregate_type: 'TEST', event_type: 'SYNTHETIC_LEDGER_SOURCE', payload: {} } });
      await ledger.post(tx, rolled); throw new Error('Synthetic rollback');
    })).rejects.toThrow('Synthetic rollback');
    expect(await db.ledger_entries.count({ where: { ref_id: rolled.refId } })).toBe(0);
    expect(await db.outbox_events.findUnique({ where: { id: marker } })).toBeNull();
    expect((await ledger.balance(owner,customerId)).duePaise).toBe('50000');
    expect(await db.audit_logs.count({ where: { actor_id: owner, entity: 'ledger_entries' } })).toBe(1);
  });
  it('TC-110 preserves precision above JS safe integers and both debit/credit invariants', async () => {
    const large = 9007199254740993n;
    await post(source({ amountPaise: large }));
    await Promise.all(Array.from({ length: 8 }, () => post(source({ type: 'CREDIT', refType: 'PAYMENT', amountPaise: 500n }))));
    expect(await ledger.balance(owner,customerId)).toMatchObject({ totalDebitPaise: String(large), totalCreditPaise: '4000', duePaise: String(large - 4000n) });
    expect((await ledger.entries(owner,customerId,2)).hasMore).toBe(true);
  });
  it('TC-112/116 requires notes, persists opening keys forever, reverses once and audits the opposite entry', async () => {
    const key = randomUUID(), opening = { type: 'DEBIT' as const, amountPaise: 12000n, note: 'Synthetic opening', entryDate: '2026-11-01' };
    await expect(ledger.opening(owner,key,customerId,{ ...opening, note: ' ' })).rejects.toMatchObject({ response: { code: 'LEDGER_NOTE_REQUIRED' } });
    const entry = await ledger.opening(owner,key,customerId,opening);
    expect((await ledger.opening(owner,key,customerId,opening)).id).toBe(entry.id);
    await expect(ledger.opening(owner,key,customerId,{ ...opening, type: 'CREDIT' })).rejects.toMatchObject({ response: { code: 'IDEMPOTENCY_MISMATCH' } });
    expect(await db.idempotency_keys.count({ where: { user_id: owner } })).toBe(0);
    const reversalKey = randomUUID(), reversed = await ledger.reverse(owner,reversalKey,entry.id,'Synthetic correction');
    expect(reversed).toMatchObject({ type: 'CREDIT', amountPaise: '12000', reversesEntryId: entry.id, refType: 'REVERSAL' });
    expect((await ledger.reverse(owner,reversalKey,entry.id,'Synthetic correction')).id).toBe(reversed.id);
    await expect(ledger.reverse(owner,randomUUID(),entry.id,'Second reversal')).rejects.toMatchObject({ response: { code: 'ENTRY_ALREADY_REVERSED' } });
    expect((await ledger.balance(owner,customerId)).duePaise).toBe('0');
    expect(await db.audit_logs.count({ where: { entity_id: reversed.id, action: 'LEDGER_REVERSED', actor_id: owner } })).toBe(1);
    expect(await db.ledger_entries.findUnique({ where: { id: entry.id } })).toMatchObject({ amount_paise: 12000n, type: 'DEBIT' });
  });
  it('TC-116 concurrent reversals create one opposite entry and reject malformed DB reversal/scoping writes', async () => {
    const entry = await post(source());
    const results = await Promise.allSettled([ledger.reverse(owner,randomUUID(),entry.id,'Synthetic first'),
      ledger.reverse(owner,randomUUID(),entry.id,'Synthetic second')]);
    expect(results.filter(r => r.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter(r => r.status === 'rejected')).toHaveLength(1);
    expect((await ledger.balance(owner,customerId)).duePaise).toBe('0');
    const bad = { vendor_id: vendorId, vendor_customer_id: customerId, created_by: owner,
      type: 'CREDIT', amount_paise: 1n, ref_type: 'REVERSAL', ref_id: entry.id, reverses_entry_id: entry.id,
      note: 'Synthetic invalid reversal', request_key: 'a'.repeat(64), request_hash: 'b'.repeat(64) };
    await expect(db.ledger_entries.create({ data: bad })).rejects.toThrow();
    await expect(db.ledger_entries.create({ data: { ...bad, ref_type: 'ORDER', ref_id: randomUUID(),
      reverses_entry_id: null, request_key: null, request_hash: null, vendor_customer_id: foreignCustomer } })).rejects.toThrow();
    expect(await db.ledger_entries.count({ where: { reverses_entry_id: entry.id } })).toBe(1);
    expect((await ledger.balance(owner,customerId)).duePaise).toBe('0');
  });
  it('rejects int64 aggregate overflow without persisting an entry, balance effect or audit', async () => {
    await post(source({ amountPaise: 9223372036854775802n }));
    const overflow = source({ amountPaise: 10n });
    await expect(post(overflow)).rejects.toThrow();
    expect(await db.ledger_entries.count({ where: { ref_id: overflow.refId } })).toBe(0);
    expect((await ledger.balance(owner,customerId)).duePaise).toBe('9223372036854775802');
    expect(await db.audit_logs.count({ where: { actor_id: owner, entity: 'ledger_entries' } })).toBe(1);
  });
  it('rejects foreign customer/actor/read/cursor scopes and role/suspension changes', async () => {
    await expect(post(source({ customerId: foreignCustomer }))).rejects.toMatchObject({ response: { code: 'CUSTOMER_NOT_FOUND' } });
    await expect(post(source({ actorId: foreignUser }))).rejects.toMatchObject({ response: { code: 'VENDOR_SCOPE_REQUIRED' } });
    await expect(ledger.balance(foreignUser,customerId)).rejects.toMatchObject({ response: { code: 'CUSTOMER_NOT_FOUND' } });
    const entry = await post(source());
    await expect(ledger.reverse(foreignUser,randomUUID(),entry.id,'Forgery')).rejects.toMatchObject({ response: { code: 'LEDGER_ENTRY_NOT_FOUND' } });
    await db.users.update({ where: { id: owner }, data: { active_role: 'CUSTOMER' } });
    await expect(post(source())).rejects.toMatchObject({ response: { code: 'VENDOR_ROLE_REQUIRED' } });
    await db.users.update({ where: { id: owner }, data: { active_role: 'VENDOR' } });
    await db.vendors.update({ where: { id: vendorId }, data: { is_suspended: true } });
    await expect(post(source())).rejects.toMatchObject({ response: { code: 'VENDOR_SUSPENDED' } });
  });
  it('TC-115 runtime cannot update/delete/truncate entries or edit balances; triggers protect operator history too', async () => {
    const entry = await post(source());
    for (const statement of [Prisma.sql`UPDATE ledger_entries SET note = 'forbidden' WHERE id = ${entry.id}::uuid`,
      Prisma.sql`DELETE FROM ledger_entries WHERE id = ${entry.id}::uuid`, Prisma.sql`TRUNCATE ledger_entries`,
      Prisma.sql`UPDATE ledger_balances SET due_paise = 0 WHERE vendor_customer_id = ${customerId}::uuid`]) {
      await expect(db.$executeRaw(statement)).rejects.toMatchObject({ meta: { code: '42501' } });
    }
    await expect(admin.$executeRaw`UPDATE ledger_entries SET note = 'forbidden' WHERE id = ${entry.id}::uuid`).rejects.toMatchObject({ meta: { code: '42501' } });
    expect((await ledger.balance(owner,customerId)).duePaise).toBe('50000');
  });
  it('TC-115 rejects unsafe column-level grants as well as table-level permissions', async () => {
    const [runtime] = await db.$queryRaw<{ name: string }[]>`SELECT current_user AS name`;
    await admin.$transaction(async tx => {
      await tx.$queryRaw`SELECT set_config('supplybiz.test_runtime_role',${runtime!.name},true)`;
      await tx.$executeRaw`DO $$ BEGIN EXECUTE format('GRANT UPDATE (due_paise) ON public.ledger_balances TO %I',
        current_setting('supplybiz.test_runtime_role')); END $$`;
    });
    try {
      await expect(ledger.assertPrivileges(db)).rejects.toMatchObject({ response: { code: 'LEDGER_GRANTS_NOT_APPLIED' } });
    } finally {
      await admin.$transaction(async tx => {
        await tx.$queryRaw`SELECT set_config('supplybiz.test_runtime_role',${runtime!.name},true)`;
        await tx.$executeRaw`DO $$ BEGIN EXECUTE format('REVOKE UPDATE (due_paise) ON public.ledger_balances FROM %I',
          current_setting('supplybiz.test_runtime_role')); END $$`;
      });
    }
    await expect(ledger.assertPrivileges(db)).resolves.toBeUndefined();
  });
  it('reconciliation records immutable drift once, emits a redacted alert and never silently repairs balances', async () => {
    await post(source()); const date = '2026-11-11';
    await admin.$executeRaw`UPDATE ledger_balances SET total_debit_paise = 50001, due_paise = 50001 WHERE vendor_customer_id = ${customerId}::uuid`;
    try {
      await db.$transaction(tx => reconciliation.batch(tx,date));
      await db.$transaction(tx => reconciliation.batch(tx,date));
      const finding = await db.ledger_reconciliation_findings.findUniqueOrThrow({ where: { business_date_vendor_customer_id: { business_date: new Date(date), vendor_customer_id: customerId } } });
      expect(finding.expected).toMatchObject({ totalDebitPaise: '50000', duePaise: '50000' });
      expect(finding.observed).toMatchObject({ totalDebitPaise: '50001', duePaise: '50001' });
      expect((await ledger.balance(owner,customerId)).duePaise).toBe('50001');
      expect(logger.error).toHaveBeenCalledWith('LEDGER_RECONCILIATION_DRIFT',undefined,'Ledger');
    } finally {
      await admin.$executeRaw`UPDATE ledger_balances SET total_debit_paise = 50000, due_paise = 50000 WHERE vendor_customer_id = ${customerId}::uuid`;
    }
  });
  it('nightly jobs deduplicate across schedulers and execute through durable leases with persisted counts', async () => {
    await post(source());
    const scope = `SYNTHETIC:${randomUUID()}`, date = '2026-11-11';
    const ids = await Promise.all([1,2].map(() => worker.schedule(LEDGER_RECONCILE,date,scope,new Date(0),{ date, cursor: null })));
    jobIds.push(ids[0]!); expect(ids[0]).toBe(ids[1]);
    expect(await worker.dispatchPendingBatch(1,ids[0])).toBe(1);
    expect(await worker.dispatchPendingBatch(1,ids[0])).toBe(0);
    const run = await db.job_runs.findUniqueOrThrow({ where: { event_id: ids[0] } });
    expect(run.finished_at).not.toBeNull(); expect((run.counts as { checked: number }).checked).toBeGreaterThan(0);
    const clockRun = await app.get(LedgerJobsService).ensureScheduled();
    expect((await app.get(LedgerJobsService).ensureScheduled()).eventId).toBe(clockRun.eventId);
  });
  it('reconciliation continuations survive reconnect and keep separate run scopes through all bounded batches', async () => {
    const rows = Array.from({ length: 101 }, () => ({ id: randomUUID(), vendor_id: vendorId,
      name: 'Synthetic Batch Customer', mobile: `+91${9000000000 + ++serial}` }));
    await db.vendor_customers.createMany({ data: rows });
    await db.ledger_entries.createMany({ data: rows.map(row => ({ vendor_id: vendorId, vendor_customer_id: row.id,
      type: 'DEBIT', amount_paise: 1n, ref_type: 'ORDER', ref_id: randomUUID(), note: '', created_by: owner })) });
    const date = '2030-11-11';
    const root = await worker.schedule(LEDGER_RECONCILE,date,`SYNTHETIC:${randomUUID()}`,new Date(0),{ date, cursor: null });
    let eventId: string | null = root, checked = 0, batches = 0;
    while (eventId) {
      jobIds.push(eventId);
      expect(await worker.dispatchPendingBatch(1,eventId)).toBe(1);
      const run = await db.job_runs.findUniqueOrThrow({ where: { event_id: eventId } });
      const counts = run.counts as { checked: number; nextEventId: string | null };
      checked += counts.checked; batches++;
      expect(counts.checked).toBeLessThanOrEqual(100);
      eventId = counts.nextEventId;
      if (eventId) {
        const job = await db.job_runs.findUniqueOrThrow({ where: { event_id: eventId } });
        expect(job.scope_id).toContain(root);
        await db.$disconnect(); await db.$connect();
      }
      if (batches > 20) throw new Error('Unexpected batch loop');
    }
    const [actual] = await db.$queryRaw<{ count: number }[]>`SELECT count(DISTINCT vendor_customer_id)::int AS count FROM ledger_entries`;
    expect(checked).toBe(actual!.count); expect(batches).toBeGreaterThan(1);
    expect(await worker.dispatchPendingBatch(1,root)).toBe(0);
  });
});
