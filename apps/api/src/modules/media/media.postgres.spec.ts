import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'node:crypto';
import { chmod, lstat, mkdir, mkdtemp, readdir, readFile, rename, rm, symlink, unlink, utimes, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import request from 'supertest';
import sharp from 'sharp';
import { PDFDocument } from 'pdf-lib';
import { configureHttpApp } from '../../bootstrap';
import { PrismaService } from '../../prisma/prisma.service';
import { PinoLogger } from '../../common/logging/pino.logger';
import { SessionTokensService } from '../auth/session-tokens.service';
import { MediaService } from './media.service';

const native = process.env.MEDIA_TEST_DATABASE_URL ? describe : describe.skip;
native('T-020 TC-503 private media HTTP → native PostgreSQL/files', () => {
  let app: INestApplication, root: string, owner: string, other: string, token: string, otherToken: string;
  let png: Buffer, pdf: Buffer;
  const admins: string[] = [], users: string[] = [];
  const envBefore = { ...process.env };
  const prisma = new PrismaService({ datasources: { db: { url: process.env.MEDIA_TEST_DATABASE_URL } } });
  const digest = (s: string) => createHash('sha256').update(s).digest('hex');
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
    app = module.createNestApplication(); configureHttpApp(app); await app.init();
  }
  async function account() {
    const user = await prisma.users.create({ data: { mobile: `test-${randomUUID()}` } });
    users.push(user.id);
    const session = await prisma.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
      refresh_token_hash: digest(randomUUID()), expires_at: new Date(Date.now() + 86400000) } });
    return { id: user.id, sessionId: session.id };
  }
  async function admin(role: string) {
    const user = await prisma.admin_users.create({ data: { email: `${randomUUID()}@example.invalid`, password_hash: 'synthetic-disabled', role } });
    admins.push(user.id);
    const access = randomUUID();
    await prisma.admin_sessions.create({ data: { admin_id: user.id, token_hash: digest(access), csrf_hash: digest('synthetic'),
      expires_at: new Date(Date.now() + 86400000) } });
    return { id: user.id, token: access };
  }
  function upload(data = png, purpose = 'PROFILE', key = randomUUID(), access = token, name = 'safe.png', mime = 'image/png') {
    return request(app.getHttpServer()).post('/api/v1/media').set('Authorization', `Bearer ${access}`)
      .set('Idempotency-Key', key).field('purpose', purpose).attach('file', data, { filename: name, contentType: mime });
  }
  function content(id: string, access = token, adminRoute = false) {
    return request(app.getHttpServer()).get(`/api/v1/${adminRoute ? 'admin/' : ''}media/${id}/content`)
      .set('Authorization', `Bearer ${access}`);
  }
  beforeAll(async () => {
    const url = new URL(process.env.MEDIA_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith('_test')) throw new Error('Use a dedicated _test database');
    const base = join(homedir(), '.local/share/supplybiz/test-uploads');
    await mkdir(base, { recursive: true, mode: 0o700 }); root = await mkdtemp(join(base, 'media-'));
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), UPLOAD_ROOT: root,
      RATE_LIMIT_MAX_REQUESTS: '1000', UPLOAD_MAX_PIXELS: '100' });
    await prisma.$connect(); await boot();
    const a = await account(), b = await account(); owner = a.id; other = b.id;
    token = app.get(SessionTokensService).issue(owner, a.sessionId, []);
    otherToken = app.get(SessionTokensService).issue(other, b.sessionId, []);
    png = await sharp({ create: { width: 2, height: 2, channels: 3, background: '#ffffff' } }).png().toBuffer();
    const document = await PDFDocument.create(); document.addPage(); pdf = Buffer.from(await document.save());
  });
  afterAll(async () => {
    await app?.close();
    // Test-owner-only cleanup in the explicitly isolated _test database; DDL rolls back on failure.
    await prisma.$transaction(async tx => {
      await tx.$executeRaw`ALTER TABLE media_access_events DISABLE TRIGGER media_access_events_immutable`;
      await tx.media_access_events.deleteMany({ where: { admin_user_id: { in: admins } } });
      await tx.$executeRaw`ALTER TABLE media_access_events ENABLE TRIGGER media_access_events_immutable`;
    });
    await prisma.media_files.deleteMany({ where: { owner_user_id: { in: users } } });
    await prisma.sessions.deleteMany({ where: { user_id: { in: users } } });
    await prisma.users.deleteMany({ where: { id: { in: users } } });
    await prisma.admin_sessions.deleteMany({ where: { admin_id: { in: admins } } });
    await prisma.admin_users.deleteMany({ where: { id: { in: admins } } });
    await prisma.$disconnect(); if (root) await rm(root, { recursive: true, force: true });
    for (const key of Object.keys(process.env)) if (!(key in envBefore)) delete process.env[key];
    Object.assign(process.env, envBefore);
  });
  afterEach(async () => { expect(await readdir(join(root, 'staging'))).toEqual([]); });

  it('persists opaque READY metadata, strips EXIF, enforces permissions and serves exact bytes', async () => {
    const jpeg = await sharp(png).jpeg().withMetadata({ exif: { IFD0: { Artist: 'Synthetic fixture' } } }).toBuffer();
    const response = await upload(jpeg, 'SHOP_PHOTO', randomUUID(), token, 'shop.jpg', 'image/jpeg').expect(201);
    expect(Object.keys(response.body).sort()).toEqual(['mediaId', 'status']);
    const row = await prisma.media_files.findUniqueOrThrow({ where: { id: response.body.mediaId as string } });
    const stored = await readFile(join(root, row.relative_storage_key));
    expect((await sharp(stored).metadata()).exif).toBeUndefined();
    expect((await lstat(join(root, row.relative_storage_key))).mode & 0o777).toBe(0o600);
    expect(row.sha256).toBe(createHash('sha256').update(stored).digest('hex'));
    expect(await app.get(MediaService).requireOwnedReady(row.id, owner, 'SHOP_PHOTO')).toBe(row.id);
    await expect(app.get(MediaService).requireOwnedReady(row.id, other, 'SHOP_PHOTO')).rejects.toThrow();
    const read = await content(row.id).expect(200).expect('Cache-Control', 'no-store').expect('X-Content-Type-Options', 'nosniff');
    expect(read.body).toEqual(stored);
    await content(row.id, otherToken).expect(404);
    await content(row.id, '').expect(401);
  });
  it('serializes concurrent duplicate uploads, persists retry across API restart, scopes keys to owner', async () => {
    const key = randomUUID();
    const responses = await Promise.all([upload(png, 'PROFILE', key), upload(png, 'PROFILE', key)]);
    expect(responses.map(r => r.status)).toEqual([201, 201]);
    expect(responses[0]!.body).toEqual(responses[1]!.body);
    expect(await prisma.media_files.count({ where: { owner_user_id: owner, request_key: digest(key) } })).toBe(1);
    const sessions = await prisma.sessions.findMany({ where: { user_id: { in: users } } });
    await app.close(); await boot();
    token = app.get(SessionTokensService).issue(owner, sessions.find(s => s.user_id === owner)!.id, []);
    otherToken = app.get(SessionTokensService).issue(other, sessions.find(s => s.user_id === other)!.id, []);
    expect((await upload(png, 'PROFILE', key).expect(201)).body).toEqual(responses[0]!.body);
    await upload(png, 'PRODUCT_IMAGE', key).expect(422);
    expect((await upload(png, 'PROFILE', key, otherToken).expect(201)).body.mediaId).not.toBe(responses[0]!.body.mediaId);
  });
  it('validates purpose, forged MIME, malformed files, PDF purpose and pixel/byte limits without leftovers', async () => {
    const before = await prisma.media_files.count();
    await upload(png, 'UNKNOWN').expect(400);
    await upload(Buffer.from('not an image')).expect(400);
    await upload(png, 'PROFILE', randomUUID(), token, 'fake.jpg', 'image/jpeg').expect(400);
    await upload(Buffer.from('<svg/>'), 'PROFILE', randomUUID(), token, 'x.svg', 'image/svg+xml').expect(400);
    await upload(pdf, 'PROFILE', randomUUID(), token, 'x.pdf', 'application/pdf').expect(400);
    await upload(Buffer.from('%PDF-broken'), 'KYC_DOC', randomUUID(), token, 'x.pdf', 'application/pdf').expect(400);
    const large = await sharp({ create: { width: 11, height: 10, channels: 3, background: '#fff' } }).png().toBuffer();
    await upload(large).expect(400);
    await upload(Buffer.alloc(5242881)).expect(413);
    expect(await prisma.media_files.count()).toBe(before);
  });
  it('accepts exactly the configured byte limit and rejects one byte over', async () => {
    const exact = Buffer.concat([pdf, Buffer.alloc(5242880 - pdf.length, 32)]);
    await upload(exact, 'SHOP_PHOTO', randomUUID(), token, 'safe.pdf', 'application/pdf').expect(201);
    await upload(Buffer.concat([exact, Buffer.from(' ')]), 'SHOP_PHOTO', randomUUID(), token, 'safe.pdf', 'application/pdf').expect(413);
  });
  it('requires authentication/key and denies extra multipart fields/path names', async () => {
    await upload(png, 'PROFILE', randomUUID(), '').expect(401);
    await request(app.getHttpServer()).post('/api/v1/media').set('Authorization', `Bearer ${token}`).expect(400);
    await request(app.getHttpServer()).post('/api/v1/media').set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', randomUUID()).field('purpose', 'PROFILE').field('owner', other).attach('file', png, 'safe.png').expect(400);
    await upload(png, 'PROFILE', randomUUID(), token, 'bad..png').expect(400);
    await request(app.getHttpServer()).post('/api/v1/media').set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', randomUUID()).send({ purpose: 'PROFILE' }).expect(400);
  });
  it('rejects a truncated multipart stream and removes its partial staging file', async () => {
    await request(app.getHttpServer()).post('/api/v1/media').set('Authorization', `Bearer ${token}`)
      .set('Idempotency-Key', randomUUID()).set('Content-Type', 'multipart/form-data; boundary=broken')
      .send('--broken\r\nContent-Disposition: form-data; name="purpose"\r\n\r\nPROFILE\r\n--broken\r\nContent-Disposition: form-data; name="file"; filename="safe.png"\r\nContent-Type: image/png\r\n\r\npartial').expect(400);
  });
  it('serves PDF only as attachment; denies SUPPORT/FINANCE and audits each OPS document read', async () => {
    const id = (await upload(pdf, 'KYC_DOC', randomUUID(), token, 'safe.pdf', 'application/pdf').expect(201)).body.mediaId as string;
    await content(id, otherToken).expect(404);
    const ops = await admin('OPS');
    await content(id, ops.token, true).expect(200).expect('Content-Type', 'application/pdf')
      .expect('Content-Disposition', `attachment; filename="${id}.pdf"`);
    expect(await prisma.media_access_events.count({ where: { media_id: id, admin_user_id: ops.id } })).toBe(1);
    await expect(prisma.media_access_events.updateMany({ where: { media_id: id }, data: { action: 'FORGED' } })).rejects.toThrow();
    await expect(prisma.media_access_events.deleteMany({ where: { media_id: id } })).rejects.toThrow();
    for (const role of ['SUPPORT', 'FINANCE']) await content(id, (await admin(role)).token, true).expect(403);
    const profile = (await upload().expect(201)).body.mediaId as string;
    await content(profile, ops.token, true).expect(404);
  });
  it('compensates a failed metadata transaction and denies symlink file/directory substitution', async () => {
    const before = await readdir(join(root, 'media'));
    await prisma.$executeRaw`ALTER TABLE media_files ADD CONSTRAINT media_test_reject CHECK (purpose <> 'PROFILE') NOT VALID`;
    try { await upload().expect(503); }
    finally { await prisma.$executeRaw`ALTER TABLE media_files DROP CONSTRAINT media_test_reject`; }
    expect(await readdir(join(root, 'media'))).toEqual(before);
    const id = (await upload().expect(201)).body.mediaId as string;
    const row = await prisma.media_files.findUniqueOrThrow({ where: { id } });
    const path = join(root, row.relative_storage_key), saved = await readFile(path);
    await unlink(path); await symlink(join(root, 'not-a-file'), path);
    await content(id).expect(404); await unlink(path); await writeFile(path, saved, { mode: 0o600 });
    await chmod(path, 0o644); await content(id).expect(404); await chmod(path, 0o600);
    const directory = join(root, 'media'), savedDirectory = join(root, 'saved-media');
    await rename(directory, savedDirectory); await symlink(join(root, 'staging'), directory);
    try { await content(id).expect(503); }
    finally { await unlink(directory); await rename(savedDirectory, directory); }
  });
  it('cleans only old staging/orphans, preserves READY referenced files', async () => {
    const id = (await upload().expect(201)).body.mediaId as string;
    const row = await prisma.media_files.findUniqueOrThrow({ where: { id } });
    const active = join(root, row.relative_storage_key);
    const stale = join(root, 'media', `${randomUUID()}.png`), staged = join(root, 'staging', randomUUID());
    await writeFile(stale, png); await writeFile(staged, png);
    for (const path of [stale, staged, active]) await utimes(path, new Date(0), new Date(0));
    await app.get(MediaService).cleanupStale();
    await expect(lstat(stale)).rejects.toMatchObject({ code: 'ENOENT' });
    await expect(lstat(staged)).rejects.toMatchObject({ code: 'ENOENT' });
    expect((await lstat(active)).isFile()).toBe(true);
    // Configured byte boundary itself is admitted, then format validation decides validity.
    expect(app.get(ConfigService).get('UPLOAD_MAX_BYTES')).toBe(5242880);
  });
});
