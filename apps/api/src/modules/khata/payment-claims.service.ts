// T-082 / RULE-18: customer statements become money only on an owned vendor decision.
import { BadRequestException,ConflictException,ForbiddenException,Injectable,NotFoundException,UnprocessableEntityException } from '@nestjs/common';
import { payment_claims } from '@prisma/client';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { homeClock } from '../home/home.service';
import { KhataAccess,KhataTx,khataAmount,khataUnavailable } from './khata-access.service';
import { ClaimQuery,ClaimRejection,KhataVersion,PaymentClaimInput } from './khata.dto';
@Injectable()
export class PaymentClaimsService {
  constructor(private readonly access:KhataAccess,private readonly plans:PlanEntitlementsService,private readonly ledger:LedgerService,private readonly notices:NotificationsService){}
  private async limit(tx:KhataTx,vendorId:string,userId:string,customerId:string,amount:bigint){
    const current=await tx.ledger_balances.findUnique({where:{vendor_customer_id:customerId}});
    const [sum]=await tx.$queryRaw<{due:string}[]>`SELECT COALESCE(SUM(b.due_paise),0)::text AS due FROM ledger_balances b JOIN vendor_customers c ON c.id=b.vendor_customer_id WHERE c.vendor_id=${vendorId}::uuid AND c.user_id=${userId}::uuid`;
    if(amount>(current?.due_paise??0n)||amount>BigInt(sum!.due))throw new UnprocessableEntityException({code:'AMOUNT_EXCEEDS_DUE'});
  }
  create(userId:string,vendorId:string,key:string,input:PaymentClaimInput){return this.access.mutate(userId,'CUSTOMER',key,`POST claim/${vendorId}`,input,async tx=>{
    let account=await tx.vendor_customers.findFirst({where:{id:input.vendorCustomerId,vendor_id:vendorId,user_id:userId,deleted_at:null}});if(!account)throw new NotFoundException({code:'KHATA_LINK_NOT_FOUND'});
    await tx.$queryRaw`SELECT id FROM vendors WHERE id=${vendorId}::uuid FOR UPDATE`;
    const v=await tx.vendors.findUniqueOrThrow({where:{id:vendorId},include:{user:{include:{roles:true}}}});
    if(v.user.status!=='ACTIVE'||!v.user.roles.some(r=>r.role==='VENDOR'))throw new ForbiddenException({code:'VENDOR_UNAVAILABLE'});
    await this.plans.requireOperation(tx,vendorId,'CONFIRM_PAYMENT');
    if(input.method==='UPI'&&!(await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}})).payment_upi_id)throw new UnprocessableEntityException({code:'UPI_NOT_AVAILABLE'});
    await tx.$queryRaw`SELECT id FROM vendor_customers WHERE id=${account.id}::uuid FOR UPDATE`;
    account=await tx.vendor_customers.findFirst({where:{id:account.id,vendor_id:vendorId,user_id:userId,deleted_at:null}});if(!account)throw new NotFoundException({code:'KHATA_LINK_NOT_FOUND'});
    const amount=khataAmount(input.amountPaise);await this.limit(tx,vendorId,userId,account.id,amount);
    if(input.upiTxnRef!==undefined&&(input.method!=='UPI'||!input.upiTxnRef.trim()))throw new BadRequestException({code:'INVALID_CLAIM_REFERENCE'});
    const clock=await homeClock(tx),row=await tx.payment_claims.create({data:{vendor_customer_id:account.id,user_id:userId,amount_paise:amount,method:input.method,upi_txn_ref:input.upiTxnRef?.trim(),created_at:clock.now}});
    await this.notices.enqueue(tx,{recipientId:v.user_id,role:'VENDOR',type:'PAYMENT_CLAIM',sourceKey:`claim:${row.id}:pending`,entityId:account.id});
    await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'PAYMENT_CLAIM_CREATED',entity:'PAYMENT_CLAIM',entity_id:row.id,after:{status:'PENDING',version:1}}});return {id:row.id,status:row.status,version:row.version};
  });}
  customerList(userId:string,vendorId:string,q:ClaimQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');if(!await tx.vendor_customers.findFirst({where:{vendor_id:vendorId,user_id:userId}}))throw new NotFoundException({code:'KHATA_LINK_NOT_FOUND'});
    const where={user_id:userId,customer:{vendor_id:vendorId,user_id:userId},...(q.status?{status:q.status}:{})};
    const rows=await tx.payment_claims.findMany({where,include:{customer:true},orderBy:[{created_at:'desc'},{id:'desc'}],take:q.limit??20,skip:q.offset??0});return {items:rows.map(r=>this.present(r,r.customer.vendor_id)),total:await tx.payment_claims.count({where})};
  },{isolationLevel:'RepeatableRead'}).catch(khataUnavailable);}
  vendorList(userId:string,q:ClaimQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'VENDOR');const v=await this.access.vendor(tx,userId),where={customer:{vendor_id:v.id},status:q.status??'PENDING'};
    const rows=await tx.payment_claims.findMany({where,orderBy:[{created_at:'desc'},{id:'desc'}],take:q.limit??20,skip:q.offset??0});return {items:rows.map(r=>this.present(r,v.id)),total:await tx.payment_claims.count({where})};
  },{isolationLevel:'RepeatableRead'}).catch(khataUnavailable);}
  decide(userId:string,id:string,key:string,input:KhataVersion|ClaimRejection,confirm:boolean){return this.access.mutate(userId,'VENDOR',key,`${confirm?'CONFIRM':'REJECT'} claim/${id}`,input,async tx=>{
    const v=await this.access.vendor(tx,userId);await this.plans.requireOperation(tx,v.id,'CONFIRM_PAYMENT');
    const row=await tx.payment_claims.findFirst({where:{id,customer:{vendor_id:v.id}},include:{customer:true}});if(!row)throw new NotFoundException({code:'PAYMENT_CLAIM_NOT_FOUND'});
    await tx.$queryRaw`SELECT id FROM vendor_customers WHERE id=${row.vendor_customer_id}::uuid FOR UPDATE`;
    await tx.$queryRaw`SELECT id FROM payment_claims WHERE id=${id}::uuid FOR UPDATE`;
    if(row.status!=='PENDING')throw new ConflictException({code:'CLAIM_ALREADY_DECIDED'});if(row.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});
    const reason=confirm?null:(input as ClaimRejection).reason.trim();if(!confirm&&!reason)throw new BadRequestException({code:'REJECT_REASON_REQUIRED'});
    const clock=await homeClock(tx);
    if(confirm){
      if(row.customer.user_id!==row.user_id||row.customer.deleted_at)throw new ConflictException({code:'CLAIM_LINK_CHANGED'});
      await this.limit(tx,v.id,row.user_id,row.vendor_customer_id,row.amount_paise);
      await this.ledger.post(tx,{vendorId:v.id,customerId:row.vendor_customer_id,actorId:userId,type:'CREDIT',amountPaise:row.amount_paise,refType:'CLAIM',refId:id,note:'Confirmed external payment claim',entryDate:clock.day});
    }
    const result=await tx.payment_claims.update({where:{id},data:{status:confirm?'CONFIRMED':'REJECTED',version:{increment:1},decided_by:userId,decided_at:clock.now,reject_reason:reason}});
    await this.notices.enqueue(tx,{recipientId:row.user_id,role:'CUSTOMER',type:confirm?'PAYMENT_CLAIM_CONFIRMED':'PAYMENT_CLAIM_REJECTED',sourceKey:`claim:${id}:${result.version}`,entityId:v.id});
    await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:`PAYMENT_CLAIM_${result.status}`,entity:'PAYMENT_CLAIM',entity_id:id,before:{status:'PENDING',version:row.version},after:{status:result.status,version:result.version}}});
    return {id,status:result.status,version:result.version};
  });}
  private present(r:payment_claims,vendorId:string){return {id:r.id,vendorId,vendorCustomerId:r.vendor_customer_id,amountPaise:String(r.amount_paise),method:r.method,upiTxnRef:r.upi_txn_ref,status:r.status,version:r.version,createdAt:r.created_at.toISOString(),decidedAt:r.decided_at?.toISOString()??null,rejectReason:r.reject_reason};}
}
