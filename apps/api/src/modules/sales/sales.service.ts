// T-079 / RULE-10/11. Actor -> vendor -> sorted products -> customer/source locks.
import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { CatalogService } from '../catalog/catalog.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { LedgerService } from '../ledger/ledger.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { homeClock } from '../home/home.service';
import { dateOnly,dayString } from '../subscriptions/subscription-policy';
import { CompleteSaleInput,SaleQuery } from './sales.dto';
type Tx=Prisma.TransactionClient;
const read={items:{orderBy:{id:'asc' as const}}};
type Sale=Prisma.salesGetPayload<{include:typeof read}>;
const max=9223372036854775807n;
function unavailable(error:unknown):never{if(error instanceof HttpException)throw error;throw new ServiceUnavailableException({code:'SALES_UNAVAILABLE'});}
function amount(value:string){const n=BigInt(value);if(n<0n||n>max)throw new BadRequestException({code:'AMOUNT_OVERFLOW'});return n;}
@Injectable()
export class SalesService {
  constructor(private readonly db:PrismaService,private readonly catalog:CatalogService,private readonly ledger:LedgerService,
    private readonly plans:PlanEntitlementsService,private readonly keys:IdempotencyService){}
  private async vendor(tx:Tx,userId:string){
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
    const user=await tx.users.findUnique({where:{id:userId},include:{roles:true,vendor:true}});
    if(!user||user.status!=='ACTIVE'||user.active_role!=='VENDOR'||!user.roles.some(r=>r.role==='VENDOR'))throw new ForbiddenException({code:'VENDOR_ROLE_REQUIRED'});
    if(!user.vendor)throw new NotFoundException({code:'VENDOR_NOT_FOUND'});
    await tx.$queryRaw`SELECT id FROM vendors WHERE id=${user.vendor.id}::uuid FOR UPDATE`;
    const vendor=await tx.vendors.findUniqueOrThrow({where:{id:user.vendor.id}});if(vendor.is_suspended)throw new ForbiddenException({code:'VENDOR_SUSPENDED'});return vendor;
  }
  complete(userId:string,key:string,input:CompleteSaleInput){
    if(typeof key!=='string'||!key.trim()||key.length>120)throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    const requestKey=createHash('sha256').update(`${userId}:${key}`).digest('hex'),hash=this.keys.hashRequestBody(input);
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId);
      const previous=await tx.sales.findUnique({where:{request_key:requestKey},include:read});
      if(previous){if(previous.vendor_id!==vendor.id||previous.request_hash!==hash)throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});return this.present(previous);}
      await this.plans.requireOperation(tx,vendor.id,'POS_SALE');await this.ledger.assertPrivileges(tx);
      const lines=input.items.map(i=>({...i,productId:i.productId.toLowerCase()}));
      const ids=lines.map(i=>i.productId);if(new Set(ids).size!==ids.length)throw new BadRequestException({code:'DUPLICATE_PRODUCT'});
      await tx.$queryRaw`SELECT id FROM products WHERE vendor_id=${vendor.id}::uuid AND id IN (${Prisma.join(ids.map(id=>Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`;
      const products=await tx.products.findMany({where:{vendor_id:vendor.id,id:{in:ids},deleted_at:null,is_active:true}});
      if(products.length!==ids.length)throw new NotFoundException({code:'PRODUCT_UNAVAILABLE'});
      let total=0n;
      const items=lines.map(line=>{
        const p=products.find(p=>p.id===line.productId)!,rate=line.ratePaise===undefined?BigInt(p.selling_price_paise):amount(line.ratePaise),sum=rate*BigInt(line.qty);
        if(line.qty>p.stock_qty)throw new ConflictException({code:'INSUFFICIENT_STOCK'});
        total+=sum;if(sum>max||total>max)throw new BadRequestException({code:'AMOUNT_OVERFLOW'});
        const volumeKnown=p.product_type!=='MILK'||['L','ML'].includes(p.unit_type);
        const milk=p.product_type==='MILK'&&volumeKnown?p.unit_value.mul(line.qty).mul(p.unit_type==='L'?1000:1):new Prisma.Decimal(0);
        return {product_id:p.id,name_snapshot:p.name,unit_value_snapshot:p.unit_value.toString(),unit_type_snapshot:p.unit_type,qty:line.qty,rate_paise:rate,amount_paise:sum,
          milk_quantity_ml:milk,milk_quantity_known:volumeKnown};
      });
      const paid=amount(input.paidPaise);if(paid>total)throw new UnprocessableEntityException({code:'PAID_EXCEEDS_TOTAL'});
      if(!input.vendorCustomerId&&paid!==total)throw new UnprocessableEntityException({code:'WALKIN_MUST_BE_PAID'});
      if(input.vendorCustomerId){
        await tx.$queryRaw`SELECT id FROM vendor_customers WHERE id=${input.vendorCustomerId}::uuid AND vendor_id=${vendor.id}::uuid FOR UPDATE`;
        if(!await tx.vendor_customers.findFirst({where:{id:input.vendorCustomerId,vendor_id:vendor.id,deleted_at:null,status:'ACTIVE'}}))throw new NotFoundException({code:'CUSTOMER_NOT_FOUND'});
      }
      const clock=await homeClock(tx),[number]=await tx.$queryRaw<{value:bigint}[]>`SELECT nextval('sale_number_sequence') AS value`;
      const sale=await tx.sales.create({data:{sale_no:`SALE${String(number!.value).padStart(8,'0')}`,vendor_id:vendor.id,vendor_customer_id:input.vendorCustomerId,
        created_by:userId,total_paise:total,paid_paise:paid,balance_paise:total-paid,payment_method:input.paymentMethod,
        sale_date:dateOnly(clock.day),created_at:clock.now,client_created_at:input.clientCreatedAt?new Date(input.clientCreatedAt):null,request_key:requestKey,request_hash:hash,items:{create:items}}});
      // Surface deferred source checks inside the callback, before side effects;
      // do not rely on the client's handling of a COMMIT-time constraint error.
      await tx.$executeRaw`SET CONSTRAINTS sales_total, sale_items_total IMMEDIATE`;
      for(const line of [...items].sort((a,b)=>a.product_id.localeCompare(b.product_id)))await this.catalog.changeStock(tx,{vendorId:vendor.id,productId:line.product_id,actorId:userId,delta:-line.qty,reason:'SALE',refId:sale.id,note:'Quick sale'});
      if(input.vendorCustomerId){
        if(total>0n)await this.ledger.post(tx,{vendorId:vendor.id,customerId:input.vendorCustomerId,actorId:userId,type:'DEBIT',amountPaise:total,refType:'SALE',refId:sale.id,note:'Quick sale',entryDate:clock.day});
        if(paid>0n)await this.ledger.post(tx,{vendorId:vendor.id,customerId:input.vendorCustomerId,actorId:userId,type:'CREDIT',amountPaise:paid,refType:'SALE',refId:sale.id,note:'Payment recorded on quick sale',entryDate:clock.day});
      }
      await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'QUICK_SALE_COMPLETED',entity:'SALE',entity_id:sale.id,after:{vendorId:vendor.id,totalPaise:String(total),paidPaise:String(paid),items:items.length}}});
      return this.present(await tx.sales.findUniqueOrThrow({where:{id:sale.id},include:read}));
    },{timeout:30000}).catch(unavailable);
  }
  list(userId:string,q:SaleQuery){return this.db.$transaction(async tx=>{
    const vendor=await this.vendor(tx,userId);await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');const clock=await homeClock(tx);
    const where={vendor_id:vendor.id,...(q.date?{sale_date:dateOnly(q.date)}:{}),...(q.vendorCustomerId?{vendor_customer_id:q.vendorCustomerId}:{})};
    if(q.vendorCustomerId&&!await tx.vendor_customers.findFirst({where:{id:q.vendorCustomerId,vendor_id:vendor.id}}))throw new NotFoundException({code:'CUSTOMER_NOT_FOUND'});
    const rows=await tx.sales.findMany({where,include:read,orderBy:[{created_at:'desc'},{id:'desc'}],take:q.limit??20,skip:q.offset??0});
    return {items:rows.map(r=>this.present(r)),total:await tx.sales.count({where}),serverTime:clock.now.toISOString(),businessDate:clock.day};
  }).catch(unavailable);}
  get(userId:string,id:string){return this.db.$transaction(async tx=>{
    const vendor=await this.vendor(tx,userId);await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');const row=await tx.sales.findFirst({where:{id,vendor_id:vendor.id},include:read});if(!row)throw new NotFoundException({code:'SALE_NOT_FOUND'});return this.present(row);
  }).catch(unavailable);}
  private present(row:Sale){return {id:row.id,saleNo:row.sale_no,vendorCustomerId:row.vendor_customer_id,totalPaise:String(row.total_paise),paidPaise:String(row.paid_paise),balancePaise:String(row.balance_paise),
    paymentStatus:row.balance_paise===0n?'PAID':'UNPAID',paymentMethod:row.payment_method,businessDate:dayString(row.sale_date),createdAt:row.created_at.toISOString(),clientCreatedAt:row.client_created_at?.toISOString()??null,
    items:row.items.map(i=>({productId:i.product_id,name:i.name_snapshot,unitValue:i.unit_value_snapshot,unitType:i.unit_type_snapshot,qty:i.qty,ratePaise:String(i.rate_paise),amountPaise:String(i.amount_paise)}))};}
}
