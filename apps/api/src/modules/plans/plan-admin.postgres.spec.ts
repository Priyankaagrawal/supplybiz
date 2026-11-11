import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomBytes, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo, createServer } from 'node:net';
import { join, resolve } from 'node:path';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { digest } from '../admin-auth/admin-crypto';
import { istInput } from '../../../../admin/src/lib/plans';

const testUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = testUrl ? describe : describe.skip;
native('T-156 TC-406/510 real catalog/assignment administration', () => {
 const db = new PrismaService({ datasources: { db: { url: testUrl } } }), env = { ...process.env };
 let app: INestApplication, finance: { id: string; token: string }, vendorId: string, basicId: string;
 let original: Awaited<ReturnType<typeof db.plans.findUniqueOrThrow>>;
 let originalPrices: Awaited<ReturnType<typeof db.plan_prices.findMany>>;
 async function boot() {
  const { AppModule } = await import('../../app.module');
  const module = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PinoLogger)
   .useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
  const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
 }
 async function admin(role: string) {
  const row = await db.admin_users.create({ data: { email: `plan-admin-${randomUUID()}@example.invalid`, role, password_hash: 'synthetic-unused' } });
  const token = randomBytes(32).toString('base64url');
  await db.admin_sessions.create({ data: { token_hash: digest(token), admin_id: row.id, csrf_hash: digest('synthetic'), expires_at: new Date(Date.now() + 3600000) } });
  return { id: row.id, token };
 }
 const catalog = (token = finance.token) => request(app.getHttpServer()).get('/api/v1/admin/plans').set('Authorization', `Bearer ${token}`);
 const save = (body: object, key: string = randomUUID(), token = finance.token, csrf = 'synthetic') => request(app.getHttpServer()).put(`/api/v1/admin/plans/${basicId}`)
  .set('Authorization', `Bearer ${token}`).set('X-CSRF-Token', csrf).set('Idempotency-Key', key).send(body);
 async function input() {
  const row = (await catalog().expect(200)).body.items.find((r: { id: string }) => r.id === basicId);
  return { name: 'Synthetic Basic', status: 'ACTIVE', isPopular: false, expectedUpdatedAt: row.updatedAt, reason: 'Synthetic catalog reason',
   prices: [{ duration: 'MONTHLY', pricePaise: 9909 }, { duration: 'HALF_YEARLY', pricePaise: 49900 }, { duration: 'YEARLY', pricePaise: 99900 }] };
 }
 beforeAll(async () => {
  const url = new URL(testUrl!);
  if (!url.pathname.endsWith('_test') || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
  Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000' });
  await db.$connect(); app = await boot(); finance = await admin('FINANCE');
  original = await db.plans.findUniqueOrThrow({ where: { code: 'BASIC' } }); basicId = original.id;
  originalPrices = await db.plan_prices.findMany({ where: { plan_id: basicId } });
  const category = await db.categories.create({ data: { code: `PLAN-UI-${randomUUID()}`, name_en: 'Synthetic plan category', name_hi: '', type: 'SUPPLY' } });
  const user = await db.users.create({ data: { mobile: `synthetic-${randomUUID()}`, active_role: 'VENDOR', roles: { create: { role: 'VENDOR' } } } });
  vendorId = (await db.vendors.create({ data: { user_id: user.id, category_id: category.id, business_name: `Synthetic Plan UI ${randomUUID()}` } })).id;
 }, 60000);
 afterAll(async () => {
  if (original) {
   await db.plans.update({ where: { id: basicId }, data: { name: original.name, status: original.status, is_popular: original.is_popular } });
   for (const price of originalPrices) await db.plan_prices.update({ where: { id: price.id }, data: { price_paise: price.price_paise } });
  }
  await app?.close(); await db.$disconnect();
  for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env, env);
 }, 60000);
 it('rejects unprivileged roles, missing CSRF/key, forged policy and invalid prices/reason', async () => {
  const body = await input();
  await save(body, randomUUID(), '').expect(401);
  for (const role of ['SUPPORT', 'OPS']) await save(body, randomUUID(), (await admin(role)).token).expect(403);
  await save(body, randomUUID(), finance.token, 'wrong').expect(403); await save(body, '').expect(400);
  for (const change of [{ customerLimit: 9999 }, { features: ['WALLET_SETTLEMENT'] }, { reason: ' ' }, { name: ' ' }, { prices: [] }, { prices: [null, null, null] },
   { prices: body.prices.map(p => ({ ...p, pricePaise: -1 })) }, { prices: body.prices.map(p => ({ ...p, duration: 'MONTHLY' })) }, { prices: [{ duration: 'MONTHLY', pricePaise: 1.5 }, ...body.prices.slice(1)] }]) await save({ ...body, ...change }).expect(400);
 });
 it('saves reference prices once, preserves policy, audits and refuses a stale overwrite', async () => {
  const body = await input(), key = randomUUID();
  const results = await Promise.all([save(body, key), save(body, key)]);
  expect(results.map(r => r.status)).toEqual([200, 200]); expect(results[0]!.body).toEqual(results[1]!.body);
  expect(results[0]!.body).toMatchObject({ customerLimit: 100, prices: expect.arrayContaining([{ duration: 'MONTHLY', pricePaise: 9909 }]) });
  expect((await db.plans.findUniqueOrThrow({ where: { id: basicId } })).customer_limit).toBe(original.customer_limit);
  expect(await db.audit_logs.count({ where: { actor_id: finance.id, action: 'PLAN_CATALOG_UPDATE' } })).toBe(1);
  await save({ ...body, name: 'Changed' }, key).expect(422); await save({ ...body, name: 'Stale' }).expect(409);
 });
 it('offers permission-scoped vendor search and paginated history without private customer/KYC fields', async () => {
  const result = await request(app.getHttpServer()).get(`/api/v1/admin/plan-vendors?search=${vendorId}`).set('Authorization', `Bearer ${finance.token}`).expect(200);
  expect(result.body.items[0].id).toBe(vendorId); expect(Object.keys(result.body.items[0]).sort()).toEqual(['businessName', 'id']);
  await request(app.getHttpServer()).get('/api/v1/admin/plan-vendors?offset=-1').set('Authorization', `Bearer ${finance.token}`).expect(400);
  await request(app.getHttpServer()).get(`/api/v1/admin/vendors/${randomUUID()}/plan-history`).set('Authorization', `Bearer ${finance.token}`).expect(404);
  const actor = await admin('SUPPORT');
  await request(app.getHttpServer()).get('/api/v1/admin/plan-vendors').set('Authorization', `Bearer ${actor.token}`).expect(403);
 });
 it('runs production S-A-09/10 forms through BFF/API/PostgreSQL, with safe retry and history', async () => {
  await app.listen(0, '127.0.0.1'); const apiPort = (app.getHttpServer().address() as AddressInfo).port;
  const reservation = createServer(); await new Promise<void>(r => reservation.listen(0, '127.0.0.1', r));
  const webPort = (reservation.address() as AddressInfo).port; await new Promise<void>(r => reservation.close(() => r()));
  const origin = `http://127.0.0.1:${webPort}`, root = resolve(__dirname, '../../../../', 'admin');
  const child = spawn(process.execPath, [join(root, 'node_modules/next/dist/bin/next'), 'start', '--hostname', '127.0.0.1', '--port', String(webPort)], {
   cwd: root, env: { ...process.env, NODE_ENV: 'production', ADMIN_ORIGIN: origin, ADMIN_API_URL: `http://127.0.0.1:${apiPort}`, ADMIN_CSRF_KEY: randomBytes(32).toString('hex'), NEXT_TELEMETRY_DISABLED: '1' }, stdio: ['ignore', 'ignore', 'pipe'], windowsHide: true,
  });
  let startup = ''; child.stderr?.on('data', (data: Buffer) => { startup = (startup + data.toString()).slice(-3000); });
  const jar = new Map([['sb_admin', finance.token], ['sb_csrf', 'synthetic']]);
  const call = async (path: string, body?: URLSearchParams, suppliedOrigin = origin) => {
   const response = await fetch(`${origin}${path}`, { redirect: 'manual', method: body ? 'POST' : 'GET', body,
    headers: { Cookie: [...jar].map(([k, v]) => `${k}=${v}`).join('; '), ...(body ? { Origin: suppliedOrigin } : {}) } });
   for (const value of response.headers.getSetCookie()) { const [pair] = value.split(';'), [name, content] = pair.split('='); jar.set(name, content); expect(value).toContain('HttpOnly'); }
   return response;
  };
  function form(html: string, action: string) {
   const block = [...html.matchAll(/<form\b[^>]*action="\/plans\/save"[^>]*>([\s\S]*?)<\/form>/g)].map(m => m[1]).find(s => s.includes(`name="action" value="${action}"`));
   if (!block) throw new Error('Plan form missing');
   const fields = new URLSearchParams();
   for (const [element] of block.matchAll(/<input\b[^>]*>/g)) {
    const name = /name="([^"]+)"/.exec(element)?.[1]; if (!name || element.includes('type="checkbox"') && !element.includes('checked')) continue;
    fields.set(name, /value="([^"]*)"/.exec(element)?.[1] ?? (element.includes('type="checkbox"') ? 'on' : ''));
   }
   return fields;
  }
  try {
   let ready = false;
   for (let i = 0; i < 300; i++) { if (child.exitCode !== null) throw new Error(`Admin startup failed: ${startup}`); try { if ((await fetch(`${origin}/login`)).ok) { ready = true; break; } } catch { /* startup */ } await new Promise(r => setTimeout(r, 100)); }
   expect(ready).toBe(true);
   const catalogPage = await call('/plans'), html = await catalogPage.text(); expect(catalogPage.status).toBe(200); expect(html).toContain('Vendor plan assignments'); expect(html).not.toContain(finance.token);
   const edit = form(html, 'catalog'); edit.set('name', 'Synthetic Basic UI'); edit.set('reason', 'Synthetic catalog UI'); edit.set('status', 'ACTIVE');
   expect((await call('/plans/save', edit, 'https://cross-origin.example.invalid')).status).toBe(403);
   const wrongKey = new URLSearchParams(edit); wrongKey.set('planId', randomUUID()); expect((await call('/plans/save', wrongKey)).status).toBe(400);
   const saved = await call('/plans/save', edit); expect(saved.status).toBe(303); expect(saved.headers.get('location')).toBe(`${origin}/plans?result=saved`);
   expect((await db.plans.findUniqueOrThrow({ where: { id: basicId } })).name).toBe('Synthetic Basic UI');
   const page = await call(`/plans/vendors/${vendorId}`), pageHtml = await page.text(); expect(page.status).toBe(200);
   const assign = form(pageHtml, 'assign'); assign.set('planId', basicId); assign.set('reason', 'Synthetic <script>reason</script>'); assign.set('endsAt', istInput(new Date(Date.now() + 30 * 86400000).toISOString()));
   // A connection loss must preserve the exact key/body for retry after API restart.
   await app.close(); expect((await call('/plans/save', assign)).headers.get('location')).toBe(`${origin}/plans/retry`);
   const retry = await call('/plans/retry'), retryHtml = await retry.text(); expect(retryHtml).toContain('Retry this request safely'); expect(retryHtml).toContain(assign.get('key')!); expect(retryHtml).not.toContain(finance.token);
   app = await boot(); await app.listen(apiPort, '127.0.0.1');
   expect((await call('/plans/save', assign)).status).toBe(303); expect((await call('/plans/save', assign)).status).toBe(303);
   expect(await db.vendor_plan_assignments.count({ where: { vendor_id: vendorId } })).toBe(1);
   const refreshed = await (await call(`/plans/vendors/${vendorId}`)).text(); expect(refreshed).toContain('Synthetic &lt;script&gt;reason&lt;/script&gt;');
   const extend = form(refreshed, 'extend'); extend.set('reason', 'Synthetic extension UI'); extend.set('endsAt', istInput(new Date(Date.now() + 60 * 86400000).toISOString()));
   expect((await call('/plans/save', extend)).status).toBe(303);
   expect(await db.vendor_plan_assignments.count({ where: { vendor_id: vendorId } })).toBe(2);
   jar.set('sb_admin', (await admin('SUPPORT')).token); const denied = await (await call('/plans')).text(); expect(denied).toContain('do not have permission'); expect(denied).not.toContain('name="action" value="catalog"');
  } finally { if (child.exitCode === null) { const stopped = new Promise<void>(r => child.once('exit', () => r())); child.kill('SIGTERM'); await stopped; } }
 }, 120000);
});
