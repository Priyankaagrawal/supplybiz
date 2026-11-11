import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, OnModuleInit, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { notifications, Prisma, user_role_type } from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import { z } from 'zod';
import { PrismaService } from '../../prisma/prisma.service';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { DevicePushInput, InboxQuery, NotificationPreferences, ReadNotifications } from './notifications.dto';
import { FcmService } from './fcm.service';
import { eventTemplates, mandatoryNotification, NotificationEvent } from './notification-events';

type Tx = Prisma.TransactionClient;
const digest = (value: string) => createHash('sha256').update(value).digest('hex');
const cutoff = () => new Date(Date.now() - 90 * 86400000);
const prefsSchema = z.object({ orders: z.boolean(), payments: z.boolean(), delivery: z.boolean(), system: z.boolean() });
const defaults: NotificationPreferences = { orders: true, payments: true, delivery: true, system: true };
@Injectable()
export class NotificationsService implements OnModuleInit {
  constructor(private readonly db: PrismaService, private readonly keys: IdempotencyService,
    private readonly dispatcher: OutboxDispatcherService, private readonly fcm: FcmService) {}
  onModuleInit() {
    this.dispatcher.register('NOTIFICATION_PUSH', (event, tx) => this.deliver(tx, event.payload));
  }
  private async actor(tx: Tx, userId: string, role?: user_role_type) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE') throw new ForbiddenException({ code: 'ACCOUNT_UNAVAILABLE' });
    const selected = role ?? user.active_role;
    if (!user.roles.some(r => r.role === selected)) throw new ForbiddenException({ code: 'ROLE_NOT_HELD' });
    return selected;
  }
  async list(userId: string, query: InboxQuery) {
    return this.db.$transaction(async tx => {
      const role = await this.actor(tx, userId, query.role);
      if (role === 'CUSTOMER' && query.category === 'DELIVERY') throw new BadRequestException({ code: 'NOTIFICATION_CATEGORY_INVALID' });
      const scope = { user_id: userId, role, cleared_at: null, created_at: { gt: cutoff() } };
      const where = { ...scope, ...(query.category && query.category !== 'ALL' ? { category: query.category } : {}) };
      const [rows, total, unreadCount] = await Promise.all([
        tx.notifications.findMany({ where, orderBy: [{ created_at: 'desc' }, { id: 'desc' }], take: query.limit ?? 50, skip: query.offset ?? 0 }),
        tx.notifications.count({ where }), tx.notifications.count({ where: { ...scope, read_at: null } }),
      ]);
      return { items: rows.map(row => this.present(row)), total, unreadCount };
    }, { isolationLevel: 'RepeatableRead' });
  }
  async preferences(userId: string) { await this.actor(this.db, userId); return this.readPreferences(this.db, userId); }
  private async readPreferences(tx: Tx, userId: string): Promise<NotificationPreferences> {
    const row = await tx.user_preferences.findUnique({ where: { user_id: userId } });
    if (!row) return { ...defaults };
    const parsed = prefsSchema.safeParse(row.notification_prefs);
    if (!parsed.success) throw new ServiceUnavailableException({ code: 'NOTIFICATION_PREFS_UNAVAILABLE' });
    return parsed.data;
  }
  savePreferences(userId: string, key: string, input: NotificationPreferences) {
    return this.mutate(userId, key, 'PUT', 'preferences', input, async tx => {
      await tx.user_preferences.upsert({ where: { user_id: userId }, create: { user_id: userId, notification_prefs: { ...input } },
        update: { notification_prefs: { ...input } } });
      return { ...input };
    });
  }
  read(userId: string, key: string, input: ReadNotifications) {
    return this.mutate(userId, key, 'POST', 'read', input, async (tx, role) => {
      if ((input.all === true) === (input.ids !== undefined) || input.all === false || input.ids?.length === 0) {
        throw new BadRequestException({ code: 'NOTIFICATION_SELECTION_INVALID' });
      }
      const where = { user_id: userId, role, cleared_at: null, created_at: { gt: cutoff() }, ...(input.ids ? { id: { in: input.ids } } : {}) };
      if (input.ids && await tx.notifications.count({ where }) !== input.ids.length) throw new NotFoundException({ code: 'NOTIFICATION_NOT_FOUND' });
      const result = await tx.notifications.updateMany({ where: { ...where, read_at: null }, data: { read_at: new Date() } });
      return { changed: result.count };
    }, input.role);
  }
  clear(userId: string, key: string, role?: user_role_type) {
    return this.mutate(userId, key, 'DELETE', 'clear', { role }, async (tx, selected) => {
      const result = await tx.notifications.updateMany({ where: { user_id: userId, role: selected, cleared_at: null,
        created_at: { gt: cutoff() } }, data: { cleared_at: new Date() } });
      return { changed: result.count };
    }, role);
  }
  registerDevice(userId: string, sessionId: string, key: string, input: DevicePushInput) {
    return this.mutate(userId, key, 'PUT', `device:${sessionId}`, input, async tx => {
      const session = await tx.sessions.findFirst({ where: { id: sessionId, user_id: userId, status: 'ACTIVE', expires_at: { gt: new Date() } } });
      const device = session?.device_id ? await tx.devices.findFirst({ where: { id: session.device_id, user_id: userId } }) : null;
      if (!device || device.platform !== 'ANDROID') throw new ConflictException({ code: 'CURRENT_ANDROID_DEVICE_REQUIRED' });
      if (input.pushEnabled && !input.pushToken) throw new BadRequestException({ code: 'PUSH_TOKEN_REQUIRED' });
      if (input.pushToken) {
        await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`push-token:${digest(input.pushToken)}`}, 0))::text`;
        const previous = await tx.devices.findUnique({ where: { push_token: input.pushToken } });
        if (previous && previous.user_id !== userId) throw new ConflictException({ code: 'DEVICE_TOKEN_IN_USE' });
        if (previous && previous.id !== device.id) await tx.devices.update({ where: { id: previous.id }, data: { push_token: null, push_enabled: false } });
      }
      const updated = await tx.devices.update({ where: { id: device.id }, data: { push_token: input.pushToken ?? null,
        push_enabled: input.pushEnabled, app_version: input.appVersion, os_version: input.osVersion, last_seen_at: new Date() } });
      return { deviceId: updated.id, pushEnabled: updated.push_enabled };
    });
  }
  /** Called by authorized domain services in THEIR transaction; no public producer. */
  async enqueue(tx: Tx, event: NotificationEvent): Promise<string | null> {
    const template = eventTemplates[event.type];
    if (!template || !/^[a-zA-Z0-9:_.-]{1,120}$/.test(event.sourceKey) ||
      (template[0] !== null && template[0] !== event.role) ||
      (template[3].endsWith('/') && !z.string().uuid().safeParse(event.entityId).success)) throw new BadRequestException({ code: 'NOTIFICATION_EVENT_INVALID' });
    const user = await tx.users.findUnique({ where: { id: event.recipientId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || !user.roles.some(r => r.role === event.role)) return null;
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`notification:${event.sourceKey}`}, 0))::text`;
    const path = `${template[3]}${template[3].endsWith('/') ? event.entityId : ''}`;
    const existing = await tx.notifications.findUnique({ where: { source_key: event.sourceKey } });
    if (existing) {
      if (existing.user_id !== event.recipientId || existing.role !== event.role || existing.type !== event.type || this.path(existing) !== path) throw new ConflictException({ code: 'NOTIFICATION_SOURCE_MISMATCH' });
      return existing.id;
    }
    const row = await tx.notifications.create({ data: { user_id: event.recipientId, role: event.role, type: event.type,
      category: template[1], source_key: event.sourceKey, title: template[2], mandatory: mandatoryNotification(event.type),
      body: event.type === 'KYC_STATUS' ? 'Open Supply Biz to view your verification decision.' : 'Open Supply Biz to view the details.', data: { path } } });
    const devices = await tx.devices.findMany({ where: { user_id: event.recipientId, platform: 'ANDROID', push_enabled: true, push_token: { not: null } } });
    for (const device of devices) {
      const id = randomUUID();
      const job = await tx.outbox_events.create({ data: { aggregate_type: 'NOTIFICATION', aggregate_id: row.id, event_type: 'NOTIFICATION_PUSH', payload: { deliveryId: id } } });
      await tx.notification_pushes.create({ data: { id, notification_id: row.id, device_id: device.id, token_hash: digest(device.push_token!), event_id: job.id } });
    }
    return row.id;
  }
  private async deliver(tx: Tx, payload: Prisma.JsonValue): Promise<Prisma.InputJsonObject> {
    const input = z.object({ deliveryId: z.string().uuid() }).strict().parse(payload);
    const delivery = await tx.notification_pushes.findUnique({ where: { id: input.deliveryId }, include: { notification: true, device: true } });
    if (!delivery || delivery.status !== 'PENDING') return { skipped: 1 };
    const n = delivery.notification;
    // Recheck current ownership/session/prefs immediately before attempting delivery.
    // Never hold the auth/user lock across external HTTP: logout must remain available.
    // An already in-flight/accepted generic push cannot be recalled.
    const device = await tx.devices.findUnique({ where: { id: delivery.device_id } });
    const user = await tx.users.findUnique({ where: { id: n.user_id }, include: { roles: true } });
    const active = device && await tx.sessions.count({ where: { user_id: n.user_id, device_id: device.id, status: 'ACTIVE', expires_at: { gt: new Date() } } });
    const current = await tx.notifications.findUnique({ where: { id: n.id } });
    const allowed = n.mandatory || (await this.readPreferences(tx, n.user_id))[n.category.toLowerCase() as keyof NotificationPreferences];
    if (!device?.push_enabled || !device.push_token || device.user_id !== n.user_id || digest(device.push_token) !== delivery.token_hash ||
      !active || user?.status !== 'ACTIVE' || !user.roles.some(r => r.role === n.role) || !allowed || !current || current.cleared_at || current.created_at <= cutoff()) {
      await tx.notification_pushes.update({ where: { id: delivery.id }, data: { status: 'SKIPPED' } }); return { skipped: 1 };
    }
    const result = await this.fcm.send(device.push_token, { id: n.id, role: n.role, type: n.type, title: n.title, body: n.body, path: this.path(n) });
    if (result === 'UNREGISTERED') await tx.devices.updateMany({ where: { id: device.id, user_id: n.user_id, push_token: device.push_token },
      data: { push_token: null, push_enabled: false } });
    await tx.notification_pushes.update({ where: { id: delivery.id }, data: { status: result === 'SENT' ? 'SENT' : 'INVALID', sent_at: result === 'SENT' ? new Date() : null } });
    return result === 'SENT' ? { sent: 1 } : { invalid: 1 };
  }
  async cleanupExpired(): Promise<number> {
    // Worker hourly catch-up; expired rows are hidden immediately on all inbox APIs.
    return this.db.$executeRaw`DELETE FROM notifications WHERE id IN
      (SELECT id FROM notifications WHERE created_at <= ${cutoff()} ORDER BY created_at LIMIT 500)`;
  }
  private path(row: notifications): string {
    return z.object({ path: z.string().startsWith('/').max(300) }).parse(row.data).path;
  }
  private present(row: notifications) {
    return { id: row.id, role: row.role, category: row.category, type: row.type, title: row.title, body: row.body,
      path: this.path(row), createdAt: row.created_at.toISOString(), readAt: row.read_at?.toISOString() ?? null };
  }
  private mutate(userId: string, key: string, method: string, action: string, input: object,
    write: (tx: Tx, role: user_role_type) => Promise<Prisma.InputJsonObject>, role?: user_role_type) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `notifications:${digest(`${userId}:${key}`)}`, hash = this.keys.hashRequestBody(input);
    return this.db.$transaction(async tx => {
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
      const selected = await this.actor(tx, userId, role);
      const path = ['read', 'clear'].includes(action) ? `${action}:${selected}` : action;
      const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
      if (cached && cached.expires_at > new Date()) {
        if (cached.method !== method || cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
      const response = await write(tx, selected);
      await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, user_id: userId,
        method, path, request_hash: hash, response_body: response, response_status: 200, expires_at: new Date(Date.now() + 86400000) } });
      return response;
    }, { timeout: 15000 }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'NOTIFICATION_WRITE_UNAVAILABLE' });
    });
  }
}
