// T-071 / RULE-10: receipt and its real ledger CREDIT commit together.
import { BadRequestException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { payments, Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { homeClock } from '../home/home.service';
import { LedgerService } from './ledger.service';
import { PaymentQuery, RecordPaymentInput } from './payments.dto';
type Tx=Prisma.TransactionClient;
function unavailable(error:unknown):never {
  if(error instanceof HttpException) throw error;
  throw new ServiceUnavailableException({code:'PAYMENTS_UNAVAILABLE'});
}
@Injectable()
export class PaymentsService {
  constructor(private readonly db:PrismaService,private readonly ledger:LedgerService,
    private readonly plans:PlanEntitlementsService,private readonly keys:IdempotencyService) {}
  private async vendor(tx:Tx,userId:string,write=false) {
    // Match ledger lock order before any vendor/customer locks, including reads.
    if(write) await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
    const user=await tx.users.findUnique({where:{id:userId},include:{roles:true,vendor:true}});
    if(!user || user.status!=='ACTIVE' || user.active_role!=='VENDOR' || !user.roles.some(r=>r.role==='VENDOR')) throw new ForbiddenException({code:'VENDOR_ROLE_REQUIRED'});
    if(!user.vendor) throw new NotFoundException({code:'VENDOR_NOT_FOUND'});
    if(write) await tx.$queryRaw`SELECT id FROM vendors WHERE id=${user.vendor.id}::uuid FOR UPDATE`;
    const vendor=write?await tx.vendors.findUniqueOrThrow({where:{id:user.vendor.id}}):user.vendor;
    if(vendor.is_suspended) throw new ForbiddenException({code:'VENDOR_SUSPENDED'});
    return vendor;
  }
  private async customer(tx:Tx,vendorId:string,id:string) {
    if(!await tx.vendor_customers.findFirst({where:{id,vendor_id:vendorId,deleted_at:null}})) throw new NotFoundException({code:'CUSTOMER_NOT_FOUND'});
  }
  record(userId:string,key:string,input:RecordPaymentInput) {
    if(typeof key!=='string' || !key.trim() || key.length>120) throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    const amount=BigInt(input.amountPaise),received=new Date(`${input.receivedOn}T00:00:00.000Z`);
    if(amount<=0n || amount>9223372036854775807n) throw new BadRequestException({code:'INVALID_PAYMENT_AMOUNT'});
    if(!Number.isFinite(received.getTime()) || received.toISOString().slice(0,10)!==input.receivedOn) throw new BadRequestException({code:'INVALID_PAYMENT_DATE'});
    const clientRef=`payment:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
    const note=input.note??'',hash=this.keys.hashRequestBody({...input,note});
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId,true);
      await this.customer(tx,vendor.id,input.vendorCustomerId);
      const previous=await tx.payments.findUnique({where:{vendor_id_client_ref:{vendor_id:vendor.id,client_ref:clientRef}}});
      if(previous) {
        if(previous.created_by!==userId || previous.request_hash!==hash) throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
        return this.present(previous);
      }
      await this.plans.requireOperation(tx,vendor.id,'RECORD_PAYMENT');
      await this.ledger.assertPrivileges(tx);
      const receipt=await tx.payments.create({data:{vendor_id:vendor.id,vendor_customer_id:input.vendorCustomerId,created_by:userId,
        amount_paise:amount,method:input.method,received_on:received,note,client_ref:clientRef,request_hash:hash}});
      await this.ledger.post(tx,{vendorId:vendor.id,customerId:input.vendorCustomerId,actorId:userId,type:'CREDIT',amountPaise:amount,
        refType:'PAYMENT',refId:receipt.id,note,entryDate:input.receivedOn});
      return this.present(receipt);
    },{timeout:15000}).catch(unavailable);
  }
  list(userId:string,q:PaymentQuery) {
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId);
      await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');
      if(q.vendorCustomerId) await this.customer(tx,vendor.id,q.vendorCustomerId);
      const where={vendor_id:vendor.id,...(q.vendorCustomerId?{vendor_customer_id:q.vendorCustomerId}:{})};
      const rows=await tx.payments.findMany({where,orderBy:[{received_on:'desc'},{created_at:'desc'},{id:'desc'}],take:q.limit??20,skip:q.offset??0});
      return {items:rows.map(row=>this.present(row)),total:await tx.payments.count({where})};
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
  summary(userId:string) {
    return this.db.$transaction(async tx=>{
      const vendor=await this.vendor(tx,userId);
      await this.plans.requireOperation(tx,vendor.id,'READ_HISTORY');
      const clock=await homeClock(tx);
      const [row]=await tx.$queryRaw<{receivable:string;received:string}[]>`SELECT
        (SELECT COALESCE(SUM(GREATEST(b.due_paise,0)),0)::text FROM ledger_balances b
          JOIN vendor_customers c ON c.id=b.vendor_customer_id WHERE c.vendor_id=${vendor.id}::uuid) AS receivable,
        (SELECT COALESCE(SUM(amount_paise),0)::text FROM payments WHERE vendor_id=${vendor.id}::uuid
          AND received_on>=date_trunc('month',${clock.day}::date)::date
          AND received_on<(date_trunc('month',${clock.day}::date)+interval '1 month')::date) AS received`;
      return {serverTime:clock.now.toISOString(),businessDate:clock.day,totalReceivablePaise:row!.receivable,thisMonthReceivedPaise:row!.received};
    },{isolationLevel:'RepeatableRead',timeout:15000}).catch(unavailable);
  }
  private present(row:payments) {
    return {id:row.id,vendorCustomerId:row.vendor_customer_id,orderId:row.order_id,amountPaise:String(row.amount_paise),
      method:row.method,receivedOn:row.received_on.toISOString().slice(0,10),note:row.note,createdAt:row.created_at.toISOString()};
  }
}
