import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomBytes, randomInt, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { digest } from '../admin-auth/admin-crypto';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { PlanRemindersService } from './plan-reminders.service';
import { PlanEntitlementsService } from './plan-entitlements.service';

const url = process.env.NATIVE_TEST_DATABASE_URL;
const native = url ? describe : describe.skip;
native('T-103 audited manual assignments, current entitlements and expiry jobs', () => {
  const db = new PrismaService({ datasources: { db: { url } } });
  const env = { ...process.env };
  let app: INestApplication, peer: INestApplication, categoryId: string, serial = randomInt(0, 800000000);
  let finance: { id: string; token: string }, basic: string, business: string;
  type Vendor = { id: string; userId: string; token: string };
  let a: Vendor, b: Vendor;
  const mobile = () => `+91${9100000000 + ++serial}`;
  const dates = (days = 30) => ({ startsAt: new Date(Date.now() - 60000).toISOString(), endsAt: new Date(Date.now() + days * 86400000).toISOString() });
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PinoLogger)
      .useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
    const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
  }
  async function admin(role: string) {
    const row = await db.admin_users.create({ data: { email: `plan-${randomUUID()}@example.invalid`, password_hash: 'synthetic-unused', role } });
    const token = randomBytes(32).toString('base64url');
    await db.admin_sessions.create({ data: { token_hash: digest(token), admin_id: row.id, csrf_hash: digest('synthetic'), expires_at: new Date(Date.now() + 3600000) } });
    return { id: row.id, token };
  }
  async function vendor(): Promise<Vendor> {
    const user = await db.users.create({ data: { mobile: mobile(), active_role: 'VENDOR', roles: { create: { role: 'VENDOR' } } } });
    const row = await db.vendors.create({ data: { user_id: user.id, category_id: categoryId } });
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(), refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    return { id: row.id, userId: user.id, token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  const input = (planId = basic) => ({ planId, ...dates(), reason: 'Synthetic manual grant' });
  const write = (body: object = input(), owner = a.id, key: string = randomUUID(), token = finance.token, instance = app, csrf = 'synthetic', assignmentId = '') =>
    request(instance.getHttpServer()).post(`/api/v1/admin/vendors/${owner}/plan-assignments${assignmentId ? `/${assignmentId}/extend` : ''}`)
      .set('Authorization', `Bearer ${token}`).set('X-CSRF-Token', csrf).set('Idempotency-Key', key).send(body);
  const current = (owner = a) => request(app.getHttpServer()).get('/api/v1/vendor/plan').set('Authorization', `Bearer ${owner.token}`);
  const createCustomer = () => request(app.getHttpServer()).post('/api/v1/vendor/customers').set('Authorization', `Bearer ${a.token}`)
    .set('Idempotency-Key', randomUUID()).send({ name: 'Synthetic Assignment Customer', mobile: mobile() });
  beforeAll(async () => {
    const parsed = new URL(url!);
    if (!parsed.pathname.endsWith('_test') || !['localhost', '127.0.0.1', '[::1]'].includes(parsed.hostname)) throw new Error('Dedicated local _test database required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: parsed.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000',
      AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
    await db.$connect(); app = await boot(); peer = await boot(); finance = await admin('FINANCE');
    categoryId = (await db.categories.create({ data: { code: `PLAN-ASSIGN-${randomUUID()}`, name_en: 'Synthetic category', name_hi: '', type: 'SUPPLY' } })).id;
    basic = (await db.plans.findUniqueOrThrow({ where: { code: 'BASIC' } })).id;
    business = (await db.plans.findUniqueOrThrow({ where: { code: 'BUSINESS' } })).id;
  });
  beforeEach(async () => { a = await vendor(); b = await vendor(); });
  afterAll(async () => {
    // Immutable audit/replay evidence retains synthetic fixtures in the isolated DB.
    await peer?.close(); await app?.close(); await db.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env);
  });
  it('serves owned current state and DB catalog with approved features/caps and no default assignment', async () => {
    expect((await current().expect(200)).body).toMatchObject({ status: 'UNASSIGNED', assignment: null, customerLimit: 50, features: [], canAddCustomer: true });
    const list = await request(app.getHttpServer()).get('/api/v1/vendor/plans').set('Authorization', `Bearer ${a.token}`).expect(200);
    expect(list.body.items.map((r: { customerLimit: number }) => r.customerLimit)).toEqual([100, 250, 500, 1000]);
    for (const row of list.body.items) { expect(row.features).toContain('QUICK_SALE'); expect(row.features).not.toContain('WALLET_SETTLEMENT'); }
    await request(app.getHttpServer()).get('/api/v1/vendor/plan').expect(401);
    await write(input(), b.id).expect(201);
    expect((await current().expect(200)).body.assignment).toBeNull();
    expect((await current(b).expect(200)).body.assignment.code).toBe('BASIC');
  });
  it('enforces approved admin roles, CSRF, key and permission on cached replay', async () => {
    await write(input(), a.id, randomUUID(), '').expect(401);
    for (const role of ['SUPPORT', 'OPS']) await write(input(), a.id, randomUUID(), (await admin(role)).token).expect(403);
    await write(input(), a.id, randomUUID(), finance.token, app, 'wrong').expect(403);
    await write(input(), a.id, '').expect(400);
    await write(input(), a.id, randomUUID(), (await admin('SUPER_ADMIN')).token).expect(201);
    const actor = await admin('FINANCE'), body = input(), key = randomUUID();
    await write(body, a.id, key, actor.token).expect(201);
    await db.admin_users.update({ where: { id: actor.id }, data: { role: 'SUPPORT' } });
    await write(body, a.id, key, actor.token).expect(403);
  });
  it('rejects malformed/forged inputs, invalid dates, missing vendor and inactive plan without state changes', async () => {
    const body = input();
    for (const change of [{ reason: '' }, { reason: ' ' }, { reason: null }, { endsAt: body.startsAt }, { endsAt: '2026-02-30T00:00:00Z' },
      { startsAt: '2026-11-11T00:00:00' }, { endsAt: '2020-01-01T00:00:00Z' }, { planId: 'bad' }, { customerLimit: 1000 }, { grantedByAdmin: finance.id }]) await write({ ...body, ...change }).expect(400);
    await write(body, randomUUID()).expect(404); await write({ ...body, planId: randomUUID() }).expect(409);
    const inactive = await db.plans.findUniqueOrThrow({ where: { code: 'PREMIUM' } });
    await db.plans.update({ where: { id: inactive.id }, data: { status: 'INACTIVE' } });
    try { await write({ ...body, planId: inactive.id }).expect(409); } finally { await db.plans.update({ where: { id: inactive.id }, data: { status: inactive.status } }); }
    expect(await db.vendor_plan_assignments.count({ where: { vendor_id: a.id } })).toBe(0);
  });
  it('commits once across instances/restart, permanently replays and detects changed body/path', async () => {
    const body = input(), key = randomUUID();
    const result = await Promise.all([write(body, a.id, key), write(body, a.id, key, finance.token, peer)]);
    expect(result.map(r => r.status)).toEqual([201, 201]); expect(result[0]!.body).toEqual(result[1]!.body);
    const assigned = result[0]!.body;
    expect(await db.audit_logs.count({ where: { entity_id: a.id, action: 'PLAN_ASSIGNED' } })).toBe(1);
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.id } })).assigned_customer_limit).toBe(100);
    const audit = await db.audit_logs.findUniqueOrThrow({ where: { id: assigned.auditId } });
    expect(audit).toMatchObject({ actor_id: finance.id, after: { code: 'BASIC', operation: 'ASSIGN', reason: body.reason } });
    expect(await db.job_runs.count({ where: { scope_id: { startsWith: `${assigned.id}:` } } })).toBe(4);
    await app.close(); app = await boot(); expect((await write(body, a.id, key).expect(201)).body).toEqual(assigned);
    await write({ ...body, reason: 'Changed' }, a.id, key).expect(422); await write(body, b.id, key).expect(422);
    const replay = await db.plan_assignment_requests.findFirstOrThrow({ where: { response: { path: ['id'], equals: assigned.id } } });
    await expect(db.plan_assignment_requests.delete({ where: { request_key: replay.request_key } })).rejects.toThrow();
    expect((await current().expect(200)).body.assignment).not.toHaveProperty('reason');
    expect(await db.vendor_plan_assignments.count({ where: { vendor_id: a.id } })).toBe(1);
  });
  it('extends only the owned current assignment with audit/history and restores an expired assignment', async () => {
    const first = (await write().expect(201)).body;
    const extension = { endsAt: new Date(Date.now() + 60 * 86400000).toISOString(), reason: 'Synthetic extension' };
    await write(extension, b.id, randomUUID(), finance.token, app, 'synthetic', first.id).expect(404);
    await write({ ...extension, endsAt: first.endsAt }, a.id, randomUUID(), finance.token, app, 'synthetic', first.id).expect(400);
    await db.vendor_plan_assignments.update({ where: { id: first.id }, data: { ends_at: new Date(Date.now() - 1) } });
    expect((await current().expect(200)).body.status).toBe('EXPIRED'); await createCustomer().expect(403);
    const key = randomUUID(), renewed = await write(extension, a.id, key, finance.token, app, 'synthetic', first.id).expect(201);
    expect(renewed.body.startsAt).toBe(first.startsAt); expect(renewed.body.id).not.toBe(first.id);
    expect((await current().expect(200)).body).toMatchObject({ status: 'ACTIVE', customerLimit: 100 }); await createCustomer().expect(201);
    expect((await write(extension, a.id, key, finance.token, app, 'synthetic', first.id).expect(201)).body).toEqual(renewed.body);
    await write(extension, a.id, randomUUID(), finance.token, app, 'synthetic', first.id).expect(404);
  });
  it('retains over-limit customers/history when downgrading and keeps effective gates/cap atomic', async () => {
    await write(input(business)).expect(201);
    await db.vendor_customers.createMany({ data: Array.from({ length: 101 }, () => ({ vendor_id: a.id, name: 'Synthetic retained', mobile: mobile() })) });
    await write(input(basic)).expect(201);
    expect((await current().expect(200)).body).toMatchObject({ status: 'ACTIVE', customerLimit: 100, activeCustomers: 101, canAddCustomer: false });
    expect((await current().expect(200)).body.features).not.toContain('ADVANCED_REPORTS'); await createCustomer().expect(422);
    expect(await db.vendor_customers.count({ where: { vendor_id: a.id } })).toBe(101);
  });
  it('keeps new business locked for scheduled assignments while preserving earlier settlement access', async () => {
    const future = { ...input(), startsAt: new Date(Date.now() + 86400000).toISOString() };
    await write(future).expect(201);
    expect((await current().expect(200)).body).toMatchObject({ status: 'SCHEDULED', features: [], canAddCustomer: false });
    await createCustomer().expect(403);
    const policy = app.get(PlanEntitlementsService);
    await expect(db.$transaction(tx => policy.requireOperation(tx, a.id, 'RECORD_PAYMENT'))).rejects.toMatchObject({ status: 403 });
    const active = (await write().expect(201)).body;
    await db.vendor_plan_assignments.update({ where: { id: active.id }, data: { ends_at: new Date(Date.now() - 1) } });
    await write(future).expect(201);
    await db.$transaction(tx => policy.requireOperation(tx, a.id, 'RECORD_PAYMENT'));
    await expect(db.$transaction(tx => policy.requireOperation(tx, a.id, 'NEW_ORDER'))).rejects.toMatchObject({ status: 403 });
  });
  it('rolls assignment, audit, projection, replay and reminder jobs back on a failed schedule', async () => {
    const reminders = app.get(PlanRemindersService), schedule = jest.spyOn(reminders, 'schedule').mockRejectedValueOnce(new Error('Synthetic scheduling failure'));
    await write().expect(503); schedule.mockRestore();
    expect(await db.vendor_plan_assignments.count({ where: { vendor_id: a.id } })).toBe(0);
    expect(await db.audit_logs.count({ where: { entity_id: a.id, action: 'PLAN_ASSIGNED' } })).toBe(0);
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.id } })).assigned_customer_limit).toBeNull();
    await write().expect(201);
  });
  it('dispatches 7/3/1/expiry reminders once, survives restart and suppresses superseded schedules', async () => {
    const assigned = (await write().expect(201)).body;
    const jobs = await db.job_runs.findMany({ where: { scope_id: { startsWith: `${assigned.id}:` } } }); expect(jobs).toHaveLength(4);
    await app.close(); app = await boot();
    for (const [days, remaining] of [[7, 6 * 86400000], [3, 2 * 86400000], [1, 3600000], [0, -1000]]) {
      await db.vendor_plan_assignments.update({ where: { id: assigned.id }, data: { ends_at: new Date(Date.now() + remaining!) } });
      const job = jobs.find(j => j.scope_id === `${assigned.id}:${days}`)!;
      await db.outbox_events.update({ where: { id: job.event_id }, data: { available_at: new Date(Date.now() - 1000) } });
      await Promise.all([app.get(OutboxDispatcherService).dispatchPendingBatch(1, job.event_id), peer.get(OutboxDispatcherService).dispatchPendingBatch(1, job.event_id)]);
      expect(await db.notifications.count({ where: { source_key: `plan:${assigned.id}:${days}` } })).toBe(1);
      expect((await db.job_runs.findUniqueOrThrow({ where: { event_id: job.event_id } })).finished_at).not.toBeNull();
    }
    const old = (await write().expect(201)).body; await write().expect(201);
    const stale = await db.job_runs.findFirstOrThrow({ where: { scope_id: `${old.id}:7` } });
    await db.outbox_events.update({ where: { id: stale.event_id }, data: { available_at: new Date(Date.now() - 1) } });
    expect(await app.get(OutboxDispatcherService).dispatchPendingBatch(1, stale.event_id)).toBe(1);
    expect(await db.notifications.count({ where: { source_key: `plan:${old.id}:7` } })).toBe(0);
  });
});
