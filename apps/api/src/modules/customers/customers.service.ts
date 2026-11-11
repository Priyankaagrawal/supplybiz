import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, vendor_customers } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { CustomerInput, CustomerPatch, CustomerQuery, LinkRequestQuery } from './customers.dto';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
export { PRE_ASSIGNMENT_CUSTOMER_LIMIT } from '../plans/plan-entitlements.service';

type Tx = Prisma.TransactionClient;
const mobile = (value: string) => value.startsWith('+91') ? value : `+91${value}`;
@Injectable()
export class CustomersService {
  constructor(private readonly db: PrismaService, private readonly idempotency: IdempotencyService,
    private readonly plans: PlanEntitlementsService) {}

  async list(userId: string, query: CustomerQuery) {
    return this.db.$transaction(async tx => {
      const vendor = await this.vendor(tx, userId);
      const entitlement = await this.plans.resolve(tx, vendor.id);
      const where: Prisma.vendor_customersWhereInput = { vendor_id: vendor.id, deleted_at: null,
        ...(['ACTIVE','INACTIVE'].includes(query.filter ?? '') ? { status: query.filter } : {}),
        ...(query.filter === 'SUBSCRIPTION' ? { subscription_links: { some: { status: { in: ['ACTIVE','PAUSED'] } } } } : {}),
        ...(query.search ? { OR: [{ name: { contains: query.search, mode: 'insensitive' } }, { mobile: { contains: query.search } }] } : {}) };
      const [rows, total, activeCount] = await Promise.all([
        tx.vendor_customers.findMany({ where, orderBy: [{ created_at: 'desc' }, { id: 'asc' }], take: query.limit ?? 50, skip: query.offset ?? 0 }),
        tx.vendor_customers.count({ where }), tx.vendor_customers.count({ where: { vendor_id: vendor.id, status: 'ACTIVE', deleted_at: null } }),
      ]);
      return { items: rows.map(row => this.present(row)), total, activeCount,
        customerLimit: entitlement.customerLimit };
    }, { isolationLevel: 'RepeatableRead' });
  }
  async get(userId: string, id: string) {
    const vendor = await this.vendor(this.db, userId);
    return this.present(await this.owned(this.db, vendor.id, id));
  }
  create(userId: string, key: string, input: CustomerInput) {
    return this.mutate(userId, key, 'POST', 'create', input, async tx => {
      const vendor = await this.vendor(tx, userId, true);
      await this.requireCapacity(tx, vendor.id);
      return this.present(await tx.vendor_customers.create({ data: { vendor_id: vendor.id,
        name: input.name, mobile: mobile(input.mobile), email: input.email, address_text: input.address,
        preferred_payment: input.preferredPayment } }));
    });
  }
  patch(userId: string, key: string, id: string, input: CustomerPatch) {
    return this.mutate(userId, key, 'PATCH', id, input, async tx => {
      const vendor = await this.vendor(tx, userId, true);
      const row = await this.owned(tx, vendor.id, id);
      if (input.mobile && mobile(input.mobile) !== row.mobile && row.user_id) throw new ConflictException({ code: 'LINKED_MOBILE_IMMUTABLE' });
      if (input.status === 'ACTIVE' && row.status !== 'ACTIVE') await this.requireCapacity(tx, vendor.id);
      return this.present(await tx.vendor_customers.update({ where: { id }, data: { name: input.name,
        mobile: input.mobile ? mobile(input.mobile) : undefined, email: input.email, address_text: input.address,
        preferred_payment: input.preferredPayment, status: input.status } }));
    });
  }
  async linkRequests(userId: string, query: LinkRequestQuery) {
    return this.db.$transaction(async tx => {
      const user = await this.customer(tx, userId);
      const where = { mobile: user.mobile, user_id: null, deleted_at: null,
        vendor: { is_suspended: false }, decisions: { none: { user_id: userId } } };
      const [rows, total] = await Promise.all([
        tx.vendor_customers.findMany({ where, include: { vendor: { select: { id: true, business_name: true } } },
          orderBy: [{ created_at: 'desc' }, { id: 'asc' }], take: query.limit ?? 50, skip: query.offset ?? 0 }),
        tx.vendor_customers.count({ where }),
      ]);
      return { items: rows.map(row => ({ id: row.id, vendorId: row.vendor.id, businessName: row.vendor.business_name })), total };
    }, { isolationLevel: 'RepeatableRead' });
  }
  decide(userId: string, key: string, id: string, decision: 'ACCEPTED' | 'DECLINED') {
    return this.mutate(userId, key, 'POST', `link/${id}/${decision}`, {}, async tx => {
      const user = await this.customer(tx, userId);
      const row = await tx.vendor_customers.findFirst({ where: { id, mobile: user.mobile, deleted_at: null } });
      if (!row) throw new NotFoundException({ code: 'LINK_REQUEST_NOT_FOUND' });
      await this.lockVendor(tx, row.vendor_id);
      const current = await tx.vendor_customers.findFirst({ where: { id, mobile: user.mobile, deleted_at: null,
        vendor: { is_suspended: false } } });
      if (!current || (current.user_id && current.user_id !== userId)) throw new NotFoundException({ code: 'LINK_REQUEST_NOT_FOUND' });
      const prior = await tx.customer_link_decisions.findUnique({ where: { vendor_customer_id_user_id: { vendor_customer_id: id, user_id: userId } } });
      if (prior && prior.decision !== decision) throw new ConflictException({ code: 'LINK_ALREADY_DECIDED' });
      if (!prior) {
        if (decision === 'ACCEPTED') await tx.vendor_customers.update({ where: { id }, data: { user_id: userId } });
        await tx.customer_link_decisions.create({ data: { vendor_customer_id: id, user_id: userId, decision } });
      }
      return { id, decision };
    });
  }
  /** T-084/T-103 call with the catalog limit inside the audited assignment transaction.
   * Expiry must not clear this projection and restore the pre-assignment allowance. */
  async setAssignedCustomerLimit(tx: Tx, vendorId: string, limit: number) {
    if (!Number.isInteger(limit) || limit < 0 || limit > 2147483647) throw new BadRequestException({ code: 'INVALID_CUSTOMER_LIMIT' });
    await this.lockVendor(tx, vendorId);
    await tx.vendors.update({ where: { id: vendorId }, data: { assigned_customer_limit: limit } });
  }
  /** Every future APP/order/link customer creator must use this lock/count in its transaction. */
  async requireCapacity(tx: Tx, vendorId: string) {
    await this.lockVendor(tx, vendorId);
    const limit = await this.plans.requireCustomerGrowth(tx, vendorId);
    const count = await tx.vendor_customers.count({ where: { vendor_id: vendorId, status: 'ACTIVE', deleted_at: null } });
    if (count >= limit) throw new UnprocessableEntityException({ code: 'PLAN_CUSTOMER_LIMIT',
      detail: `The active customer limit is ${limit}. Contact support to change the assigned plan.` });
  }
  /** T-072 maintains current subscription membership atomically with its own state. */
  async setSubscriptionReference(tx: Tx, subscriptionId: string, customerId: string,
    status: 'PENDING' | 'ACTIVE' | 'PAUSED' | 'ENDED' | 'CANCELLED' | 'REJECTED') {
    return tx.customer_subscription_links.upsert({ where: { subscription_id: subscriptionId },
      create: { subscription_id: subscriptionId, vendor_customer_id: customerId, status }, update: { vendor_customer_id: customerId, status } });
  }
  /** Ledger/order readers use this after role authorization; matching mobile alone never grants access. */
  async requireLinked(tx: Tx, userId: string, id: string) {
    await this.customer(tx, userId);
    const row = await tx.vendor_customers.findFirst({ where: { id, user_id: userId, deleted_at: null } });
    if (!row) throw new NotFoundException({ code: 'CUSTOMER_NOT_FOUND' });
    return row;
  }
  private async vendor(tx: Tx, userId: string, lock = false) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true, vendor: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR')) throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    if (!user.vendor) throw new ConflictException({ code: 'CATEGORY_REQUIRED' });
    if (lock) await this.lockVendor(tx, user.vendor.id);
    const vendor = lock ? await tx.vendors.findUniqueOrThrow({ where: { id: user.vendor.id } }) : user.vendor;
    if (vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
    return vendor;
  }
  private async customer(tx: Tx, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'CUSTOMER' || !user.roles.some(r => r.role === 'CUSTOMER')) throw new ForbiddenException({ code: 'CUSTOMER_ROLE_REQUIRED' });
    return user;
  }
  private lockVendor(tx: Tx, id: string) { return tx.$queryRaw`SELECT id FROM vendors WHERE id = ${id}::uuid FOR UPDATE`; }
  private async owned(tx: Tx, vendorId: string, id: string) {
    const row = await tx.vendor_customers.findFirst({ where: { id, vendor_id: vendorId, deleted_at: null } });
    if (!row) throw new NotFoundException({ code: 'CUSTOMER_NOT_FOUND' });
    return row;
  }
  private present(row: vendor_customers) {
    return { id: row.id, name: row.name, mobile: row.mobile, email: row.email, address: row.address_text,
      preferredPayment: row.preferred_payment, status: row.status, userId: row.user_id, linkStatus: row.user_id ? 'LINKED' : 'UNLINKED' };
  }
  private mutate(userId: string, key: string, method: string, path: string, input: object, write: (tx: Tx) => Promise<Prisma.InputJsonObject>) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `customers:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
    const requestHash = this.idempotency.hashRequestBody(input);
    return this.db.$transaction(async tx => {
      // Same user lock as role/session writes. Vendor lock serializes shared capacity and link decisions.
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
      if (path.startsWith('link/')) await this.customer(tx, userId); else await this.vendor(tx, userId);
      const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
      if (cached && cached.expires_at > new Date()) {
        if (cached.method !== method || cached.path !== path || cached.request_hash !== requestHash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
      const response = await write(tx);
      await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, user_id: userId, method, path,
        request_hash: requestHash, response_status: method === 'POST' ? 201 : 200, response_body: response,
        expires_at: new Date(Date.now() + 86400000) } });
      return response;
    }, { timeout: 15000 }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') throw new ConflictException({ code: 'DUPLICATE' });
      throw new ServiceUnavailableException({ code: 'CUSTOMER_WRITE_UNAVAILABLE' });
    });
  }
}
