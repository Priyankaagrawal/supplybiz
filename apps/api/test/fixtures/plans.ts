// Synthetic native-test fixture only. This is not an administrator grant workflow.
import { Prisma, plan_code } from '@prisma/client';
import { CUSTOMER_LIMITS, PLAN_FEATURES } from '../../src/modules/plans/plan-policy';

export async function assignPlanFixture(tx: Prisma.TransactionClient, vendorId: string, code: plan_code,
  startsAt = new Date(Date.now() - 60000), endsAt = new Date(Date.now() + 86400000)) {
  await tx.$queryRaw`SELECT id FROM vendors WHERE id = ${vendorId}::uuid FOR UPDATE`;
  const plan = await tx.plans.upsert({ where: { code }, update: {}, create: { code, name: code,
    customer_limit: CUSTOMER_LIMITS[code], features: [...PLAN_FEATURES[code]] } });
  const admin = await tx.admin_users.create({ data: { email: `fixture-${crypto.randomUUID()}@example.invalid`,
    password_hash: 'synthetic-unused', role: 'SUPER_ADMIN' } });
  const audit = await tx.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: admin.id,
    action: 'PLAN_ASSIGNED', entity: 'VENDOR', entity_id: vendorId, after: { code, fixture: true } } });
  await tx.vendor_plan_assignments.updateMany({ where: { vendor_id: vendorId, superseded_at: null }, data: { superseded_at: new Date() } });
  const assignment = await tx.vendor_plan_assignments.create({ data: { vendor_id: vendorId, plan_id: plan.id,
    starts_at: startsAt, ends_at: endsAt, reason: 'Synthetic entitlement fixture', granted_by_admin: admin.id, audit_id: audit.id } });
  await tx.vendors.update({ where: { id: vendorId }, data: { assigned_customer_limit: CUSTOMER_LIMITS[code] } });
  return assignment;
}
