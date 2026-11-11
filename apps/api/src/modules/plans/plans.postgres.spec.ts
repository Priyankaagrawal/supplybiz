import { Controller, ExecutionContext, Get, INestApplication, UseGuards } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomInt, randomUUID } from 'node:crypto';
import { plan_code } from '@prisma/client';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionGuard } from '../auth/sessions.controller';
import { SessionTokensService } from '../auth/session-tokens.service';
import { PlanEntitlementsService } from './plan-entitlements.service';
import { CUSTOMER_LIMITS, PLAN_FEATURES, PlanOperation } from './plan-policy';
import { PlanGuard, RequirePlanFeature } from './plan.guard';
import { assignPlanFixture } from '../../../test/fixtures/plans';

const databaseUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = databaseUrl ? describe : describe.skip;
native('T-084 TC-120/121/125/126 native entitlements and HTTP capacity', () => {
  const db = new PrismaService({ datasources: { db: { url: databaseUrl } } });
  const env = { ...process.env };
  let app: INestApplication, plans: PlanEntitlementsService, categoryId: string;
  let serial = randomInt(0, 800000000);
  type Actor = { userId: string; vendorId: string; token: string };
  let a: Actor, b: Actor;
  const phone = () => `+91${9100000000 + ++serial}`;
  // Routes exist only in this testing module; no production/test-mode paid-route stub.
  @Controller('plan-fixture')
  @UseGuards({ canActivate: (c: ExecutionContext) => app.get(SessionGuard).canActivate(c) },
    { canActivate: (c: ExecutionContext) => app.get(PlanGuard).canActivate(c) })
  class FixtureController {
    @Get('sale') @RequirePlanFeature('QUICK_SALE') sale() { return { allowed: true }; }
    @Get('reports') @RequirePlanFeature('ADVANCED_REPORTS') reports() { return { allowed: true }; }
  }
  async function account(role: 'VENDOR' | 'CUSTOMER' = 'VENDOR'): Promise<Actor> {
    const user = await db.users.create({ data: { mobile: phone(), active_role: role, roles: { create: { role } } } });
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
      refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    const vendor = role === 'VENDOR' ? await db.vendors.create({ data: { user_id: user.id, category_id: categoryId } }) : null;
    return { userId: user.id, vendorId: vendor?.id ?? '', token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  const grant = (actor: Actor, code: plan_code, start?: Date, end?: Date) => db.$transaction(tx => assignPlanFixture(tx, actor.vendorId, code, start, end));
  const feature = (path: string, actor = a) => request(app.getHttpServer()).get(`/api/v1/plan-fixture/${path}`).set('Authorization', `Bearer ${actor.token}`);
  const create = (actor = a, key = randomUUID()) => request(app.getHttpServer()).post('/api/v1/vendor/customers')
    .set('Authorization', `Bearer ${actor.token}`).set('Idempotency-Key', key).send({ name: 'Synthetic Plan Customer', mobile: phone() });
  const patch = (id: string, body: object, actor = a) => request(app.getHttpServer()).patch(`/api/v1/vendor/customers/${id}`)
    .set('Authorization', `Bearer ${actor.token}`).set('Idempotency-Key', randomUUID()).send(body);
  const operation = (op: PlanOperation) => db.$transaction(tx => plans.requireOperation(tx, a.vendorId, op));
  async function fill(count: number, actor = a) {
    await db.vendor_customers.createMany({ data: Array.from({ length: count }, () => ({ vendor_id: actor.vendorId, name: 'Synthetic Capacity', mobile: phone() })) });
  }
  beforeAll(async () => {
    const url = new URL(databaseUrl!);
    if (!url.pathname.endsWith('_test') || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000',
      AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
    await db.$connect();
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule], controllers: [FixtureController] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
    app = module.createNestApplication(); configureHttpApp(app); await app.init(); plans = app.get(PlanEntitlementsService);
    categoryId = (await db.categories.create({ data: { code: `PLAN-${randomUUID()}`, name_en: 'Synthetic Plan Category', name_hi: '', type: 'SUPPLY', product_types: ['OTHER'] } })).id;
  });
  beforeEach(async () => { a = await account(); b = await account(); });
  afterAll(async () => {
    // Audit/stock records are append-only: retain synthetic fixtures in isolated DB.
    await app?.close(); await db.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env);
  });
  it('TC-125 allows exactly 50 setup customers without a default/trial or paid features', async () => {
    await feature('sale').expect(403); await fill(49);
    const race = await Promise.all([create(), create()]);
    expect(race.map(r => r.status).sort()).toEqual([201, 422]);
    expect(await db.vendor_plan_assignments.count({ where: { vendor_id: a.vendorId } })).toBe(0);
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).assigned_customer_limit).toBeNull();
  });
  it.each(Object.keys(CUSTOMER_LIMITS) as plan_code[])('TC-120/121 checks %s features and last-slot concurrency', async code => {
    await grant(a, code); await feature('sale').expect(200);
    await feature('reports').expect(['BUSINESS', 'PREMIUM'].includes(code) ? 200 : 403);
    for (const allowed of PLAN_FEATURES[code]) await db.$transaction(tx => plans.requireFeature(tx, a.vendorId, allowed));
    for (const denied of PLAN_FEATURES.PREMIUM.filter(f => !PLAN_FEATURES[code].includes(f))) {
      await expect(db.$transaction(tx => plans.requireFeature(tx, a.vendorId, denied))).rejects.toMatchObject({ status: 403 });
    }
    await expect(db.$transaction(tx => plans.requireFeature(tx, a.vendorId, 'WALLET_SETTLEMENT' as never))).rejects.toMatchObject({ status: 403 });
    await fill(CUSTOMER_LIMITS[code] - 1);
    const race = await Promise.all([create(), create()]);
    expect(race.map(r => r.status).sort()).toEqual([201, 422]);
    expect(race.find(r => r.status === 422)!.body).toMatchObject({ code: 'PLAN_CUSTOMER_LIMIT',
      detail: `The active customer limit is ${CUSTOMER_LIMITS[code]}. Contact support to change the assigned plan.` });
  });
  it('denies missing session, foreign vendor claims, wrong role, disabled user and suspension', async () => {
    await grant(b, 'PREMIUM');
    await request(app.getHttpServer()).get('/api/v1/plan-fixture/sale').expect(401);
    await feature(`sale?vendorId=${b.vendorId}&plan=PREMIUM`).set('X-Plan', 'PREMIUM').expect(403);
    await feature('sale', b).expect(200);
    await feature('sale', await account('CUSTOMER')).expect(403);
    await grant(a, 'BASIC');
    await db.users.update({ where: { id: a.userId }, data: { active_role: 'CUSTOMER' } }); await feature('sale').expect(403);
    await db.users.update({ where: { id: a.userId }, data: { active_role: 'VENDOR', status: 'BLOCKED' } }); await feature('sale').expect(403);
    await db.users.update({ where: { id: a.userId }, data: { status: 'ACTIVE' } });
    await db.vendors.update({ where: { id: a.vendorId }, data: { is_suspended: true } }); await feature('sale').expect(403); await create().expect(403);
  });
  it('TC-125 expires without a grace/fallback, retains reads and permitted settlement/order operations, then renews', async () => {
    await grant(a, 'STANDARD'); const id = (await create().expect(201)).body.id;
    await patch(id, { status: 'INACTIVE' }).expect(200);
    await grant(a, 'STANDARD', new Date(Date.now() - 120000), new Date(Date.now() - 1));
    await feature('sale').expect(403); expect((await create().expect(403)).body.code).toBe('PLAN_FEATURE_LOCKED');
    await patch(id, { status: 'ACTIVE' }).expect(403); await patch(id, { name: 'Synthetic Preserved' }).expect(200);
    for (const op of ['READ_HISTORY', 'RECORD_PAYMENT', 'CONFIRM_PAYMENT', 'COMPLETE_ORDER', 'CANCEL_ORDER'] as const) await operation(op);
    for (const op of ['NEW_ORDER', 'POS_SALE', 'SUBSCRIPTION', 'GENERATE_DELIVERY'] as const) await expect(operation(op)).rejects.toMatchObject({ status: 403 });
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).assigned_customer_limit).toBe(250);
    await grant(a, 'BASIC'); await create().expect(201); await feature('sale').expect(200);
    await expect(operation('SUBSCRIPTION')).rejects.toMatchObject({ status: 403 });
  });
  it('TC-125 rejects future starts and unaudited projection; uses DB time after waiting on the vendor lock', async () => {
    await db.vendors.update({ where: { id: a.vendorId }, data: { assigned_customer_limit: 1000 } });
    await feature('sale').expect(403); await create().expect(403);
    await grant(a, 'PREMIUM', new Date(Date.now() + 60000), new Date(Date.now() + 120000));
    await feature('sale').expect(403); await create().expect(403);
    await grant(a, 'BASIC');
    let release!: () => void, locked!: () => void;
    const acquired = new Promise<void>(r => { locked = r; }); const hold = new Promise<void>(r => { release = r; });
    const writer = db.$transaction(async tx => {
      await tx.$queryRaw`SELECT id FROM vendors WHERE id = ${a.vendorId}::uuid FOR UPDATE`;
      await tx.vendor_plan_assignments.updateMany({ where: { vendor_id: a.vendorId, superseded_at: null }, data: { ends_at: new Date(Date.now() + 150) } });
      locked(); await hold;
    });
    await acquired; const waiting = expect(operation('NEW_ORDER')).rejects.toMatchObject({ status: 403 });
    await new Promise(r => setTimeout(r, 250)); release(); await writer;
    await waiting;
  });
  it('TC-126 retains customers at downgrade, blocks growth until below cap and applies new gates immediately', async () => {
    await grant(a, 'BUSINESS'); await fill(102); await grant(a, 'BASIC');
    await feature('reports').expect(403); await feature('sale').expect(200); await operation('NEW_ORDER');
    await create().expect(422);
    const rows = await db.vendor_customers.findMany({ where: { vendor_id: a.vendorId }, take: 3 });
    await patch(rows[0]!.id, { name: 'Synthetic Still Editable' }).expect(200);
    for (const row of rows) await patch(row.id, { status: 'INACTIVE' }).expect(200);
    await patch(rows[0]!.id, { status: 'ACTIVE' }).expect(200);
    await patch(rows[1]!.id, { status: 'ACTIVE' }).expect(422);
    expect(await db.vendor_customers.count({ where: { vendor_id: a.vendorId } })).toBe(102);
  });
  it('denies mismatched audit evidence and never restores setup access when current assignment is absent', async () => {
    const assigned = await grant(a, 'PREMIUM');
    const wrongAudit = await db.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: assigned.granted_by_admin,
      entity: 'VENDOR', entity_id: b.vendorId, action: 'PLAN_ASSIGNED' } });
    await db.vendor_plan_assignments.update({ where: { id: assigned.id }, data: { audit_id: wrongAudit.id } });
    await feature('sale').expect(403); await create().expect(403);
    await db.vendor_plan_assignments.update({ where: { id: assigned.id }, data: { superseded_at: new Date() } });
    await db.vendors.update({ where: { id: a.vendorId }, data: { assigned_customer_limit: null } });
    await create().expect(403);
  });
  it('keeps assignment/projection changes atomic and rejects overlapping current rows or invalid dates', async () => {
    const first = await grant(a, 'STANDARD');
    await expect(db.$transaction(async tx => {
      await assignPlanFixture(tx, a.vendorId, 'BASIC'); throw new Error('Synthetic rollback');
    })).rejects.toThrow('Synthetic rollback');
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).assigned_customer_limit).toBe(250);
    expect((await db.vendor_plan_assignments.findUniqueOrThrow({ where: { id: first.id } })).superseded_at).toBeNull();
    await expect(grant(a, 'BASIC', new Date(), new Date(Date.now() - 1))).rejects.toThrow();
    await feature('sale').expect(200);
    const audit = await db.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: first.granted_by_admin,
      entity: 'VENDOR', entity_id: a.vendorId, action: 'PLAN_ASSIGNED' } });
    await expect(db.vendor_plan_assignments.create({ data: { vendor_id: a.vendorId, plan_id: first.plan_id,
      starts_at: first.starts_at, ends_at: first.ends_at, reason: 'Synthetic duplicate', granted_by_admin: first.granted_by_admin, audit_id: audit.id } })).rejects.toThrow();
  });
  it('locks current stock management routes and prevents stock PATCH/opening bypass', async () => {
    const body = { name: 'Synthetic Product', productType: 'OTHER', unitType: 'PCS', unitValue: 1, sellingPricePaise: 100, stockQty: 0 };
    const product = (data: object) => request(app.getHttpServer()).post('/api/v1/vendor/products').set('Authorization', `Bearer ${a.token}`).set('Idempotency-Key', randomUUID()).send(data);
    const row = await product(body).expect(201);
    const adjust = () => request(app.getHttpServer()).post(`/api/v1/vendor/products/${row.body.id}/stock-adjustments`).set('Authorization', `Bearer ${a.token}`).set('Idempotency-Key', randomUUID()).send({ delta: 1, reason: 'Synthetic recount' });
    await adjust().expect(403); await product({ ...body, stockQty: 1 }).expect(403);
    await grant(a, 'STANDARD'); await adjust().expect(403);
    await request(app.getHttpServer()).patch(`/api/v1/vendor/products/${row.body.id}`).set('Authorization', `Bearer ${a.token}`).set('Idempotency-Key', randomUUID()).send({ stockQty: 0, name: 'Synthetic Renamed' }).expect(200);
    await request(app.getHttpServer()).patch(`/api/v1/vendor/products/${row.body.id}`).set('Authorization', `Bearer ${a.token}`).set('Idempotency-Key', randomUUID()).send({ stockQty: 1, stockReason: 'Synthetic recount' }).expect(403);
    await grant(a, 'BUSINESS'); await adjust().expect(201);
    await grant(a, 'BASIC'); await adjust().expect(403);
    expect((await db.products.findUniqueOrThrow({ where: { id: row.body.id } })).stock_qty).toBe(1);
  });
});
