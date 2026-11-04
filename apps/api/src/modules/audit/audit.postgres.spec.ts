import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomBytes, randomUUID } from 'node:crypto';
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { AddressInfo } from 'node:net';
import * as argon2 from 'argon2';
import request from 'supertest';
import { PrismaService } from '../../prisma/prisma.service';
import { PinoLogger } from '../../common/logging/pino.logger';
import { configureHttpApp } from '../../bootstrap';
import { decryptSecret, digest, totp } from '../admin-auth/admin-crypto';
import { auditContext } from './audit-context';
import { AuditPage } from './audit.controller';
const native = process.env.ADMIN_TEST_DATABASE_URL ? describe : describe.skip;
native('T-152 TC-408 native PostgreSQL audit and S-A-16 smoke', () => {
 const db = new PrismaService({ datasources: { db: { url: process.env.ADMIN_TEST_DATABASE_URL } } });
 const env = { ...process.env }, ids: string[] = [], key = randomBytes(32), password = randomBytes(32).toString('hex');
 let app: INestApplication, root: string, hash: string;
 let superAdmin: { id: string; token: string };
 async function fixture(role = 'SUPER_ADMIN') {
   const user = await db.admin_users.create({ data: { email: `audit-${randomUUID()}@example.invalid`, password_hash: hash, role } });
   ids.push(user.id);
   const token = randomBytes(32).toString('base64url');
   await db.admin_sessions.create({ data: { token_hash: digest(token), csrf_hash: digest('synthetic'), admin_id: user.id,
     expires_at: new Date(Date.now() + 3600000) } });
   return { id: user.id, token, email: user.email };
 }
 function get(query: Record<string, string> = {}, token = superAdmin.token) {
   return request(app.getHttpServer()).get('/api/v1/admin/audit-logs').query(query).set('Authorization', `Bearer ${token}`);
 }
 beforeAll(async () => {
   const url = new URL(process.env.ADMIN_TEST_DATABASE_URL!);
   if (!url.pathname.endsWith('_test')) throw new Error('Dedicated _test database required');
   const base = join(homedir(), '.local/share/supplybiz/test-uploads');
   await mkdir(base, { recursive: true, mode: 0o700 }); root = await mkdtemp(join(base, 'audit-'));
   Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), ADMIN_TOTP_KEY: key.toString('hex'),
     UPLOAD_ROOT: root, RATE_LIMIT_MAX_REQUESTS: '1000' });
   hash = await argon2.hash(password, { type: argon2.argon2id });
   const { AppModule } = await import('../../app.module');
   const module = await Test.createTestingModule({ imports: [AppModule] })
     .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
   app = module.createNestApplication(); configureHttpApp(app); await app.init();
   superAdmin = await fixture();
 });
 afterAll(async () => {
   await app?.close();
   await db.admin_auth_challenges.deleteMany({ where: { admin_id: { in: ids } } });
   await db.admin_sessions.deleteMany({ where: { admin_id: { in: ids } } });
   await db.admin_users.updateMany({ where: { id: { in: ids } }, data: { status: 'DISABLED' } });
   // Immutable synthetic audit/media records remain only in the dedicated test DB.
   await db.$disconnect(); if (root) await rm(root, { recursive: true, force: true });
   for (const name of Object.keys(process.env)) if (!(name in env)) delete process.env[name];
   Object.assign(process.env, env);
 });
 it('enforces SUPER_ADMIN on the API, validates filters and exposes no write route', async () => {
   await get({}, '').expect(401);
   for (const role of ['OPS', 'SUPPORT', 'FINANCE']) await get({}, (await fixture(role)).token).expect(403);
   await get({ actorId: 'invalid' }).expect(400); await get({ action: 'invalid' }).expect(400);
   await get({ beforeId: 'invalid' }).expect(400); await get({ extra: 'invalid' }).expect(400);
   await get({ action: 'NO_SUCH_ACTION' }).expect(200, { items: [], hasMore: false });
   await request(app.getHttpServer()).patch('/api/v1/admin/audit-logs').set('Authorization', `Bearer ${superAdmin.token}`).expect(404);
   await get().expect(200).expect('Cache-Control', 'no-store');
 });
 it('atomically captures before/after with explicit redaction and transaction-local actor/IP', async () => {
   const user = await fixture('SUPPORT');
   await db.$transaction(async tx => {
     await auditContext(tx, superAdmin.id, '127.0.0.1');
     await tx.admin_users.update({ where: { id: user.id }, data: { role: 'OPS' } });
   });
   const row = await db.audit_logs.findFirstOrThrow({ where: { entity_id: user.id, action: 'ADMIN_ACCOUNT_UPDATE' } });
   expect(row.actor_id).toBe(superAdmin.id); expect(row.ip).toBe('127.0.0.1');
   expect(row.before).toMatchObject({ role: 'SUPPORT', totp_enrolled: false }); expect(row.after).toMatchObject({ role: 'OPS' });
   expect(Object.keys(row.after as object).sort()).toEqual(['failed_attempts', 'last_login_at', 'locked_until', 'role', 'status', 'totp_enrolled']);
   expect(JSON.stringify(row)).not.toContain(user.email); expect(JSON.stringify(row)).not.toContain(hash);
   const count = await db.audit_logs.count({ where: { entity_id: user.id } });
   await expect(db.$transaction(async tx => {
     await auditContext(tx, superAdmin.id, '127.0.0.1');
     await tx.admin_users.update({ where: { id: user.id }, data: { role: 'FINANCE' } });
     throw new Error('rollback');
   })).rejects.toThrow('rollback');
   expect(await db.audit_logs.count({ where: { entity_id: user.id } })).toBe(count);
   expect((await db.admin_users.findUniqueOrThrow({ where: { id: user.id } })).role).toBe('OPS');
   const system = await fixture();
   const created = await db.audit_logs.findFirstOrThrow({ where: { entity_id: system.id } });
   expect(created.actor_type).toBe('SYSTEM'); expect(created.actor_id).toBeNull(); expect(created.ip).toBeNull();
 });
 it('audits real HTTP login, TOTP enrolment, logout and private document reads without secrets', async () => {
   const user = await fixture();
   const post = (path: string) => request(app.getHttpServer()).post(`/api/v1/admin/auth/${path}`).set('Idempotency-Key', randomUUID());
   const challenge = await post('login').send({ email: user.email, password }).expect(200);
   const saved = await db.admin_auth_challenges.findUniqueOrThrow({ where: { token_hash: digest(challenge.body.challengeToken as string) } });
   const secret = decryptSecret(saved.secret_enc, key);
   const verified = await post('totp/verify').send({ challengeToken: challenge.body.challengeToken, code: totp(secret, Math.floor(Date.now() / 30000)) }).expect(200);
   const token = verified.body.sessionToken as string;
   const owner = await db.users.create({ data: { mobile: `test-${randomUUID()}` } });
   const mediaId = randomUUID(), bytes = Buffer.from('synthetic-private-content');
   await writeFile(join(root, 'kyc', `${mediaId}.png`), bytes, { mode: 0o600 });
   await db.media_files.create({ data: { id: mediaId, owner_user_id: owner.id, purpose: 'KYC_DOC',
     relative_storage_key: `kyc/${mediaId}.png`, mime: 'image/png', size: bytes.length,
     sha256: digest(bytes.toString()), request_key: digest(randomUUID()), request_hash: digest(randomUUID()) } });
   await request(app.getHttpServer()).get(`/api/v1/admin/media/${mediaId}/content`).set('Authorization', `Bearer ${token}`).expect(200);
   const read = await db.audit_logs.findFirstOrThrow({ where: { entity_id: mediaId } });
   expect(read.actor_id).toBe(user.id); expect(read.action).toBe('KYC_DOCUMENT_READ'); expect(read.ip).toMatch(/127\.0\.0\.1/);
   await post('logout').set('Authorization', `Bearer ${token}`).set('X-CSRF-Token', verified.body.csrfToken as string).expect(204);
   const rows = await db.audit_logs.findMany({ where: { actor_id: user.id } });
   expect(rows.map(r => r.action)).toEqual(expect.arrayContaining(['PASSWORD_VERIFIED', 'TOTP_ENROLLED_LOGIN', 'LOGOUT']));
   expect(rows.every(r => r.ip?.includes('127.0.0.1'))).toBe(true);
   for (const privateValue of [password, hash, secret, token, user.email, saved.secret_enc]) expect(JSON.stringify(rows)).not.toContain(privateValue);
 });
 it('paginates tied timestamps without gaps/duplicates and keeps actor/action filters', async () => {
   const actor = await fixture();
   const at = new Date();
   await db.audit_logs.createMany({ data: Array.from({ length: 55 }, () => ({ id: randomUUID(), actor_type: 'ADMIN',
     actor_id: actor.id, action: 'LOGIN_SUCCEEDED', entity: 'admin_auth', entity_id: actor.id, at })) });
   const first = (await get({ actorId: actor.id, action: 'LOGIN_SUCCEEDED' }).expect(200)).body as AuditPage;
   expect(first.items).toHaveLength(50); expect(first.hasMore).toBe(true);
   const second = (await get({ actorId: actor.id, action: 'LOGIN_SUCCEEDED', beforeId: first.items[49].id }).expect(200)).body as AuditPage;
   expect(second.items).toHaveLength(5); expect(second.hasMore).toBe(false);
   expect(new Set([...first.items, ...second.items].map(r => r.id)).size).toBe(55);
   expect(first.items.every(r => r.actor_id === actor.id && r.action === 'LOGIN_SUCCEEDED')).toBe(true);
 });
 it('rejects UPDATE, DELETE, TRUNCATE and rolls back the business write when audit persistence fails', async () => {
   const user = await fixture();
   await expect(db.audit_logs.updateMany({ where: { entity_id: user.id }, data: { action: 'TAMPERED' } })).rejects.toThrow();
   await expect(db.audit_logs.deleteMany({ where: { entity_id: user.id } })).rejects.toThrow();
   await expect(db.$executeRaw`TRUNCATE audit_logs`).rejects.toThrow();
   // Invalid UUID context makes the AFTER trigger fail, proving atomic failure.
   await expect(db.$transaction(async tx => {
     await tx.$queryRaw`SELECT set_config('supplybiz.audit_actor', 'invalid', true)`;
     await tx.admin_users.update({ where: { id: user.id }, data: { role: 'SUPPORT' } });
   })).rejects.toThrow();
   expect((await db.admin_users.findUniqueOrThrow({ where: { id: user.id } })).role).toBe('SUPER_ADMIN');
 });
 it('serves the production S-A-16 page through Next.js → API → PostgreSQL', async () => {
   await app.listen(0, '127.0.0.1');
   const port = (app.getHttpServer().address() as AddressInfo).port;
   const adminRoot = resolve(__dirname, '../../../../', 'admin'), origin = 'http://127.0.0.1:3140';
   const child = spawn(process.execPath, [join(adminRoot, 'node_modules/next/dist/bin/next'), 'start', '--hostname', '127.0.0.1', '--port', '3140'], {
     cwd: adminRoot, env: { ...process.env, NODE_ENV: 'production', ADMIN_ORIGIN: origin,
       ADMIN_API_URL: `http://127.0.0.1:${port}`, ADMIN_CSRF_KEY: randomBytes(32).toString('hex'), NEXT_TELEMETRY_DISABLED: '1' }, stdio: 'ignore' });
   let spawnError = false; child.on('error', () => { spawnError = true; });
   async function page(path: string, token = superAdmin.token) {
     const response = await fetch(`${origin}${path}`, { headers: { Cookie: `sb_admin=${token}` }, redirect: 'manual' });
     expect(response.headers.get('cache-control')).toContain('no-store'); return response.text();
   }
   try {
     let ready = false;
     for (let i = 0; i < 60; i++) {
       if (spawnError || child.exitCode !== null) throw new Error('Next.js smoke server did not start');
       try { if ((await fetch(`${origin}/login`)).ok) { ready = true; break; } } catch { /* startup */ }
       await new Promise(done => setTimeout(done, 100));
     }
     expect(ready).toBe(true);
     expect(await page('/')).toContain('Open audit log');
     const html = await page('/audit-logs');
     expect(html).toContain('Audit log'); expect(html).toContain('Before'); expect(html).toContain('ADMIN_ACCOUNT_INSERT');
     expect(html).not.toContain(hash); expect(html).not.toContain(superAdmin.token);
     expect(await page('/audit-logs?action=NO_SUCH_ACTION')).toContain('No audit records match');
     expect(await page('/audit-logs?actorId=invalid')).toContain('Invalid filter');
     const support = await fixture('SUPPORT');
     expect(await page('/', support.token)).not.toContain('Open audit log');
     expect(await page('/audit-logs', support.token)).toContain('You do not have permission');
   } finally {
     if (child.exitCode === null) {
       const stopped = new Promise<void>(done => child.once('exit', () => done())); child.kill('SIGTERM'); await stopped;
     }
   }
 }, 20000);
});
