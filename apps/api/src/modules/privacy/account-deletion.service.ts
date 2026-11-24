import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { createHash, createHmac } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { OtpService } from '../auth/otp.service';
import type { DeletionPreview, DeletionReceipt } from './account-deletion.controller';
type Tx=Prisma.TransactionClient;
@Injectable()
export class AccountDeletionService {
 constructor(private readonly db:PrismaService,private readonly otp:OtpService,private readonly config:ConfigService){}
 private async active(tx:Tx,userId:string,sessionId?:string) {
  await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
  const row=await tx.users.findUniqueOrThrow({where:{id:userId}});
  const session=sessionId?await tx.sessions.findFirst({where:{id:sessionId,user_id:userId,status:'ACTIVE',expires_at:{gt:new Date()}}}):true;
  if(row.status!=='ACTIVE'||!session)throw new ForbiddenException({code:'ACCOUNT_UNAVAILABLE'});
  return row;
 }
 private async receivables(tx:Tx,userId:string):Promise<DeletionPreview> {
  const vendor=await tx.vendors.findUnique({where:{user_id:userId},select:{id:true}});
  const [row]=vendor?await tx.$queryRaw<{due:string}[]>`SELECT coalesce(sum(greatest(b.due_paise,0)),0)::text AS due FROM ledger_balances b JOIN vendor_customers c ON c.id=b.vendor_customer_id WHERE c.vendor_id=${vendor.id}::uuid`:[];
  return {vendor:!!vendor,outstandingReceivablesPaise:row?.due??'0'};
 }
 preview(userId:string){return this.db.$transaction(async tx=>{await this.active(tx,userId);return this.receivables(tx,userId);});}
 async send(userId:string,sessionId:string,deviceId:string,ip:string) {
  const row=await this.db.$transaction(tx=>this.active(tx,userId,sessionId));
  return this.otp.send({mobile:row.mobile,channel:'SMS'},{deviceId,ip},`DELETE_ACCOUNT:${userId}`);
 }
 private receipt(row:{id:string;requested_at:Date;erase_by:Date;status:string}):DeletionReceipt {
  return {requestId:row.id,requestedAt:row.requested_at.toISOString(),eraseBy:row.erase_by.toISOString(),status:row.status};
 }
 async confirm(userId:string,sessionId:string,key:string,code:string,acknowledge:boolean,ip?:string) {
  if(!key?.trim()||key.length>120)throw new BadRequestException({code:'VALIDATION_FAILED'});
  const requestKey=createHash('sha256').update(`${userId}:${key}`).digest('hex');
  const hash=createHmac('sha256',this.config.getOrThrow<string>('OTP_HMAC_PEPPER')).update(`${code}:${acknowledge}`).digest('hex');
  // OTP verification never runs inside a database transaction holding account locks.
  const row=await this.db.$transaction(async tx=>{
   await this.active(tx,userId,sessionId);
   if(BigInt((await this.receivables(tx,userId)).outstandingReceivablesPaise)>0n&&!acknowledge)throw new ConflictException({code:'RECEIVABLES_ACK_REQUIRED'});
   return tx.users.findUniqueOrThrow({where:{id:userId}});
  });
  await this.otp.verify(row.mobile,code,`DELETE_ACCOUNT:${userId}`);
  return this.db.$transaction(async tx=>{
   await this.active(tx,userId,sessionId);
   // Recheck warning after OTP; server state, never a client supplied due amount.
   if(BigInt((await this.receivables(tx,userId)).outstandingReceivablesPaise)>0n&&!acknowledge)throw new ConflictException({code:'RECEIVABLES_ACK_REQUIRED'});
   const [clock]=await tx.$queryRaw<{now:Date;erase:Date}[]>`SELECT clock_timestamp() AS now, clock_timestamp()+interval '30 days' AS erase`;
   const request=await tx.account_deletions.create({data:{user_id:userId,request_key:requestKey,request_hash:hash,requested_at:clock!.now,erase_by:clock!.erase}});
   await tx.users.update({where:{id:userId},data:{status:'DELETED'}});
   await tx.sessions.updateMany({where:{user_id:userId},data:{status:'REVOKED',revoked_at:clock!.now}});
   await tx.devices.updateMany({where:{user_id:userId},data:{push_token:null,push_enabled:false}});
   await tx.vendors.updateMany({where:{user_id:userId},data:{is_suspended:true}});
   await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:'ACCOUNT_DELETION_REQUESTED',entity:'account_deletions',entity_id:request.id,after:{eraseBy:request.erase_by.toISOString(),receivablesAcknowledged:acknowledge},ip}});
   return this.receipt(request);
  }).catch((error:unknown)=>{if(error instanceof HttpException)throw error;throw new ServiceUnavailableException({code:'DELETION_UNAVAILABLE'});});
 }
}
