import { Controller, Get, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdir, mkdtemp, rm } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { AddressInfo } from 'node:net';
import * as argon2 from 'argon2';
import request from 'supertest';
import { PrismaService } from '../../prisma/prisma.service';
import { PinoLogger } from '../../common/logging/pino.logger';
import { configureHttpApp } from '../../bootstrap';
import { AdminAuthService } from './admin-auth.service';
import { AdminPermission } from './admin-auth.controller';
@Controller('admin/test-permissions')
class PolicyProbe {
 @Get('kyc') @AdminPermission('kyc.review') kyc() { return { allowed: true }; }
 @Get('unlisted') unlisted() { return { allowed: true }; }
}
import { base32, decryptSecret, digest, encryptSecret, totp } from './admin-crypto';
import { permissions } from './admin-policy';
import { windowsPrivateDirectory } from '../../storage/windows-private-directory';
const native = process.env.ADMIN_TEST_DATABASE_URL ? describe : describe.skip;
native('T-150 TC-400/401 real PostgreSQL admin HTTP/session smoke', () => {
 const db = new PrismaService({ datasources: { db: { url: process.env.ADMIN_TEST_DATABASE_URL } } });
 const env = { ...process.env }, ids: string[] = [], key = randomBytes(32);
 let app: INestApplication, peer: INestApplication, root: string, hash: string;
 const password = randomBytes(32).toString('hex');
 async function boot() {
   const { AppModule } = await import('../../app.module');
   const module = await Test.createTestingModule({ imports: [AppModule], controllers: [PolicyProbe] })
     .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
   const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
 }
 beforeAll(async () => {
   const url = new URL(process.env.ADMIN_TEST_DATABASE_URL!);
   if (!url.pathname.endsWith('_test')) throw new Error('Dedicated _test database required');
   const base = join(homedir(), '.local/share/supplybiz/test-uploads');
   await mkdir(base, { recursive: true, mode: 0o700 }); root = await mkdtemp(join(base, 'admin-'));
   if (process.platform === 'win32') await windowsPrivateDirectory(root, true);
   Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), ADMIN_TOTP_KEY: key.toString('hex'),
     UPLOAD_ROOT: root, RATE_LIMIT_MAX_REQUESTS: '1000' });
   hash = await argon2.hash(password, { type: argon2.argon2id });
   await db.$connect(); app = await boot(); peer = await boot();
 });
 afterAll(async () => {
   await peer?.close(); await app?.close();
   await db.admin_auth_challenges.deleteMany({ where: { admin_id: { in: ids } } });
   await db.admin_sessions.deleteMany({ where: { admin_id: { in: ids } } });
   // Auth events are intentionally append-only, including in this isolated test DB.
   await db.admin_users.updateMany({ where: { id: { in: ids } }, data: { status: 'DISABLED' } });
   await db.$disconnect(); if (root) await rm(root, { recursive: true, force: true });
   for (const name of Object.keys(process.env)) if (!(name in env)) delete process.env[name];
   Object.assign(process.env, env);
 });
 async function fixture(role = 'SUPPORT', enrolled = false) {
   const secret = base32(randomBytes(20));
   const user = await db.admin_users.create({ data: { email: `admin-${randomUUID()}@example.invalid`, password_hash: hash,
     role, totp_secret_enc: enrolled ? encryptSecret(secret, key) : null } }); ids.push(user.id); return { ...user, secret };
 }
 function post(path: string, instance = app) { return request(instance.getHttpServer()).post(`/api/v1/admin/auth/${path}`).set('Idempotency-Key', randomUUID()); }
 async function start(email: string) { return (await post('login').send({ email, password }).expect(200)).body as { challengeToken: string }; }
 async function login(role = 'SUPPORT') {
   const user = await fixture(role), challenge = await start(user.email);
   const { enrollmentSecret } = (await request(app.getHttpServer()).get('/api/v1/admin/auth/challenge')
     .set('Authorization', `Bearer ${challenge.challengeToken}`).expect(200)).body as { enrollmentSecret: string };
   const result = await post('totp/verify').send({ ...challenge, code: totp(enrollmentSecret, Math.floor(Date.now() / 30000)) }).expect(200);
   return { user, challenge, ...(result.body as { sessionToken: string; csrfToken: string }) };
 }
 function me(token: string, instance = app) { return request(instance.getHttpServer()).get('/api/v1/admin/auth/me').set('Authorization', `Bearer ${token}`); }
 it('TC-400 enrols only after TOTP, hashes credentials, encrypts secret, consumes challenge, redacts responses', async () => {
   const result = await login();
   expect((await me(result.sessionToken, peer).expect(200)).body).toEqual({ id: result.user.id, role: 'SUPPORT', permissions: permissions('SUPPORT') });
   await me(result.challenge.challengeToken).expect(401);
   await post('totp/verify').send({ ...result.challenge, code: '000000' }).expect(401);
   const user = await db.admin_users.findUniqueOrThrow({ where: { id: result.user.id } });
   expect(user.totp_secret_enc).not.toContain(result.user.secret);
   const session = await db.admin_sessions.findUniqueOrThrow({ where: { token_hash: digest(result.sessionToken) } });
   expect(session.csrf_hash).toBe(digest(result.csrfToken));
   expect(session.expires_at.getTime() - session.created_at.getTime()).toBe(8 * 3600000);
   expect(await db.admin_auth_events.count({ where: { admin_id: user.id, action: 'TOTP_ENROLLED_LOGIN' } })).toBe(1);
   expect(await db.idempotency_keys.count({ where: { path: { startsWith: '/api/v1/admin/' } } })).toBe(0);
 });
 it('TC-400 rejects incorrect password/TOTP; five failures lock across API processes', async () => {
   const user = await fixture('OPS', true), challenge = await start(user.email);
   const code = totp(user.secret, Math.floor(Date.now() / 30000));
   const bad = String((Number(code) + 123) % 1000000).padStart(6, '0');
   for (let i = 0; i < 5; i++) await post('totp/verify', peer).send({ ...challenge, code: bad }).expect(401);
   await post('totp/verify').send({ ...challenge, code }).expect(401);
   await post('login').send({ email: user.email, password }).expect(401);
   expect((await db.admin_users.findUniqueOrThrow({ where: { id: user.id } })).failed_attempts).toBe(5);
   const wrong = await fixture();
   for (let i = 0; i < 5; i++) await post('login', peer).send({ email: wrong.email, password: 'invalid-test-password' }).expect(401);
   await post('login').send({ email: wrong.email, password }).expect(401);
   await post('login').send({ email: `absent-${randomUUID()}@example.invalid`, password }).expect(401);
 });
 it('TC-400 concurrent TOTP verification produces exactly one session and prevents code reuse', async () => {
   const user = await fixture('FINANCE', true), challenge = await start(user.email);
   const code = totp(user.secret, Math.floor(Date.now() / 30000));
   const results = await Promise.all([app, peer].map(instance => post('totp/verify', instance).send({ ...challenge, code })));
   expect(results.map(r => r.status).sort()).toEqual([200, 401]);
   const again = await start(user.email);
   await post('totp/verify').send({ ...again, code }).expect(401);
   expect(await db.admin_sessions.count({ where: { admin_id: user.id } })).toBe(1);
 });
 it('TC-400 expired challenge, disabled user and unknown role fail closed', async () => {
   const user = await fixture(), challenge = await start(user.email);
   await db.admin_auth_challenges.update({ where: { token_hash: digest(challenge.challengeToken) }, data: { expires_at: new Date(0) } });
   await post('totp/verify').send({ ...challenge, code: '000000' }).expect(401);
   await db.admin_users.update({ where: { id: user.id }, data: { status: 'DISABLED' } });
   await post('login').send({ email: user.email, password }).expect(401);
   const unknown = await fixture('FUTURE_ROLE'); await post('login').send({ email: unknown.email, password }).expect(401);
 });
 it('TC-400 idle and absolute session expiry are checked server-side', async () => {
   const idle = await login(), absolute = await login();
   await db.admin_sessions.update({ where: { token_hash: digest(idle.sessionToken) }, data: { last_used_at: new Date(Date.now() - 30 * 60000 - 1) } });
   await me(idle.sessionToken, peer).expect(401);
   await db.admin_sessions.update({ where: { token_hash: digest(absolute.sessionToken) }, data: { expires_at: new Date(0) } });
   await me(absolute.sessionToken).expect(401);
 });
 it('TC-400 logout requires matching CSRF, revokes across instances, account disabling also revokes access', async () => {
   const result = await login();
   await post('logout').set('Authorization', `Bearer ${result.sessionToken}`).expect(403);
   await me(result.sessionToken).expect(200);
   await post('logout').set('Authorization', `Bearer ${result.sessionToken}`).set('X-CSRF-Token', result.csrfToken).expect(204);
   await me(result.sessionToken, peer).expect(401);
   const disabled = await login();
   await db.admin_users.update({ where: { id: disabled.user.id }, data: { status: 'DISABLED' } });
   await me(disabled.sessionToken).expect(401);
 });
 it('TC-401 approved role grants are authoritative, unlisted permissions denied, role changes take immediate effect', async () => {
   for (const role of ['SUPER_ADMIN', 'OPS', 'SUPPORT', 'FINANCE']) {
     const result = await login(role), service = peer.get(AdminAuthService);
     await expect(service.authenticate(result.sessionToken, role === 'SUPPORT' ? 'vendors.read' : role === 'OPS' ? 'kyc.review' : 'plans.manage')).resolves.toBeDefined();
     await expect(service.authenticate(result.sessionToken, 'future.unlisted')).rejects.toThrow();
     await request(app.getHttpServer()).get('/api/v1/admin/test-permissions/unlisted').set('Authorization', `Bearer ${result.sessionToken}`).expect(403);
     await request(app.getHttpServer()).get('/API/V1/ADMIN/test-permissions/unlisted').set('Authorization', `Bearer ${result.sessionToken}`).expect(403);
     await request(peer.getHttpServer()).get('/api/v1/admin/test-permissions/kyc').set('Authorization', `Bearer ${result.sessionToken}`).expect(['SUPER_ADMIN', 'OPS'].includes(role) ? 200 : 403);
     if (role === 'SUPPORT') {
       await expect(service.authenticate(result.sessionToken, 'kyc.review')).rejects.toThrow();
       await expect(service.authenticate(result.sessionToken, 'kyc.documents')).rejects.toThrow();
       await expect(service.authenticate(result.sessionToken, 'reports.export')).rejects.toThrow();
     }
     await db.admin_users.update({ where: { id: result.user.id }, data: { role: 'SUPPORT' } });
     await expect(service.authenticate(result.sessionToken, 'plans.manage')).rejects.toThrow();
   }
 });
 it('TC-400 database auth event immutability and AES integrity reject modification', async () => {
   const result = await login();
   await expect(db.admin_auth_events.deleteMany({ where: { admin_id: result.user.id } })).rejects.toThrow();
   const encrypted = encryptSecret(base32(randomBytes(20)), key);
   expect(() => decryptSecret(encrypted, randomBytes(32))).toThrow();
   // RFC 6238 SHA1 vector at 59 seconds, truncated to six digits.
   expect(totp(base32(Buffer.from('12345678901234567890')), 1)).toBe('287082');
 });
 it('TC-400/401 production Next.js BFF password/enrolment/logout smoke with real API and PostgreSQL', async () => {
   await app.listen(0, '127.0.0.1');
   const port = (app.getHttpServer().address() as AddressInfo).port;
   const adminRoot = resolve(__dirname, '../../../../', 'admin');
   const origin = 'http://127.0.0.1:3139';
   const child = spawn(process.execPath, [join(adminRoot, 'node_modules/next/dist/bin/next'), 'start', '--hostname', '127.0.0.1', '--port', '3139'], {
     cwd: adminRoot, env: { ...process.env, NODE_ENV: 'production', ADMIN_ORIGIN: origin,
       ADMIN_API_URL: `http://127.0.0.1:${port}`, ADMIN_CSRF_KEY: randomBytes(32).toString('hex'), NEXT_TELEMETRY_DISABLED: '1' },
     stdio: ['ignore', 'ignore', 'pipe'], windowsHide: true,
   });
   let startupError = '';
   child.stderr?.on('data', (chunk: Buffer) => { startupError = (startupError + chunk.toString()).slice(-4000); });
   let spawnError = false; child.on('error', () => { spawnError = true; });
   const jar = new Map<string, string>();
   async function call(path: string, body?: URLSearchParams, suppliedOrigin = origin) {
     const response = await fetch(`${origin}${path}`, { redirect: 'manual',
       method: body ? 'POST' : 'GET', headers: { Cookie: [...jar].map(([name, value]) => `${name}=${value}`).join('; '),
         ...(body ? { Origin: suppliedOrigin } : {}) }, body });
     for (const cookie of response.headers.getSetCookie()) {
       const [pair] = cookie.split(';'), [name, value] = pair.split('=');
       if (value) jar.set(name, value); else jar.delete(name);
       expect(cookie.includes('HttpOnly')).toBe(true); expect(cookie.toLowerCase().includes('samesite=strict')).toBe(true);
     }
     return response;
   }
   function formCsrf(html: string): string {
     const value = /name="csrf" value="([^"]+)"/.exec(html)?.[1];
     if (!value) throw new Error('CSRF form field missing'); return value;
   }
   try {
     let ready = false;
     for (let i = 0; i < 200; i++) {
       if (spawnError || child.exitCode !== null) throw new Error('Next.js smoke server did not start');
       try { if ((await fetch(`${origin}/login`)).ok) { ready = true; break; } } catch { /* startup */ }
       await new Promise(done => setTimeout(done, 100));
     }
     if (!ready) throw new Error(`Next.js smoke server did not become ready: ${startupError}`);
     const user = await fixture('SUPPORT');
     // loading.tsx enables streamed redirects, whose HTTP status can be 200.
     const anonymous = await call('/');
     expect((await anonymous.text()).includes('url=/login')).toBe(true);
     const loginPage = await call('/login'); expect(loginPage.headers.get('cache-control')).toContain('no-store');
     const csrf = formCsrf(await loginPage.text());
     const credentials = new URLSearchParams({ email: user.email, password, csrf });
     expect((await call('/auth/login', credentials, 'https://cross-origin.example.invalid')).status).toBe(403);
     expect((await call('/auth/login', new URLSearchParams({ email: user.email, password, csrf: 'invalid' }))).status).toBe(403);
     const started = await call('/auth/login', credentials);
     expect(started.status).toBe(303); expect(started.headers.get('location')).toBe(`${origin}/totp`);
     expect(jar.has('sb_admin')).toBe(false); expect(jar.has('sb_pending')).toBe(true);
     const challenge = await db.admin_auth_challenges.findUniqueOrThrow({ where: { token_hash: digest(jar.get('sb_pending')!) } });
     const secret = decryptSecret(challenge.secret_enc, key);
     const totpPage = await call('/totp'), html = await totpPage.text();
     expect(html.includes(secret)).toBe(true);
     const verified = await call('/auth/verify', new URLSearchParams({ csrf: formCsrf(html), code: totp(secret, Math.floor(Date.now() / 30000)) }));
     expect(verified.status).toBe(303); expect(jar.has('sb_pending')).toBe(false); expect(jar.has('sb_admin')).toBe(true);
     const home = await call('/'), homeHtml = await home.text();
     expect(homeHtml.includes('Signed in as <!-- -->SUPPORT')).toBe(true);
     expect(homeHtml.includes('View vendors')).toBe(true); expect(homeHtml.includes('Manual KYC review')).toBe(false);
     expect(homeHtml.includes(jar.get('sb_admin')!)).toBe(false);
     const sessionToken = jar.get('sb_admin')!;
     const loggedOut = await call('/auth/logout', new URLSearchParams({ csrf: formCsrf(homeHtml) }));
     expect(loggedOut.status).toBe(303); expect(jar.size).toBe(0);
     await me(sessionToken, peer).expect(401);
   } finally {
     if (child.exitCode === null) {
       const stopped = new Promise<void>(done => child.once('exit', () => done()));
       child.kill('SIGTERM'); await stopped;
     }
   }
 }, 60000);

});
