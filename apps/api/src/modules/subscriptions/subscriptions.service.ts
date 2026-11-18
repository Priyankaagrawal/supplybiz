// T-072: all consent, config, references and notices commit in the same transaction.
import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, user_role_type } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AddressesService } from '../addresses/addresses.service';
import { CatalogService } from '../catalog/catalog.service';
import { CustomersService } from '../customers/customers.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationEvent } from '../notifications/notification-events';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { PLAN_FEATURES } from '../plans/plan-policy';
import { VendorsService } from '../vendors/vendors.service';
import { CustomerSubscriptionInput, SubscriptionPatch, SubscriptionPause, SubscriptionQuery, SubscriptionReject, SubscriptionSkip, SubscriptionVersion, VendorSubscriptionInput } from './subscriptions.dto';
import { addDays, dateOnly, dayString, effectiveDay, monthlyEstimate, pausedOn, SubscriptionClock, subscriptionRead, SubscriptionRead } from './subscription-policy';
import { SubscriptionGenerationService } from './subscription-generation.service';
import { KhataReadService } from '../khata/khata-read.service';
import { KhataMonthQuery } from '../khata/khata.dto';
import { khataMonth } from '../khata/khata-access.service';
type Tx=Prisma.TransactionClient;
type Action='EDIT'|'APPROVE'|'REJECT'|'PAUSE'|'RESUME'|'CANCEL'|'SKIP';
const mask=(days:number[])=>days.reduce((m,d)=>m|(1<<(d-1)),0);
const days=(value:number)=>Array.from({length:7},(_,i)=>i+1).filter(d=>value&(1<<(d-1)));
function unavailable(error:unknown):never {
  if(error instanceof HttpException) throw error;
  if(error instanceof Prisma.PrismaClientKnownRequestError && error.code==='P2002') throw new ConflictException({code:'DUPLICATE'});
  throw new ServiceUnavailableException({code:'SUBSCRIPTIONS_UNAVAILABLE'});
}
@Injectable()
export class SubscriptionsService {
  constructor(private readonly db:PrismaService,private readonly keys:IdempotencyService,
    private readonly catalog:CatalogService,private readonly customers:CustomersService,
    private readonly addresses:AddressesService,private readonly vendors:VendorsService,
    private readonly plans:PlanEntitlementsService,private readonly notifications:NotificationsService,
    private readonly clock:SubscriptionClock,private readonly generation:SubscriptionGenerationService,
    private readonly khata:KhataReadService) {}
  private async actor(tx:Tx,id:string,role:user_role_type) {
    const user=await tx.users.findUnique({where:{id},include:{roles:true,vendor:true}});
    if(!user || user.status!=='ACTIVE' || user.active_role!==role || !user.roles.some(r=>r.role===role)) throw new ForbiddenException({code:`${role}_ROLE_REQUIRED`});
    if(role==='VENDOR' && (!user.vendor || user.vendor.is_suspended)) throw new ForbiddenException({code:'VENDOR_UNAVAILABLE'});
    return user;
  }
  private async scope(tx:Tx,userId:string,role:user_role_type) {
    const user=await this.actor(tx,userId,role);
    return role==='VENDOR'?{vendor_id:user.vendor!.id}:{customer:{user_id:userId}};
  }
  private async owned(tx:Tx,userId:string,role:user_role_type,id:string) {
    const row=await tx.subscriptions.findFirst({where:{id,...await this.scope(tx,userId,role)},include:subscriptionRead});
    if(!row) throw new NotFoundException({code:'SUBSCRIPTION_NOT_FOUND'});
    return row;
  }
  private async available(tx:Tx,vendorId:string,customer=false) {
    const v=await tx.vendors.findUnique({where:{id:vendorId},include:{settings:true,user:true,category:true}});
    if(!v || v.is_suspended || v.user.status!=='ACTIVE' || !v.settings ||
      customer && (v.kyc_status!=='VERIFIED' || v.category.status!=='ENABLED' || v.category.type!=='SUPPLY')) throw new NotFoundException({code:'VENDOR_UNAVAILABLE'});
    const entitlement=await this.plans.requireOperation(tx,vendorId,'SUBSCRIPTION');
    return {v,entitlement};
  }
  private async lockVendor(tx:Tx,id:string) {await tx.$queryRaw`SELECT id FROM vendors WHERE id=${id}::uuid FOR UPDATE`;}
  private async product(tx:Tx,vendorId:string,id:string,slot:string) {
    await tx.$queryRaw`SELECT id FROM products WHERE id=${id}::uuid AND vendor_id=${vendorId}::uuid FOR UPDATE`;
    const product=await this.catalog.requireSelectable(tx,vendorId,id);
    const settings=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}});
    if(!Array.isArray(settings.time_slots) || !settings.time_slots.includes(slot)) throw new UnprocessableEntityException({code:'INVALID_TIME_SLOT'});
    return product;
  }
  private mutation(userId:string,role:user_role_type,key:string,path:string,input:object,
    write:(tx:Tx)=>Promise<{id:string;version:number;status:string;effectiveFrom:string}>) {
    if(typeof key!=='string' || !key.trim() || key.length>120) throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    const requestKey=createHash('sha256').update(`${userId}:${key}`).digest('hex'),hash=this.keys.hashRequestBody(input);
    return this.db.$transaction(async tx=>{
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
      await this.actor(tx,userId,role);
      const prior=await tx.subscription_requests.findUnique({where:{request_key:requestKey}});
      if(prior) {
        if(prior.path!==`${role}/${path}` || prior.request_hash!==hash) throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
        await this.owned(tx,userId,role,(prior.response as {id:string}).id);
        return prior.response;
      }
      const response=await write(tx);
      await tx.subscription_requests.create({data:{request_key:requestKey,user_id:userId,path:`${role}/${path}`,request_hash:hash,response}});
      return response;
    },{timeout:15000}).catch(unavailable);
  }
  create(userId:string,role:user_role_type,key:string,input:CustomerSubscriptionInput|VendorSubscriptionInput) {
    return this.mutation(userId,role,key,'create',input,async tx=>{
      const user=await this.actor(tx,userId,role),cInput=input as CustomerSubscriptionInput,vInput=input as VendorSubscriptionInput;
      const vendorId=role==='CUSTOMER'?cInput.vendorId:user.vendor!.id;
      await this.lockVendor(tx,vendorId);
      const {v,entitlement}=await this.available(tx,vendorId,role==='CUSTOMER');
      if(role==='CUSTOMER' && v.user_id===userId) throw new UnprocessableEntityException({code:'SELF_SUBSCRIPTION_NOT_ALLOWED'});
      await this.product(tx,vendorId,input.productId,input.timeSlot);
      const clock=await this.clock.now(tx),start=dateOnly(input.startDate),end=input.endDate?dateOnly(input.endDate):null;
      if(input.startDate<addDays(clock.day,1) || end && end<start) throw new UnprocessableEntityException({code:'INVALID_SUBSCRIPTION_DATES'});
      let customer;
      let address:Prisma.InputJsonObject;
      if(role==='CUSTOMER') {
        const a=await this.addresses.requireOwned(tx,userId,cInput.addressId);
        if(!await this.vendors.covers(vendorId,a.latitude,a.longitude,a.pincode,tx)) throw new UnprocessableEntityException({code:'NOT_SERVICEABLE'});
        address={label:a.label,line1:a.line1,line2:a.line2,city:a.city,state:a.state,pincode:a.pincode,latitude:a.latitude,longitude:a.longitude};
        customer=await tx.vendor_customers.findFirst({where:{vendor_id:vendorId,mobile:user.mobile,deleted_at:null}});
        if(customer && customer.user_id!==userId) throw new ConflictException({code:'CUSTOMER_LINK_REQUIRED'});
        if(!customer) {
          await this.customers.requireCapacity(tx,vendorId);
          customer=await tx.vendor_customers.create({data:{vendor_id:vendorId,user_id:userId,name:user.name??'Customer',mobile:user.mobile,preferred_payment:input.paymentMethod}});
        }
      } else {
        if((vInput.vendorCustomerId!==undefined)===(vInput.newCustomer!==undefined)) throw new BadRequestException({code:'CUSTOMER_SELECTION_REQUIRED'});
        if(vInput.newCustomer) {
          await this.customers.requireCapacity(tx,vendorId);
          const n=vInput.newCustomer;
          customer=await tx.vendor_customers.create({data:{vendor_id:vendorId,name:n.name,mobile:n.mobile.startsWith('+91')?n.mobile:`+91${n.mobile}`,
            email:n.email,address_text:n.address,preferred_payment:n.preferredPayment}});
        } else customer=await tx.vendor_customers.findFirst({where:{id:vInput.vendorCustomerId!,vendor_id:vendorId,deleted_at:null}});
        if(!customer) throw new NotFoundException({code:'CUSTOMER_NOT_FOUND'});
        address={text:customer.address_text};
      }
      if(customer.status!=='ACTIVE') throw new ForbiddenException({code:'CUSTOMER_INACTIVE'});
      const auto=!!(v.settings!.auto_accept_subscriptions && entitlement.assignment && PLAN_FEATURES[entitlement.assignment.plan.code].includes('AUTO_ACCEPT'));
      const status=role==='VENDOR'||auto?'ACTIVE':'PENDING_APPROVAL';
      const row=await tx.subscriptions.create({data:{vendor_id:vendorId,vendor_customer_id:customer.id,product_id:input.productId,
        start_date:start,end_date:end,address_snapshot:address,payment_method:input.paymentMethod,created_by:role,creator_user_id:userId,
        revisions:{create:{version:1,effective_from:start,qty:input.qty,weekdays:mask(input.weekdays),time_slot:input.timeSlot,status,action:'CREATE',actor_id:userId}}}});
      await this.references(tx,row.id,customer.id,input.productId,status);
      if(role==='CUSTOMER') await this.notifications.enqueue(tx,{recipientId:v.user_id,role:'VENDOR',type:status==='PENDING_APPROVAL'?'SUBSCRIPTION_REQUEST':'SUBSCRIPTION_CHANGED_VENDOR',sourceKey:`sub:${row.id}:1:vendor`,entityId:row.id});
      if(status==='ACTIVE' && customer.user_id) await this.notifications.enqueue(tx,{recipientId:customer.user_id,role:'CUSTOMER',type:'SUBSCRIPTION_APPROVED',sourceKey:`sub:${row.id}:1:customer`,entityId:row.id});
      await this.generation.scheduleCreated(tx,row.id,vendorId,input.startDate);
      return {id:row.id,version:1,status,effectiveFrom:input.startDate};
    });
  }
  private async references(tx:Tx,id:string,customerId:string,productId:string,status:string) {
    const refStatus=(status==='PENDING_APPROVAL'?'PENDING':status) as 'ACTIVE'|'PAUSED'|'PENDING'|'CANCELLED'|'REJECTED';
    await this.customers.setSubscriptionReference(tx,id,customerId,refStatus);
    await this.catalog.setSubscriptionReference(tx,id,productId,refStatus);
  }
  change(userId:string,role:user_role_type,key:string,id:string,action:Action,input:SubscriptionVersion|SubscriptionPatch|SubscriptionPause|SubscriptionSkip|SubscriptionReject) {
    return this.mutation(userId,role,key,`${id}/${action}`,input,async tx=>{
      let row=await this.owned(tx,userId,role,id);
      await this.lockVendor(tx,row.vendor_id);
      row=await this.owned(tx,userId,role,id);
      if(row.version!==input.version) throw new ConflictException({code:'VERSION_CONFLICT'});
      const latest=row.revisions.at(-1)!;
      const clock=await this.clock.now(tx);
      if(['CANCELLED','REJECTED'].includes(latest.status) || row.end_date && dayString(row.end_date)<clock.day) throw new ConflictException({code:'INVALID_SUBSCRIPTION_STATE'});
      let effective=[dayString(row.start_date),effectiveDay(clock.now)].sort().at(-1)!;
      let status=latest.status,qty=latest.qty,weekdays=latest.weekdays,slot=latest.time_slot;
      if(['APPROVE','REJECT'].includes(action)) {
        if(role!=='VENDOR' || status!=='PENDING_APPROVAL') throw new ConflictException({code:'INVALID_SUBSCRIPTION_STATE'});
        status=action==='APPROVE'?'ACTIVE':'REJECTED';
      } else if(status!=='ACTIVE' && action!=='CANCEL') throw new ConflictException({code:'INVALID_SUBSCRIPTION_STATE'});
      if(['EDIT','APPROVE','RESUME'].includes(action)) {
        await this.available(tx,row.vendor_id,role==='CUSTOMER');
        if(row.customer.deleted_at || row.customer.status!=='ACTIVE') throw new ForbiddenException({code:'CUSTOMER_INACTIVE'});
      }
      if(action==='EDIT') {
        const patch=input as SubscriptionPatch;
        if(patch.qty===undefined && patch.weekdays===undefined && patch.timeSlot===undefined) throw new BadRequestException({code:'EMPTY_PATCH'});
        qty=patch.qty??qty;weekdays=patch.weekdays?mask(patch.weekdays):weekdays;slot=patch.timeSlot??slot;
        const last=await tx.orders.findFirst({where:{subscription_id:id},orderBy:{delivery_date:'desc'}});
        if(last) effective=[effective,addDays(dayString(last.delivery_date),1)].sort().at(-1)!;
      }
      if(['EDIT','APPROVE','RESUME'].includes(action)) await this.product(tx,row.vendor_id,row.product_id,slot);
      if(action==='CANCEL') status='CANCELLED';
      if(action==='PAUSE') {
        const p=input as SubscriptionPause,from=p.fromDate??effective,to=p.toDate?dateOnly(p.toDate):null;
        dateOnly(from);
        if(from<effective) throw new UnprocessableEntityException({code:'PAST_CUTOFF',detail:`Changes can first apply on ${effective}. Customer changes close at 21:00 IST on the previous day.`});
        if(to && dayString(to)<from || row.end_date && from>dayString(row.end_date)) throw new UnprocessableEntityException({code:'INVALID_PAUSE_DATES'});
        effective=from;
        await tx.subscription_pauses.create({data:{subscription_id:id,from_date:dateOnly(from),to_date:to}});
      }
      if(action==='RESUME') {
        const active=row.pauses.filter(p=>(!p.to_date || dayString(p.to_date)>=effective) && (!p.resumed_from || dayString(p.resumed_from)>effective));
        if(!active.length) throw new ConflictException({code:'SUBSCRIPTION_NOT_PAUSED'});
        await tx.subscription_pauses.updateMany({where:{id:{in:active.map(p=>p.id)}},data:{resumed_from:dateOnly(effective)}});
      }
      if(action==='SKIP') {
        const date=(input as SubscriptionSkip).date;dateOnly(date);
        if(date<clock.day || date<dayString(row.start_date) || row.end_date && date>dayString(row.end_date)) throw new UnprocessableEntityException({code:'INVALID_SKIP_DATE'});
        if(role==='CUSTOMER' && date<effective) throw new UnprocessableEntityException({code:'PAST_CUTOFF',detail:`Changes can first apply on ${effective}. Customer changes close at 21:00 IST on the previous day.`});
        effective=date;
        const generated=await tx.orders.findFirst({where:{subscription_id:id,delivery_date:dateOnly(date)}});
        if(generated) {
          if(!['NEW','ACCEPTED'].includes(generated.status)) throw new ConflictException({code:'GENERATED_ORDER_NOT_CANCELLABLE'});
          await tx.orders.update({where:{id:generated.id},data:{status:'CANCELLED',cancel_reason:'SUBSCRIPTION_SKIP',version:{increment:1}}});
          await tx.order_status_events.create({data:{order_id:generated.id,status:'CANCELLED',reason:'SUBSCRIPTION_SKIP'}});
          const v=await tx.vendors.findUniqueOrThrow({where:{id:row.vendor_id}});
          await this.notifications.enqueue(tx,{recipientId:v.user_id,role:'VENDOR',type:'ORDER_CANCELLED',sourceKey:`sub:${id}:skip:${date}:vendor`,entityId:generated.id});
        }
        await tx.subscription_skips.upsert({where:{subscription_id_date:{subscription_id:id,date:dateOnly(date)}},create:{subscription_id:id,date:dateOnly(date)},update:{}});
      }
      if(row.end_date && effective>dayString(row.end_date) && action!=='CANCEL') throw new UnprocessableEntityException({code:'SUBSCRIPTION_ENDED'});
      const version=row.version+1;
      await tx.subscriptions.update({where:{id},data:{version}});
      await tx.subscription_revisions.create({data:{subscription_id:id,version,effective_from:dateOnly(effective),qty,weekdays,time_slot:slot,status,action,
        reason:action==='REJECT'?(input as SubscriptionReject).reason:null,actor_id:userId}});
      // Keep conservative deletion/filter guards for frozen dates until T-073 advances them.
      const referenceStatus=['CANCELLED','REJECTED'].includes(status) && effective>addDays(clock.day,1) && latest.status==='ACTIVE'?'ACTIVE':status;
      await this.references(tx,id,row.vendor_customer_id,row.product_id,action==='PAUSE'?'PAUSED':referenceStatus);
      await this.notice(tx,row,role,action,version);
      return {id,version,status:action==='PAUSE'?'PAUSED':status,effectiveFrom:effective};
    });
  }
  private async notice(tx:Tx,row:SubscriptionRead,role:user_role_type,action:Action,version:number) {
    const type:NotificationEvent['type']=action==='APPROVE'?'SUBSCRIPTION_APPROVED':action==='REJECT'?'SUBSCRIPTION_REJECTED':action==='PAUSE'?'SUBSCRIPTION_PAUSED':action==='RESUME'?'SUBSCRIPTION_RESUMED':action==='CANCEL'?'SUBSCRIPTION_CANCELLED':action==='SKIP'?'SUBSCRIPTION_SKIPPED':'SUBSCRIPTION_UPDATED';
    if(row.customer.user_id) await this.notifications.enqueue(tx,{recipientId:row.customer.user_id,role:'CUSTOMER',type,sourceKey:`sub:${row.id}:${version}:customer`,entityId:row.id});
    if(role==='CUSTOMER') {
      const vendor=await tx.vendors.findUniqueOrThrow({where:{id:row.vendor_id}});
      await this.notifications.enqueue(tx,{recipientId:vendor.user_id,role:'VENDOR',type:'SUBSCRIPTION_CHANGED_VENDOR',sourceKey:`sub:${row.id}:${version}:vendor`,entityId:row.id});
    }
  }
  private present(row:SubscriptionRead,day:string) {
    const latest=row.revisions.at(-1)!;
    let status=latest.status;
    if(status==='ACTIVE' && row.end_date && dayString(row.end_date)<day) status='COMPLETED';
    if(status==='ACTIVE' && pausedOn(row,day)) status='PAUSED';
    return {id:row.id,vendorId:row.vendor_id,vendorCustomerId:row.vendor_customer_id,productId:row.product_id,productName:row.product.name,
      qty:latest.qty,weekdays:days(latest.weekdays),timeSlot:latest.time_slot,startDate:dayString(row.start_date),endDate:row.end_date?dayString(row.end_date):null,
      addressSnapshot:row.address_snapshot,paymentMethod:row.payment_method,createdBy:row.created_by,status,version:row.version,effectiveFrom:dayString(latest.effective_from),
      ...monthlyEstimate(BigInt(row.product.subscription_price_paise??row.product.selling_price_paise),latest.qty,latest.weekdays,dayString(row.start_date),row.end_date?dayString(row.end_date):null,day.slice(0,7)),estimateMonth:day.slice(0,7),
      revisions:row.revisions.map(r=>({version:r.version,effectiveFrom:dayString(r.effective_from),qty:r.qty,weekdays:days(r.weekdays),timeSlot:r.time_slot,status:r.status,action:r.action,reason:r.reason})),
      pauses:row.pauses.map(p=>({fromDate:dayString(p.from_date),toDate:p.to_date?dayString(p.to_date):null,resumedFrom:p.resumed_from?dayString(p.resumed_from):null})),skips:row.skips.map(s=>dayString(s.date))};
  }
  list(userId:string,role:user_role_type,q:SubscriptionQuery) {
    return this.db.$transaction(async tx=>{
      const where=await this.scope(tx,userId,role);
      if(role==='VENDOR') await this.plans.requireOperation(tx,(await this.actor(tx,userId,role)).vendor!.id,'READ_HISTORY');
      const clock=await this.clock.now(tx);
      const rows=await tx.subscriptions.findMany({where,include:subscriptionRead,orderBy:[{created_at:'desc'},{id:'asc'}],take:q.limit??20,skip:q.offset??0});
      return {serverTime:clock.now.toISOString(),businessDate:clock.day,items:rows.map(r=>this.present(r,clock.day)),total:await tx.subscriptions.count({where})};
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
  get(userId:string,role:user_role_type,id:string) {
    return this.db.$transaction(async tx=>{
      const row=await this.owned(tx,userId,role,id),clock=await this.clock.now(tx);
      if(role==='VENDOR') await this.plans.requireOperation(tx,row.vendor_id,'READ_HISTORY');
      return this.present(row,clock.day);
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
  statement(userId:string,id:string,q:KhataMonthQuery) {
    return this.db.$transaction(async tx=>{
      const row=await this.owned(tx,userId,'CUSTOMER',id),clock=await this.clock.now(tx),month=q.month??clock.day.slice(0,7),{from,to}=khataMonth(month);
      const where={subscription_id:id,vendor_id:row.vendor_id,vendor_customer_id:row.vendor_customer_id,status:'DELIVERED',delivery_date:{gte:from,lt:to}};
      const orders=await tx.orders.findMany({where,include:{items:true},orderBy:[{delivery_date:'desc'},{id:'asc'}],take:q.limit??20,skip:q.offset??0});
      const totals=await tx.orders.aggregate({where,_sum:{total_paise:true},_count:true});
      const [quantity]=await tx.$queryRaw<{qty:string}[]>`SELECT COALESCE(SUM(i.qty),0)::text AS qty FROM order_items i JOIN orders o ON o.id=i.order_id WHERE o.subscription_id=${id}::uuid AND o.vendor_id=${row.vendor_id}::uuid AND o.vendor_customer_id=${row.vendor_customer_id}::uuid AND o.status='DELIVERED' AND o.delivery_date>=${from}::date AND o.delivery_date<${to}::date`;
      const ledger=await this.khata.entries(tx,row.vendor_id,[row.customer],{month,limit:50,offset:0});
      return {subscriptionId:id,month,items:orders.map(o=>({orderId:o.id,deliveryDate:dayString(o.delivery_date),productName:o.items.map(i=>i.product_name_snapshot).join(', '),qty:o.items.reduce((n,i)=>n+i.qty,0),amountPaise:String(o.total_paise),paymentStatus:o.payment_status})),total:totals._count,deliveredAmountPaise:String(totals._sum.total_paise??0n),deliveredQty:quantity!.qty,ledger};
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
  plansFor(userId:string,vendorId:string,addressId:string) {
    return this.db.$transaction(async tx=>{
      await this.actor(tx,userId,'CUSTOMER');
      const {v}=await this.available(tx,vendorId,true),a=await this.addresses.requireOwned(tx,userId,addressId);
      if(!await this.vendors.covers(vendorId,a.latitude,a.longitude,a.pincode,tx)) throw new UnprocessableEntityException({code:'NOT_SERVICEABLE'});
      const clock=await this.clock.now(tx),start=addDays(clock.day,1);
      const products=await tx.products.findMany({where:{vendor_id:vendorId,is_active:true,deleted_at:null},orderBy:[{name:'asc'},{id:'asc'}]});
      const items=products.flatMap(p=>{
        const ml=p.unit_type==='L'?p.unit_value.mul(1000):p.unit_type==='ML'?p.unit_value:null;
        const options=[{kind:'CUSTOM',qty:1},...(ml && ml.greaterThan(0)?[500,1000,2000].flatMap(size=>{
          const qty=new Prisma.Decimal(size).div(ml);return qty.isInteger() && qty.greaterThanOrEqualTo(1) && qty.lessThanOrEqualTo(2147483647)?[{kind:`${size}_ML_DAILY`,qty:qty.toNumber()}]:[];
        }):[])];
        return options.map(o=>({productId:p.id,productName:p.name,...o,mostPopular:null,
          ...monthlyEstimate(BigInt(p.subscription_price_paise??p.selling_price_paise),o.qty,127,start,null,clock.day.slice(0,7))}));
      });
      return {items,timeSlots:Array.isArray(v.settings!.time_slots)?v.settings!.time_slots:[],freeDelivery:v.settings!.delivery_charge_paise===0,earliestStartDate:start,estimateMonth:clock.day.slice(0,7)};
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
}
