import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { NotificationsService } from './notifications.service';
import { FcmService } from './fcm.service';
import { NotificationEvent } from './notification-events';

const native = process.env.NOTIFICATIONS_TEST_DATABASE_URL ? describe : describe.skip;
native('T-032 TC-100–TC-102 native inbox/worker/session isolation (FCM mocked)', () => {
  const db = new PrismaService({ datasources: { db: { url: process.env.NOTIFICATIONS_TEST_DATABASE_URL } } });
  const env = { ...process.env };
  let app: INestApplication, peer: INestApplication, service: NotificationsService, worker: OutboxDispatcherService;
  let a: { id: string; token: string; sessionId: string; deviceId: string }, b: typeof a;
  const accounts: string[] = [];
  const send = jest.fn<Promise<'SENT' | 'UNREGISTERED'>, [string, unknown]>().mockResolvedValue('SENT');
  const allOff = { orders: false, payments: false, delivery: false, system: false };
  const allOn = { orders: true, payments: true, delivery: true, system: true };
  async function boot() {
    const { AppModule } = await import('../../app.module');
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() })
      .overrideProvider(FcmService).useValue({ send }).compile();
    const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
  }
  async function account(both = false) {
    const user = await db.users.create({ data: { mobile: `synthetic-${randomUUID()}`, active_role: both ? 'VENDOR' : 'CUSTOMER',
      roles: { create: both ? [{ role: 'VENDOR' }, { role: 'CUSTOMER' }] : [{ role: 'CUSTOMER' }] } } });
    accounts.push(user.id);
    const device = await db.devices.create({ data: { user_id: user.id, platform: 'ANDROID' } });
    const session = await db.sessions.create({ data: { user_id: user.id, device_id: device.id, family_id: randomUUID(),
      refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 86400000) } });
    return { id: user.id, deviceId: device.id, sessionId: session.id, token: app.get(SessionTokensService).issue(user.id, session.id, []) };
  }
  function get(path: string, token = a.token) { return request(app.getHttpServer()).get(`/api/v1${path}`).set('Authorization', `Bearer ${token}`); }
  function put(path: string, body: object, key = randomUUID(), token = a.token) {
    return request(app.getHttpServer()).put(`/api/v1${path}`).set('Authorization', `Bearer ${token}`).set('Idempotency-Key', key).send(body);
  }
  function read(body: object, key = randomUUID(), token = a.token) {
    return request(app.getHttpServer()).post('/api/v1/notifications/read').set('Authorization', `Bearer ${token}`).set('Idempotency-Key', key).send(body);
  }
  function emit(type: NotificationEvent['type'], overrides: Partial<NotificationEvent> = {}) {
    return db.$transaction(tx => service.enqueue(tx, { recipientId: a.id, role: 'VENDOR', type, sourceKey: `synthetic:${randomUUID()}`,
      entityId: randomUUID(), ...overrides }));
  }
  async function job(notificationId: string) { return db.notification_pushes.findFirstOrThrow({ where: { notification_id: notificationId } }); }
  async function dispatch(notificationId: string) { return worker.dispatchPendingBatch(1, (await job(notificationId)).event_id); }
  beforeAll(async () => {
    const url = new URL(process.env.NOTIFICATIONS_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test DB required');
    Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), FCM_ENABLED: 'false', OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '2000' });
    await db.$connect(); app = await boot(); peer = await boot();
    service = app.get(NotificationsService); worker = app.get(OutboxDispatcherService);
    a = await account(true); b = await account();
  });
  afterAll(async () => {
    await peer?.close(); await app?.close();
    const rows = await db.notifications.findMany({ where: { user_id: { in: accounts } }, select: { id: true } });
    await db.notifications.deleteMany({ where: { user_id: { in: accounts } } });
    await db.outbox_events.deleteMany({ where: { aggregate_type: 'NOTIFICATION', aggregate_id: { in: rows.map(r => r.id) } } });
    await db.idempotency_keys.deleteMany({ where: { user_id: { in: accounts } } });
    await db.user_preferences.deleteMany({ where: { user_id: { in: accounts } } });
    await db.sessions.deleteMany({ where: { user_id: { in: accounts } } });
    await db.devices.deleteMany({ where: { user_id: { in: accounts } } });
    await db.users.deleteMany({ where: { id: { in: accounts } } }); await db.$disconnect();
    for (const name of Object.keys(process.env)) if (!(name in env)) delete process.env[name]; Object.assign(process.env, env);
  });
  beforeEach(() => send.mockReset().mockResolvedValue('SENT'));
  it('TC-100 inbox role/category/pagination never leaks another owner or unsupported role', async () => {
    await emit('ORDER_NEW'); await emit('DELIVERY_UPDATE'); await emit('SECURITY');
    await emit('PAYMENT_RECORDED', { role: 'CUSTOMER' });
    const response = await get('/notifications?role=VENDOR&category=ORDERS&limit=1').expect(200);
    expect(response.body.items).toHaveLength(1); expect(response.body.items[0]).toMatchObject({ category: 'ORDERS', readAt: null, role: 'VENDOR' });
    expect(response.body.unreadCount).toBe(3); expect(response.body.total).toBe(1);
    expect((await get('/notifications?role=CUSTOMER').expect(200)).body.items).toHaveLength(1);
    expect((await get('/notifications', b.token).expect(200)).body.total).toBe(0);
    await get('/notifications?role=VENDOR', b.token).expect(403); await get('/notifications?role=CUSTOMER&category=DELIVERY').expect(400);
    await get('/notifications', '').expect(401); await get('/notifications?limit=101').expect(400);
  });
  it('TC-101 read/clear are owner/role scoped, durable and concurrent-replay safe', async () => {
    const id = (await emit('KYC_STATUS'))!; const key = randomUUID();
    const responses = await Promise.all([read({ ids: [id] }, key), read({ ids: [id] }, key)]);
    expect(responses.map(r => r.status)).toEqual([200,200]); expect(responses[0]!.body).toEqual({ changed: 1 });
    expect(responses[1]!.body).toEqual(responses[0]!.body);
    await read({ ids: [id] }, randomUUID(), b.token).expect(404); await read({ ids: [id], role: 'CUSTOMER' }).expect(404);
    await read({ ids: [id], all: true }).expect(400); await read({ all: false }).expect(400); await read({ ids: [] }).expect(400);
    await read({ all: true }, key).expect(422); await read({ all: true }).expect(200);
    const clearKey = randomUUID();
    const clear = () => request(app.getHttpServer()).delete('/api/v1/notifications?role=VENDOR')
      .set('Authorization', `Bearer ${a.token}`).set('Idempotency-Key', clearKey);
    const first = await clear().expect(200); expect(first.body.changed).toBeGreaterThan(0);
    expect((await clear().expect(200)).body).toEqual(first.body);
    expect((await get('/notifications?role=VENDOR').expect(200)).body.total).toBe(0);
    expect((await get('/notifications?role=CUSTOMER').expect(200)).body.total).toBe(1);
    expect((await db.notifications.findUniqueOrThrow({ where: { id } })).cleared_at).not.toBeNull();
  });
  it('current-device binding hides tokens, prevents foreign claims, and stale retry cannot restore a rotated token', async () => {
    const token1 = `synthetic-device-${randomUUID()}`, token2 = `synthetic-device-${randomUUID()}`, key = randomUUID();
    const saved = await put('/me/devices/current', { pushToken: token1, pushEnabled: true }, key).expect(200);
    expect(saved.body).toEqual({ deviceId: a.deviceId, pushEnabled: true }); expect(JSON.stringify(saved.body)).not.toContain(token1);
    await put('/me/devices/current', { pushToken: token1, pushEnabled: true }, randomUUID(), b.token).expect(409);
    await put('/me/devices/current', { pushToken: token1, pushEnabled: true, deviceId: b.deviceId }).expect(400);
    await put('/me/devices/current', { pushEnabled: false }).expect(200);
    expect((await db.devices.findUniqueOrThrow({ where: { id: a.deviceId } })).push_token).toBeNull();
    await put('/me/devices/current', { pushToken: null, pushEnabled: true }).expect(400);
    await put('/me/devices/current', { pushToken: token2, pushEnabled: true }).expect(200);
    await put('/me/devices/current', { pushToken: token1, pushEnabled: true }, key).expect(200);
    expect((await db.devices.findUniqueOrThrow({ where: { id: a.deviceId } })).push_token).toBe(token2);
  });
  it('TC-102 optional category off suppresses push while KYC bypasses preferences and inbox remains', async () => {
    await put('/me/notification-prefs', allOff).expect(200);
    await put('/me/notification-prefs', { ...allOff, kyc: false }).expect(400);
    const optional = (await emit('ORDER_NEW'))!, mandatory = (await emit('KYC_STATUS'))!;
    await dispatch(optional); expect((await job(optional)).status).toBe('SKIPPED'); expect(send).not.toHaveBeenCalled();
    await dispatch(mandatory); expect((await job(mandatory)).status).toBe('SENT'); expect(send).toHaveBeenCalledTimes(1);
    expect(send.mock.calls[0]![1]).toMatchObject({ title: 'KYC status updated', path: '/vendor/onboarding/status' });
    expect((await get('/notifications?category=ORDERS').expect(200)).body.items).toHaveLength(1);
    expect((await get('/me/notification-prefs').expect(200)).body).toEqual(allOff);
    const key = randomUUID();
    await put('/me/notification-prefs', allOn, key).expect(200);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'CUSTOMER' } });
    await put('/me/notification-prefs', allOn, key).expect(200);
    await db.users.update({ where: { id: a.id }, data: { active_role: 'VENDOR' } });
  });
  it('producer concurrent dedupe and rollback keep inbox/outbox/device jobs atomic', async () => {
    const sourceKey = `synthetic:${randomUUID()}`;
    const emitFrom = (instance: INestApplication) => db.$transaction(tx => instance.get(NotificationsService).enqueue(tx,
      { recipientId: a.id, role: 'VENDOR', type: 'KYC_STATUS', sourceKey }));
    const ids = await Promise.all([emitFrom(app), emitFrom(peer)]); expect(ids[0]).toBe(ids[1]);
    expect(await db.notification_pushes.count({ where: { notification_id: ids[0]! } })).toBe(1);
    const rolledBack = `synthetic:${randomUUID()}`;
    await expect(db.$transaction(async tx => {
      await service.enqueue(tx, { recipientId: a.id, role: 'VENDOR', type: 'KYC_STATUS', sourceKey: rolledBack }); throw new Error('Synthetic rollback');
    })).rejects.toThrow('Synthetic rollback');
    expect(await db.notifications.count({ where: { source_key: rolledBack } })).toBe(0);
  });
  it('two worker instances claim a target once and do not consume unrelated queued events', async () => {
    const id = (await emit('KYC_STATUS'))!, event = (await job(id)).event_id;
    const other = (await emit('KYC_STATUS'))!, otherJob = await job(other);
    const result = await Promise.all([worker.dispatchPendingBatch(1, event), peer.get(OutboxDispatcherService).dispatchPendingBatch(1, event)]);
    expect(result.reduce((sum, n) => sum + n, 0)).toBe(1); expect(send).toHaveBeenCalledTimes(1);
    expect((await db.outbox_events.findUniqueOrThrow({ where: { id: otherJob.event_id } })).attempt_count).toBe(0);
    await expect(worker.dispatchPendingBatch(1, 'bad')).rejects.toThrow('Invalid event ID');
  });
  it('transient/unavailable provider leaves inbox durable and retries with no false SENT state', async () => {
    const id = (await emit('KYC_STATUS'))!, event = (await job(id)).event_id;
    send.mockRejectedValueOnce(new Error('synthetic-provider-unavailable'));
    expect(await dispatch(id)).toBe(0); expect((await job(id)).status).toBe('PENDING');
    expect((await db.outbox_events.findUniqueOrThrow({ where: { id: event } })).status).toBe('PENDING');
    await db.outbox_events.update({ where: { id: event }, data: { available_at: new Date(Date.now() - 1000) } });
    expect(await dispatch(id)).toBe(1); expect((await job(id)).status).toBe('SENT');
  });
  it('token rotation or disabling permission skips queued pushes; UNREGISTERED removes stale tokens', async () => {
    const old = (await emit('KYC_STATUS'))!;
    await put('/me/devices/current', { pushToken: `synthetic-new-${randomUUID()}`, pushEnabled: true }).expect(200);
    await dispatch(old); expect((await job(old)).status).toBe('SKIPPED'); expect(send).not.toHaveBeenCalled();
    const invalid = (await emit('KYC_STATUS'))!; send.mockResolvedValueOnce('UNREGISTERED');
    await dispatch(invalid); expect((await job(invalid)).status).toBe('INVALID');
    expect((await db.devices.findUniqueOrThrow({ where: { id: a.deviceId } })).push_token).toBeNull();
    await put('/me/devices/current', { pushToken: `synthetic-again-${randomUUID()}`, pushEnabled: true }).expect(200);
    const disabled = (await emit('KYC_STATUS'))!;
    await put('/me/devices/current', { pushToken: null, pushEnabled: false }).expect(200);
    await dispatch(disabled); expect((await job(disabled)).status).toBe('SKIPPED');
    await put('/me/devices/current', { pushToken: `synthetic-final-${randomUUID()}`, pushEnabled: true }).expect(200);
  });
  it('an in-flight UNREGISTERED response cannot erase a concurrently rotated token', async () => {
    const id = (await emit('KYC_STATUS'))!;
    let start!: () => void, finish!: () => void;
    const started = new Promise<void>(resolve => { start = resolve; });
    const released = new Promise<void>(resolve => { finish = resolve; });
    send.mockImplementationOnce(async () => { start(); await released; return 'UNREGISTERED'; });
    const running = dispatch(id);
    await started;
    const token = `synthetic-rotated-${randomUUID()}`;
    try { await put('/me/devices/current', { pushToken: token, pushEnabled: true }).expect(200); }
    finally { finish(); await running; }
    expect((await db.devices.findUniqueOrThrow({ where: { id: a.deviceId } })).push_token).toBe(token);
    expect((await job(id)).status).toBe('INVALID');
  });
  it('90-day expiry is hidden immediately, pruned in a bounded worker batch, and clear suppresses late push', async () => {
    const expired = (await emit('KYC_STATUS'))!;
    await db.notifications.update({ where: { id: expired }, data: { created_at: new Date(Date.now() - 91 * 86400000) } });
    expect((await get('/notifications').expect(200)).body.items.map((n: { id: string }) => n.id)).not.toContain(expired);
    await dispatch(expired); expect((await job(expired)).status).toBe('SKIPPED');
    await service.cleanupExpired(); expect(await db.notifications.findUnique({ where: { id: expired } })).toBeNull();
    const clear = (await emit('KYC_STATUS'))!; await db.notifications.update({ where: { id: clear }, data: { cleared_at: new Date() } });
    await dispatch(clear); expect((await job(clear)).status).toBe('SKIPPED'); expect(send).not.toHaveBeenCalled();
  });
  it('revoked sessions and blocked accounts suppress pushes even while a token remains registered', async () => {
    const revoked = (await emit('KYC_STATUS'))!;
    await db.sessions.update({ where: { id: a.sessionId }, data: { status: 'REVOKED' } });
    await dispatch(revoked); expect((await job(revoked)).status).toBe('SKIPPED');
    await db.sessions.update({ where: { id: a.sessionId }, data: { status: 'ACTIVE' } });
    const blocked = (await emit('KYC_STATUS'))!;
    await db.users.update({ where: { id: a.id }, data: { status: 'BLOCKED' } });
    await get('/notifications').expect(403);
    await dispatch(blocked); expect((await job(blocked)).status).toBe('SKIPPED');
    await db.users.update({ where: { id: a.id }, data: { status: 'ACTIVE' } });
    expect(send).not.toHaveBeenCalled();
  });
  it('logout all clears every owned device token while preserving another account', async () => {
    const c = await account();
    await put('/me/devices/current', { pushToken: `synthetic-c-${randomUUID()}`, pushEnabled: true }, randomUUID(), c.token).expect(200);
    const extra = await db.devices.create({ data: { user_id: c.id, platform: 'ANDROID', push_token: `synthetic-c2-${randomUUID()}` } });
    await db.sessions.create({ data: { user_id: c.id, device_id: extra.id, family_id: randomUUID(), refresh_token_hash: randomUUID(), expires_at: new Date(Date.now() + 86400000) } });
    const otherToken = `synthetic-other-${randomUUID()}`;
    await put('/me/devices/current', { pushToken: otherToken, pushEnabled: true }, randomUUID(), b.token).expect(200);
    await request(app.getHttpServer()).post('/api/v1/auth/logout?all=true').set('Authorization', `Bearer ${c.token}`).set('Idempotency-Key', randomUUID()).expect(204);
    expect((await db.devices.findMany({ where: { user_id: c.id } })).every(d => d.push_token === null && !d.push_enabled)).toBe(true);
    expect((await db.devices.findUniqueOrThrow({ where: { id: b.deviceId } })).push_token).toBe(otherToken);
  });
  it('logout unregisters tokens and queued delivery requires an active owned session', async () => {
    const id = (await emit('KYC_STATUS'))!, inflight = (await emit('KYC_STATUS'))!;
    let start!: () => void, finish!: () => void;
    const started = new Promise<void>(resolve => { start = resolve; });
    const released = new Promise<void>(resolve => { finish = resolve; });
    send.mockImplementationOnce(async () => { start(); await released; return 'SENT'; });
    const running = dispatch(inflight); await started;
    try { await request(app.getHttpServer()).post('/api/v1/auth/logout').set('Authorization', `Bearer ${a.token}`).set('Idempotency-Key', randomUUID()).expect(204); }
    finally { finish(); await running; } // This attempt began before logout.
    const device = await db.devices.findUniqueOrThrow({ where: { id: a.deviceId } });
    expect(device.push_token).toBeNull(); expect(device.push_enabled).toBe(false);
    await dispatch(id); expect((await job(id)).status).toBe('SKIPPED'); expect(send).toHaveBeenCalledTimes(1);
    await get('/notifications').expect(401);
  });
});
