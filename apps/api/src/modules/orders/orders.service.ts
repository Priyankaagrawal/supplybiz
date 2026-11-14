import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { orders, Prisma, user_role_type } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { BusinessRuleException } from '../../common/business-rule.exception';
import { AddressesService } from '../addresses/addresses.service';
import { CustomersService } from '../customers/customers.service';
import { VendorsService } from '../vendors/vendors.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { NotificationsService } from '../notifications/notifications.service';
import { homeClock } from '../home/home.service';
import { OrderCancelInput, OrderPlaceInput, OrderQuery, OrderQuoteInput, OrderTransitionInput } from './orders.dto';
import { DeliveryQuery } from './orders.dto';
import { DeliveryEffectsService } from './delivery-effects.service';
import { OrderReorder } from './orders.dto';
type Tx = Prisma.TransactionClient;
const orderRead={items:{orderBy:{id:'asc' as const}},timeline:{orderBy:[{at:'asc' as const},{id:'asc' as const}]},customer:true,vendor:{include:{user:true}}} satisfies Prisma.ordersInclude;
type OrderRead=Prisma.ordersGetPayload<{include:typeof orderRead}>;
const digest = (value: string) => createHash('sha256').update(value).digest('hex');
const ongoing = ['NEW','ACCEPTED','PREPARING','OUT_FOR_DELIVERY'];
const cancelled = ['REJECTED','CANCELLED'];
const inactive = [...cancelled,'FAILED'];
function unavailable(error: unknown): never {
  if (error instanceof HttpException) throw error;
  // Do not send DB diagnostics (which may contain addresses/PII) to the global logger.
  throw new ServiceUnavailableException({code:'ORDERS_UNAVAILABLE'});
}
export function orderDate(value: string) {
  const date = new Date(`${value}T00:00:00.000Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0,10) !== value) throw new BadRequestException({ code:'INVALID_DELIVERY_DATE' });
  return date;
}
@Injectable()
export class OrdersService {
  constructor(private readonly db: PrismaService, private readonly addresses: AddressesService,
    private readonly customers: CustomersService, private readonly vendors: VendorsService,
    private readonly plans: PlanEntitlementsService, private readonly keys: IdempotencyService,
    private readonly notifications: NotificationsService, private readonly deliveryEffects: DeliveryEffectsService) {}
  private async actor(tx: Tx, userId: string, role: user_role_type) {
    const user = await tx.users.findUnique({where:{id:userId},include:{roles:true}});
    if (!user || user.status !== 'ACTIVE' || user.active_role !== role || !user.roles.some(r=>r.role===role)) throw new ForbiddenException({code:`${role}_ROLE_REQUIRED`});
    return user;
  }
  private async vendor(tx: Tx,userId: string) {
    await this.actor(tx,userId,'VENDOR');
    const vendor = await tx.vendors.findUnique({where:{user_id:userId}});
    if (!vendor) throw new NotFoundException({code:'VENDOR_NOT_FOUND'});
    if (vendor.is_suspended) throw new ForbiddenException({code:'VENDOR_SUSPENDED'});
    return vendor;
  }
  private async scope(tx: Tx,userId: string,role: user_role_type): Promise<Prisma.ordersWhereInput> {
    if (role === 'VENDOR') return {vendor_id:(await this.vendor(tx,userId)).id};
    await this.actor(tx,userId,'CUSTOMER');
    // A matching mobile alone never grants access to a vendor's offline history.
    return {customer:{user_id:userId}};
  }
  private async owned(tx: Tx,userId: string,role: user_role_type,id: string) {
    const order = await tx.orders.findFirst({where:{id,...await this.scope(tx,userId,role)}});
    if (!order) throw new NotFoundException({code:'ORDER_NOT_FOUND'});
    return order;
  }
  quote(userId: string,input: OrderQuoteInput) {
    return this.db.$transaction(async tx=> (await this.price(tx,userId,input)).quote,{timeout:15000}).catch(unavailable);
  }
  options(userId: string,vendorId: string,addressId: string) {
    return this.db.$transaction(async tx=>{
      await this.actor(tx,userId,'CUSTOMER');
      const address=await this.addresses.requireOwned(tx,userId,addressId);
      await this.plans.requireOperation(tx,vendorId,'NEW_ORDER');
      const vendor=await tx.vendors.findUniqueOrThrow({where:{id:vendorId},include:{settings:true,user:true,category:true}});
      if (vendor.user_id===userId) throw new UnprocessableEntityException({code:'SELF_ORDER_NOT_ALLOWED'});
      if (vendor.kyc_status!=='VERIFIED' || vendor.user.status!=='ACTIVE' || vendor.category.type!=='SUPPLY' || vendor.category.status!=='ENABLED' || !vendor.settings) throw new NotFoundException({code:'VENDOR_UNAVAILABLE'});
      if (!await this.vendors.covers(vendorId,address.latitude,address.longitude,address.pincode,tx)) throw new UnprocessableEntityException({code:'NOT_SERVICEABLE'});
      const clock=await homeClock(tx),settings=vendor.settings;
      const holidays=await tx.vendor_holidays.findMany({where:{vendor_id:vendorId}});
      const cutoff=settings.same_day_cutoff?.toISOString().slice(11,19) ?? null;
      const time=new Date(clock.now.getTime()+19800000).toISOString().slice(11,19);
      const pauseUntil=settings.delivery_paused_until ? new Date(settings.delivery_paused_until.getTime()+19800000).toISOString().slice(0,10) : null;
      const dates=Array.from({length:8},(_,i)=>new Date(orderDate(clock.day).getTime()+i*86400000).toISOString().slice(0,10));
      return {serverTime:clock.now.toISOString(),businessDate:clock.day,sameDayCutoff:cutoff,
        availableDates:dates.filter((d,i)=>(i>0 || settings.accepting_today && cutoff!==null && time<cutoff) &&
          !holidays.some(h=>h.date.toISOString().slice(0,10)===d) && (!settings.delivery_paused || pauseUntil!==null && d>pauseUntil)),
        timeSlots:Array.isArray(settings.time_slots)?settings.time_slots.filter((s):s is string=>typeof s==='string' && s.length>0 && s.length<=80):[]};
    },{timeout:15000}).catch(unavailable);
  }
  private async price(tx: Tx,userId: string,input: OrderQuoteInput) {
    await this.actor(tx,userId,'CUSTOMER');
    if (!['POD_CASH','POD_UPI'].includes(input.paymentMode)) throw new BadRequestException({code:'PAYMENT_MODE_NOT_ALLOWED'});
    const vendor = await tx.vendors.findUnique({where:{id:input.vendorId},include:{settings:true,user:true,category:true}});
    if (vendor?.user_id===userId) throw new UnprocessableEntityException({code:'SELF_ORDER_NOT_ALLOWED'});
    if (!vendor || vendor.is_suspended || vendor.kyc_status!=='VERIFIED' || vendor.user.status!=='ACTIVE' || vendor.category.status!=='ENABLED' || vendor.category.type!=='SUPPLY' || !vendor.settings) throw new NotFoundException({code:'VENDOR_UNAVAILABLE'});
    // Assignment/settings/customer writers use this vendor lock too; re-read after it.
    await this.plans.requireOperation(tx,vendor.id,'NEW_ORDER');
    const current = await tx.vendors.findUniqueOrThrow({where:{id:vendor.id},include:{settings:true,user:true,category:true}});
    if (current.is_suspended || current.kyc_status!=='VERIFIED' || current.user.status!=='ACTIVE' || current.category.status!=='ENABLED' || current.category.type!=='SUPPLY') throw new NotFoundException({code:'VENDOR_UNAVAILABLE'});
    const settings = current.settings!;
    const address = await this.addresses.requireOwned(tx,userId,input.addressId);
    if (!await this.vendors.covers(vendor.id,address.latitude,address.longitude,address.pincode,tx)) throw new UnprocessableEntityException({code:'NOT_SERVICEABLE'});
    const clock = await homeClock(tx), date = orderDate(input.deliveryDate), today = orderDate(clock.day);
    if (date < today || date.getTime() > today.getTime()+7*86400000) throw new UnprocessableEntityException({code:'INVALID_DELIVERY_DATE'});
    const cutoff = settings.same_day_cutoff?.toISOString().slice(11,19) ?? null;
    const time = new Date(clock.now.getTime()+19800000).toISOString().slice(11,19);
    if (input.deliveryDate===clock.day && (!settings.accepting_today || !cutoff || time>=cutoff)) throw new UnprocessableEntityException({code:'PAST_CUTOFF'});
    if (settings.delivery_paused && (!settings.delivery_paused_until || date.getTime() <= orderDate(new Date(settings.delivery_paused_until.getTime()+19800000).toISOString().slice(0,10)).getTime())) throw new UnprocessableEntityException({code:'DELIVERY_PAUSED'});
    if (await tx.vendor_holidays.findUnique({where:{vendor_id_date:{vendor_id:vendor.id,date}}})) throw new UnprocessableEntityException({code:'VENDOR_HOLIDAY'});
    if (!Array.isArray(settings.time_slots) || !settings.time_slots.includes(input.timeSlot)) throw new UnprocessableEntityException({code:'INVALID_TIME_SLOT'});
    const ids = input.items.map(i=>i.productId);
    if (!ids.length || ids.length>100 || new Set(ids).size!==ids.length) throw new BadRequestException({code:'INVALID_ORDER_ITEMS'});
    // Deterministic product lock order matches stock/price writers; no stock decrement until T-049.
    await tx.$queryRaw`SELECT id FROM products WHERE vendor_id=${vendor.id}::uuid AND id IN (${Prisma.join(ids.map(id=>Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`;
    const products = await tx.products.findMany({where:{vendor_id:vendor.id,id:{in:ids},is_active:true,deleted_at:null}});
    const lines = input.items.map(item=>{
      const product = products.find(p=>p.id===item.productId);
      if (!product) throw new BusinessRuleException(422,'PRODUCT_UNAVAILABLE',{productId:item.productId});
      if (!Number.isInteger(item.qty) || item.qty<product.moq) throw new BusinessRuleException(422,'BELOW_MOQ',{productId:product.id});
      if (item.qty>product.stock_qty) throw new BusinessRuleException(422,'OUT_OF_STOCK',{productId:product.id});
      const total = BigInt(product.selling_price_paise)*BigInt(item.qty);
      const milk = product.product_type==='MILK' && ['L','ML'].includes(product.unit_type)
        ? product.unit_value.mul(product.unit_type==='L'?1000:1).mul(item.qty) : new Prisma.Decimal(0);
      return {product,qty:item.qty,total,milk};
    });
    const subtotal = lines.reduce((sum,l)=>sum+l.total,0n), charge = BigInt(settings.delivery_charge_paise), total = subtotal+charge;
    if (total>9223372036854775807n) throw new UnprocessableEntityException({code:'ORDER_TOTAL_TOO_LARGE'});
    if (subtotal<BigInt(settings.min_order_paise)) throw new UnprocessableEntityException({code:'MIN_ORDER_NOT_MET'});
    const existing = {vendor_id:vendor.id,delivery_date:date,status:{notIn:inactive}};
    if (settings.max_daily_orders!==null && await tx.orders.count({where:existing})>=settings.max_daily_orders) throw new UnprocessableEntityException({code:'CAPACITY_REACHED',detail:'Vendor fully booked for this date'});
    if (settings.daily_milk_capacity_ml!==null) {
      const used = await tx.order_items.aggregate({where:{order:existing},_sum:{milk_quantity_ml:true}});
      const next = lines.reduce((sum,l)=>sum.add(l.milk),used._sum.milk_quantity_ml ?? new Prisma.Decimal(0));
      if (next.gt(settings.daily_milk_capacity_ml)) throw new UnprocessableEntityException({code:'CAPACITY_REACHED',detail:'Vendor fully booked for this date'});
    }
    return {vendor:current,address,date,lines,quote:{serverTime:clock.now.toISOString(),businessDate:clock.day,sameDayCutoff:cutoff,
      items:lines.map(l=>({productId:l.product.id,name:l.product.name,qty:l.qty,unitValue:l.product.unit_value.toString(),unitType:l.product.unit_type,unitPricePaise:String(l.product.selling_price_paise),lineTotalPaise:String(l.total)})),
      subtotalPaise:String(subtotal),deliveryChargePaise:String(charge),discountPaise:'0',totalPaise:String(total)}};
  }
  place(userId: string,key: string,input: OrderPlaceInput) {
    return this.mutate(userId,'CUSTOMER',key,'place',input,async tx=>{
      const priced = await this.price(tx,userId,input);
      if (priced.quote.totalPaise!==input.expectedTotalPaise) throw new BusinessRuleException(409,'PRICE_CHANGED',{quote:priced.quote});
      const user = await this.actor(tx,userId,'CUSTOMER');
      let customer = await tx.vendor_customers.findFirst({where:{vendor_id:input.vendorId,mobile:user.mobile,deleted_at:null}});
      if (customer && customer.user_id!==userId) throw new ConflictException({code:'CUSTOMER_LINK_REQUIRED'});
      if (customer?.status==='INACTIVE') throw new ForbiddenException({code:'CUSTOMER_INACTIVE'});
      if (!customer) {
        await this.customers.requireCapacity(tx,input.vendorId);
        customer = await tx.vendor_customers.create({data:{vendor_id:input.vendorId,user_id:userId,mobile:user.mobile,name:user.name ?? 'Customer',preferred_payment:input.paymentMode==='POD_UPI'?'UPI':'CASH'}});
      }
      const [number] = await tx.$queryRaw<{value:bigint}[]>`SELECT nextval('order_number_sequence') AS value`;
      const a=priced.address;
      const order = await tx.orders.create({data:{order_no:`ORD${String(number!.value).padStart(8,'0')}`,vendor_id:input.vendorId,vendor_customer_id:customer.id,
        source:'APP',status:'NEW',delivery_date:priced.date,time_slot:input.timeSlot,
        address_snapshot:{id:a.id,label:a.label,line1:a.line1,line2:a.line2,landmark:a.landmark,city:a.city,state:a.state,pincode:a.pincode,latitude:a.latitude,longitude:a.longitude,isDefault:a.is_default},
        subtotal_paise:BigInt(priced.quote.subtotalPaise),delivery_charge_paise:BigInt(priced.quote.deliveryChargePaise),total_paise:BigInt(priced.quote.totalPaise),
        payment_mode:input.paymentMode,payment_status:'UNPAID',items:{create:priced.lines.map(l=>({product_id:l.product.id,product_name_snapshot:l.product.name,
          unit_snapshot:{value:l.product.unit_value.toString(),type:l.product.unit_type},unit_price_paise:BigInt(l.product.selling_price_paise),qty:l.qty,line_total_paise:l.total,milk_quantity_ml:l.milk}))},
        timeline:{create:{status:'NEW'}}}});
      await this.notifications.enqueue(tx,{recipientId:priced.vendor.user_id,role:'VENDOR',type:'ORDER_NEW',sourceKey:`order:${order.id}:new`,entityId:order.id});
      return this.present(order);
    });
  }
  list(userId: string,role: user_role_type,q: OrderQuery) {
    return this.db.$transaction(async tx=>{
      const scope = await this.scope(tx,userId,role);
      const status = q.status && q.status!=='ALL' ? {in:q.status==='CANCELLED'?cancelled:[q.status]} :
        q.tab==='ONGOING'?{in:ongoing}:q.tab==='CANCELLED'?{in:cancelled}:q.tab==='DELIVERED'?{in:['DELIVERED']}:undefined;
      const term = q.q?.replace(/[\\%_]/g,'\\$&');
      const where: Prisma.ordersWhereInput = {...scope,status,delivery_date:q.date?orderDate(q.date):undefined,
        ...(term?{OR:[{order_no:{contains:term,mode:'insensitive'}},{customer:{name:{contains:term,mode:'insensitive'}}}]}:{})};
      const [rows,total] = await Promise.all([tx.orders.findMany({where,include:{items:{orderBy:{id:'asc'}}},orderBy:[{created_at:'desc'},{id:'desc'}],take:q.limit ?? 20,skip:q.offset ?? 0}),tx.orders.count({where})]);
      return {items:rows.map(o=>({...this.present(o),itemSummary:o.items.map(i=>`${i.product_name_snapshot} × ${i.qty}`)})),total};
    },{isolationLevel:'RepeatableRead'}).catch(unavailable);
  }
  reorder(userId:string,id:string) {
    return this.db.$transaction(async tx=>{
      const order=await this.owned(tx,userId,'CUSTOMER',id);
      if(!['DELIVERED','FAILED','CANCELLED','REJECTED'].includes(order.status)) throw new ConflictException({code:'INVALID_STATE_TRANSITION'});
      await this.plans.requireOperation(tx,order.vendor_id,'NEW_ORDER');
      const vendor=await tx.vendors.findUniqueOrThrow({where:{id:order.vendor_id},include:{user:true,category:true}});
      if(vendor.kyc_status!=='VERIFIED' || vendor.user.status!=='ACTIVE' || vendor.category.status!=='ENABLED' || vendor.category.type!=='SUPPLY') throw new NotFoundException({code:'VENDOR_UNAVAILABLE'});
      const customer=await tx.vendor_customers.findUniqueOrThrow({where:{id:order.vendor_customer_id}});
      if(customer.deleted_at || customer.status!=='ACTIVE') throw new UnprocessableEntityException({code:'CUSTOMER_INACTIVE'});
      const saved=await tx.order_items.findMany({where:{order_id:id},orderBy:{id:'asc'}});
      const quantities=new Map<string,{name:string;qty:bigint}>();
      for(const i of saved) {
        const previous=quantities.get(i.product_id);
        quantities.set(i.product_id,{name:i.product_name_snapshot,qty:(previous?.qty??0n)+BigInt(i.qty)});
      }
      const products=await tx.products.findMany({where:{vendor_id:vendor.id,id:{in:[...quantities.keys()]},deleted_at:null,is_active:true}});
      const result:OrderReorder={vendorId:vendor.id,vendorName:vendor.business_name??'',items:[],unavailable:[]};
      for(const [productId,line] of quantities) {
        const p=products.find(p=>p.id===productId);
        const reason=!p?'PRODUCT_UNAVAILABLE':line.qty<=0n || line.qty<BigInt(p.moq)?'BELOW_MOQ':line.qty>BigInt(p.stock_qty)?'INSUFFICIENT_STOCK':null;
        if(reason || !p) {result.unavailable.push({productId,name:line.name,reason:reason!});continue;}
        result.items.push({qty:Number(line.qty),product:{id:p.id,name:p.name,productType:p.product_type,milkType:p.milk_type,unitValue:p.unit_value.toNumber(),unitType:p.unit_type,
          sellingPricePaise:p.selling_price_paise,subscriptionPricePaise:p.subscription_price_paise,stockQty:p.stock_qty,moq:p.moq,description:p.description,
          imageMediaId:p.image_media_id,isActive:p.is_active,version:p.version}});
      }
      // Cart preview only: no order, stock, ledger, notice or replay writes.
      return result;
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
  detail(userId: string,role: user_role_type,id: string) {
    return this.db.$transaction(async tx=>{
      await this.owned(tx,userId,role,id);
      return this.presentDetail(await tx.orders.findUniqueOrThrow({where:{id},include:orderRead}));
    },{isolationLevel:'RepeatableRead'}).catch(unavailable);
  }
  private presentDetail(full:OrderRead) {
    return {...this.present(full),vendorMobile:full.vendor.user.mobile,vendorName:full.vendor.business_name,customerName:full.customer.name,customerMobile:full.customer.mobile,address:full.address_snapshot,
      subtotalPaise:String(full.subtotal_paise),deliveryChargePaise:String(full.delivery_charge_paise),discountPaise:String(full.discount_paise),
      rejectReason:full.reject_reason,cancelReason:full.cancel_reason,failReason:full.fail_reason,
      items:full.items.map(i=>{const unit=i.unit_snapshot as {value?:string|number;type?:string};return {productId:i.product_id,name:i.product_name_snapshot,qty:i.qty,unitValue:String(unit.value ?? ''),unitType:unit.type ?? '',unitPricePaise:String(i.unit_price_paise),lineTotalPaise:String(i.line_total_paise)};}),
      timeline:full.timeline.map(e=>({status:e.status,reason:e.reason,at:e.at.toISOString()}))};
  }
  deliveries(userId:string,q:DeliveryQuery) {
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId),clock=await homeClock(tx),day=q.date ?? clock.day;
      const where={vendor_id:vendor.id,delivery_date:orderDate(day),status:{in:['ACCEPTED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','FAILED']}};
      const groups=await tx.orders.groupBy({by:['status'],where,_count:{_all:true}});
      const counts={ALL:0,PENDING:0,PREPARING:0,OUT_FOR_DELIVERY:0,DELIVERED:0,FAILED:0};
      for(const group of groups){const key=(group.status==='ACCEPTED'?'PENDING':group.status) as keyof typeof counts;counts[key]=group._count._all;counts.ALL+=group._count._all;}
      const status=q.status && q.status!=='ALL'?q.status==='PENDING'?'ACCEPTED':q.status:null;
      const rows=await tx.orders.findMany({where:{...where,...(status?{status}:{})},include:orderRead,
        orderBy:[{time_slot:'asc'},{created_at:'asc'},{id:'asc'}],take:q.limit ?? 20,skip:q.offset ?? 0});
      return {serverTime:clock.now.toISOString(),businessDate:clock.day,deliveryDate:day,counts,total:counts[(q.status ?? 'ALL') as keyof typeof counts],items:rows.map(o=>this.presentDetail(o))};
    },{isolationLevel:'RepeatableRead'}).catch(unavailable);
  }
  transition(userId: string,key: string,id: string,input: OrderTransitionInput) {
    return this.mutate(userId,'VENDOR',key,`transition/${id}`,input,async tx=>{
      const order = await this.owned(tx,userId,'VENDOR',id);
      await this.plans.requireOperation(tx,order.vendor_id,'COMPLETE_ORDER');
      await tx.$queryRaw`SELECT id FROM orders WHERE id=${id}::uuid FOR UPDATE`;
      const current = await tx.orders.findUniqueOrThrow({where:{id}});
      const allowed: Record<string,readonly string[]> = {NEW:['ACCEPTED','REJECTED'],ACCEPTED:['PREPARING','OUT_FOR_DELIVERY'],PREPARING:['OUT_FOR_DELIVERY'],OUT_FOR_DELIVERY:['DELIVERED','FAILED']};
      if (current.version!==input.version) throw new ConflictException({code:'VERSION_CONFLICT'});
      if (!allowed[current.status]?.includes(input.to)) throw new ConflictException({code:'INVALID_STATE_TRANSITION'});
      let reason: string | null = null;
      if(input.to!=='DELIVERED' && input.payment!==undefined) throw new BadRequestException({code:'UNEXPECTED_PAYMENT'});
      if (input.to==='REJECTED') {
        if (!input.reason || !['CUSTOMER_UNAVAILABLE','OUT_OF_STOCK','NOT_SERVICEABLE','CUSTOMER_REQUEST','OTHER'].includes(input.reason) || input.reason==='OTHER' && (!input.reasonText || input.reasonText.length<5 || input.reasonText.length>200)) throw new BadRequestException({code:'REJECT_REASON_REQUIRED'});
        reason = input.reason==='OTHER'?input.reasonText!:input.reason;
      } else if(input.to==='FAILED') {
        if(!input.reason || input.reason.length>200 || input.reasonText!==undefined) throw new BadRequestException({code:'FAIL_REASON_REQUIRED'});
        reason=input.reason;
      } else if (input.reason!==undefined || input.reasonText!==undefined) throw new BadRequestException({code:'UNEXPECTED_REASON'});
      const completion=input.to==='DELIVERED'?await this.deliveryEffects.complete(tx,userId,current,input):null;
      const updated = await tx.orders.update({where:{id},data:{status:input.to,version:{increment:1},
        ...(input.to==='REJECTED'?{reject_reason:reason}:{}),...(input.to==='FAILED'?{fail_reason:reason}:{}),
        ...(completion?{completed_at:completion.completedAt,payment_status:completion.paymentStatus}:{})}});
      await tx.order_status_events.create({data:{order_id:id,status:input.to,reason,
        client_created_at:input.clientCreatedAt===undefined?null:new Date(input.clientCreatedAt)}});
      const customer=await tx.vendor_customers.findUniqueOrThrow({where:{id:order.vendor_customer_id}});
      const event = input.to==='ACCEPTED'?'ORDER_ACCEPTED':input.to==='REJECTED'?'ORDER_REJECTED':input.to==='OUT_FOR_DELIVERY'?'OUT_FOR_DELIVERY':input.to==='DELIVERED'?'ORDER_DELIVERED':input.to==='FAILED'?'DELIVERY_FAILED':null;
      if (customer.user_id && event) await this.notifications.enqueue(tx,{recipientId:customer.user_id,role:'CUSTOMER',type:event,sourceKey:`order:${id}:${updated.version}`,entityId:id});
      return this.present(updated);
    });
  }
  cancel(userId: string,key: string,id: string,input: OrderCancelInput) {
    return this.mutate(userId,'CUSTOMER',key,`cancel/${id}`,input,async tx=>{
      const order = await this.owned(tx,userId,'CUSTOMER',id);
      // Cancellation of an existing NEW order remains available after plan expiry.
      await tx.$queryRaw`SELECT id FROM vendors WHERE id=${order.vendor_id}::uuid FOR UPDATE`;
      const current=await tx.orders.findUniqueOrThrow({where:{id}});
      if (current.status!=='NEW') throw new ConflictException({code:'INVALID_STATE_TRANSITION'});
      if (current.version!==input.version) throw new ConflictException({code:'VERSION_CONFLICT'});
      const updated=await tx.orders.update({where:{id},data:{status:'CANCELLED',cancel_reason:'CUSTOMER_REQUEST',version:{increment:1}}});
      await tx.order_status_events.create({data:{order_id:id,status:'CANCELLED',reason:'CUSTOMER_REQUEST'}});
      const vendor=await tx.vendors.findUniqueOrThrow({where:{id:order.vendor_id}});
      await this.notifications.enqueue(tx,{recipientId:vendor.user_id,role:'VENDOR',type:'ORDER_CANCELLED',sourceKey:`order:${id}:cancelled`,entityId:id});
      return this.present(updated);
    });
  }
  private present(o: orders) {
    return {id:o.id,orderNo:o.order_no,vendorId:o.vendor_id,status:o.status,version:o.version,deliveryDate:o.delivery_date.toISOString().slice(0,10),timeSlot:o.time_slot,
      totalPaise:String(o.total_paise),paymentMode:o.payment_mode,paymentStatus:o.payment_status,source:o.source,createdAt:o.created_at.toISOString()};
  }
  private mutate(userId: string,role: user_role_type,key: string,path: string,input: object,write: (tx: Tx)=>Promise<Prisma.InputJsonObject>) {
    if (!key?.trim() || key.length>120) throw new BadRequestException({code:'VALIDATION_FAILED'});
    return this.db.$transaction(async tx=>{
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
      await this.actor(tx,userId,role);
      if (role==='VENDOR') await this.vendor(tx,userId);
      const requestKey=digest(`${userId}:${key}`),hash=this.keys.hashRequestBody(input);
      const cached=await tx.order_requests.findUnique({where:{request_key:requestKey}});
      if (cached) {
        if (cached.path!==path || cached.request_hash!==hash) throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
        const result = cached.response as {id:string};
        await this.owned(tx,userId,role,result.id);
        return cached.response;
      }
      const response=await write(tx);
      await tx.order_requests.create({data:{request_key:requestKey,user_id:userId,path,request_hash:hash,response}});
      return response;
    },{timeout:15000}).catch(unavailable);
  }
}
