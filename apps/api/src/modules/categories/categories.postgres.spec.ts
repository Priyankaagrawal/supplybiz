// T-153 / FR-405: real HTTP, PostgreSQL and production S-A-08.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomBytes, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo } from 'node:net';
import { join, resolve } from 'node:path';
import request from 'supertest';
import { PrismaService } from '../../prisma/prisma.service';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { digest } from '../admin-auth/admin-crypto';
const native = process.env.ADMIN_TEST_DATABASE_URL ? describe : describe.skip;
native('T-153 category management', () => {
 const db = new PrismaService({ datasources: { db: { url: process.env.ADMIN_TEST_DATABASE_URL } } });
 const env = { ...process.env }, ids: string[] = [], categoryIds: string[] = [];
 let app: INestApplication, categoryDb: PrismaService, ops: { id: string; token: string }, categoryId: string;
 const input = { code: `TEST_${randomBytes(8).toString('hex').toUpperCase()}`, name: 'Synthetic category', icon: 'milk',
  type: 'SUPPLY', status: 'ENABLED', sortOrder: 123, productTypes: ['Milk', 'Curd'] };
 async function fixture(role: string) {
  const admin = await db.admin_users.create({ data: { email: `category-${randomUUID()}@example.invalid`, password_hash: 'synthetic-unused', role } });
  ids.push(admin.id); const token = randomBytes(32).toString('base64url');
  await db.admin_sessions.create({ data: { token_hash: digest(token), csrf_hash: digest('synthetic'), admin_id: admin.id, expires_at: new Date(Date.now() + 3600000) } });
  return { id: admin.id, token };
 }
 function write(body: object = input, id = '', key: string = randomUUID(), token = ops.token, csrf = 'synthetic') {
  return request(app.getHttpServer())[id ? 'put' : 'post'](`/api/v1/admin/categories${id ? `/${id}` : ''}`)
   .set('Authorization', `Bearer ${token}`).set('X-CSRF-Token', csrf).set('Idempotency-Key', key).send(body);
 }
 beforeAll(async () => {
  const url = new URL(process.env.ADMIN_TEST_DATABASE_URL!);
  if (!url.pathname.endsWith('_test') || !['localhost', '127.0.0.1'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
  Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), RATE_LIMIT_MAX_REQUESTS: '1000' });
  const { AppModule } = await import('../../app.module');
  const module = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PinoLogger)
   .useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
  categoryDb = module.select(AppModule).get(PrismaService, { strict: true });
  app = module.createNestApplication(); configureHttpApp(app); await app.init(); ops = await fixture('OPS');
 });
 afterAll(async () => {
  await app?.close();
  await db.admin_sessions.deleteMany({ where: { admin_id: { in: ids } } });
  await db.admin_users.updateMany({ where: { id: { in: ids } }, data: { status: 'DISABLED' } });
  await db.categories.deleteMany({ where: { id: { in: categoryIds } } });
  await db.$disconnect(); Object.assign(process.env, env);
  for (const name of Object.keys(process.env)) if (!(name in env)) delete process.env[name];
 });
 it('denies anonymous, SUPPORT and FINANCE; requires CSRF and a mutation key', async () => {
  await write(input, '', randomUUID(), '').expect(401);
  for (const role of ['SUPPORT', 'FINANCE']) {
   const actor = await fixture(role);
   await request(app.getHttpServer()).get('/api/v1/admin/categories').set('Authorization', `Bearer ${actor.token}`).expect(403);
   await write(input, '', randomUUID(), actor.token).expect(403);
  }
  await write(input, '', randomUUID(), ops.token, 'wrong').expect(403);
  await write(input, '', '').expect(400);
 });
 it('validates enums, integer ordering, names, icons and product types', async () => {
  for (const change of [{ name: ' ' }, { code: 'invalid' }, { icon: '<script>' }, { type: 'UNKNOWN' }, { status: 'UNKNOWN' },
   { sortOrder: -1 }, { sortOrder: 1.5 }, { productTypes: ['Milk', 'Milk'] }, { productTypes: [' '] }, { extra: 'no' }]) {
   await write({ ...input, ...change }).expect(400);
  }
 });
 it('creates once on concurrent retry, audits atomically, scopes retries and rejects changed payloads', async () => {
  const key = randomUUID();
  const [a, b] = await Promise.all([write(input, '', key), write(input, '', key)]);
  expect(a.status).toBe(201); expect(b.status).toBe(201); expect(a.body).toEqual(b.body);
  categoryId = a.body.id as string; categoryIds.push(categoryId);
  expect(await db.categories.count({ where: { code: input.code } })).toBe(1);
  const rows = await db.audit_logs.findMany({ where: { entity_id: categoryId } });
  expect(rows).toHaveLength(1); expect(rows[0]).toMatchObject({ actor_id: ops.id, action: 'CATEGORY_CREATE', after: { name: input.name } });
  await write({ ...input, name: 'Changed' }, '', key).expect(422);
  await write(input, '', key, (await fixture('SUPER_ADMIN')).token).expect(409);
 });
 it('updates persisted order/icon/product types, hides without deleting, and returns missing/duplicate errors', async () => {
  const changed = { ...input, status: 'HIDDEN', sortOrder: 3, icon: '', productTypes: ['Other'] };
  await write(changed, categoryId).expect(200);
  expect(await db.categories.findUniqueOrThrow({ where: { id: categoryId } })).toMatchObject({ status: 'HIDDEN', sort_order: 3, icon: null, product_types: ['Other'] });
  expect(await db.audit_logs.findFirst({ where: { entity_id: categoryId, action: 'CATEGORY_UPDATE' } })).toMatchObject({ before: { status: 'ENABLED' }, after: { status: 'HIDDEN' } });
  await write(input).expect(409); await write(input, randomUUID()).expect(404);
  const page = await request(app.getHttpServer()).get('/api/v1/admin/categories').set('Authorization', `Bearer ${ops.token}`).expect(200).expect('Cache-Control', 'no-store');
  expect(page.body.items).toContainEqual(expect.objectContaining({ id: categoryId, status: 'HIDDEN' }));
 });
 it('rolls back category edits when audit persistence fails', async () => {
  const original = db.$transaction.bind(db);
  let attemptedName: string | undefined;
  const spy = jest.spyOn(categoryDb, '$transaction').mockImplementation((async (callback: (tx: unknown) => Promise<unknown>) =>
   original(async tx => callback(new Proxy(tx, { get(target, name) { return name === 'audit_logs'
    ? { ...tx.audit_logs, create: async () => { attemptedName = (await tx.categories.findUniqueOrThrow({ where: { id: categoryId } })).name_en;
      throw new Error('synthetic audit unavailable'); } } : Reflect.get(target, name); } })))) as typeof db.$transaction);
  try { await write({ ...input, name: 'Must roll back' }, categoryId).expect(503); }
  finally { spy.mockRestore(); }
  expect(attemptedName).toBe('Must roll back');
  expect((await db.categories.findUniqueOrThrow({ where: { id: categoryId } })).name_en).toBe(input.name);
 });
 it('prevents changing the type of a category referenced by a vendor', async () => {
  const user = await db.users.create({ data: { mobile: `synthetic-${randomUUID()}` } });
  const vendor = await db.vendors.create({ data: { user_id: user.id, category_id: categoryId } });
  try { await write({ ...input, type: 'BILL' }, categoryId).expect(409); }
  finally { await db.vendors.delete({ where: { id: vendor.id } }); await db.users.delete({ where: { id: user.id } }); }
 });
 (process.env.CATEGORIES_ADMIN_SMOKE === '1' ? it : it.skip)('serves production S-A-08 and saves through the CSRF-protected BFF to the real database', async () => {
  await app.listen(0, '127.0.0.1');
  const port = (app.getHttpServer().address() as AddressInfo).port, adminRoot = resolve(__dirname, '../../../../admin');
  const origin = 'http://127.0.0.1:3143';
  const child = spawn(process.execPath, [join(adminRoot, 'node_modules/next/dist/bin/next'), 'start', '--hostname', '127.0.0.1', '--port', '3143'], {
   cwd: adminRoot, env: { ...process.env, NODE_ENV: 'production', ADMIN_API_URL: `http://127.0.0.1:${port}`, ADMIN_ORIGIN: origin,
    ADMIN_CSRF_KEY: randomBytes(32).toString('hex'), NEXT_TELEMETRY_DISABLED: '1' }, stdio: 'ignore' });
  let failed = false; child.on('error', () => { failed = true; });
  try {
   let ready = false;
   for (let i = 0; i < 100; i++) {
    if (failed || child.exitCode !== null) throw new Error('Next smoke server failed');
    try { if ((await fetch(`${origin}/login`)).ok) { ready = true; break; } } catch { /* startup */ }
    await new Promise(done => setTimeout(done, 100));
   }
   expect(ready).toBe(true);
   const headers = { Cookie: `sb_admin=${ops.token}; sb_csrf=synthetic` };
   const response = await fetch(`${origin}/categories`, { headers });
   expect(response.headers.get('cache-control')).toContain('no-store');
   const html = await response.text(); expect(html).toContain('Create category'); expect(html).toContain(input.name); expect(html).not.toContain(ops.token);
   const csrf = html.match(/name="csrf" value="([^"]+)"/)?.[1]; expect(csrf).toBeDefined();
   const body = new URLSearchParams({ ...input, productTypes: 'Milk\nOther', sortOrder: '4', id: categoryId, key: randomUUID(), csrf: csrf! });
   expect((await fetch(`${origin}/categories/save`, { method: 'POST', headers: { ...headers, Origin: 'https://wrong.invalid' }, body, redirect: 'manual' })).status).toBe(403);
   const saved = await fetch(`${origin}/categories/save`, { method: 'POST', headers: { ...headers, Origin: origin }, body, redirect: 'manual' });
   expect(saved.status).toBe(303); expect(saved.headers.get('location')).toContain('result=saved');
   expect((await db.categories.findUniqueOrThrow({ where: { id: categoryId } })).sort_order).toBe(4);
   const support = await fixture('SUPPORT');
   expect(await (await fetch(`${origin}/categories`, { headers: { Cookie: `sb_admin=${support.token}` } })).text()).toContain('You do not have permission');
  } finally {
   if (child.exitCode === null) { const stopped = new Promise<void>(done => child.once('exit', () => done())); child.kill('SIGTERM'); await stopped; }
  }
 }, 30000);
});
