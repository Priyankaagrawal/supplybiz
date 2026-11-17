// T-074 / RULE-20: actor -> vendor -> order locks; no financial reversal or resurrection.
import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { PLAN_FEATURES } from '../plans/plan-policy';
import { dateOnly, dayString, SubscriptionClock, subscriptionForDate, subscriptionRead } from '../subscriptions/subscription-policy';
import { AvailabilityPatch, HolidayInput, HolidayQuery } from './availability.dto';
type Tx=Prisma.TransactionClient;
const cancellable=['NEW','ACCEPTED','PREPARING'];
function unavailable(error:unknown):never {if(error instanceof HttpException)throw error;throw new ServiceUnavailableException({code:'AVAILABILITY_UNAVAILABLE'});}
@Injectable()
export class AvailabilityService {
  constructor(private readonly db:PrismaService,private readonly plans:PlanEntitlementsService,private readonly keys:IdempotencyService,
    private readonly notifications:NotificationsService,private readonly clock:SubscriptionClock){}
  private async vendor(tx:Tx,userId:string) {
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
    const user=await tx.users.findUnique({where:{id:userId},include:{roles:true,vendor:true}});
    if(!user || user.status!=='ACTIVE' || user.active_role!=='VENDOR' || !user.roles.some(r=>r.role==='VENDOR'))throw new ForbiddenException({code:'VENDOR_ROLE_REQUIRED'});
    if(!user.vendor)throw new NotFoundException({code:'VENDOR_NOT_FOUND'});
    await tx.$queryRaw`SELECT id FROM vendors WHERE id=${user.vendor.id}::uuid FOR UPDATE`;
    const vendor=await tx.vendors.findUniqueOrThrow({where:{id:user.vendor.id}});
    if(vendor.is_suspended)throw new ForbiddenException({code:'VENDOR_SUSPENDED'});
    await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');return vendor;
  }
  private async snapshot(tx:Tx,vendorId:string) {
    const row=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}}),state=await this.plans.resolve(tx,vendorId),clock=await this.clock.now(tx);
    return {version:row.version,acceptingToday:row.accepting_today,deliveryPaused:row.delivery_paused,deliveryPausedUntil:row.delivery_paused_until?.toISOString()??null,
      canResume:!!(state.active&&state.assignment&&PLAN_FEATURES[state.assignment.plan.code].includes('BASIC_ORDER_MANAGEMENT')),canReduceActivity:true,
      serverTime:clock.now.toISOString(),businessDate:clock.day};
  }
  get(userId:string){return this.db.$transaction(async tx=>this.snapshot(tx,(await this.vendor(tx,userId)).id)).catch(unavailable);}
  private where(vendorId:string,day:string,all:boolean) {return {vendor_id:vendorId,delivery_date:all?{gte:dateOnly(day)}:dateOnly(day),status:{in:cancellable}};}
  impact(userId:string,date?:string){return this.db.$transaction(async tx=>{
    const v=await this.vendor(tx,userId),clock=await this.clock.now(tx);if(date && (dateOnly(date),date<clock.day))throw new UnprocessableEntityException({code:'HOLIDAY_IN_PAST'});
    return {affectedOrders:await tx.orders.count({where:this.where(v.id,date??clock.day,date===undefined)}),serverTime:clock.now.toISOString(),businessDate:clock.day};
  }).catch(unavailable);}
  list(userId:string,q:HolidayQuery){return this.db.$transaction(async tx=>{
    const v=await this.vendor(tx,userId),clock=await this.clock.now(tx),where={vendor_id:v.id,date:{gte:dateOnly(clock.day)}};
    const rows=await tx.vendor_holidays.findMany({where,orderBy:[{date:'asc'},{id:'asc'}],take:q.limit??20,skip:q.offset??0});
    return {items:rows.map(r=>({id:r.id,date:dayString(r.date),reason:r.reason})),total:await tx.vendor_holidays.count({where}),serverTime:clock.now.toISOString(),businessDate:clock.day};
  }).catch(unavailable);}
  private async cancel(tx:Tx,vendorId:string,day:string,all:boolean,reason:string) {
    let count=0;
    while(true){
      const rows=await tx.orders.findMany({where:this.where(vendorId,day,all),include:{customer:true},orderBy:{id:'asc'},take:100});
      if(!rows.length)return count;
      for(const order of rows){
        await tx.$queryRaw`SELECT id FROM orders WHERE id=${order.id}::uuid FOR UPDATE`;
        const changed=await tx.orders.updateMany({where:{id:order.id,version:order.version,status:{in:cancellable}},data:{status:'CANCELLED',cancel_reason:reason,version:{increment:1}}});
        if(changed.count!==1)throw new ConflictException({code:'VERSION_CONFLICT'});
        await tx.order_status_events.create({data:{order_id:order.id,status:'CANCELLED',reason}});
        if(order.customer.user_id)await this.notifications.enqueue(tx,{recipientId:order.customer.user_id,role:'CUSTOMER',type:'ORDER_CANCELLED_CUSTOMER',entityId:order.id,sourceKey:`order:${order.id}:${order.version+1}`});
        count++;
      }
    }
  }
  private async notifySubscribers(tx:Tx,vendorId:string,day:string,source:string,type:'VENDOR_HOLIDAY'|'VENDOR_DELIVERY_PAUSED'|'VENDOR_DELIVERY_RESUMED') {
    let cursor:string|undefined;const notified=new Set<string>(),settings=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}});
    while(true){
      const rows=await tx.subscriptions.findMany({where:{vendor_id:vendorId,...(cursor?{id:{gt:cursor}}:{}),OR:[{end_date:null},{end_date:{gte:dateOnly(day)}}]},include:subscriptionRead,orderBy:{id:'asc'},take:100});
      if(!rows.length)return;
      for(const row of rows){
        const recipient=row.customer.user_id;
        const affected=type==='VENDOR_HOLIDAY'?!!subscriptionForDate(row,day,settings):row.revisions.at(-1)?.status==='ACTIVE';
        if(recipient&&affected&&!notified.has(recipient)){
          await this.notifications.enqueue(tx,{recipientId:recipient,role:'CUSTOMER',type,sourceKey:`${source}:${recipient}`});notified.add(recipient);
        }
      }
      cursor=rows.at(-1)!.id;
    }
  }
  patch(userId:string,key:string,input:AvailabilityPatch){return this.mutate(userId,key,'PATCH availability',input,async(tx,vendorId)=>{
    const before=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}}),clock=await this.clock.now(tx);
    if(before.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});
    if(input.acceptingToday===undefined && input.deliveryPaused===undefined)throw new BadRequestException({code:'EMPTY_PATCH'});
    if(input.acceptingToday===true || input.deliveryPaused===false)await this.plans.requireOperation(tx,vendorId,'NEW_ORDER');
    await tx.vendor_settings.update({where:{vendor_id:vendorId},data:{accepting_today:input.acceptingToday,delivery_paused:input.deliveryPaused,
      delivery_paused_until:input.deliveryPaused===undefined?undefined:null,version:{increment:1}}});
    const cancelledOrders=input.deliveryPaused===true?await this.cancel(tx,vendorId,clock.day,true,'Vendor deliveries paused'):0;
    if(input.deliveryPaused!==undefined&&(before.delivery_paused!==input.deliveryPaused||before.delivery_paused_until!==null))await this.notifySubscribers(tx,vendorId,clock.day,`availability:${vendorId}:${before.version+1}`,input.deliveryPaused?'VENDOR_DELIVERY_PAUSED':'VENDOR_DELIVERY_RESUMED');
    const availability=await this.snapshot(tx,vendorId);
    await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'VENDOR_AVAILABILITY_UPDATED',entity:'VENDOR',entity_id:vendorId,
      before:{version:before.version,acceptingToday:before.accepting_today,deliveryPaused:before.delivery_paused},after:{...availability,cancelledOrders}}});
    return {availability,cancelledOrders};
  });}
  create(userId:string,key:string,input:HolidayInput){return this.mutate(userId,key,'POST holiday',input,async(tx,vendorId)=>{
    const clock=await this.clock.now(tx),date=dateOnly(input.date),reason=input.reason.trim();
    if(input.date<clock.day)throw new UnprocessableEntityException({code:'HOLIDAY_IN_PAST'});
    if(!reason || reason.length>100)throw new BadRequestException({code:'INVALID_HOLIDAY_REASON'});
    if(await tx.vendor_holidays.findUnique({where:{vendor_id_date:{vendor_id:vendorId,date}}}))throw new ConflictException({code:'HOLIDAY_EXISTS'});
    const row=await tx.vendor_holidays.create({data:{vendor_id:vendorId,date,reason}}),cancelledOrders=await this.cancel(tx,vendorId,input.date,false,'Vendor holiday');
    await this.notifySubscribers(tx,vendorId,input.date,`holiday:${row.id}`,'VENDOR_HOLIDAY');
    await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'VENDOR_HOLIDAY_CREATED',entity:'VENDOR',entity_id:vendorId,after:{holidayId:row.id,date:input.date,cancelledOrders}}});
    return {holiday:{id:row.id,date:input.date,reason},cancelledOrders};
  });}
  delete(userId:string,key:string,id:string){return this.mutate(userId,key,`DELETE holiday/${id}`,{},async(tx,vendorId)=>{
    const row=await tx.vendor_holidays.findFirst({where:{id,vendor_id:vendorId}});if(!row)throw new NotFoundException({code:'HOLIDAY_NOT_FOUND'});
    const clock=await this.clock.now(tx);if(dayString(row.date)<=clock.day)throw new ConflictException({code:'HOLIDAY_NOT_FUTURE'});
    await this.plans.requireOperation(tx,vendorId,'NEW_ORDER');await tx.vendor_holidays.delete({where:{id}});
    await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'VENDOR_HOLIDAY_DELETED',entity:'VENDOR',entity_id:vendorId,before:{holidayId:id,date:dayString(row.date)}}});
    return {id,deleted:true};
  });}
  private async mutate(userId:string,key:string,path:string,input:object,write:(tx:Tx,vendorId:string)=>Promise<object>){
    if(typeof key!=='string'||!key.trim()||key.length>120)throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    return this.db.$transaction(async tx=>{
      const v=await this.vendor(tx,userId),requestKey=createHash('sha256').update(`${userId}:${key}`).digest('hex'),hash=this.keys.hashRequestBody(input);
      const known=await tx.vendor_operation_requests.findUnique({where:{request_key:requestKey}});
      if(known){if(known.path!==path||known.request_hash!==hash)throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});return known.response;}
      const result=await write(tx,v.id);
      await tx.vendor_operation_requests.create({data:{request_key:requestKey,user_id:userId,path,request_hash:hash,response:result as Prisma.InputJsonObject}});
      return result;
    },{timeout:45000}).catch(unavailable);
  }
}
