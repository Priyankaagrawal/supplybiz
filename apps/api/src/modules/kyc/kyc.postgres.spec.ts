import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createDecipheriv, randomBytes, randomUUID } from 'node:crypto';
import { mkdir, mkdtemp, rm } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import sharp from 'sharp';
import request from 'supertest';
import { ConfigService } from '@nestjs/config';
import { configureHttpApp } from '../../bootstrap';
import { PrismaService } from '../../prisma/prisma.service';
import { PinoLogger } from '../../common/logging/pino.logger';
import { SessionTokensService } from '../auth/session-tokens.service';
import { digest } from '../admin-auth/admin-crypto';
import { KycSubmissionDto } from './kyc.dto';
const native = process.env.KYC_TEST_DATABASE_URL ? describe : describe.skip;
native('T-022 TC-024–026/509 manual KYC HTTP → native PostgreSQL', () => {
  const db = new PrismaService({ datasources: { db: { url: process.env.KYC_TEST_DATABASE_URL } } });
  const env = { ...process.env }, encryptionKey = randomBytes(32);
  let app: INestApplication, root: string, userId: string, vendorId: string, access: string, other: string, otherId: string, customer: string;
  let ops: string, support: string, finance: string, superAdmin: string, submissionId: string, input: KycSubmissionDto;
  const adminIds: string[] = [];
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
    app = module.createNestApplication(); configureHttpApp(app); await app.init();
    if (userId) {
      const session = await db.sessions.findFirstOrThrow({ where: { user_id: userId } });
      access = app.get(SessionTokensService).issue(userId, session.id, []);
      const secondSession = await db.sessions.findFirstOrThrow({ where: { user_id: otherId } });
      other = app.get(SessionTokensService).issue(otherId, secondSession.id, []);
    }
  }
  async function account(role: 'VENDOR' | 'CUSTOMER' = 'VENDOR') {
    const user = await db.users.create({ data: { mobile: `kyc-${randomUUID()}`, active_role: role, roles: { create: { role } } } });
    const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(), refresh_token_hash: randomUUID(),
      expires_at: new Date(Date.now() + 3600000) } });
    return { id: user.id, token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  async function admin(role: string) {
    const row = await db.admin_users.create({ data: { email: `kyc-${randomUUID()}@example.invalid`, password_hash: 'synthetic-not-a-login', role } });
    adminIds.push(row.id); const token = randomBytes(32).toString('base64url');
    await db.admin_sessions.create({ data: { token_hash: digest(token), csrf_hash: digest('synthetic'), admin_id: row.id, expires_at: new Date(Date.now() + 3600000) } });
    return token;
  }
  function submit(body: object = input, key: string = randomUUID(), token = access) {
    return request(app.getHttpServer()).post('/api/v1/vendor/kyc').set('Authorization', `Bearer ${token}`).set('Idempotency-Key', key).send(body);
  }
  function get(path = '/vendor/kyc', token = access) {
    return request(app.getHttpServer()).get(`/api/v1${path}`).set('Authorization', `Bearer ${token}`);
  }
  function decision(id = submissionId, value = 'REJECTED', key: string = randomUUID(), token = ops, csrf = 'synthetic') {
    return request(app.getHttpServer()).post(`/api/v1/admin/kyc/${id}/decision`).set('Authorization', `Bearer ${token}`)
      .set('X-CSRF-Token', csrf).set('Idempotency-Key', key).send({ decision: value, reason: 'Synthetic review reason' });
  }
  beforeAll(async () => {
    const url = new URL(process.env.KYC_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith('_test')) throw new Error('Dedicated _test database required');
    const base = join(homedir(), '.local/share/supplybiz/test-uploads');
    await mkdir(base, { recursive: true, mode: 0o700 }); root = await mkdtemp(join(base, 'kyc-'));
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), UPLOAD_ROOT: root,
      FIELD_ENCRYPTION_KEY: encryptionKey.toString('hex'), RATE_LIMIT_MAX_REQUESTS: '2000' });
    await db.$connect(); await boot();
    const owner = await account(); userId = owner.id; access = owner.token;
    const second = await account(); other = second.token; otherId = second.id; customer = (await account('CUSTOMER')).token;
    ops = await admin('OPS'); support = await admin('SUPPORT'); finance = await admin('FINANCE'); superAdmin = await admin('SUPER_ADMIN');
    const category = await db.categories.create({ data: { code: `KYC-${randomUUID()}`, name_en: 'Synthetic', name_hi: '', type: 'SUPPLY' } });
    const vendor = await db.vendors.create({ data: { user_id: userId, category_id: category.id, business_name: 'Synthetic Dairy', onboarding_step: 3, settings: { create: {} } } });
    vendorId = vendor.id;
    const ids: string[] = [];
    // Synthetic images only. Never fixture real Aadhaar/PAN/bank data.
    for (const background of ['#aaa', '#bbb', '#ccc']) {
      const png = await sharp({ create: { width: 3, height: 3, channels: 3, background } }).png().toBuffer();
      const uploaded = await request(app.getHttpServer()).post('/api/v1/media').set('Authorization', `Bearer ${access}`)
        .set('Idempotency-Key', randomUUID()).field('purpose', 'KYC_DOC').attach('file', png, 'synthetic.png').expect(201);
      ids.push(uploaded.body.mediaId as string);
    }
    input = { aadhaarFrontMediaId: ids[0]!, aadhaarBackMediaId: ids[1]!, panMediaId: ids[2]!, pan: 'ZZZZZ0000Z',
      holderName: 'Synthetic Holder', bankName: 'Synthetic Bank', accountNumber: '000000000001', accountNumberConfirmation: '000000000001', ifsc: 'ZZZZ0000000' };
  });
  afterAll(async () => {
    await app?.close();
    await db.admin_sessions.deleteMany({ where: { admin_id: { in: adminIds } } });
    await db.admin_users.updateMany({ where: { id: { in: adminIds } }, data: { status: 'DISABLED' } });
    // Immutable synthetic revisions/audits remain only in the dedicated test DB.
    await db.$disconnect(); if (root) await rm(root, { recursive: true, force: true });
    for (const name of Object.keys(process.env)) if (!(name in env)) delete process.env[name];
    Object.assign(process.env, env);
  });
  it('TC-024 rejects invalid/mismatched banking fields, full Aadhaar and forged policy fields', async () => {
    await get().expect(404);
    for (const patch of [{ accountNumberConfirmation: '000000000002' }, { accountNumber: '123' }, { ifsc: 'SBIN1001234' },
      { pan: 'BAD' }, { holderName: '  ' }, { bankName: null }, { upiId: 'bad' }, { aadhaar: '000000000000' },
      { vendorId }, { status: 'VERIFIED' }, { verificationMethod: 'API' }, { aadhaarFrontMediaId: input.panMediaId }]) {
      await submit({ ...input, ...patch }).expect(400);
    }
    await submit(input, '').expect(400); await submit(input, randomUUID(), '').expect(401);
    await submit(input, randomUUID(), customer).expect(403);
    expect(await db.vendor_kyc.count({ where: { vendor_id: vendorId } })).toBe(0);
  });
  it('rejects cross-owner/wrong-purpose attachments and inactive vendor roles', async () => {
    const media = await db.media_files.findUniqueOrThrow({ where: { id: input.panMediaId } });
    const bad = await db.media_files.create({ data: { ...media, id: randomUUID(), relative_storage_key: `media/${randomUUID()}.png`, purpose: 'PROFILE', request_key: digest(randomUUID()) } });
    await submit({ ...input, panMediaId: bad.id }).expect(404);
    await db.media_files.update({ where: { id: bad.id }, data: { purpose: 'KYC_DOC', owner_user_id: otherId } });
    await submit({ ...input, panMediaId: bad.id }).expect(404);
    await submit({ ...input, panMediaId: randomUUID() }).expect(404);
    await db.users.update({ where: { id: userId }, data: { active_role: 'CUSTOMER' } });
    await submit().expect(403);
    await db.users.update({ where: { id: userId }, data: { active_role: 'VENDOR' } });
    await submit(input, randomUUID(), other).expect(409);
  });
  it('TC-509 submits once across concurrency/restart; encrypts PAN/account and redacts all responses/replays/audits', async () => {
    const key: string = randomUUID();
    const results = await Promise.all([submit(input, key), submit(input, key)]);
    expect(results.map(r => r.status)).toEqual([201, 201]); expect(results[0]!.body).toEqual(results[1]!.body);
    submissionId = results[0]!.body.id as string;
    expect((await submit(Object.fromEntries(Object.entries(input).reverse()), key).expect(201)).body).toEqual(results[0]!.body);
    expect(results[0]!.body).toMatchObject({ status: 'MANUAL_REVIEW', verificationMethod: 'MANUAL_REVIEW', providerChecks: 'NOT_RUN', accountLast4: '0001' });
    await submit({ ...input, bankName: 'Changed' }, key).expect(422);
    await submit().expect(409);
    const stored = await db.vendor_kyc.findUniqueOrThrow({ where: { id: submissionId } });
    function decrypt(value: string, field: string) {
      const bytes = Buffer.from(value.slice(7), 'base64');
      const cipher = createDecipheriv('aes-256-gcm', encryptionKey, bytes.subarray(0, 12));
      cipher.setAAD(Buffer.from(`supplybiz:kyc:v1:${vendorId}:${field}`)); cipher.setAuthTag(bytes.subarray(12, 28));
      return Buffer.concat([cipher.update(bytes.subarray(28)), cipher.final()]).toString();
    }
    expect(decrypt(stored.pan_enc, 'pan')).toBe(input.pan); expect(decrypt(stored.account_number_enc, 'account')).toBe(input.accountNumber);
    const replay = await db.idempotency_keys.findMany({ where: { path: 'submit' } });
    const audit = await db.audit_logs.findMany({ where: { entity_id: submissionId } });
    for (const value of [input.pan, input.accountNumber]) {
      expect(JSON.stringify(stored)).not.toContain(value); expect(JSON.stringify(results[0]!.body)).not.toContain(value);
      expect(JSON.stringify(replay)).not.toContain(value); expect(JSON.stringify(audit)).not.toContain(value);
    }
    await app.close(); await boot();
    expect((await get().expect(200)).body).toEqual(results[0]!.body);
    expect((await submit(input, key).expect(201)).body).toEqual(results[0]!.body);
    expect(await db.vendor_kyc.count({ where: { vendor_id: vendorId } })).toBe(1);
    expect((await db.vendors.findUniqueOrThrow({ where: { id: vendorId } })).kyc_status).toBe('MANUAL_REVIEW');
  });
  it('requires permitted admin sessions/CSRF, validates decision/reason, denies vendor and SUPPORT/FINANCE', async () => {
    for (const token of [support, finance]) {
      await get('/admin/kyc', token).expect(403); await decision(submissionId, 'VERIFIED', randomUUID(), token).expect(403);
    }
    await get('/admin/kyc', access).expect(401); await decision(submissionId, 'VERIFIED', randomUUID(), ops, '').expect(403);
    await get('/admin/kyc?extra=1', ops).expect(400); await get('/admin/kyc/invalid', ops).expect(400);
    await get(`/admin/kyc/${submissionId}`, ops).expect(200).expect('Cache-Control', 'no-store');
    const queue = await get('/admin/kyc', superAdmin).expect(200);
    expect(queue.body.items.some((r: { id: string }) => r.id === submissionId)).toBe(true);
    for (const patch of [{ decision: 'PENDING' }, { reason: ' ' }, { reason: '  x' }, { reviewerId: randomUUID() }]) {
      await request(app.getHttpServer()).post(`/api/v1/admin/kyc/${submissionId}/decision`)
        .set('Authorization', `Bearer ${ops}`).set('X-CSRF-Token', 'synthetic').set('Idempotency-Key', randomUUID())
        .send({ decision: 'VERIFIED', reason: 'Synthetic reason', ...patch }).expect(400);
    }
  });
  it('rolls back decision/status/audit when notice persistence fails', async () => {
    await db.$executeRaw`ALTER TABLE kyc_notices ADD CONSTRAINT kyc_test_fail CHECK (status <> 'REJECTED') NOT VALID`;
    try { await decision().expect(503); }
    finally { await db.$executeRaw`ALTER TABLE kyc_notices DROP CONSTRAINT kyc_test_fail`; }
    expect((await get().expect(200)).body.status).toBe('MANUAL_REVIEW');
    expect((await db.vendors.findUniqueOrThrow({ where: { id: vendorId } })).kyc_status).toBe('MANUAL_REVIEW');
    expect(await db.audit_logs.count({ where: { entity_id: submissionId, action: 'KYC_REJECTED' } })).toBe(0);
  });
  it('TC-026 rejects once, saves immutable reason/reviewer/audit/notice and permits fresh resubmission', async () => {
    const key: string = randomUUID(); const responses = await Promise.all([decision(submissionId, 'REJECTED', key), decision(submissionId, 'REJECTED', key)]);
    expect(responses.map(r => r.status)).toEqual([201, 201]); expect(responses[0]!.body).toEqual(responses[1]!.body);
    await decision(submissionId, 'VERIFIED', key).expect(422); await decision().expect(409);
    expect((await get().expect(200)).body).toMatchObject({ status: 'REJECTED', reason: 'Synthetic review reason', providerChecks: 'NOT_RUN' });
    const notices = await get('/vendor/kyc/notices').expect(200); expect(notices.body).toHaveLength(1);
    await expect(db.vendor_kyc.update({ where: { id: submissionId }, data: { reason: 'Changed' } })).rejects.toThrow();
    const audit = await db.audit_logs.findFirstOrThrow({ where: { entity_id: submissionId, action: 'KYC_REJECTED' } });
    expect(audit.ip).toMatch(/127\.0\.0\.1/); expect(audit.before).toMatchObject({ status: 'MANUAL_REVIEW' });
    expect(audit.actor_id).toBe(responses[0]!.body.reviewerId); expect(audit.after).toMatchObject({ status: 'REJECTED', providerChecks: 'NOT_RUN' });
    submissionId = (await submit().expect(201)).body.id as string;
    expect(await db.vendor_kyc.count({ where: { vendor_id: vendorId } })).toBe(2);
  });
  it('TC-025 conflicting concurrent decisions commit only one decision and notification', async () => {
    const results = await Promise.all([decision(submissionId, 'REJECTED'), decision(submissionId, 'REJECTED', randomUUID(), superAdmin)]);
    expect(results.map(r => r.status).sort()).toEqual([201, 409]);
    const winner = results.find(r => r.status === 201)!;
    expect((await db.vendors.findUniqueOrThrow({ where: { id: vendorId } })).kyc_status).toBe(winner.body.status);
    expect(await db.kyc_notices.count({ where: { submission_id: submissionId } })).toBe(1);
    expect(await db.audit_logs.count({ where: { entity_id: submissionId, actor_type: 'ADMIN' } })).toBe(1);
  });
  it('TC-025 approval by SUPER_ADMIN persists VERIFIED with NOT_RUN and prevents further submission', async () => {
    submissionId = (await submit().expect(201)).body.id as string;
    await decision(submissionId, 'VERIFIED', randomUUID(), superAdmin).expect(201);
    expect((await get().expect(200)).body).toMatchObject({ status: 'VERIFIED', providerChecks: 'NOT_RUN', verificationMethod: 'MANUAL_REVIEW' });
    await submit().expect(409);
    const notices = await get('/vendor/kyc/notices').expect(200);
    expect(notices.body[0].status).toBe('VERIFIED');
    await get('/vendor/kyc', other).expect(409);
  });
  it('fails closed without encryption or outside dev/test; inactive accounts cannot replay', async () => {
    const config = app.get(ConfigService); const spy = jest.spyOn(config, 'get').mockImplementation((name: string) => name === 'FIELD_ENCRYPTION_KEY' ? undefined : process.env[name]);
    try { await submit().expect(503); } finally { spy.mockRestore(); }
    const mode = jest.spyOn(config, 'getOrThrow').mockImplementation((name: string) => name === 'NODE_ENV' ? 'production' : process.env[name]);
    try { await submit().expect(503); } finally { mode.mockRestore(); }
    await db.users.update({ where: { id: userId }, data: { status: 'BLOCKED' } });
    await get().expect(403); await submit().expect(403);
  });
});
