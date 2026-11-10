import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { unlink } from 'node:fs/promises';
import { join } from 'node:path';
import sharp from 'sharp';
import { Test } from '@nestjs/testing';
import { createHash, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PrismaService } from '../../prisma/prisma.service';
import { PinoLogger } from '../../common/logging/pino.logger';
import { SessionTokensService } from '../auth/session-tokens.service';
import { VendorsService } from './vendors.service';

const native = process.env.VENDORS_TEST_DATABASE_URL ? describe : describe.skip;
native('T-021 TC-020–TC-022 vendor onboarding HTTP → PostgreSQL', () => {
  const prisma = new PrismaService({ datasources: { db: { url: process.env.VENDORS_TEST_DATABASE_URL } } });
  const before = { ...process.env };
  let app: INestApplication, token: string, other: string, customer: string, owner: string;
  const users: string[] = [], categories: string[] = [], media: string[] = [], files: string[] = [];
  let categoryId: string, disabled: string, bill: string;
  const info = { businessName: 'Synthetic Dairy', gstin: '', addressLine: '123 Test Road', city: 'Test City',
    state: 'Test State', pincode: '560001', latitude: 12.97, longitude: 77.59 };
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
    app = module.createNestApplication(); configureHttpApp(app); await app.init();
    if (users.length) {
      const sessions = await prisma.sessions.findMany({ where: { user_id: { in: users } } });
      const tokens = users.map(id => app.get(SessionTokensService).issue(id, sessions.find(s => s.user_id === id)!.id, []));
      [token, other, customer] = tokens as [string, string, string];
    }
  }
  async function account(vendor = true) {
    const user = await prisma.users.create({ data: { mobile: `synthetic-${randomUUID()}`, active_role: vendor ? 'VENDOR' : 'CUSTOMER',
      roles: { create: { role: vendor ? 'VENDOR' : 'CUSTOMER' } } } });
    users.push(user.id);
    const session = await prisma.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
      refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    return { id: user.id, token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  function get(path = 'onboarding', access = token) {
    return request(app.getHttpServer()).get(`/api/v1/vendor/${path}`).set('Authorization', `Bearer ${access}`);
  }
  function category(id = categoryId, key = randomUUID(), access = token) {
    return request(app.getHttpServer()).post('/api/v1/vendor/onboarding/category')
      .set('Authorization', `Bearer ${access}`).set('Idempotency-Key', key).send({ categoryId: id });
  }
  function business(body: object = info, key = randomUUID(), access = token) {
    return request(app.getHttpServer()).put('/api/v1/vendor/onboarding/business')
      .set('Authorization', `Bearer ${access}`).set('Idempotency-Key', key).send(body);
  }
  async function photo(purpose = 'SHOP_PHOTO', status = 'READY', user = owner) {
    const row = await prisma.media_files.create({ data: { id: randomUUID(), owner_user_id: user, purpose, status,
      relative_storage_key: `media/${randomUUID()}.png`, mime: 'image/png', size: 1, sha256: '0'.repeat(64),
      request_key: createHash('sha256').update(randomUUID()).digest('hex'), request_hash: '0'.repeat(64) } });
    media.push(row.id); return row.id;
  }
  beforeAll(async () => {
    const url = new URL(process.env.VENDORS_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith('_test')) throw new Error('Dedicated _test database required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), RATE_LIMIT_MAX_REQUESTS: '1000' });
    await prisma.$connect(); await boot();
    const a = await account(); owner = a.id; token = a.token;
    other = (await account()).token; customer = (await account(false)).token;
    for (const [type, status] of [['SUPPLY', 'ENABLED'], ['SUPPLY', 'HIDDEN'], ['BILL', 'ENABLED']] as const) {
      const row = await prisma.categories.create({ data: { code: `TEST-${randomUUID()}`, name_en: 'Synthetic', name_hi: '', type, status } });
      categories.push(row.id);
    }
    [categoryId, disabled, bill] = categories as [string, string, string];
  });
  afterAll(async () => {
    await app?.close();
    const vendors = await prisma.vendors.findMany({ where: { user_id: { in: users } } });
    await prisma.vendor_service_pincodes.deleteMany({ where: { vendor_id: { in: vendors.map(v => v.id) } } });
    await prisma.vendor_settings.deleteMany({ where: { vendor_id: { in: vendors.map(v => v.id) } } });
    await prisma.vendors.deleteMany({ where: { user_id: { in: users } } });
    await prisma.idempotency_keys.deleteMany({ where: { user_id: { in: users } } });
    await prisma.media_files.deleteMany({ where: { id: { in: media } } });
    await prisma.sessions.deleteMany({ where: { user_id: { in: users } } });
    await prisma.users.deleteMany({ where: { id: { in: users } } });
    await prisma.categories.deleteMany({ where: { id: { in: categories } } });
    await prisma.$disconnect();
    for (const path of files) await unlink(path);
    for (const key of Object.keys(process.env)) if (!(key in before)) delete process.env[key];
    Object.assign(process.env, before);
  });
  it('TC-020 lists only enabled supply categories and requires selection before business', async () => {
    const response = await get('onboarding/categories').expect(200);
    const ids = (response.body as { id: string }[]).map(c => c.id);
    expect(ids).toContain(categoryId); expect(ids).not.toContain(disabled); expect(ids).not.toContain(bill);
    await get().expect(404); await business().expect(409);
    await category(disabled).expect(400); await category(bill).expect(400); await category(randomUUID()).expect(400);
    await category('invalid').expect(400);
  });
  it('creates one profile/default settings atomically across concurrent and restarted retries', async () => {
    const key = randomUUID();
    const responses = await Promise.all([category(categoryId, key), category(categoryId, key)]);
    expect(responses.map(r => r.status)).toEqual([201, 201]);
    expect(responses[0]!.body).toEqual(responses[1]!.body);
    expect(responses[0]!.body).toMatchObject({ onboardingStep: 2, kycStatus: 'NOT_VERIFIED', businessName: null,
      settings: { serviceRadiusKm: 3, pincodes: [], deliveryChargePaise: 0, minOrderPaise: 0, timeSlots: [], autoAcceptSubscriptions: false, acceptingToday: false } });
    await category(disabled, key).expect(422);
    await app.close(); await boot();
    expect((await category(categoryId, key).expect(201)).body).toEqual(responses[0]!.body);
    expect(await prisma.vendors.count({ where: { user_id: owner } })).toBe(1);
  });
  it('TC-021 rejects malformed business data, null required values and forged server fields', async () => {
    for (const patch of [{ businessName: 'X' }, { businessName: '  ' }, { gstin: 'BAD' }, { pincode: '12345' },
      { pincode: '012345' }, { latitude: 91 }, { longitude: -181 }, { latitude: '12' }, { city: '' },
      { state: null }, { latitude: null }, { vendorId: randomUUID() }, { kycStatus: 'VERIFIED' }, { onboardingStep: 4 }]) {
      await business({ ...info, ...patch }).expect(400);
    }
    expect((await get().expect(200)).body.onboardingStep).toBe(2);
    await request(app.getHttpServer()).put('/api/v1/vendor/onboarding/business').set('Authorization', `Bearer ${token}`).send(info).expect(400);
  });
  it('TC-022 persists valid business, optional GSTIN and location through application restart', async () => {
    const key = randomUUID();
    const saved = await business(info, key).expect(200);
    expect(saved.body).toMatchObject({ businessName: info.businessName, gstin: null, onboardingStep: 3, latitude: 12.97 });
    await app.close(); await boot();
    expect((await get().expect(200)).body).toEqual(saved.body);
    expect((await business(info, key).expect(200)).body).toEqual(saved.body);
    await business({ ...info, businessName: 'Changed' }, key).expect(422);
    const points = await prisma.$queryRaw<{ lat: number; lng: number }[]>`SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng FROM vendors WHERE user_id = ${owner}::uuid`;
    expect(points[0]).toEqual({ lat: 12.97, lng: 77.59 });
    await category().expect(201); expect((await get().expect(200)).body.onboardingStep).toBe(3);
    await business({ ...info, gstin: '29ABCDE1234F1Z5' }).expect(200);
  });
  it('denies unauthenticated/customer/inactive-role access and isolates owners sharing a key', async () => {
    await get('onboarding', '').expect(401); await get('onboarding', customer).expect(403);
    await category(categoryId, randomUUID(), customer).expect(403);
    await get('onboarding', other).expect(404);
    const key = randomUUID();
    const a = await category(categoryId, key).expect(201), b = await category(categoryId, key, other).expect(201);
    expect(a.body.id).not.toBe(b.body.id); expect(b.body.businessName).toBeNull();
    await prisma.users.update({ where: { id: owner }, data: { active_role: 'CUSTOMER' } });
    await get().expect(403); await category().expect(403);
    await prisma.users.update({ where: { id: owner }, data: { active_role: 'VENDOR' } });
  });
  it('attaches only owned READY shop photos; preserves omitted and clears explicit null', async () => {
    const png = await sharp({ create: { width: 2, height: 2, channels: 3, background: '#fff' } }).png().toBuffer();
    const uploaded = await request(app.getHttpServer()).post('/api/v1/media')
      .set('Authorization', `Bearer ${token}`).set('Idempotency-Key', randomUUID())
      .field('purpose', 'SHOP_PHOTO').attach('file', png, 'shop.png').expect(201);
    const id = uploaded.body.mediaId as string; media.push(id);
    const row = await prisma.media_files.findUniqueOrThrow({ where: { id } });
    files.push(join(app.get(ConfigService).getOrThrow<string>('UPLOAD_ROOT'), row.relative_storage_key));
    await business({ ...info, shopPhotoMediaId: id }).expect(200);
    expect((await business().expect(200)).body.shopPhotoMediaId).toBe(id);
    const display = await request(app.getHttpServer()).get(`/api/v1/media/${id}/content`)
      .set('Authorization', `Bearer ${token}`).expect(200);
    expect(display.body).toEqual(png);
    const otherUser = users[1]!;
    for (const bad of [await photo('PROFILE'), await photo('SHOP_PHOTO', 'READY', otherUser), randomUUID()]) {
      await business({ ...info, shopPhotoMediaId: bad }).expect(404);
    }
    expect((await get().expect(200)).body.shopPhotoMediaId).toBe(id);
    expect((await business({ ...info, shopPhotoMediaId: null }).expect(200)).body.shopPhotoMediaId).toBeNull();
  });
  it('rolls profile writes back if replay persistence fails', async () => {
    const key = randomUUID();
    await prisma.$executeRaw`ALTER TABLE idempotency_keys ADD CONSTRAINT vendor_test_reject CHECK (path <> 'business') NOT VALID`;
    try { await business({ ...info, businessName: 'Must Roll Back' }, key).expect(503); }
    finally { await prisma.$executeRaw`ALTER TABLE idempotency_keys DROP CONSTRAINT vendor_test_reject`; }
    expect((await get().expect(200)).body.businessName).toBe(info.businessName);
  });
  function area(body: object, key = randomUUID(), access = token) {
    return request(app.getHttpServer()).put('/api/v1/vendor/settings/service-area')
      .set('Authorization', `Bearer ${access}`).set('Idempotency-Key', key).send(body);
  }
  it('T-023 TC-028 validates radius/pincodes and rejects forged ownership and missing keys', async () => {
    const valid = { serviceRadiusKm: 3, pincodes: ['560002'] };
    for (const patch of [{ serviceRadiusKm: 0 }, { serviceRadiusKm: 21 }, { serviceRadiusKm: 1.5 },
      { serviceRadiusKm: '3' }, { pincodes: null }, { pincodes: ['012345'] }, { pincodes: [560002] },
      { pincodes: ['560002', '560002'] }, { vendorId: randomUUID() }, { serviceRadiusKm: null, pincodes: [] }]) {
      await area({ ...valid, ...patch }).expect(400);
    }
    await area({ pincodes: [] }).expect(400);
    await area({ serviceRadiusKm: 3 }).expect(400);
    await request(app.getHttpServer()).put('/api/v1/vendor/settings/service-area')
      .set('Authorization', `Bearer ${token}`).send(valid).expect(400);
    await area(valid, randomUUID(), '').expect(401);
    await area(valid, randomUUID(), customer).expect(403);
    await prisma.users.update({ where: { id: owner }, data: { active_role: 'CUSTOMER' } });
    await area(valid).expect(403);
    await prisma.users.update({ where: { id: owner }, data: { active_role: 'VENDOR' } });
    await area(valid, randomUUID(), other).expect(409); // no shop coordinates
  });
  it('T-023 persists atomically, isolates owners and replays concurrent requests through restart', async () => {
    const body = { serviceRadiusKm: 3, pincodes: ['560003', '560002'] }, key = randomUUID();
    const version = (await get().expect(200)).body.settings.version as number;
    const responses = await Promise.all([area(body, key), area(body, key)]);
    expect(responses.map(r => r.status)).toEqual([200, 200]);
    expect(responses[0]!.body).toEqual(responses[1]!.body);
    expect(responses[0]!.body.settings).toMatchObject({ serviceRadiusKm: 3, pincodes: ['560002', '560003'], version: version + 1 });
    expect((await get('settings/service-area', other).expect(200)).body.settings.pincodes).toEqual([]);
    await app.close(); await boot();
    expect((await area(body, key).expect(200)).body).toEqual(responses[0]!.body);
    await area({ ...body, serviceRadiusKm: 4 }, key).expect(422);
    const saved = (await get('settings/service-area').expect(200)).body;
    await prisma.$executeRaw`ALTER TABLE idempotency_keys ADD CONSTRAINT area_test_reject CHECK (path <> 'service-area') NOT VALID`;
    try { await area({ serviceRadiusKm: 5, pincodes: ['560004'] }).expect(503); }
    finally { await prisma.$executeRaw`ALTER TABLE idempotency_keys DROP CONSTRAINT area_test_reject`; }
    expect((await get('settings/service-area').expect(200)).body).toEqual(saved);
  });
  it('T-023 TC-028 uses PostGIS meters and adds pincode coverage; supports radius-only and pincode-only', async () => {
    const id = (await get().expect(200)).body.id as string;
    const points = await prisma.$queryRaw<{ lat: number; lng: number; meters: number }[]>`
      SELECT ST_Y(p::geometry) AS lat, ST_X(p::geometry) AS lng, meters FROM vendors v,
        (VALUES (2900), (3100)) AS d(meters),
        LATERAL (SELECT ST_Project(v.location, meters, 0) AS p) q WHERE v.id = ${id}::uuid`;
    const service = app.get(VendorsService);
    for (const p of points) expect(await service.covers(id, p.lat, p.lng, '560099')).toBe(p.meters === 2900);
    const far = points.find(p => p.meters === 3100)!;
    expect(await service.covers(id, far.lat, far.lng, '560002')).toBe(true);
    await area({ serviceRadiusKm: null, pincodes: ['560002'] }).expect(200);
    expect(await service.covers(id, info.latitude, info.longitude, '560099')).toBe(false);
    expect(await service.covers(id, far.lat, far.lng, '560002')).toBe(true);
    await area({ serviceRadiusKm: 1, pincodes: [] }).expect(200);
    expect(await service.covers(id, far.lat, far.lng, '560002')).toBe(false);
    await area({ serviceRadiusKm: 20, pincodes: [] }).expect(200);
    expect(await service.covers(id, far.lat, far.lng, '560099')).toBe(true);
    expect(await service.covers(randomUUID(), far.lat, far.lng, '560002')).toBe(false);
    await expect(service.covers(id, 91, 0, '560002')).rejects.toThrow();
  });
  it('prevents onboarding edits from bypassing KYC review or account blocking', async () => {
    await prisma.vendors.update({ where: { user_id: owner }, data: { kyc_status: 'MANUAL_REVIEW', onboarding_step: 4 } });
    await business().expect(409);
    const another = await prisma.categories.create({ data: { code: `TEST-${randomUUID()}`, name_en: 'Synthetic Other', name_hi: '', type: 'SUPPLY' } });
    categories.push(another.id); await category(another.id).expect(409);
    expect((await get().expect(200)).body.onboardingStep).toBe(4);
    await prisma.users.update({ where: { id: owner }, data: { status: 'BLOCKED' } }); await get().expect(403);
  });
});
