import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { CustomersService } from './customers.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';

const testDatabaseUrl = process.env.CUSTOMERS_TEST_DATABASE_URL ?? process.env.NATIVE_TEST_DATABASE_URL;
const native = testDatabaseUrl ? describe : describe.skip;
native('T-028 TC-060–TC-064 customer foundation over native PostgreSQL/HTTP', () => {
  const db = new PrismaService({ datasources: { db: { url: testDatabaseUrl } } });
  const env = { ...process.env };
  let app: INestApplication, peer: INestApplication, service: CustomersService, categoryId: string;
  let a: { id: string; sessionId: string; token: string; vendorId: string }, b: typeof a, c: typeof a;
  let serial = 0;
  const ids: string[] = [];
  const phone = () => String(9000000000 + ++serial);
  const input = (value = phone()) => ({ name: 'Synthetic Customer', mobile: value, address: 'Synthetic address' });
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
    const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
  }
  async function account(role: 'VENDOR' | 'CUSTOMER', number = phone()) {
    const user = await db.users.create({ data: { mobile: `+91${number}`, active_role: role, roles: { create: { role } } } });
    ids.push(user.id);
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
      refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    const vendor = role === 'VENDOR' ? await db.vendors.create({ data: { user_id: user.id, category_id: categoryId } }) : null;
    return { id: user.id, sessionId: session.id, vendorId: vendor?.id ?? '', token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  function get(path = '', token = a.token) {
    return request(app.getHttpServer()).get(`/api/v1/vendor/customers${path}`).set('Authorization', `Bearer ${token}`);
  }
  function create(body: object = input(), key = randomUUID(), token = a.token, instance = app) {
    return request(instance.getHttpServer()).post('/api/v1/vendor/customers').set('Authorization', `Bearer ${token}`).set('Idempotency-Key', key).send(body);
  }
  function patch(id: string, body: object, key = randomUUID(), token = a.token) {
    return request(app.getHttpServer()).patch(`/api/v1/vendor/customers/${id}`).set('Authorization', `Bearer ${token}`).set('Idempotency-Key', key).send(body);
  }
  function links(token = c.token) { return request(app.getHttpServer()).get('/api/v1/customer/link-requests').set('Authorization', `Bearer ${token}`); }
  function decide(id: string, action = 'accept', token = c.token, key = randomUUID(), instance = app) {
    return request(instance.getHttpServer()).post(`/api/v1/customer/link-requests/${id}/${action}`).set('Authorization', `Bearer ${token}`).set('Idempotency-Key', key);
  }
  async function fill(vendorId: string, count: number) {
    await db.vendor_customers.createMany({ data: Array.from({ length: count }, () => ({ vendor_id: vendorId,
      name: 'Synthetic Capacity', mobile: `+91${phone()}` })) });
  }
  beforeAll(async () => {
    const url = new URL(testDatabaseUrl!);
    if (!url.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '5000',
      AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
    await db.$connect(); app = await boot(); peer = await boot(); service = app.get(CustomersService);
    categoryId = (await db.categories.create({ data: { code: `CUSTOMERS-${randomUUID()}`, name_en: 'Synthetic category', name_hi: '', type: 'SUPPLY' } })).id;
  });
  beforeEach(async () => { a = await account('VENDOR'); b = await account('VENDOR'); c = await account('CUSTOMER'); });
  afterAll(async () => {
    await peer?.close(); await app?.close();
    const where = { vendor: { user_id: { in: ids } } };
    await db.customer_link_decisions.deleteMany({ where: { customer: where } });
    await db.customer_subscription_links.deleteMany({ where: { customer: where } });
    await db.vendor_customers.deleteMany({ where });
    await db.vendor_plan_assignments.deleteMany({ where: { vendor: { user_id: { in: ids } } } });
    await db.vendors.deleteMany({ where: { user_id: { in: ids } } });
    await db.idempotency_keys.deleteMany({ where: { user_id: { in: ids } } });
    await db.sessions.deleteMany({ where: { user_id: { in: ids } } });
    await db.users.deleteMany({ where: { id: { in: ids } } });
    if (categoryId) await db.categories.delete({ where: { id: categoryId } });
    await db.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env);
  });
  it('TC-060/061 normalizes mobile, persists one create across two instances/restart and detects duplicates', async () => {
    const body = input(), key = randomUUID();
    const result = await Promise.all([create(body, key), create(body, key, a.token, peer)]);
    expect(result.map(r => r.status)).toEqual([201,201]); expect(result[0]!.body).toEqual(result[1]!.body);
    const id = result[0]!.body.id;
    expect((await get(`/${id}`).expect(200)).body).toMatchObject({ mobile: `+91${body.mobile}`, status: 'ACTIVE', userId: null, linkStatus: 'UNLINKED' });
    await app.close(); app = await boot(); service = app.get(CustomersService);
    a.token = app.get(SessionTokensService).issue(a.id, a.sessionId, []);
    expect((await create(body, key).expect(201)).body).toEqual(result[0]!.body);
    await create({ ...body, name: 'Changed' }, key).expect(422);
    await patch(id, { name: 'Changed' }, key).expect(422);
    expect((await create({ ...body, mobile: `+91${body.mobile}` }).expect(409)).body.code).toBe('DUPLICATE');
    await create(body, randomUUID(), b.token).expect(201);
  });
  it('validates required fields, null PATCH, email, mobile and forged ownership/limits', async () => {
    for (const bad of [{ name: ' ' }, { name: null }, { mobile: '123' }, { mobile: null }, { email: 'bad' },
      { preferredPayment: 'CARD' }, { preferredPayment: null }, { address: null }, { userId: c.id }, { vendorId: b.vendorId },
      { customerLimit: 1000 }, { status: 'INACTIVE' }]) await create({ ...input(), ...bad }).expect(400);
    const id = (await create().expect(201)).body.id;
    for (const bad of [{ name: null }, { mobile: null }, { status: null }, { status: 'BAD' }, { address: null }]) await patch(id, bad).expect(400);
    await patch(id, { email: 'synthetic@example.invalid' }).expect(200);
    expect((await patch(id, { email: null }).expect(200)).body.email).toBeNull();
    await request(app.getHttpServer()).post('/api/v1/vendor/customers').set('Authorization', `Bearer ${a.token}`).send(input()).expect(400);
    await get('/bad-uuid').expect(400); await get('?limit=101').expect(400); await get('?filter=UNKNOWN').expect(400);
  });
  it('TC-060 searches/filters/paginates, retains inactive detail and uses real subscription references', async () => {
    const first = (await create({ ...input(), name: 'Synthetic Alpha' }).expect(201)).body.id;
    const second = (await create({ ...input(), name: 'Synthetic Beta' }).expect(201)).body.id;
    await patch(second, { status: 'INACTIVE', preferredPayment: 'UPI' }).expect(200);
    expect((await get('?search=ALPHA&filter=ACTIVE').expect(200)).body.total).toBe(1);
    const detail = (await get(`/${second}`).expect(200)).body;
    expect((await get(`?search=${detail.mobile.slice(-6)}&filter=INACTIVE`).expect(200)).body.items[0].id).toBe(second);
    expect((await get('?filter=SUBSCRIPTION').expect(200)).body.total).toBe(0);
    const subscriptionId = randomUUID();
    await db.$transaction(tx => service.setSubscriptionReference(tx, subscriptionId, first, 'PAUSED'));
    expect((await get('?filter=SUBSCRIPTION').expect(200)).body.items[0].id).toBe(first);
    await db.$transaction(tx => service.setSubscriptionReference(tx, subscriptionId, first, 'CANCELLED'));
    expect((await get('?filter=SUBSCRIPTION').expect(200)).body.total).toBe(0);
    expect((await get('?limit=1&offset=1').expect(200)).body).toMatchObject({ total: 2, activeCount: 1, customerLimit: 50 });
  });
  it('TC-062 enforces exactly 50 pre-assignment, serializes final slot and counts reactivation but not inactive', async () => {
    await fill(a.vendorId, 49);
    const result = await Promise.all([create(input()), create(input(), randomUUID(), a.token, peer)]);
    expect(result.map(r => r.status).sort()).toEqual([201,422]);
    expect(result.find(r => r.status === 422)!.body.code).toBe('PLAN_CUSTOMER_LIMIT');
    const row = result.find(r => r.status === 201)!.body;
    const retryBody = input(), retryKey = randomUUID();
    await create(retryBody, retryKey).expect(422);
    await patch(row.id, { status: 'INACTIVE' }).expect(200);
    await create(retryBody, retryKey).expect(201); // Failed attempt did not reserve key or consume capacity.
    await patch(row.id, { status: 'ACTIVE' }).expect(422);
    await patch(row.id, { name: 'Synthetic Edited While Full' }).expect(200);
    expect((await get().expect(200)).body.activeCount).toBe(50);
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).assigned_customer_limit).toBeNull();
  });
  it('TC-062 assignment hook preserves 100/250/500/1000 limits and rolls back atomically without changing catalog', async () => {
    const catalogBefore = await db.plans.findMany({ orderBy: { code: 'asc' } });
    for (const [code, limit] of [['BASIC',100],['STANDARD',250],['BUSINESS',500],['PREMIUM',1000]] as const) {
      const owner = await account('VENDOR');
      await db.$transaction(tx => assignPlanFixture(tx, owner.vendorId, code));
      await fill(owner.vendorId, limit - 1);
      const race = await Promise.all([create(input(), randomUUID(), owner.token), create(input(), randomUUID(), owner.token, peer)]);
      expect(race.map(r => r.status).sort()).toEqual([201,422]);
      expect((await get('', owner.token).expect(200)).body).toMatchObject({ activeCount: limit, customerLimit: limit });
    }
    await expect(db.$transaction(async tx => { await service.setAssignedCustomerLimit(tx, a.vendorId, 100); throw new Error('Synthetic rollback'); })).rejects.toThrow('Synthetic rollback');
    expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).assigned_customer_limit).toBeNull();
    expect(await db.plans.findMany({ orderBy: { code: 'asc' } })).toEqual(catalogBefore);
  });
  it('denies unauthenticated, cross-vendor, inactive-role and suspended access including cached mutations', async () => {
    const body = input(), key = randomUUID(), id = (await create(body, key).expect(201)).body.id;
    await get('', '').expect(401); await get('', c.token).expect(403); await create(input(), randomUUID(), c.token).expect(403);
    await get(`/${id}`, b.token).expect(404); await patch(id, { name: 'Forgery' }, randomUUID(), b.token).expect(404);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'CUSTOMER' } });
    await get().expect(403); await create(body, key).expect(403);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'VENDOR' } });
    await db.vendors.update({ where: { id: a.vendorId }, data: { is_suspended: true } });
    await get().expect(403); await create(body, key).expect(403);
    await links(a.token).expect(403);
  });
  it('TC-064 derives prompts after registration; matching mobile never grants access until explicit consent', async () => {
    const number = phone(), id = (await create(input(number)).expect(201)).body.id;
    const person = await account('CUSTOMER', number);
    expect((await links(person.token).expect(200)).body.items).toEqual([{ id, vendorId: a.vendorId, businessName: null }]);
    expect((await links().expect(200)).body.items).toEqual([]);
    await decide(id).expect(404);
    await expect(db.$transaction(tx => service.requireLinked(tx, person.id, id))).rejects.toMatchObject({ response: { code: 'CUSTOMER_NOT_FOUND' } });
    const key = randomUUID(), accepted = await Promise.all([decide(id, 'accept', person.token, key), decide(id, 'accept', person.token, key, peer)]);
    expect(accepted.map(r => r.status)).toEqual([201,201]);
    expect(await db.customer_link_decisions.count({ where: { vendor_customer_id: id } })).toBe(1);
    expect((await db.$transaction(tx => service.requireLinked(tx, person.id, id))).id).toBe(id);
    await expect(db.$transaction(tx => service.requireLinked(tx, c.id, id))).rejects.toMatchObject({ response: { code: 'CUSTOMER_NOT_FOUND' } });
    expect((await links(person.token).expect(200)).body.items).toEqual([]);
    expect((await get(`/${id}`).expect(200)).body).toMatchObject({ userId: person.id, linkStatus: 'LINKED' });
    await patch(id, { mobile: phone() }).expect(409);
    await patch(id, { status: 'INACTIVE' }).expect(200);
    expect((await db.$transaction(tx => service.requireLinked(tx, person.id, id))).id).toBe(id);
    await decide(id, 'decline', person.token).expect(409);
  });
  it('TC-064 persists decline/replay and rejects conflicting decisions, suspended prompts and stale mobile matches', async () => {
    const number = (await db.users.findUniqueOrThrow({ where: { id: c.id } })).mobile;
    const id = (await create(input(number)).expect(201)).body.id;
    const key = randomUUID(); await decide(id, 'decline', c.token, key).expect(201);
    await decide(id, 'decline', c.token, key).expect(201); await decide(id, 'accept').expect(409);
    expect((await links().expect(200)).body.items).toEqual([]);
    expect((await db.vendor_customers.findUniqueOrThrow({ where: { id } })).user_id).toBeNull();
    const otherId = (await create(input(number), randomUUID(), b.token).expect(201)).body.id;
    await db.vendors.update({ where: { id: b.vendorId }, data: { is_suspended: true } });
    expect((await links().expect(200)).body.items).toEqual([]); await decide(otherId).expect(404);
    await db.vendors.update({ where: { id: b.vendorId }, data: { is_suspended: false } });
    await patch(otherId, { mobile: phone() }, randomUUID(), b.token).expect(200);
    await decide(otherId).expect(404);
  });
});
