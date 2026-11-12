import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomInt, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from './home.service';

const databaseUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = databaseUrl ? describe : describe.skip;
native('T-042 / TC-201 customer home native PostgreSQL/HTTP', () => {
  const db = new PrismaService({ datasources: { db: { url: databaseUrl } } });
  const env = { ...process.env }, categories: string[] = [];
  let app: INestApplication, serial = 0;
  type Actor = { id: string; token: string; mobile: string };
  let a: Actor, b: Actor, vendor: Actor, vendorId: string, productId: string, ownedId: string, foreignId: string, unlinkedId: string;
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
    const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
  }
  async function account(role: 'CUSTOMER' | 'VENDOR' = 'CUSTOMER'): Promise<Actor> {
    const user = await db.users.create({ data: { mobile: `synthetic-home-${randomUUID()}`, active_role: role, roles: { create: { role } } } });
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(), refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    return { id: user.id, mobile: user.mobile, token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  async function category(status: 'ENABLED' | 'COMING_SOON' | 'HIDDEN', type: 'SUPPLY' | 'BILL' = 'SUPPLY') {
    const row = await db.categories.create({ data: { code: `HOME-${randomUUID()}`, name_en: 'Synthetic English category', name_hi: '', type, status,
      icon: 'milk', sort_order: 0, product_types: ['MILK'] } }); categories.push(row.id); return row;
  }
  const get = (query: object = {}, actor = a) => request(app.getHttpServer()).get('/api/v1/customer/home')
    .set('Authorization', `Bearer ${actor.token}`).query(query);
  async function order(customerId: string, offset = 0, status = 'ACCEPTED') {
    const clock = await db.$transaction(tx => homeClock(tx));
    const date = new Date(`${clock.day}T00:00:00Z`); date.setUTCDate(date.getUTCDate() + offset);
    return db.orders.create({ data: { order_no: `SYN-${randomUUID()}`, vendor_id: vendorId, vendor_customer_id: customerId,
      source: 'APP', status, delivery_date: date, time_slot: '07:00-08:00', address_snapshot: { synthetic: true },
      subtotal_paise: 12300n, delivery_charge_paise: 0n, total_paise: 12300n, payment_mode: 'POD_CASH', payment_status: 'UNPAID',
      created_at: new Date(Date.now() - ++serial * 1000), items: { create: { product_id: productId, product_name_snapshot: 'Synthetic order-time milk',
        unit_snapshot: { value: 1, type: 'L' }, unit_price_paise: 12300n, qty: 1, line_total_paise: 12300n } } } });
  }
  beforeAll(async () => {
    const url = new URL(databaseUrl!);
    if (!url.pathname.endsWith('_test') || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test DB required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000',
      AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
    await db.$connect(); app = await boot(); a = await account(); b = await account(); vendor = await account('VENDOR');
    const cat = await category('ENABLED');
    vendorId = (await db.vendors.create({ data: { user_id: vendor.id, category_id: cat.id, business_name: 'Synthetic home vendor' } })).id;
    productId = (await db.products.create({ data: { vendor_id: vendorId, name: 'Current catalog name', product_type: 'MILK', milk_type: 'TONED', unit_type: 'L', unit_value: 1, selling_price_paise: 100 } })).id;
    ownedId = (await db.vendor_customers.create({ data: { vendor_id: vendorId, user_id: a.id, name: 'Synthetic linked', mobile: '+919000000001' } })).id;
    foreignId = (await db.vendor_customers.create({ data: { vendor_id: vendorId, user_id: b.id, name: 'Synthetic foreign', mobile: '+919000000002' } })).id;
    // A matching mobile without consent must not expose its orders.
    const match = `+91${9000000000 + randomInt(0, 999999999)}`; await db.users.update({ where: { id: a.id }, data: { mobile: match } });
    unlinkedId = (await db.vendor_customers.create({ data: { vendor_id: vendorId, name: 'Synthetic unlinked', mobile: match } })).id;
  });
  afterAll(async () => {
    if (categories.length) await db.categories.updateMany({ where: { id: { in: categories } }, data: { status: 'HIDDEN' } });
    await app?.close(); await db.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env);
  });
  it('TC-201 exposes English enabled/coming-soon supply categories, with stable order and no marketing/provider fields', async () => {
    const enabled = await category('ENABLED'), coming = await category('COMING_SOON'), hidden = await category('HIDDEN'), bill = await category('ENABLED', 'BILL');
    const response = await get().expect(200);
    expect(response.headers['cache-control']).toBe('no-store');
    const rows = response.body.categories as { id: string; available: boolean }[];
    expect(rows.find(r => r.id === enabled.id)).toMatchObject({ name: enabled.name_en, available: true, productTypes: ['MILK'], icon: 'milk' });
    expect(rows.find(r => r.id === coming.id)).toMatchObject({ status: 'COMING_SOON', available: false });
    expect(rows.some(r => [hidden.id, bill.id].includes(r.id))).toBe(false);
    const tied = rows.filter(r => [enabled.id, coming.id].includes(r.id)).map(r => r.id); expect(tied).toEqual([...tied].sort());
    expect(response.body).not.toHaveProperty('banners'); expect(response.body).not.toHaveProperty('coupons');
    expect(response.body.businessDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
  it('TC-201 returns only today’s linked customer orders, preserving snapshot names and existing history', async () => {
    const today = await order(ownedId), yesterday = await order(ownedId, -1), tomorrow = await order(ownedId, 1), foreign = await order(foreignId), unmatched = await order(unlinkedId);
    await db.products.update({ where: { id: productId }, data: { name: 'Changed live name', is_active: false, deleted_at: new Date() } });
    await db.vendors.update({ where: { id: vendorId }, data: { is_suspended: true } });
    await db.vendor_customers.update({ where: { id: ownedId }, data: { status: 'INACTIVE' } });
    const response = await get({ lat: 0, lng: 0, pincode: '110001' }).expect(200);
    expect(response.body.deliveries).toHaveLength(1);
    expect(response.body.deliveries[0]).toMatchObject({ id: today.id, vendorId, status: 'ACCEPTED', timeSlot: '07:00-08:00',
      items: [{ productId, name: 'Synthetic order-time milk', qty: 1 }] });
    const text = JSON.stringify(response.body); for (const row of [yesterday, tomorrow, foreign, unmatched]) expect(text).not.toContain(row.id);
    for (const field of ['mobile', 'address_snapshot', 'vendor_customer_id', 'subtotal_paise']) expect(text).not.toContain(field);
    expect((await get({}, b).expect(200)).body.deliveries.map((r: { id: string }) => r.id)).toEqual([foreign.id]);
  });
  it('uses database IST date at midnight boundaries, independent of UTC date', async () => {
    const before = await db.$transaction(tx => homeClock(tx, new Date('2026-11-11T18:29:59.999Z')));
    const after = await db.$transaction(tx => homeClock(tx, new Date('2026-11-11T18:30:00.000Z')));
    expect(before.day).toBe('2026-11-11'); expect(after.day).toBe('2026-11-12');
    expect(after.now.toISOString()).toBe('2026-11-11T18:30:00.000Z');
  });
  it('paginates tied orders without duplicates and scopes cursors to owner/current day', async () => {
    const time = new Date();
    for (let i = 0; i < 44; i++) { const row = await order(ownedId); await db.orders.update({ where: { id: row.id }, data: { created_at: time } }); }
    const first = (await get().expect(200)).body, second = (await get({ cursor: first.nextCursor }).expect(200)).body, third = (await get({ cursor: second.nextCursor }).expect(200)).body;
    expect([first.deliveries.length, second.deliveries.length, third.deliveries.length]).toEqual([20, 20, 5]); expect(third.nextCursor).toBeNull();
    const ids = [...first.deliveries, ...second.deliveries, ...third.deliveries].map((r: { id: string }) => r.id);
    expect(new Set(ids).size).toBe(45);
    await get({ cursor: first.nextCursor }, b).expect(400);
    await get({ cursor: (await order(ownedId, -1)).id }).expect(400);
  });
  it('refresh/restart reads current persisted status and empty accounts remain empty', async () => {
    const row = (await get({ limit: 1 }).expect(200)).body.deliveries[0];
    await db.orders.update({ where: { id: row.id }, data: { status: 'PREPARING', version: { increment: 1 } } });
    await app.close(); app = await boot();
    expect((await get({ limit: 1 }).expect(200)).body.deliveries[0].status).toBe('PREPARING');
    const empty = await account(); const result = (await get({}, empty).expect(200)).body;
    expect(result.deliveries).toEqual([]); expect(result.nextCursor).toBeNull();
  });
  it('denies session/role abuse and rejects forged dates/owners, invalid location pairs and pagination', async () => {
    await request(app.getHttpServer()).get('/api/v1/customer/home').expect(401); await get({}, vendor).expect(403);
    for (const query of [{ userId: b.id }, { date: '2020-01-01' }, { vendorId }, { lat: '' }, { lat: 1 }, { lat: 91, lng: 0 },
      { lat: 'NaN', lng: 0 }, { pincode: '000000' }, { limit: 0 }, { limit: 51 }, { cursor: 'bad' }]) await get(query).expect(400);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'VENDOR' } }); await get().expect(403);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'CUSTOMER', status: 'BLOCKED' } }); await get().expect(403);
  });
});
