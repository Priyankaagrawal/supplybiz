import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, vendor_settings } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { PLAN_FEATURES } from '../plans/plan-policy';
import { SubscriptionClock } from './subscription-policy';
import { SubscriptionQuery } from './subscriptions.dto';
import { SubscriptionSettingsPatch, SubscriptionSettingsSummary } from './subscription-settings.dto';
type Tx=Prisma.TransactionClient;
type Entitlement=Awaited<ReturnType<PlanEntitlementsService['resolve']>>;
const time=(value:Date|null)=>value?value.toISOString().slice(11,16):null;
const storedTime=(value:string|null)=>value===null?null:new Date(`2000-01-01T${value}:00Z`);
export function capacityMl(value:string) {
  if(!/^(0|[1-9]\d{0,6})(\.\d{1,3})?$/.test(value)) throw new BadRequestException({code:'INVALID_MILK_CAPACITY'});
  const [whole,fraction='']=value.split('.'),ml=BigInt(whole!)*1000n+BigInt(fraction.padEnd(3,'0'));
  if(ml<=0n || ml>2147483647n) throw new BadRequestException({code:'INVALID_MILK_CAPACITY'});
  return Number(ml);
}
export function capacityLitres(value:number|null) {
  if(value===null) return null;
  const ml=BigInt(value),fraction=String(ml%1000n).padStart(3,'0').replace(/0+$/,'');
  return `${ml/1000n}${fraction?`.${fraction}`:''}`;
}
function unavailable(error:unknown):never {
  if(error instanceof HttpException) throw error;
  throw new ServiceUnavailableException({code:'SUBSCRIPTION_SETTINGS_UNAVAILABLE'});
}
@Injectable()
export class SubscriptionSettingsService {
  constructor(private readonly db:PrismaService,private readonly plans:PlanEntitlementsService,
    private readonly keys:IdempotencyService,private readonly clock:SubscriptionClock) {}
  private async vendor(tx:Tx,userId:string,write=false) {
    if(write) await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
    const user=await tx.users.findUnique({where:{id:userId},include:{roles:true,vendor:true}});
    if(!user || user.status!=='ACTIVE' || user.active_role!=='VENDOR' || !user.roles.some(r=>r.role==='VENDOR')) throw new ForbiddenException({code:'VENDOR_ROLE_REQUIRED'});
    if(!user.vendor) throw new ConflictException({code:'VENDOR_NOT_FOUND'});
    await tx.$queryRaw`SELECT id FROM vendors WHERE id=${user.vendor.id}::uuid FOR UPDATE`;
    const vendor=await tx.vendors.findUniqueOrThrow({where:{id:user.vendor.id}});
    if(vendor.is_suspended) throw new ForbiddenException({code:'VENDOR_SUSPENDED'});
    return vendor;
  }
  private controls(row:vendor_settings) {
    return {version:row.version,autoAcceptSubscriptions:row.auto_accept_subscriptions,
      deliveryAvailable:row.subscription_delivery_available,deliveryStartTime:time(row.subscription_delivery_start),deliveryEndTime:time(row.subscription_delivery_end),
      maxDailyOrders:row.max_daily_orders,dailyMilkCapacityLitres:capacityLitres(row.daily_milk_capacity_ml),pauseAllSubscriptions:row.pause_all_subscriptions};
  }
  private current(vendorId:string,day:string) {
    return Prisma.sql`WITH current_subscriptions AS (
      SELECT s.id,s.vendor_customer_id, CASE WHEN r.status<>'ACTIVE' THEN r.status
        WHEN s.end_date<${day}::date THEN 'COMPLETED'
        WHEN EXISTS(SELECT 1 FROM subscription_pauses p WHERE p.subscription_id=s.id
          AND p.from_date<=${day}::date AND (p.to_date IS NULL OR p.to_date>=${day}::date)
          AND (p.resumed_from IS NULL OR p.resumed_from>${day}::date)) THEN 'PAUSED'
        ELSE 'ACTIVE' END AS status
      FROM subscriptions s JOIN LATERAL(SELECT status FROM subscription_revisions
        WHERE subscription_id=s.id ORDER BY version DESC LIMIT 1) r ON TRUE
      WHERE s.vendor_id=${vendorId}::uuid)`;
  }
  private async snapshot(tx:Tx,vendorId:string,state:Entitlement) {
    const row=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}}),clock=await this.clock.now(tx);
    const [summary]=await tx.$queryRaw<SubscriptionSettingsSummary[]>`${this.current(vendorId,clock.day)}
      SELECT COUNT(*)::int AS "totalSubscriptions", COUNT(*) FILTER(WHERE status='ACTIVE')::int AS active,
      COUNT(*) FILTER(WHERE status='PAUSED')::int AS paused,COUNT(*) FILTER(WHERE status='PENDING_APPROVAL')::int AS "pendingApproval",
      COUNT(*) FILTER(WHERE status='CANCELLED')::int AS cancelled,COUNT(*) FILTER(WHERE status='REJECTED')::int AS rejected,
      COUNT(*) FILTER(WHERE status='COMPLETED')::int AS completed,
      (SELECT COUNT(DISTINCT c.id)::int FROM current_subscriptions a JOIN vendor_customers c ON c.id=a.vendor_customer_id
        WHERE c.vendor_id=${vendorId}::uuid AND c.deleted_at IS NULL AND a.status IN ('ACTIVE','PAUSED')) AS "subscriptionCustomers"
      FROM current_subscriptions`;
    const features=state.active && state.assignment?PLAN_FEATURES[state.assignment.plan.code]:[];
    const canAutoAccept=features.includes('AUTO_ACCEPT');
    return {...this.controls(row),serverTime:clock.now.toISOString(),businessDate:clock.day,canAutoAccept,
      effectiveAutoAcceptSubscriptions:canAutoAccept && row.auto_accept_subscriptions,
      canEditSubscriptions:features.includes('SUBSCRIPTIONS'),canReduceActivity:true,summary:{...summary!}};
  }
  get(userId:string) {
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId),state=await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');
      return this.snapshot(tx,vendor.id,state);
    },{timeout:15000}).catch(unavailable);
  }
  patch(userId:string,key:string,input:SubscriptionSettingsPatch) {
    if(typeof key!=='string' || !key.trim() || key.length>120) throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    const requestKey=`subscription-settings:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`,hash=this.keys.hashRequestBody(input);
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId,true),state=await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');
      const cached=await tx.idempotency_keys.findUnique({where:{idempotency_key:requestKey}});
      if(cached && cached.expires_at>new Date()) {
        if(cached.method!=='PATCH' || cached.path!=='subscription-settings' || cached.request_hash!==hash) throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
        return cached.response_body;
      }
      const fields=Object.keys(input).filter(k=>k!=='version');
      if(!fields.length) throw new BadRequestException({code:'EMPTY_PATCH'});
      if([input.clearDeliveryWindow,input.clearMaxDailyOrders,input.clearDailyMilkCapacity].some(v=>v===false) ||
        input.clearDeliveryWindow && (input.deliveryStartTime!=null || input.deliveryEndTime!=null) ||
        input.clearMaxDailyOrders && input.maxDailyOrders!=null || input.clearDailyMilkCapacity && input.dailyMilkCapacityLitres!=null) {
        throw new BadRequestException({code:'INVALID_CLEAR_SELECTION'});
      }
      const before=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendor.id}});
      if(before.version!==input.version) throw new ConflictException({code:'VERSION_CONFLICT'});
      const reducing=fields.every(k=>k==='autoAcceptSubscriptions' && input.autoAcceptSubscriptions===false || k==='pauseAllSubscriptions' && input.pauseAllSubscriptions===true || k==='deliveryAvailable' && input.deliveryAvailable===false);
      if(!reducing) await this.plans.requireOperation(tx,vendor.id,'SUBSCRIPTION');
      if(input.autoAcceptSubscriptions===true) await this.plans.requireFeature(tx,vendor.id,'AUTO_ACCEPT');
      const start=input.clearDeliveryWindow?null:input.deliveryStartTime===undefined?time(before.subscription_delivery_start):input.deliveryStartTime;
      const end=input.clearDeliveryWindow?null:input.deliveryEndTime===undefined?time(before.subscription_delivery_end):input.deliveryEndTime;
      if((start===null)!==(end===null) || start!==null && start===end) throw new BadRequestException({code:'INVALID_DELIVERY_WINDOW'});
      const update=await tx.vendor_settings.updateMany({where:{vendor_id:vendor.id,version:input.version},data:{
        auto_accept_subscriptions:input.autoAcceptSubscriptions,subscription_delivery_available:input.deliveryAvailable,
        subscription_delivery_start:input.clearDeliveryWindow?null:input.deliveryStartTime===undefined?undefined:storedTime(input.deliveryStartTime),
        subscription_delivery_end:input.clearDeliveryWindow?null:input.deliveryEndTime===undefined?undefined:storedTime(input.deliveryEndTime),
        max_daily_orders:input.clearMaxDailyOrders?null:input.maxDailyOrders,daily_milk_capacity_ml:input.clearDailyMilkCapacity?null:input.dailyMilkCapacityLitres===undefined?undefined:
          input.dailyMilkCapacityLitres===null?null:capacityMl(input.dailyMilkCapacityLitres),
        pause_all_subscriptions:input.pauseAllSubscriptions,version:{increment:1}}});
      if(update.count!==1) throw new ConflictException({code:'VERSION_CONFLICT'});
      const after=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendor.id}});
      await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'SUBSCRIPTION_SETTINGS_UPDATED',entity:'VENDOR',entity_id:vendor.id,
        before:this.controls(before),after:this.controls(after)}});
      const response=await this.snapshot(tx,vendor.id,state);
      await tx.idempotency_keys.upsert({where:{idempotency_key:requestKey},create:{idempotency_key:requestKey,user_id:userId,method:'PATCH',path:'subscription-settings',request_hash:hash,response_status:200,response_body:response,expires_at:new Date(Date.now()+86400000)},
        update:{request_hash:hash,response_body:response,expires_at:new Date(Date.now()+86400000)}});
      return response;
    },{timeout:15000}).catch(unavailable);
  }
  customers(userId:string,q:SubscriptionQuery) {
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId);await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');
      const clock=await this.clock.now(tx);
      const items=await tx.$queryRaw<{id:string;name:string;mobile:string;status:string;activeSubscriptions:number;pausedSubscriptions:number}[]>`${this.current(vendor.id,clock.day)}
        SELECT c.id,c.name,c.mobile,c.status,COUNT(*) FILTER(WHERE a.status='ACTIVE')::int AS "activeSubscriptions",
          COUNT(*) FILTER(WHERE a.status='PAUSED')::int AS "pausedSubscriptions"
        FROM current_subscriptions a JOIN vendor_customers c ON c.id=a.vendor_customer_id
        WHERE c.vendor_id=${vendor.id}::uuid AND c.deleted_at IS NULL AND a.status IN ('ACTIVE','PAUSED')
        GROUP BY c.id ORDER BY c.name,c.id LIMIT ${q.limit??20} OFFSET ${q.offset??0}`;
      const [count]=await tx.$queryRaw<{total:number}[]>`${this.current(vendor.id,clock.day)}
        SELECT COUNT(DISTINCT c.id)::int AS total FROM current_subscriptions a JOIN vendor_customers c ON c.id=a.vendor_customer_id
        WHERE c.vendor_id=${vendor.id}::uuid AND c.deleted_at IS NULL AND a.status IN ('ACTIVE','PAUSED')`;
      return {items,total:count!.total,serverTime:clock.now.toISOString(),businessDate:clock.day};
    },{timeout:15000}).catch(unavailable);
  }
}
