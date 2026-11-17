// FR-253: explicit payment publication, separate from verification-only KYC.
import { BadRequestException,ConflictException,Injectable,NotFoundException } from '@nestjs/common';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { KhataAccess,khataUnavailable } from './khata-access.service';
import { KhataReadService } from './khata-read.service';
import { PaymentPublicationInput } from './khata.dto';
@Injectable()
export class PaymentDetailsService {
  constructor(private readonly access:KhataAccess,private readonly reads:KhataReadService,private readonly plans:PlanEntitlementsService){}
  vendor(userId:string){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'VENDOR');const v=await this.access.vendor(tx,userId),settings=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:v.id}});
    return {version:settings.version,published:settings.payment_upi_id!==null,upiId:settings.payment_upi_id,payeeName:v.business_name??''};
  }).catch(khataUnavailable);}
  publish(userId:string,key:string,input:PaymentPublicationInput){return this.access.mutate(userId,'VENDOR',key,'PATCH payment-details',input,async tx=>{
    const v=await this.access.vendor(tx,userId),before=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:v.id}});
    if(before.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});
    if(input.publish?!input.upiId:input.upiId!==undefined)throw new BadRequestException({code:'INVALID_PAYMENT_PUBLICATION'});
    if(input.publish&&!v.business_name?.trim())throw new BadRequestException({code:'BUSINESS_NAME_REQUIRED'});
    if(input.publish)await this.plans.requireOperation(tx,v.id,'RECORD_PAYMENT');
    await tx.vendor_settings.update({where:{vendor_id:v.id},data:{payment_upi_id:input.publish?input.upiId:null,version:{increment:1}}});
    await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'PAYMENT_DETAILS_PUBLICATION',entity:'VENDOR',entity_id:v.id,before:{published:before.payment_upi_id!==null,version:before.version},after:{published:input.publish,version:before.version+1}}});
    return {version:before.version+1,published:input.publish};
  });}
  customer(userId:string,vendorId:string){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');const links=await tx.vendor_customers.findMany({where:{vendor_id:vendorId,user_id:userId}});if(!links.length)throw new NotFoundException({code:'KHATA_LINK_NOT_FOUND'});
    const v=await tx.vendors.findUniqueOrThrow({where:{id:vendorId}}),settings=await tx.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}}),balances=await tx.ledger_balances.findMany({where:{vendor_customer_id:{in:links.map(l=>l.id)}}});
    const allowed=await this.reads.canSettle(tx,vendorId),due=balances.reduce((n,b)=>n+b.due_paise,0n);
    const accounts=links.map(l=>{const amount=balances.find(b=>b.vendor_customer_id===l.id)?.due_paise??0n,max=amount<due?amount:due;return {vendorCustomerId:l.id,duePaise:String(amount),maxClaimPaise:String(max>0n?max:0n),canClaim:allowed&&!l.deleted_at&&amount>0n&&due>0n};});
    const available=accounts.some(a=>a.canClaim),upiId=allowed?settings.payment_upi_id:null;
    return {vendorId,payeeName:v.business_name??'',upiId,upiAvailable:available&&upiId!==null,cashAvailable:available,duePaise:String(due),accounts};
  },{isolationLevel:'RepeatableRead'}).catch(khataUnavailable);}
}
