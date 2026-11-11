import { BadRequestException, ConflictException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, users } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { auditContext } from '../audit/audit-context';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { CUSTOMER_LIMITS } from '../plans/plan-policy';
import { BadgeInput, ManagementInput, ManagementQuery } from './management.dto';
type Tx = Prisma.TransactionClient;
type Vendor = Prisma.vendorsGetPayload<{ include: { user: true; category: true } }>;
const isUuid = (value: string) => /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(value);
@Injectable()
export class ManagementService {
 constructor(private readonly db: PrismaService, private readonly auth: AdminAuthService, private readonly keys: IdempotencyService) {}
 private user(row: users) { return { id: row.id, name: row.name, mobile: row.mobile, status: row.status, updatedAt: row.updated_at.toISOString() }; }
 private vendor(row: Vendor) { return { id: row.id, businessName: row.business_name, account: this.user(row.user), category: row.category.name_en,
  city: row.city, kycStatus: row.kyc_status, isSuspended: row.is_suspended, badges: row.badges, updatedAt: row.updated_at.toISOString() }; }
 async vendors(query: ManagementQuery) {
  const value = query.search?.trim(), text = { contains: value, mode: 'insensitive' as const };
  const where: Prisma.vendorsWhereInput = value ? { OR: [{ business_name: text }, { user: { name: text } }, { user: { mobile: { contains: value } } }, ...(isUuid(value) ? [{ id: value }] : [])] } : {};
  return this.db.$transaction(async tx => {
   const [rows, total] = await Promise.all([tx.vendors.findMany({ where, include: { user: true, category: true }, orderBy: [{ created_at: 'desc' }, { id: 'asc' }], take: 20, skip: query.offset ?? 0 }), tx.vendors.count({ where })]);
   return { items: rows.map(row => this.vendor(row)), total };
  }, { isolationLevel: 'RepeatableRead' });
 }
 async vendorDetail(id: string) {
  return this.db.$transaction(async tx => {
   const row = await tx.vendors.findUnique({ where: { id }, include: { user: true, category: true } });
   if (!row) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
   const plan = await tx.vendor_plan_assignments.findFirst({ where: { vendor_id: id, superseded_at: null }, include: { plan: true, audit: true } });
   const [clock] = await tx.$queryRaw<{ now: Date }[]>`SELECT clock_timestamp() AS now`;
   const audited = plan?.audit.actor_type === 'ADMIN' && plan.audit.actor_id === plan.granted_by_admin && plan.audit.action === 'PLAN_ASSIGNED' && plan.audit.entity === 'VENDOR' && plan.audit.entity_id === id;
   const available = audited && !row.is_suspended && row.user.status === 'ACTIVE' && plan.plan.status === 'ACTIVE';
   return { ...this.vendor(row), planCode: plan?.plan.code ?? null, planStartsAt: plan?.starts_at.toISOString() ?? null, planEndsAt: plan?.ends_at.toISOString() ?? null,
    planStatus: plan ? !available ? 'UNAVAILABLE' : plan.ends_at <= clock!.now ? 'EXPIRED' : plan.starts_at > clock!.now ? 'SCHEDULED' : 'ACTIVE' : row.assigned_customer_limit === null ? 'UNASSIGNED' : 'UNAVAILABLE',
    customerLimit: plan ? CUSTOMER_LIMITS[plan.plan.code] : row.assigned_customer_limit ?? 50 };
  }, { isolationLevel: 'RepeatableRead' });
 }
 async customers(query: ManagementQuery) {
  const value = query.search?.trim();
  const where: Prisma.usersWhereInput = { roles: { some: { role: 'CUSTOMER' } }, ...(value ? { OR: [{ name: { contains: value, mode: 'insensitive' } }, { mobile: { contains: value } }, ...(isUuid(value) ? [{ id: value }] : [])] } : {}) };
  return this.db.$transaction(async tx => {
   const [rows, total] = await Promise.all([tx.users.findMany({ where, orderBy: [{ created_at: 'desc' }, { id: 'asc' }], take: 20, skip: query.offset ?? 0 }), tx.users.count({ where })]);
   return { items: rows.map(row => this.user(row)), total };
  }, { isolationLevel: 'RepeatableRead' });
 }
 async customerDetail(id: string) {
  const row = await this.db.users.findFirst({ where: { id, roles: { some: { role: 'CUSTOMER' } } } });
  if (!row) throw new NotFoundException({ code: 'CUSTOMER_NOT_FOUND' });
  return this.user(row);
 }
 async change(token: string, csrf: string, key: string, id: string, action: 'SUSPEND' | 'REINSTATE' | 'BADGES' | 'BLOCK' | 'UNBLOCK', input: ManagementInput | BadgeInput, ip?: string) {
  if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
  const vendorAction = ['SUSPEND', 'REINSTATE', 'BADGES'].includes(action);
  return this.db.$transaction(async tx => {
   const actor = await this.auth.authenticateInTransaction(tx, token, vendorAction ? 'vendors.manage' : 'customers.manage', csrf);
   await auditContext(tx, actor.id, ip);
   const requestKey = createHash('sha256').update(`${actor.id}:${key}`).digest('hex'), path = `${action}/${id}`, hash = this.keys.hashRequestBody(input);
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`management:${requestKey}`}, 0))::text`;
   const cached = await tx.management_requests.findUnique({ where: { request_key: requestKey } });
   if (cached) { if (cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' }); return cached.response; }
   let response: Prisma.InputJsonObject;
   if (vendorAction) {
    const known = await tx.vendors.findUnique({ where: { id }, select: { user_id: true } });
    if (!known) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
    await this.lockUser(tx, known.user_id);
    await tx.$queryRaw`SELECT id FROM vendors WHERE id = ${id}::uuid FOR UPDATE`;
    const before = await tx.vendors.findUniqueOrThrow({ where: { id }, include: { user: true } });
    if (before.user.status === 'DELETED') throw new ConflictException({ code: 'ACCOUNT_DELETED' });
    this.version(before.updated_at, input.expectedUpdatedAt);
    const row = await tx.vendors.update({ where: { id }, data: action === 'BADGES' ? { badges: (input as BadgeInput).badges.map(value => value.trim()) } : { is_suspended: action === 'SUSPEND' } });
    response = { id, updatedAt: row.updated_at.toISOString(), isSuspended: row.is_suspended, badges: row.badges };
    await this.audit(tx, actor.id, `VENDOR_${action}`, 'vendors', id, { isSuspended: before.is_suspended, badges: before.badges }, { isSuspended: row.is_suspended, badges: row.badges }, input.reason, ip);
   } else {
    await this.lockUser(tx, id);
    const before = await tx.users.findFirst({ where: { id, roles: { some: { role: 'CUSTOMER' } } } });
    if (!before) throw new NotFoundException({ code: 'CUSTOMER_NOT_FOUND' });
    if (before.status === 'DELETED') throw new ConflictException({ code: 'ACCOUNT_DELETED' });
    this.version(before.updated_at, input.expectedUpdatedAt);
    const row = await tx.users.update({ where: { id }, data: { status: action === 'BLOCK' ? 'BLOCKED' : 'ACTIVE' } });
    if (action === 'BLOCK') {
     await tx.sessions.updateMany({ where: { user_id: id, status: 'ACTIVE' }, data: { status: 'REVOKED', revoked_at: new Date() } });
     await tx.devices.updateMany({ where: { user_id: id }, data: { push_token: null, push_enabled: false } });
    }
    response = { id, status: row.status, updatedAt: row.updated_at.toISOString() };
    await this.audit(tx, actor.id, `CUSTOMER_${action}`, 'users', id, { status: before.status }, { status: row.status }, input.reason, ip);
   }
   await tx.management_requests.create({ data: { request_key: requestKey, admin_id: actor.id, path, request_hash: hash, response } });
   return response;
  }, { timeout: 15000 }).catch((error: unknown) => { if (error instanceof HttpException) throw error; throw new ServiceUnavailableException({ code: 'MANAGEMENT_WRITE_UNAVAILABLE' }); });
 }
 private lockUser(tx: Tx, id: string) { return tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${id}, 0))::text`; }
 private version(actual: Date, expected: string) { if (actual.getTime() !== new Date(expected).getTime()) throw new ConflictException({ code: 'MANAGEMENT_CHANGED' }); }
 private audit(tx: Tx, actor: string, action: string, entity: string, id: string, before: Prisma.InputJsonObject, after: Prisma.InputJsonObject, reason: string, ip?: string) {
  return tx.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: actor, action, entity, entity_id: id, before, after: { ...after, reason: reason.trim() }, ip } });
 }
}
