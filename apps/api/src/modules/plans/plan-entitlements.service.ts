import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { CUSTOMER_LIMITS, EXPIRY_OPERATIONS, OPERATION_FEATURES, PLAN_FEATURES, PlanFeature, PlanOperation } from './plan-policy';

export const PRE_ASSIGNMENT_CUSTOMER_LIMIT = 50;
type Tx = Prisma.TransactionClient;
@Injectable()
export class PlanEntitlementsService {
  /** Call inside the business transaction; assignment writers use the same vendor lock.
   * DB time is evaluated after acquiring the lock. Never cache a client claim or plan tier. */
  async resolve(tx: Tx, vendorId: string) {
    const vendors = await tx.$queryRaw<{ id: string; is_suspended: boolean; assigned_customer_limit: number | null }[]>`
      SELECT id, is_suspended, assigned_customer_limit FROM vendors WHERE id = ${vendorId}::uuid FOR UPDATE`;
    const vendor = vendors[0];
    if (!vendor) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
    if (vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
    const [clock] = await tx.$queryRaw<{ now: Date }[]>`SELECT clock_timestamp() AS now`;
    const assignment = await tx.vendor_plan_assignments.findFirst({ where: { vendor_id: vendorId, superseded_at: null },
      include: { plan: true, audit: true } });
    const audited = assignment && assignment.audit.actor_type === 'ADMIN' && assignment.audit.actor_id === assignment.granted_by_admin &&
      assignment.audit.entity === 'VENDOR' && assignment.audit.entity_id === vendorId && assignment.audit.action === 'PLAN_ASSIGNED';
    const active = !!(audited && assignment.plan.status === 'ACTIVE' && assignment.starts_at <= clock!.now && clock!.now < assignment.ends_at);
    const history = !assignment && await tx.vendor_plan_assignments.findFirst({ where: { vendor_id: vendorId }, select: { id: true } });
    return { assignment, active, expired: !!(audited && assignment.ends_at <= clock!.now), everAssigned: !!assignment || !!history || vendor.assigned_customer_limit !== null,
      customerLimit: assignment ? CUSTOMER_LIMITS[assignment.plan.code] : vendor.assigned_customer_limit ?? PRE_ASSIGNMENT_CUSTOMER_LIMIT };
  }
  async requireFeature(tx: Tx, vendorId: string, feature: PlanFeature) {
    const state = await this.resolve(tx, vendorId);
    if (!state.active || !state.assignment || !PLAN_FEATURES[state.assignment.plan.code].includes(feature)) this.locked();
    return state;
  }
  /** Expiry exceptions supplement, never replace, caller authorization and order-state rules. */
  async requireOperation(tx: Tx, vendorId: string, operation: PlanOperation) {
    const state = await this.resolve(tx, vendorId);
    if (!state.active) {
      if (state.expired && EXPIRY_OPERATIONS.includes(operation)) return state;
      this.locked();
    }
    if (!state.assignment || !PLAN_FEATURES[state.assignment.plan.code].includes(OPERATION_FEATURES[operation])) this.locked();
    return state;
  }
  async requireCustomerGrowth(tx: Tx, vendorId: string) {
    const state = await this.resolve(tx, vendorId);
    if (state.everAssigned && !state.active) this.locked();
    return state.customerLimit;
  }
  private locked(): never {
    throw new ForbiddenException({ code: 'PLAN_FEATURE_LOCKED', detail: 'Contact support to assign or renew a plan.' });
  }
}
