import { BadRequestException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { dateOnly } from '../subscriptions/subscription-policy';
import { VendorDashboard, VendorDashboardQuery } from './vendor-dashboard.dto';
@Injectable()
export class VendorDashboardService {
  constructor(private readonly db: PrismaService) {}
  get(userId: string, query: VendorDashboardQuery): Promise<VendorDashboard> {
    if (query.date !== undefined) {
      dateOnly(query.date);
      if (query.date.startsWith('0000')) throw new BadRequestException({ code: 'INVALID_DATE' });
    }
    return this.db.$transaction(async tx => {
      const actor = await tx.users.findUnique({ where: { id: userId }, include: { roles: true, vendor: true } });
      if (!actor || actor.status !== 'ACTIVE' || actor.active_role !== 'VENDOR' || !actor.roles.some(r => r.role === 'VENDOR')) {
        throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
      }
      if (!actor.vendor) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
      if (actor.vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
      const id = actor.vendor.id;
      // Basic read before assignment/after expiry grants no paid feature. One
      // repeatable snapshot covers identity/header and every aggregate; no cache.
      const [row] = await tx.$queryRaw<(Omit<VendorDashboard, 'serverTime'> & { now: Date })[]>`
        WITH clock AS (SELECT statement_timestamp() AS now),
        selected AS (SELECT now, (now AT TIME ZONE 'Asia/Kolkata')::date AS business_day,
          COALESCE(${query.date ?? null}::date, (now AT TIME ZONE 'Asia/Kolkata')::date) AS day FROM clock),
        bounds AS (SELECT *, day::timestamp AT TIME ZONE 'Asia/Kolkata' AS start_at,
          (day + 1)::timestamp AT TIME ZONE 'Asia/Kolkata' AS end_at FROM selected),
        order_metrics AS (
          SELECT count(*) FILTER (WHERE o.delivery_date=b.day)::int AS total,
            count(*) FILTER (WHERE o.delivery_date=b.day AND o.status IN ('NEW','ACCEPTED','PREPARING','OUT_FOR_DELIVERY'))::int AS pending,
            count(*) FILTER (WHERE o.delivery_date=b.day AND o.status='DELIVERED')::int AS completed,
            COALESCE(sum(o.total_paise) FILTER (WHERE o.status='DELIVERED' AND o.completed_at>=b.start_at AND o.completed_at<b.end_at),0) AS day_sales,
            COALESCE(sum(o.total_paise) FILTER (WHERE o.status='DELIVERED'),0) AS lifetime_sales
          FROM orders o CROSS JOIN bounds b WHERE o.vendor_id=${id}::uuid),
        pos_metrics AS (
          SELECT COALESCE(sum(s.total_paise) FILTER (WHERE s.sale_date=b.day),0) AS day_sales,
            COALESCE(sum(s.total_paise),0) AS lifetime_sales
          FROM sales s CROSS JOIN bounds b WHERE s.vendor_id=${id}::uuid),
        stock AS (
          SELECT COALESCE(sum(p.stock_qty::numeric*p.unit_value*
            CASE p.unit_type WHEN 'L' THEN 1::numeric WHEN 'ML' THEN 0.001::numeric ELSE 0::numeric END),0)::text AS litres,
            count(*) FILTER (WHERE p.stock_qty>0 AND p.unit_type NOT IN ('L','ML'))::int AS unmeasured
          FROM products p WHERE p.vendor_id=${id}::uuid AND p.product_type='MILK' AND p.is_active AND p.deleted_at IS NULL)
        SELECT b.now, to_char(b.business_day,'YYYY-MM-DD') AS "businessDate", to_char(b.day,'YYYY-MM-DD') AS date,
          v.business_name AS "shopName", v.city, v.shop_photo_media_id AS "shopPhotoMediaId", (v.kyc_status='VERIFIED') AS verified,
          o.total AS "todayOrders", o.pending AS "pendingOrders", o.completed AS "completedOrders",
          (o.day_sales+s.day_sales)::text AS "todaySalesPaise", (o.lifetime_sales+s.lifetime_sales)::text AS "totalEarningsPaise",
          stock.litres AS "milkStockLitres", stock.unmeasured AS "milkStockUnmeasuredProducts",
          (SELECT count(*)::int FROM vendor_customers c WHERE c.vendor_id=v.id AND c.status='ACTIVE' AND c.deleted_at IS NULL) AS "activeCustomers"
        FROM vendors v CROSS JOIN bounds b CROSS JOIN order_metrics o CROSS JOIN pos_metrics s CROSS JOIN stock
        WHERE v.id=${id}::uuid`;
      const { now, ...metrics } = row!;
      return { ...metrics, serverTime: now.toISOString() };
    }, { isolationLevel: 'RepeatableRead' }).catch((e: unknown) => {
      if (e instanceof HttpException) throw e;
      throw new ServiceUnavailableException({ code: 'DASHBOARD_UNAVAILABLE' });
    });
  }
}
