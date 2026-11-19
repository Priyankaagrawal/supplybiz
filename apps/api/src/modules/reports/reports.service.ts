import { BadRequestException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { homeClock } from '../home/home.service';
import { ledgerRoots } from '../ledger/ledger-roots';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { dateOnly } from '../subscriptions/subscription-policy';
import { ReportDailySales, ReportProducts, ReportProductsQuery, ReportQuery, ReportRange, ReportSummary } from './reports.dto';
type Tx=Prisma.TransactionClient;
export function reportRange(query:ReportQuery,today:string){
  if((query.from===undefined)!==(query.to===undefined))throw new BadRequestException({code:'REPORT_RANGE_REQUIRED'});
  const from=query.from??today,to=query.to??today;
  const start=dateOnly(from),end=dateOnly(to),days=(end.getTime()-start.getTime())/86400000+1;
  if(from.startsWith('0000')||to.startsWith('0000')||days<1||days>366)throw new BadRequestException({code:'INVALID_REPORT_RANGE'});
  return {from,to,days};
}
// Shared source semantics for summary/table parity. Parameterized vendor and dates only.
export function reportSources(id:string,range:{from:string;to:string}){return Prisma.sql`
  bounds AS (SELECT ${range.from}::date AS first_day,${range.to}::date AS last_day,
    ${range.from}::date::timestamp AT TIME ZONE 'Asia/Kolkata' AS start_at,
    (${range.to}::date+1)::timestamp AT TIME ZONE 'Asia/Kolkata' AS end_at),
  source_orders AS (SELECT o.* FROM orders o CROSS JOIN bounds b WHERE o.vendor_id=${id}::uuid AND o.status='DELIVERED' AND o.completed_at>=b.start_at AND o.completed_at<b.end_at),
  source_sales AS (SELECT s.* FROM sales s CROSS JOIN bounds b WHERE s.vendor_id=${id}::uuid AND s.sale_date>=b.first_day AND s.sale_date<=b.last_day),
  lines AS (
    SELECT i.product_id,i.product_name_snapshot AS name,i.unit_snapshot->>'value' AS unit_value,i.unit_snapshot->>'type' AS unit_type,
      i.qty::numeric AS qty,i.line_total_paise::numeric AS amount,i.milk_quantity_ml AS milk,
      (i.milk_quantity_known OR i.milk_quantity_ml>0) AS milk_known FROM order_items i JOIN source_orders o ON o.id=i.order_id
    UNION ALL
    SELECT i.product_id,i.name_snapshot,i.unit_value_snapshot,i.unit_type_snapshot,i.qty::numeric,i.amount_paise::numeric,
      i.milk_quantity_ml,i.milk_quantity_known FROM sale_items i JOIN source_sales s ON s.id=i.sale_id),
  sold AS (SELECT (o.completed_at AT TIME ZONE 'Asia/Kolkata')::date AS day,o.total_paise::numeric AS amount FROM source_orders o
    UNION ALL SELECT s.sale_date,s.total_paise::numeric FROM source_sales s)`;}
@Injectable()
export class ReportsService {
  constructor(private readonly db:PrismaService,private readonly plans:PlanEntitlementsService){}
  private read<T>(userId:string,q:ReportQuery,advanced:boolean,select:(tx:Tx,id:string,range:ReportRange,days:number)=>Promise<T>){
    return this.db.$transaction(async tx=>{
      const actor=await tx.users.findUnique({where:{id:userId},include:{roles:true,vendor:true}});
      if(!actor||actor.status!=='ACTIVE'||actor.active_role!=='VENDOR'||!actor.roles.some(r=>r.role==='VENDOR'))throw new ForbiddenException({code:'VENDOR_ROLE_REQUIRED'});
      if(!actor.vendor)throw new NotFoundException({code:'VENDOR_NOT_FOUND'});
      const id=actor.vendor.id;
      // Existing expiry/history exception permits basic summary, never a new paid
      // advanced entitlement. Never-assigned/future-first plans remain denied.
      await this.plans.requireOperation(tx,id,'READ_HISTORY');
      if(advanced)await this.plans.requireFeature(tx,id,'ADVANCED_REPORTS');
      const clock=await homeClock(tx),{from,to,days}=reportRange(q,clock.day);
      return select(tx,id,{from,to,serverTime:clock.now.toISOString(),businessDate:clock.day},days);
    },{isolationLevel:'RepeatableRead',timeout:30000}).catch((e:unknown)=>{
      if(e instanceof HttpException)throw e;throw new ServiceUnavailableException({code:'REPORTS_UNAVAILABLE'});
    });
  }
  summary(userId:string,q:ReportQuery):Promise<ReportSummary>{return this.read(userId,q,false,async(tx,id,range)=>{
    const [metrics]=await tx.$queryRaw<Omit<ReportSummary,keyof ReportRange>[]>`${ledgerRoots(id)},${reportSources(id,range)},
      earnings AS (SELECT COALESCE(SUM(CASE WHEN e.type='CREDIT' THEN e.amount_paise::numeric ELSE -e.amount_paise::numeric END),0) AS amount
        FROM ledger_entries e JOIN ledger_roots r ON r.id=e.id CROSS JOIN bounds b
        WHERE e.vendor_id=${id}::uuid AND e.entry_date>=b.first_day AND e.entry_date<=b.last_day
          AND r.root_type='CREDIT' AND r.ref_type IN ('PAYMENT','SALE','CLAIM')),
      item_metrics AS (SELECT COALESCE(SUM(amount),0) AS amount,COALESCE(SUM(milk),0)/1000 AS milk,
        COUNT(*) FILTER(WHERE NOT milk_known)::int AS unmeasured FROM lines),
      goods AS (SELECT COALESCE(SUM(amount),0) AS amount FROM sold),
      charges AS (SELECT COALESCE(SUM(delivery_charge_paise),0) AS amount,COALESCE(SUM(discount_paise),0) AS discount FROM source_orders)
      SELECT goods.amount::text AS "totalSalesPaise",
        (SELECT COUNT(*)::int FROM orders o CROSS JOIN bounds b WHERE o.vendor_id=${id}::uuid AND o.delivery_date>=b.first_day AND o.delivery_date<=b.last_day) AS "totalOrders",
        (SELECT COUNT(*)::int FROM orders o CROSS JOIN bounds b WHERE o.vendor_id=${id}::uuid AND o.delivery_date>=b.first_day AND o.delivery_date<=b.last_day AND o.status='DELIVERED') AS "deliveredOrders",
        (SELECT COUNT(*)::int FROM orders o CROSS JOIN bounds b WHERE o.vendor_id=${id}::uuid AND o.delivery_date>=b.first_day AND o.delivery_date<=b.last_day AND o.status='CANCELLED') AS "cancelledOrders",
        trim_scale(item_metrics.milk)::text AS "milkSoldLitres",item_metrics.unmeasured AS "milkSoldUnmeasuredLines",
        (earnings.amount+(SELECT COALESCE(SUM(paid_paise),0) FROM source_sales WHERE vendor_customer_id IS NULL))::text AS "totalEarningsPaise",
        (SELECT COALESCE(SUM(GREATEST(l.due_paise,0)),0)::text FROM ledger_balances l JOIN vendor_customers c ON c.id=l.vendor_customer_id WHERE c.vendor_id=${id}::uuid) AS "pendingPaymentsPaise",
        (SELECT COUNT(*)::int FROM vendor_customers c WHERE c.vendor_id=${id}::uuid AND c.status='ACTIVE' AND c.deleted_at IS NULL) AS "activeCustomers",
        item_metrics.amount::text AS "productSalesPaise",charges.amount::text AS "deliveryChargesPaise",charges.discount::text AS "discountPaise",
        (goods.amount-item_metrics.amount-charges.amount+charges.discount)::text AS "unitemizedSalesPaise"
      FROM goods CROSS JOIN charges CROSS JOIN item_metrics CROSS JOIN earnings`;
    return {...range,...metrics!};
  });}
  daily(userId:string,q:ReportQuery):Promise<ReportDailySales>{return this.read(userId,q,true,async(tx,id,range,days)=>{
    const bucket=days>62?'WEEK':'DAY';
    const items=await tx.$queryRaw<ReportDailySales['items']>`WITH ${reportSources(id,range)},
      dates AS (SELECT generate_series(first_day::timestamp,last_day::timestamp,interval '1 day')::date AS day FROM bounds),
      periods AS (SELECT CASE WHEN ${bucket}='WEEK' THEN date_trunc('week',day::timestamp)::date ELSE day END AS period,
        MIN(day) AS first_day,MAX(day) AS last_day FROM dates GROUP BY 1),
      values_by_day AS (SELECT day,SUM(amount) AS amount FROM sold GROUP BY day)
      SELECT to_char(p.first_day,'YYYY-MM-DD') AS "from",to_char(p.last_day,'YYYY-MM-DD') AS "to",COALESCE(SUM(v.amount),0)::text AS "salesPaise"
      FROM periods p LEFT JOIN values_by_day v ON v.day>=p.first_day AND v.day<=p.last_day GROUP BY p.period,p.first_day,p.last_day ORDER BY p.period`;
    return {...range,bucket,items};
  });}
  products(userId:string,q:ReportProductsQuery):Promise<ReportProducts>{return this.read(userId,q,true,async(tx,id,range)=>{
    const cte=Prisma.sql`WITH ${reportSources(id,range)}, product_groups AS (
      SELECT product_id,name,unit_value,unit_type,SUM(qty) AS qty,SUM(amount) AS amount FROM lines GROUP BY product_id,name,unit_value,unit_type)`;
    const items=await tx.$queryRaw<ReportProducts['items']>`${cte} SELECT product_id AS "productId",name,COALESCE(unit_value,'') AS "unitValue",COALESCE(unit_type,'') AS "unitType",qty::text AS "quantityPacks",amount::text AS "salesPaise"
      FROM product_groups ORDER BY lower(name),product_id,name,unit_value,unit_type LIMIT ${q.limit??20} OFFSET ${q.offset??0}`;
    const [totals]=await tx.$queryRaw<{total:number;totalProductSalesPaise:string}[]>`${cte} SELECT COUNT(*)::int AS total,COALESCE(SUM(amount),0)::text AS "totalProductSalesPaise" FROM product_groups`;
    return {...range,items,...totals!};
  });}
}
