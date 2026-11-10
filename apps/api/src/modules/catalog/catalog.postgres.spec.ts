import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import sharp from 'sharp';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { CatalogService } from './catalog.service';

const native = process.env.CATALOG_TEST_DATABASE_URL ? describe : describe.skip;
native('T-026 catalog HTTP → native PostgreSQL (TC-035–TC-041 focused foundation)', () => {
  const db = new PrismaService({ datasources: { db: { url: process.env.CATALOG_TEST_DATABASE_URL } } });
  const before = { ...process.env };
  let app: INestApplication, catalog: CatalogService, owner: string, vendorId: string, categoryId: string;
  let token: string, other: string, customer: string, id: string;
  const accounts: { id: string; sessionId: string }[] = [];
  const input = { name: 'Synthetic Cow Milk', productType: 'MILK', milkType: 'COW', unitValue: 1.5,
    unitType: 'L', sellingPricePaise: 6000, subscriptionPricePaise: 5500, stockQty: 20 };
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
    app = module.createNestApplication(); configureHttpApp(app); await app.init();
    catalog = app.get(CatalogService);
    if (accounts.length) [token, other, customer] = accounts.map(a => app.get(SessionTokensService).issue(a.id, a.sessionId, []));
  }
  async function account(role: 'VENDOR' | 'CUSTOMER') {
    const user = await db.users.create({ data: { mobile: `synthetic-${randomUUID()}`, active_role: role, roles: { create: { role } } } });
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
      refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    accounts.push({ id: user.id, sessionId: session.id });
    if (role === 'VENDOR') await db.vendors.create({ data: { user_id: user.id, category_id: categoryId, settings: { create: {} } } });
    return app.get(SessionTokensService).issue(user.id, session.id, []);
  }
  function get(path = '', access = token) {
    return request(app.getHttpServer()).get(`/api/v1/vendor/products${path}`).set('Authorization', `Bearer ${access}`);
  }
  function create(body: object = input, key = randomUUID(), access = token) {
    return request(app.getHttpServer()).post('/api/v1/vendor/products').set('Authorization', `Bearer ${access}`)
      .set('Idempotency-Key', key).send(body);
  }
  function patch(body: object, product = id, key = randomUUID(), access = token) {
    return request(app.getHttpServer()).patch(`/api/v1/vendor/products/${product}`).set('Authorization', `Bearer ${access}`)
      .set('Idempotency-Key', key).send(body);
  }
  function adjust(delta: number, key = randomUUID(), product = id, access = token) {
    return request(app.getHttpServer()).post(`/api/v1/vendor/products/${product}/stock-adjustments`)
      .set('Authorization', `Bearer ${access}`).set('Idempotency-Key', key).send({ delta, reason: 'Synthetic count correction' });
  }
  function remove(product = id, key = randomUUID(), access = token) {
    return request(app.getHttpServer()).delete(`/api/v1/vendor/products/${product}`).set('Authorization', `Bearer ${access}`).set('Idempotency-Key', key);
  }
  beforeAll(async () => {
    const url = new URL(process.env.CATALOG_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '1000' });
    await db.$connect(); await boot();
    categoryId = (await db.categories.create({ data: { code: `CATALOG-${randomUUID()}`, name_en: 'Synthetic Catalog', name_hi: '',
      type: 'SUPPLY', product_types: ['MILK','PANEER','OTHER'] } })).id;
    token = await account('VENDOR'); other = await account('VENDOR'); customer = await account('CUSTOMER');
    owner = accounts[0]!.id;
    vendorId = (await db.vendors.findUniqueOrThrow({ where: { user_id: owner } })).id;
  });
  afterAll(async () => {
    // Append-only movements retain synthetic fixtures in the dedicated test DB.
    await app?.close(); await db.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in before)) delete process.env[key];
    Object.assign(process.env, before);
  });
  it('TC-035 creates one priced product/opening movement across concurrent retry and restart', async () => {
    expect((await get().expect(200)).body).toEqual({ items: [], total: 0 });
    const key = randomUUID(), result = await Promise.all([create(input, key), create(input, key)]);
    expect(result.map(r => r.status)).toEqual([201,201]); expect(result[0]!.body).toEqual(result[1]!.body);
    id = result[0]!.body.id;
    expect(result[0]!.body).toMatchObject({ name: input.name, unitValue: 1.5, moq: 1, stockQty: 20, isActive: true });
    expect(await db.stock_movements.count({ where: { product_id: id, reason: 'OPENING' } })).toBe(1);
    await app.close(); await boot(); expect((await create(input, key).expect(201)).body).toEqual(result[0]!.body);
    await create({ ...input, name: 'Changed' }, key).expect(422);
    await patch({ name: 'Changed' }, id, key).expect(422);
    expect((await get(`/${id}`).expect(200)).body).toEqual(result[0]!.body);
  });
  it('TC-036 validates prices, types, units, nulls, pack quantities and forged fields', async () => {
    for (const bad of [{ subscriptionPricePaise: 6001 }, { subscriptionPricePaise: -1 }, { sellingPricePaise: 1.5 }, { sellingPricePaise: 0 },
      { sellingPricePaise: 2147483648 }, { stockQty: -1 }, { stockQty: 1.5 }, { moq: 0 }, { moq: null },
      { stockQty: null }, { name: '  ' }, { name: null }, { productType: 'NO_TYPE' }, { milkType: null },
      { unitValue: 0 }, { unitValue: 1.0001 }, { unitType: 'BAD' }, { description: 'x'.repeat(501) }, { vendorId: vendorId }]) {
      await create({ ...input, ...bad }).expect(400);
    }
    await create({ ...input, productType: 'PANEER' }).expect(400);
    for (const bad of [{ name: null }, { sellingPricePaise: null }, { stockQty: null }, { isActive: null }, { stockQty: 12 }]) await patch(bad).expect(400);
    await request(app.getHttpServer()).post('/api/v1/vendor/products').set('Authorization', `Bearer ${token}`).send(input).expect(400);
    await adjust(0).expect(400); await adjust(-21).expect(409); await adjust(2147483647).expect(400);
    expect((await get(`/${id}`).expect(200)).body.stockQty).toBe(20);
    expect((await patch({ subscriptionPricePaise: 0 }).expect(200)).body.subscriptionPricePaise).toBe(0);
  });
  it('denies IDOR, customer/inactive-role access, suspension, and unauthenticated requests', async () => {
    await get('', '').expect(401); await get('', customer).expect(403);
    await create(input, randomUUID(), customer).expect(403);
    await get(`/${id}`, other).expect(404); await patch({ name: 'Forgery' }, id, randomUUID(), other).expect(404);
    await adjust(-1, randomUUID(), id, other).expect(404); await remove(id, randomUUID(), other).expect(404);
    await db.users.update({ where: { id: owner }, data: { active_role: 'CUSTOMER' } });
    await get().expect(403); await patch({ name: 'Forgery' }).expect(403);
    await db.users.update({ where: { id: owner }, data: { active_role: 'VENDOR' } });
    await db.vendors.update({ where: { id: vendorId }, data: { is_suspended: true } });
    await get().expect(403); await adjust(-1).expect(403);
    await db.vendors.update({ where: { id: vendorId }, data: { is_suspended: false } });
  });
  it('attaches a real private product image, rejects wrong owner/purpose and clears nullable fields', async () => {
    const png = await sharp({ create: { width: 2, height: 2, channels: 3, background: 'white' } }).png().toBuffer();
    const upload = (access: string, purpose: string) => request(app.getHttpServer()).post('/api/v1/media')
      .set('Authorization', `Bearer ${access}`).set('Idempotency-Key', randomUUID()).field('purpose', purpose).attach('file', png, 'synthetic.png');
    const media = (await upload(token, 'PRODUCT_IMAGE').expect(201)).body.mediaId;
    await patch({ imageMediaId: media }).expect(200);
    await request(app.getHttpServer()).get(`/api/v1/media/${media}/content`).set('Authorization', `Bearer ${token}`).expect(200);
    await patch({ imageMediaId: (await upload(other, 'PRODUCT_IMAGE').expect(201)).body.mediaId }).expect(404);
    await patch({ imageMediaId: (await upload(token, 'SHOP_PHOTO').expect(201)).body.mediaId }).expect(404);
    await patch({ imageMediaId: randomUUID() }).expect(404);
    expect((await patch({ imageMediaId: null, subscriptionPricePaise: null }).expect(200)).body).toMatchObject({ imageMediaId: null, subscriptionPricePaise: null });
  });
  it('TC-037/038 combines case-insensitive search/filter/pagination and guards inactive selection', async () => {
    await create({ ...input, name: 'Synthetic Paneer', productType: 'PANEER', milkType: null }).expect(201);
    const list = await get('?search=cOw&productType=MILK&limit=1').expect(200);
    expect(list.body.total).toBe(1); expect(list.body.items[0].id).toBe(id);
    expect((await get('?search=cOw&productType=PANEER').expect(200)).body.total).toBe(0);
    expect((await get('?limit=1&offset=1').expect(200)).body.items).toHaveLength(1);
    await get('?limit=101').expect(400);
    await patch({ isActive: false }).expect(200);
    await expect(db.$transaction(tx => catalog.requireSelectable(tx, vendorId, id))).rejects.toMatchObject({ response: { code: 'PRODUCT_UNAVAILABLE' } });
    await patch({ isActive: true }).expect(200);
  });
  it('TC-040/041 serializes adjustments and emits one durable event per 10-pack crossing', async () => {
    const key = randomUUID();
    const result = await Promise.all([adjust(-10, key), adjust(-10, key)]);
    expect(result.map(r => r.status)).toEqual([201,201]); expect(result[0]!.body).toEqual(result[1]!.body);
    expect(result[0]!.body.stockQty).toBe(10);
    const events = () => db.outbox_events.findMany({ where: { aggregate_id: id, event_type: 'STOCK_LOW' } });
    expect(await events()).toHaveLength(1);
    expect((await events())[0]!.payload).toMatchObject({ stockQty: 10, threshold: 10, minimumPlan: 'BUSINESS', requiredFeature: 'STOCK_ALERTS' });
    await adjust(-1).expect(201); expect(await events()).toHaveLength(1);
    await adjust(3).expect(201); await adjust(-2).expect(201); expect(await events()).toHaveLength(2);
    const race = await Promise.all([adjust(-7), adjust(-7)]);
    expect(race.map(r => r.status).sort()).toEqual([201,409]);
    expect((await get(`/${id}`).expect(200)).body.stockQty).toBe(3);
    const movements = await db.stock_movements.findMany({ where: { product_id: id } });
    expect(movements.reduce((sum, m) => sum + m.delta, 0)).toBe(3);
    await expect(db.stock_movements.update({ where: { id: movements[0]!.id }, data: { delta: 99 } })).rejects.toThrow();
  });
  it('rolls product, stock movement and event back together on transaction failure', async () => {
    const row = (await create(input).expect(201)).body;
    await expect(db.$transaction(async tx => {
      await catalog.changeStock(tx, { vendorId, productId: row.id, actorId: owner, delta: -10, reason: 'ORDER', note: 'Synthetic delivery', refId: randomUUID() });
      throw new Error('Synthetic rollback');
    })).rejects.toThrow('Synthetic rollback');
    expect((await get(`/${row.id}`).expect(200)).body.stockQty).toBe(20);
    expect(await db.stock_movements.count({ where: { product_id: row.id } })).toBe(1);
    expect(await db.outbox_events.count({ where: { aggregate_id: row.id } })).toBe(0);
    expect((await patch({ stockQty: 10, stockReason: 'Synthetic recount' }, row.id).expect(200)).body.stockQty).toBe(10);
    expect(await db.outbox_events.count({ where: { aggregate_id: row.id } })).toBe(1);
  });
  it('TC-040 commits delivery/reversal stock hooks in the caller transaction without changing prices', async () => {
    const row = (await create({ ...input, stockQty: 12 }).expect(201)).body;
    const reference = randomUUID();
    await db.$transaction(tx => catalog.changeStock(tx, { vendorId, productId: row.id, actorId: owner,
      delta: -2, reason: 'ORDER', note: 'Synthetic delivered order', refId: reference }));
    expect((await get(`/${row.id}`).expect(200)).body).toMatchObject({ stockQty: 10, sellingPricePaise: 6000, subscriptionPricePaise: 5500 });
    expect(await db.stock_movements.findFirst({ where: { product_id: row.id, ref_id: reference } })).toMatchObject({ delta: -2, reason: 'ORDER' });
    await db.$transaction(tx => catalog.changeStock(tx, { vendorId, productId: row.id, actorId: owner,
      delta: 2, reason: 'REVERSAL', note: 'Synthetic reversed delivery', refId: reference }));
    expect((await get(`/${row.id}`).expect(200)).body.stockQty).toBe(12);
  });
  it('TC-039 blocks ACTIVE/PAUSED references, permits deactivation, then soft deletes with replay', async () => {
    const reference = randomUUID();
    await db.$transaction(tx => catalog.setSubscriptionReference(tx, reference, id, 'ACTIVE'));
    expect((await remove().expect(409)).body.code).toBe('PRODUCT_IN_USE');
    await patch({ isActive: false }).expect(200);
    await db.$transaction(tx => catalog.setSubscriptionReference(tx, reference, id, 'PAUSED'));
    await remove().expect(409);
    await db.$transaction(tx => catalog.setSubscriptionReference(tx, reference, id, 'ENDED'));
    const key = randomUUID(); expect((await remove(id, key).expect(200)).body).toEqual({ id, deleted: true });
    expect((await remove(id, key).expect(200)).body.deleted).toBe(true);
    await get(`/${id}`).expect(404); await patch({ name: 'Revive' }).expect(404); await adjust(1).expect(404);
    await expect(db.$transaction(tx => catalog.setSubscriptionReference(tx, randomUUID(), id, 'ACTIVE'))).rejects.toThrow();
    expect((await db.products.findUniqueOrThrow({ where: { id } })).deleted_at).not.toBeNull();
    expect(await db.stock_movements.count({ where: { product_id: id } })).toBeGreaterThan(0);
  });
});
