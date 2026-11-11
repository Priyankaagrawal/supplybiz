import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomBytes, randomInt, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo, createServer } from 'node:net';
import { join, resolve } from 'node:path';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { digest } from '../admin-auth/admin-crypto';
import { SessionTokensService } from '../auth/session-tokens.service';
import { OtpService } from '../auth/otp.service';
import { ManagementService } from './management.service';
const databaseUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = databaseUrl ? describe : describe.skip;
native('T-155 TC-404/405/408 native account/vendor administration', () => {
 const db = new PrismaService({ datasources: { db: { url: databaseUrl } } }), env = { ...process.env };
 let app: INestApplication, peer: INestApplication, categoryId: string, serial = randomInt(0, 800000000);
 let ops: { id: string; token: string }, support: typeof ops;
 type Account = { id: string; vendorId: string; token: string; mobile: string };
 let a: Account, b: Account;
 async function boot() {
  const { AppModule } = await import('../../app.module');
  const module = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
  const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
 }
 async function admin(role: string) {
  const row = await db.admin_users.create({ data: { email: `management-${randomUUID()}@example.invalid`, role, password_hash: 'synthetic-unused' } });
  const token = randomBytes(32).toString('base64url'); await db.admin_sessions.create({ data: { token_hash: digest(token), admin_id: row.id, csrf_hash: digest('synthetic'), expires_at: new Date(Date.now() + 3600000) } }); return { id: row.id, token };
 }
 async function account(): Promise<Account> {
  const mobile = `+91${9100000000 + ++serial}`;
  const row = await db.users.create({ data: { mobile, name: 'Synthetic Managed Account', active_role: 'VENDOR', roles: { create: [{ role: 'VENDOR' }, { role: 'CUSTOMER' }] } } });
  const vendor = await db.vendors.create({ data: { user_id: row.id, category_id: categoryId, business_name: 'Synthetic Managed Vendor' } });
  const session = await db.sessions.create({ data: { user_id: row.id, family_id: randomUUID(), refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
  return { id: row.id, vendorId: vendor.id, mobile, token: app.get(SessionTokensService).issue(row.id, session.id, []) };
 }
 const get = (path: string, token = ops.token) => request(app.getHttpServer()).get(`/api/v1/admin/${path}`).set('Authorization', `Bearer ${token}`);
 const body = async (kind = 'vendors', id = a.vendorId) => ({ reason: 'Synthetic status decision', expectedUpdatedAt: (await get(`${kind}/${id}`).expect(200)).body.updatedAt });
 function change(path: string, input: object, key: string = randomUUID(), token = ops.token, instance = app, csrf = 'synthetic', patch = false) {
  return request(instance.getHttpServer())[patch ? 'patch' : 'post'](`/api/v1/admin/${path}`).set('Authorization', `Bearer ${token}`).set('X-CSRF-Token', csrf).set('Idempotency-Key', key).send(input);
 }
 beforeAll(async () => {
  const url = new URL(databaseUrl!); if (!url.pathname.endsWith('_test') || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
  Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000', AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
  await db.$connect(); app = await boot(); peer = await boot(); ops = await admin('OPS'); support = await admin('SUPPORT');
  categoryId = (await db.categories.create({ data: { code: `MGMT-${randomUUID()}`, name_en: 'Synthetic category', name_hi: '', type: 'SUPPLY' } })).id;
 }, 60000);
 beforeEach(async () => { a = await account(); b = await account(); });
 afterAll(async () => { await peer?.close(); await app?.close(); await db.$disconnect(); for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env); }, 60000);
 it('authorizes scoped search/detail, bounds pagination and excludes private credentials/KYC', async () => {
  for (const kind of ['vendors', 'customers']) { await get(kind, '').expect(401); await get(kind, (await admin('FINANCE')).token).expect(403); await get(kind, support.token).expect(200); await get(`${kind}?offset=-1`).expect(400); }
  expect((await get(`vendors?search=${a.vendorId}`).expect(200)).body.items[0].id).toBe(a.vendorId);
  expect((await get(`customers?search=${a.mobile.slice(3)}`).expect(200)).body.items.some((r: { id: string }) => r.id === a.id)).toBe(true);
  const detail = (await get(`vendors/${a.vendorId}`).expect(200)).body;
  expect(detail).toMatchObject({ badges: [], planCode: null, customerLimit: 50, planStatus: 'UNASSIGNED' });
  expect(JSON.stringify(detail)).not.toMatch(/password|refresh_token|pan_enc|aadhaar|bank/);
  await get(`vendors/${randomUUID()}`).expect(404); await get('customers/bad-id').expect(400);
 });
 it('rejects unauthorized, stale and forged mutations and validates badge arrays/reasons', async () => {
  const input = await body();
  await change(`vendors/${a.vendorId}/suspend`, input, randomUUID(), support.token).expect(403);
  await change(`vendors/${a.vendorId}/suspend`, input, randomUUID(), ops.token, app, 'wrong').expect(403);
  await change(`vendors/${a.vendorId}/suspend`, input, '').expect(400);
  for (const bad of [{ reason: ' ' }, { isSuspended: true }, { kycStatus: 'VERIFIED' }]) await change(`vendors/${a.vendorId}/suspend`, { ...input, ...bad }).expect(400);
  for (const badges of [[null], [5], [' '], ['A', 'a'], Array(11).fill('a'), ['x'.repeat(41)]]) await change(`vendors/${a.vendorId}`, { ...input, badges }, randomUUID(), ops.token, app, 'synthetic', true).expect(400);
  await change(`vendors/${a.vendorId}`, { ...input, badges: ['Synthetic quality'] }, randomUUID(), ops.token, app, 'synthetic', true).expect(200);
  await change(`vendors/${a.vendorId}/suspend`, input).expect(409);
  expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).kyc_status).toBe('NOT_VERIFIED');
 });
 it('TC-404 serializes suspension/replay and denies vendor business without deleting records or altering KYC/plan', async () => {
  const input = await body(), key = randomUUID(), path = `vendors/${a.vendorId}/suspend`;
  const result = await Promise.all([change(path, input, key), change(path, input, key, ops.token, peer)]);
  expect(result.map(r => r.status)).toEqual([200, 200]); expect(result[0]!.body).toEqual(result[1]!.body);
  const denied = await request(app.getHttpServer()).get('/api/v1/vendor/customers').set('Authorization', `Bearer ${a.token}`).expect(403); expect(denied.body.code).toBe('VENDOR_SUSPENDED');
  await get(`vendors/${a.vendorId}`).expect(200);
  const audit = await db.audit_logs.findMany({ where: { action: 'VENDOR_SUSPEND', entity_id: a.vendorId } }); expect(audit).toHaveLength(1);
  expect(JSON.stringify(audit[0]!.after)).not.toContain(a.mobile);
  await change(`vendors/${a.vendorId}/reinstate`, await body()).expect(200);
  await change(path, input, key).expect(200); // Permanent replay must not re-suspend after a later reinstatement.
  expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).is_suspended).toBe(false);
  await change(path, { ...input, reason: 'Changed' }, key).expect(422);
  const actor = await admin('OPS'), fresh = await body(), freshKey = randomUUID(); await change(path, fresh, freshKey, actor.token).expect(200);
  await db.admin_users.update({ where: { id: actor.id }, data: { role: 'SUPPORT' } }); await change(path, fresh, freshKey, actor.token).expect(403);
 });
 it('TC-405 revokes sessions and blocks a verified-OTP login; unblock requires fresh sign-in', async () => {
  const path = `customers/${a.id}`;
  await db.devices.create({ data: { user_id: a.id, platform: 'ANDROID', push_token: `synthetic-${randomUUID()}` } });
  await change(`${path}/block`, await body('customers', a.id)).expect(200);
  await request(app.getHttpServer()).get('/api/v1/me').set('Authorization', `Bearer ${a.token}`).expect(401);
  expect(await db.sessions.count({ where: { user_id: a.id, status: 'ACTIVE' } })).toBe(0);
  expect((await db.devices.findFirstOrThrow({ where: { user_id: a.id } })).push_token).toBeNull();
  // Only OTP verification is simulated; account/session persistence and HTTP are real.
  const otp = jest.spyOn(app.get(OtpService), 'verify').mockResolvedValue(undefined);
  const login = () => request(app.getHttpServer()).post('/api/v1/auth/otp/verify').set('Idempotency-Key', randomUUID()).send({ mobile: a.mobile, code: '123456', device: { platform: 'ANDROID' } });
  try {
   expect((await login().expect(403)).body.code).toBe('ACCOUNT_BLOCKED');
   await change(`${path}/unblock`, await body('customers', a.id)).expect(200);
   await request(app.getHttpServer()).get('/api/v1/me').set('Authorization', `Bearer ${a.token}`).expect(401);
   const fresh = await login().expect(200); await request(app.getHttpServer()).get('/api/v1/me').set('Authorization', `Bearer ${fresh.body.accessToken}`).expect(200);
  } finally { otp.mockRestore(); }
  await db.users.update({ where: { id: a.id }, data: { status: 'DELETED' } }); await change(`${path}/unblock`, await body('customers', a.id)).expect(409);
 });
 it('rolls audit/status/replay back together on failure and preserves immutable replay evidence', async () => {
  // Inject failure at the service's in-transaction audit boundary, not the root Prisma delegate.
  const service = app.get(ManagementService) as unknown as { audit: () => Promise<unknown> };
  const audit = jest.spyOn(service, 'audit').mockRejectedValueOnce(new Error('Synthetic audit failure'));
  try { await change(`vendors/${a.vendorId}/suspend`, await body()).expect(503); } finally { audit.mockRestore(); }
  expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).is_suspended).toBe(false);
  expect(await db.audit_logs.count({ where: { action: 'VENDOR_SUSPEND', entity_id: a.vendorId } })).toBe(0);
  await change(`vendors/${a.vendorId}/suspend`, await body()).expect(200);
  const cached = await db.management_requests.findFirstOrThrow({ where: { path: `SUSPEND/${a.vendorId}` } });
  await expect(db.management_requests.delete({ where: { request_key: cached.request_key } })).rejects.toThrow();
 });
 it('runs production list/detail/status/badge forms through Next.js BFF and PostgreSQL', async () => {
  await app.listen(0, '127.0.0.1'); const apiPort = (app.getHttpServer().address() as AddressInfo).port;
  const reservation = createServer(); await new Promise<void>(r => reservation.listen(0, '127.0.0.1', r)); const webPort = (reservation.address() as AddressInfo).port; await new Promise<void>(r => reservation.close(() => r()));
  const origin = `http://127.0.0.1:${webPort}`, root = resolve(__dirname, '../../../../', 'admin');
  const child = spawn(process.execPath, [join(root, 'node_modules/next/dist/bin/next'), 'start', '--hostname', '127.0.0.1', '--port', String(webPort)], { cwd: root,
   env: { ...process.env, NODE_ENV: 'production', ADMIN_ORIGIN: origin, ADMIN_API_URL: `http://127.0.0.1:${apiPort}`, ADMIN_CSRF_KEY: randomBytes(32).toString('hex'), NEXT_TELEMETRY_DISABLED: '1' }, stdio: ['ignore', 'ignore', 'pipe'], windowsHide: true });
  let startup = ''; child.stderr?.on('data', (data: Buffer) => { startup = (startup + data.toString()).slice(-3000); });
  const jar = new Map([['sb_admin', ops.token], ['sb_csrf', 'synthetic']]);
  async function call(path: string, form?: URLSearchParams, suppliedOrigin = origin) {
   const result = await fetch(`${origin}${path}`, { redirect: 'manual', method: form ? 'POST' : 'GET', body: form,
    headers: { Cookie: [...jar].map(([key, value]) => `${key}=${value}`).join('; '), ...(form ? { Origin: suppliedOrigin } : {}) } });
   for (const cookie of result.headers.getSetCookie()) { const [pair] = cookie.split(';'), [name, value] = pair.split('='); jar.set(name, value); expect(cookie).toContain('HttpOnly'); } return result;
  }
  function form(html: string, action: string) {
   const block = [...html.matchAll(/<form\b[^>]*action="\/management\/save"[^>]*>([\s\S]*?)<\/form>/g)].map(m => m[1]).find(s => s.includes(`name="action" value="${action}"`));
   if (!block) throw new Error('Management form missing'); const fields = new URLSearchParams();
   for (const [element] of block.matchAll(/<input\b[^>]*>/g)) { const name = /name="([^"]+)"/.exec(element)?.[1]; if (!name) continue; fields.set(name, /value="([^"]*)"/.exec(element)?.[1] ?? 'on'); }
   fields.set('reason', 'Synthetic UI decision'); return fields;
  }
  try {
   let ready = false; for (let i = 0; i < 300; i++) { if (child.exitCode !== null) throw new Error(`Admin failed: ${startup}`); try { if ((await fetch(`${origin}/login`)).ok) { ready = true; break; } } catch { /* startup */ } await new Promise(r => setTimeout(r, 100)); } expect(ready).toBe(true);
   const list = await (await call(`/vendors?search=${a.vendorId}`)).text(); expect(list).toContain('Synthetic Managed Vendor'); expect(list).not.toContain(ops.token);
   const detail = await (await call(`/vendors/${a.vendorId}`)).text(), suspend = form(detail, 'suspend');
   expect((await call('/management/save', suspend, 'https://cross-origin.example.invalid')).status).toBe(403);
   const forged = new URLSearchParams(suspend); forged.set('id', b.vendorId); expect((await call('/management/save', forged)).status).toBe(400);
   const unconfirmed = new URLSearchParams(suspend); unconfirmed.delete('confirm'); expect((await call('/management/save', unconfirmed)).status).toBe(400);
   // Preserve request/key across a real API outage, then retry the same mutation.
   await app.close(); expect((await call('/management/save', suspend)).headers.get('location')).toBe(`${origin}/management/retry`);
   const recovery = await (await call('/management/retry')).text(); expect(recovery).toContain(suspend.get('key')!); expect(recovery).toContain('Retry this request safely');
   app = await boot(); await app.listen(apiPort, '127.0.0.1');
   expect((await call('/management/save', suspend)).status).toBe(303); expect((await call('/management/save', suspend)).status).toBe(303);
   expect((await db.vendors.findUniqueOrThrow({ where: { id: a.vendorId } })).is_suspended).toBe(true);
   const suspended = await (await call(`/vendors/${a.vendorId}`)).text(); expect(suspended).toContain('SUSPENDED');
   expect((await call('/management/save', form(suspended, 'reinstate'))).status).toBe(303);
   const badges = form(await (await call(`/vendors/${a.vendorId}`)).text(), 'badges'); badges.set('badges', 'Synthetic <display>');
   expect((await call('/management/save', badges)).status).toBe(303); expect(await (await call(`/vendors/${a.vendorId}`)).text()).toContain('Synthetic &lt;display&gt;');
   const customer = form(await (await call(`/customers/${a.id}`)).text(), 'block'); expect((await call('/management/save', customer)).status).toBe(303); expect((await db.users.findUniqueOrThrow({ where: { id: a.id } })).status).toBe('BLOCKED');
   jar.set('sb_admin', support.token); const readOnly = await (await call(`/vendors/${a.vendorId}`)).text(); expect(readOnly).not.toContain('action="/management/save"');
   jar.set('sb_admin', (await admin('FINANCE')).token); expect(await (await call('/customers')).text()).toContain('do not have permission');
  } finally { if (child.exitCode === null) { const stopped = new Promise<void>(r => child.once('exit', () => r())); child.kill('SIGTERM'); await stopped; } }
 }, 120000);
});
