import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, vendor_plan_assignments } from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { auditContext } from '../audit/audit-context';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { CustomersService } from '../customers/customers.service';
import { PlanEntitlementsService } from './plan-entitlements.service';
import { CUSTOMER_LIMITS, PLAN_FEATURES } from './plan-policy';
import { AssignPlanInput, AssignmentResponse, CatalogPlanInput, CurrentPlanResponse, ExtendPlanInput, PlanAdminQuery } from './plans.dto';
import { PlanRemindersService } from './plan-reminders.service';

@Injectable()
export class PlansService {
  constructor(private readonly db: PrismaService, private readonly auth: AdminAuthService,
    private readonly keys: IdempotencyService, private readonly entitlements: PlanEntitlementsService,
    private readonly customers: CustomersService, private readonly reminders: PlanRemindersService) {}
  async catalog(userId?: string) {
    if (userId) await this.vendor(this.db, userId);
    const rows = await this.db.plans.findMany({ where: userId ? { status: 'ACTIVE' } : {}, include: { prices: { orderBy: { duration: 'asc' } } }, orderBy: { customer_limit: 'asc' } });
    return { items: rows.map(row => ({ id: row.id, code: row.code, name: row.name, updatedAt: row.updated_at.toISOString(),
      customerLimit: CUSTOMER_LIMITS[row.code], features: [...PLAN_FEATURES[row.code]], isPopular: row.is_popular, status: row.status,
      prices: row.prices.map(price => {
        const value = Number(price.price_paise);
        if (!Number.isSafeInteger(value) || value < 0) throw new ServiceUnavailableException({ code: 'PLAN_CATALOG_UNAVAILABLE' });
        return { duration: price.duration, pricePaise: value };
      }) })) };
  }
  async vendors(query: PlanAdminQuery) {
    const search = query.search?.trim();
    const where: Prisma.vendorsWhereInput = search ? { OR: [{ business_name: { contains: search, mode: 'insensitive' } },
      ...(/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(search) ? [{ id: search }] : [])] } : {};
    return this.db.$transaction(async tx => {
      const [items, total] = await Promise.all([tx.vendors.findMany({ where, select: { id: true, business_name: true },
        orderBy: [{ created_at: 'desc' }, { id: 'asc' }], take: 20, skip: query.offset ?? 0 }), tx.vendors.count({ where })]);
      return { items: items.map(row => ({ id: row.id, businessName: row.business_name })), total };
    }, { isolationLevel: 'RepeatableRead' });
  }
  async history(vendorId: string, query: PlanAdminQuery) {
    return this.db.$transaction(async tx => {
      if (!await tx.vendors.findUnique({ where: { id: vendorId }, select: { id: true } })) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
      const where = { vendor_id: vendorId };
      const [rows, total] = await Promise.all([tx.vendor_plan_assignments.findMany({ where, include: { plan: true },
        orderBy: [{ created_at: 'desc' }, { id: 'desc' }], take: 20, skip: query.offset ?? 0 }), tx.vendor_plan_assignments.count({ where })]);
      return { items: rows.map(row => ({ ...this.present(row, row.plan.code), supersededAt: row.superseded_at?.toISOString() ?? null })), total };
    }, { isolationLevel: 'RepeatableRead' });
  }
  async saveCatalog(token: string, csrf: string, key: string, id: string, input: CatalogPlanInput, ip?: string) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    return this.db.$transaction(async tx => {
      const actor = await this.auth.authenticateInTransaction(tx, token, 'plans.manage', csrf);
      await auditContext(tx, actor.id, ip);
      const requestKey = createHash('sha256').update(`${actor.id}:${key}`).digest('hex'), path = `catalog/${id}`, hash = this.keys.hashRequestBody(input);
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`plan:${requestKey}`}, 0))::text`;
      const cached = await tx.plan_assignment_requests.findUnique({ where: { request_key: requestKey } });
      if (cached) {
        if (cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response;
      }
      await tx.$queryRaw`SELECT id FROM plans WHERE id = ${id}::uuid FOR UPDATE`;
      const before = await tx.plans.findUnique({ where: { id }, include: { prices: true } });
      if (!before) throw new NotFoundException({ code: 'PLAN_NOT_FOUND' });
      if (before.updated_at.getTime() !== new Date(input.expectedUpdatedAt).getTime()) throw new ConflictException({ code: 'PLAN_CATALOG_CHANGED' });
      // Approved caps/features are fixed policy. Catalog editing cannot mutate entitlements.
      const row = await tx.plans.update({ where: { id }, data: { name: input.name.trim(), status: input.status, is_popular: input.isPopular } });
      for (const price of input.prices) await tx.plan_prices.upsert({ where: { plan_id_duration: { plan_id: id, duration: price.duration } },
        create: { plan_id: id, duration: price.duration, price_paise: BigInt(price.pricePaise) }, update: { price_paise: BigInt(price.pricePaise) } });
      const response = { id, code: row.code, name: row.name, status: row.status, isPopular: row.is_popular,
        updatedAt: row.updated_at.toISOString(), customerLimit: CUSTOMER_LIMITS[row.code], features: [...PLAN_FEATURES[row.code]],
        prices: input.prices.map(price => ({ ...price })) };
      await tx.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: actor.id, action: 'PLAN_CATALOG_UPDATE', entity: 'plans', entity_id: id, ip,
        before: { name: before.name, status: before.status, isPopular: before.is_popular,
          prices: before.prices.map(price => ({ duration: price.duration, pricePaise: price.price_paise.toString() })) },
        after: { ...response, reason: input.reason.trim() } } });
      await tx.plan_assignment_requests.create({ data: { request_key: requestKey, admin_id: actor.id, path, request_hash: hash, response } });
      return response;
    }, { timeout: 15000 }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'PLAN_WRITE_UNAVAILABLE' });
    });
  }
  async current(userId: string): Promise<CurrentPlanResponse> {
    return this.db.$transaction(async tx => this.currentVendor(tx, (await this.vendor(tx, userId)).id));
  }
  async adminCurrent(vendorId: string): Promise<CurrentPlanResponse> {
    return this.db.$transaction(tx => this.currentVendor(tx, vendorId));
  }
  private async currentVendor(tx: Prisma.TransactionClient, vendorId: string): Promise<CurrentPlanResponse> {
    const state = await this.entitlements.resolve(tx, vendorId);
    const activeCustomers = await tx.vendor_customers.count({ where: { vendor_id: vendorId, status: 'ACTIVE', deleted_at: null } });
    const row = state.assignment;
    return { assignment: row ? { id: row.id, planId: row.plan_id, code: row.plan.code, startsAt: row.starts_at.toISOString(), endsAt: row.ends_at.toISOString() } : null,
      status: state.active ? 'ACTIVE' : state.expired ? 'EXPIRED' : state.scheduled ? 'SCHEDULED' : state.everAssigned ? 'UNAVAILABLE' : 'UNASSIGNED',
      customerLimit: state.customerLimit, activeCustomers,
      canAddCustomer: (!state.everAssigned || state.active) && activeCustomers < state.customerLimit,
      features: state.active && state.assignment ? [...PLAN_FEATURES[state.assignment.plan.code]] : [] };
  }
  async assign(token: string, csrf: string, key: string, vendorId: string, input: AssignPlanInput | ExtendPlanInput, assignmentId?: string, ip?: string) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    return this.db.$transaction(async tx => {
      // Same admin lock as logout/role changes; authorization precedes even a cached replay.
      const actor = await this.auth.authenticateInTransaction(tx, token, 'plans.manage', csrf);
      await auditContext(tx, actor.id, ip);
      const requestKey = createHash('sha256').update(`${actor.id}:${key}`).digest('hex');
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`plan:${requestKey}`}, 0))::text`;
      const path = `${vendorId}/${assignmentId ?? 'assign'}`, hash = this.keys.hashRequestBody(input);
      const cached = await tx.plan_assignment_requests.findUnique({ where: { request_key: requestKey } });
      if (cached) {
        if (cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response;
      }
      const [vendor] = await tx.$queryRaw<{ id: string; is_suspended: boolean }[]>`SELECT id, is_suspended FROM vendors WHERE id = ${vendorId}::uuid FOR UPDATE`;
      if (!vendor) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
      if (vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
      const [clock] = await tx.$queryRaw<{ now: Date }[]>`SELECT clock_timestamp() AS now`;
      const before = await tx.vendor_plan_assignments.findFirst({ where: { vendor_id: vendorId, superseded_at: null }, include: { plan: true } });
      if (assignmentId && before?.id !== assignmentId) throw new NotFoundException({ code: 'PLAN_ASSIGNMENT_NOT_FOUND' });
      const planId = assignmentId ? before!.plan_id : (input as AssignPlanInput).planId;
      const plan = await tx.plans.findUnique({ where: { id: planId } });
      if (!plan || plan.status !== 'ACTIVE') throw new ConflictException({ code: 'PLAN_UNAVAILABLE' });
      const startsAt = assignmentId ? before!.starts_at : new Date((input as AssignPlanInput).startsAt), endsAt = new Date(input.endsAt);
      if (!Number.isFinite(startsAt.getTime()) || !Number.isFinite(endsAt.getTime()) || endsAt <= startsAt || endsAt <= clock!.now ||
        (assignmentId && endsAt <= before!.ends_at)) throw new BadRequestException({ code: 'INVALID_PLAN_DATES' });
      if (!input.reason?.trim() || input.reason.length > 500) throw new BadRequestException({ code: 'PLAN_REASON_REQUIRED' });
      const id = randomUUID();
      const after = { id, vendorId, planId, code: plan.code, startsAt: startsAt.toISOString(), endsAt: endsAt.toISOString(), reason: input.reason.trim(), grantedByAdmin: actor.id };
      const audit = await tx.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: actor.id, action: 'PLAN_ASSIGNED', entity: 'VENDOR', entity_id: vendorId,
        before: before ? { ...this.present(before, before.plan.code) } : undefined, after: { ...after, operation: assignmentId ? 'EXTEND' : 'ASSIGN' }, ip } });
      if (before) await tx.vendor_plan_assignments.update({ where: { id: before.id }, data: { superseded_at: clock!.now } });
      const row = await tx.vendor_plan_assignments.create({ data: { id, vendor_id: vendorId, plan_id: planId, starts_at: startsAt, ends_at: endsAt,
        reason: input.reason.trim(), granted_by_admin: actor.id, audit_id: audit.id } });
      await this.customers.setAssignedCustomerLimit(tx, vendorId, CUSTOMER_LIMITS[plan.code]);
      await this.reminders.schedule(tx, row, clock!.now);
      const response = { ...this.present(row, plan.code) };
      await tx.plan_assignment_requests.create({ data: { request_key: requestKey, admin_id: actor.id, path, request_hash: hash, response } });
      return response;
    }, { timeout: 15000 }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'PLAN_WRITE_UNAVAILABLE' });
    });
  }
  private async vendor(tx: Prisma.TransactionClient, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true, vendor: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR') || !user.vendor) throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    if (user.vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
    return user.vendor;
  }
  private present(row: vendor_plan_assignments, code: string): AssignmentResponse {
    return { id: row.id, vendorId: row.vendor_id, planId: row.plan_id, code, startsAt: row.starts_at.toISOString(), endsAt: row.ends_at.toISOString(),
      reason: row.reason, grantedByAdmin: row.granted_by_admin, auditId: row.audit_id };
  }
}
