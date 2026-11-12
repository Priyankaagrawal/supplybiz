import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomInt, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { VendorsService } from '../vendors/vendors.service';
import { AddressesService } from './addresses.service';

const databaseUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = databaseUrl ? describe : describe.skip;
native('T-040 / TC-290 native customer address HTTP and PostGIS', () => {
  const db = new PrismaService({ datasources: { db: { url: databaseUrl } } });
  const env = { ...process.env }, ids: string[] = [];
  let app: INestApplication, peer: INestApplication;
  let serial = randomInt(0, 800000000);
  type Actor = { id: string; sessionId: string; token: string };
  let a: Actor, b: Actor, vendor: Actor;
  const input = () => ({ label: 'Home', line1: 'Synthetic Flat 1', line2: 'Synthetic Area',
    city: 'Synthetic City', state: 'Synthetic State', pincode: '560001', latitude: 12.97, longitude: 77.59 });
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
    const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
  }
  async function account(role: 'CUSTOMER' | 'VENDOR' = 'CUSTOMER'): Promise<Actor> {
    const user = await db.users.create({ data: { mobile: `+91${9100000000 + ++serial}`, active_role: role, roles: { create: { role } } } });
    ids.push(user.id);
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
      refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    return { id: user.id, sessionId: session.id, token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  const root = '/api/v1/customer/addresses';
  const get = (path = '', actor = a) => request(app.getHttpServer()).get(`${root}${path}`).set('Authorization', `Bearer ${actor.token}`);
  const create = (body: object = input(), key: string = randomUUID(), actor = a, instance = app) => request(instance.getHttpServer())
    .post(root).set('Authorization', `Bearer ${actor.token}`).set('Idempotency-Key', key).send(body);
  const patch = (id: string, body: object, key = randomUUID(), actor = a, instance = app) => request(instance.getHttpServer())
    .patch(`${root}/${id}`).set('Authorization', `Bearer ${actor.token}`).set('Idempotency-Key', key).send(body);
  const remove = (id: string, key = randomUUID(), actor = a) => request(app.getHttpServer())
    .delete(`${root}/${id}`).set('Authorization', `Bearer ${actor.token}`).set('Idempotency-Key', key);
  beforeAll(async () => {
    const url = new URL(databaseUrl!);
    if (!url.pathname.endsWith('_test') || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000',
      AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
    await db.$connect(); app = await boot(); peer = await boot();
  });
  beforeEach(async () => { a = await account(); b = await account(); vendor = await account('VENDOR'); });
  afterAll(async () => {
    await peer?.close(); await app?.close();
    await db.addresses.deleteMany({ where: { user_id: { in: ids } } });
    await db.idempotency_keys.deleteMany({ where: { user_id: { in: ids } } });
    await db.sessions.deleteMany({ where: { user_id: { in: ids } } });
    await db.users.deleteMany({ where: { id: { in: ids } } });
    await db.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env);
  });
  it('TC-290 persists CRUD, generated geography, one default, soft deletion and default replacement', async () => {
    expect((await get().expect(200)).body.items).toEqual([]);
    const first = (await create({ ...input(), isDefault: false }).expect(201)).body;
    expect(first).toMatchObject({ ...input(), isDefault: true, landmark: '' });
    const second = (await create({ ...input(), label: 'Work' }).expect(201)).body;
    expect(second.isDefault).toBe(false);
    await patch(second.id, { isDefault: true, longitude: 78, landmark: 'Synthetic landmark' }).expect(200);
    expect((await get().expect(200)).body.items.filter((r: { isDefault: boolean }) => r.isDefault).map((r: { id: string }) => r.id)).toEqual([second.id]);
    const geo = await db.$queryRaw<{ x: number; y: number }[]>`SELECT ST_X(location::geometry) x, ST_Y(location::geometry) y FROM addresses WHERE id = ${second.id}::uuid`;
    expect(geo).toEqual([{ x: 78, y: input().latitude }]);
    expect((await get(`/${second.id}`).expect(200)).headers['cache-control']).toBe('no-store');
    await remove(second.id).expect(200); await get(`/${second.id}`).expect(404);
    expect((await get(`/${first.id}`).expect(200)).body.isDefault).toBe(true);
    expect((await db.addresses.findUniqueOrThrow({ where: { id: second.id } })).deleted_at).not.toBeNull();
    await remove(first.id).expect(200); expect((await get().expect(200)).body.items).toEqual([]);
    expect((await create().expect(201)).body.isDefault).toBe(true);
  });
  it('TC-290 rejects missing, null, forged and invalid numeric/address input without changing state', async () => {
    for (const bad of [{ line1: '' }, { line2: ' ' }, { city: null }, { state: '' }, { label: null }, { landmark: null },
      { latitude: 91 }, { latitude: '12.97' }, { longitude: -181 }, { longitude: null }, { latitude: null },
      { pincode: '012345' }, { pincode: 560001 }, { isDefault: 'true' }, { userId: b.id }, { id: randomUUID() }]) {
      await create({ ...input(), ...bad }).expect(400);
    }
    await create({}).expect(400);
    const row = (await create().expect(201)).body;
    for (const bad of [{ line1: null }, { line2: '' }, { latitude: null }, { isDefault: null }, { pincode: '99999' }]) await patch(row.id, bad).expect(400);
    await get('/invalid').expect(400);
    await request(app.getHttpServer()).post(root).set('Authorization', `Bearer ${a.token}`).send(input()).expect(400);
    await create(input(), 'x'.repeat(121)).expect(400);
    expect((await get().expect(200)).body.items).toEqual([row]);
  });
  it('denies unauthenticated, foreign-owner, vendor-role and inactive-role access including replay', async () => {
    const key = randomUUID(), row = (await create(input(), key).expect(201)).body;
    await request(app.getHttpServer()).get(root).expect(401);
    await get(`/${row.id}`, b).expect(404); await patch(row.id, { label: 'Forgery' }, randomUUID(), b).expect(404);
    await remove(row.id, randomUUID(), b).expect(404); await get('', vendor).expect(403);
    await create(input(), randomUUID(), vendor).expect(403);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'VENDOR' } });
    await get().expect(403); await create(input(), key).expect(403);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'CUSTOMER', status: 'BLOCKED' } });
    await get().expect(403); await create(input(), key).expect(403);
    await db.users.update({ where: { id: a.id }, data: { status: 'ACTIVE' } });
    await db.sessions.update({ where: { id: a.sessionId }, data: { status: 'REVOKED', revoked_at: new Date() } });
    await get().expect(401); await create(input(), key).expect(401);
  });
  it('replays concurrent creates across instances/restart; rejects key reuse across payload/method/target', async () => {
    const key = randomUUID(), body = input();
    const race = await Promise.all([create(body, key), create(body, key, a, peer)]);
    expect(race.map(r => r.status)).toEqual([201, 201]); expect(race[0]!.body).toEqual(race[1]!.body);
    await app.close(); app = await boot();
    expect((await create(body, key).expect(201)).body).toEqual(race[0]!.body);
    await create({ ...body, label: 'Changed' }, key).expect(422);
    await patch(race[0]!.body.id, body, key).expect(422);
    const other = (await create(body, key, b).expect(201)).body; expect(other.id).not.toBe(race[0]!.body.id);
    const editKey = randomUUID(); await patch(race[0]!.body.id, { label: 'Edited' }, editKey).expect(200);
    const second = (await create().expect(201)).body;
    await patch(second.id, { label: 'Edited' }, editKey).expect(422);
    const deleteKey = randomUUID(); const deleted = await remove(second.id, deleteKey).expect(200);
    expect((await remove(second.id, deleteKey).expect(200)).body).toEqual(deleted.body);
    expect((await get().expect(200)).body.items).toHaveLength(1);
  });
  it('TC-290 serializes concurrent first/default/delete operations and enforces DB unique default', async () => {
    const initial = await Promise.all([create(), create(input(), randomUUID(), a, peer)]);
    expect(initial.map(r => r.status)).toEqual([201, 201]);
    const [one, two] = initial.map(r => r.body.id as string);
    const switches = await Promise.all([patch(one!, { isDefault: true }), patch(two!, { isDefault: true }, randomUUID(), a, peer)]);
    expect(switches.map(r => r.status)).toEqual([200, 200]);
    const rows = (await get().expect(200)).body.items as { id: string; isDefault: boolean }[];
    expect(rows.filter(r => r.isDefault)).toHaveLength(1);
    const nonDefault = rows.find(r => !r.isDefault)!;
    await expect(db.addresses.update({ where: { id: nonDefault.id }, data: { is_default: true } })).rejects.toMatchObject({ code: 'P2002' });
    const deletes = await Promise.all([remove(one!), remove(two!)]);
    expect(deletes.map(r => r.status)).toEqual([200, 200]); expect((await get().expect(200)).body.items).toEqual([]);
  });
  it('preserves default on rejected clearing and permits retry with an unreserved failure key', async () => {
    const one = (await create().expect(201)).body, two = (await create().expect(201)).body;
    const key = randomUUID(); await patch(one.id, { isDefault: false }, key).expect(409);
    expect((await get(`/${one.id}`).expect(200)).body.isDefault).toBe(true);
    await patch(two.id, { isDefault: true }).expect(200);
    await patch(one.id, { isDefault: false }, key).expect(200);
    expect((await get(`/${two.id}`).expect(200)).body.isDefault).toBe(true);
  });
  it('passes owned coordinates to existing server coverage helper, without accepting foreign/deleted addresses', async () => {
    const row = (await create().expect(201)).body;
    const owned = await db.$transaction(tx => app.get(AddressesService).requireOwned(tx, a.id, row.id));
    await expect(db.$transaction(tx => app.get(AddressesService).requireOwned(tx, b.id, row.id))).rejects.toMatchObject({ status: 404 });
    const category = await db.categories.create({ data: { code: `ADDRESS-${randomUUID()}`, name_en: 'Synthetic', name_hi: '', type: 'SUPPLY' } });
    const supplier = await db.vendors.create({ data: { user_id: vendor.id, category_id: category.id,
      latitude: owned.latitude, longitude: owned.longitude, settings: { create: { service_radius_km: 3 } } } });
    try {
      const covers = app.get(VendorsService);
      expect(await covers.covers(supplier.id, owned.latitude, owned.longitude, owned.pincode)).toBe(true);
      expect(await covers.covers(supplier.id, 0, 0, owned.pincode)).toBe(false);
      await db.vendor_service_pincodes.create({ data: { vendor_id: supplier.id, pincode: owned.pincode } });
      expect(await covers.covers(supplier.id, 0, 0, owned.pincode)).toBe(true);
      await remove(row.id).expect(200);
      await expect(db.$transaction(tx => app.get(AddressesService).requireOwned(tx, a.id, row.id))).rejects.toMatchObject({ status: 404 });
    } finally {
      await db.vendor_service_pincodes.deleteMany({ where: { vendor_id: supplier.id } });
      await db.vendor_settings.deleteMany({ where: { vendor_id: supplier.id } });
      await db.vendors.delete({ where: { id: supplier.id } }); await db.categories.delete({ where: { id: category.id } });
    }
  });
});
