import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminDashboard } from './dashboard.dto';
@Injectable()
export class DashboardService {
 constructor(private readonly db: PrismaService) {}
 async get(): Promise<AdminDashboard> {
  // One statement gives every all-time metric the same database snapshot.
  const [row] = await this.db.$queryRaw<(Omit<AdminDashboard, 'serverTime' | 'planRevenueStatus' | 'gmvScope'> & { now: Date })[]>`
   SELECT statement_timestamp() AS now,
    (SELECT count(*)::int FROM vendors) AS "vendorsTotal",
    (SELECT count(*)::int FROM vendors WHERE is_suspended) AS "vendorsSuspended",
    (SELECT count(*)::int FROM vendors WHERE kyc_status = 'MANUAL_REVIEW') AS "kycPending",
    (SELECT count(*)::int FROM vendors WHERE kyc_status = 'VERIFIED') AS "kycVerified",
    (SELECT count(*)::int FROM users u WHERE EXISTS (SELECT 1 FROM user_roles r WHERE r.user_id = u.id AND r.role = 'CUSTOMER')) AS "customersTotal",
    (SELECT count(*)::int FROM users u WHERE u.status = 'BLOCKED' AND EXISTS (SELECT 1 FROM user_roles r WHERE r.user_id = u.id AND r.role = 'CUSTOMER')) AS "customersBlocked",
    (SELECT count(*)::int FROM orders) AS "ordersTotal",
    (SELECT count(*)::int FROM orders WHERE status = 'DELIVERED') AS "ordersDelivered",
    (SELECT count(*)::int FROM orders WHERE status = 'FAILED') AS "ordersFailed",
    (SELECT coalesce(sum(total_paise),0)::text FROM orders WHERE status = 'DELIVERED') AS "recordedGmvPaise",
    (SELECT count(*)::int FROM vendor_plan_assignments) AS "planAssignmentsTotal"`;
  const { now, ...metrics } = row!;
  return { ...metrics, serverTime: now.toISOString(), planRevenueStatus: 'UNAVAILABLE', gmvScope: 'DELIVERED_ORDERS_ONLY' };
 }
}
