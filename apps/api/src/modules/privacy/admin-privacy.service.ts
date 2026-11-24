import { BadRequestException, ConflictException, GoneException, HttpException, Injectable, NotFoundException, PayloadTooLargeException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, account_deletions, privacy_exports } from '@prisma/client';
import { createHash, createHmac } from 'node:crypto';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { PrivacyExportInput, PrivacyHoldInput, PrivacyRequestRow } from './admin-privacy.dto';
import { subjectSnapshot } from './subject-snapshot';
type Tx=Prisma.TransactionClient;
@Injectable()
export class AdminPrivacyService {
 constructor(private readonly db:PrismaService,private readonly auth:AdminAuthService,private readonly keys:IdempotencyService,private readonly config:ConfigService){}
 private hash(input:object){
  const key=this.config.get<string>('ADMIN_TOTP_KEY');if(!key||!/^[a-f0-9]{64}$/i.test(key))throw new ServiceUnavailableException({code:'PRIVACY_WRITE_UNAVAILABLE'});
  return createHmac('sha256',key).update('privacy-request:v1:').update(this.keys.hashRequestBody(input)).digest('hex');
 }
 private deletion(r:account_deletions):PrivacyRequestRow{return {id:r.id,userId:r.user_id,kind:'DELETION',status:r.status==='ERASED'&&r.retention_hold_reason?'ERASED_HELD':r.status,createdAt:r.requested_at.toISOString(),deadline:r.erase_by.toISOString(),reason:r.hold_reason??r.retention_hold_reason,version:r.version};}
 private exportRow(r:privacy_exports,now:Date):PrivacyRequestRow{return {id:r.id,userId:r.user_id,kind:'EXPORT',status:r.expires_at>now?'READY':'EXPIRED',createdAt:r.created_at.toISOString(),deadline:r.expires_at.toISOString(),reason:r.reason,version:1};}
 async list(offset:number){
  return this.db.$transaction(async tx=>{
   const [clock]=await tx.$queryRaw<{now:Date}[]>`SELECT statement_timestamp() AS now`;
   const rows=await tx.$queryRaw<{id:string;kind:string}[]>`SELECT id,kind FROM (
    SELECT id,'DELETION' AS kind,requested_at AS created FROM account_deletions
    UNION ALL SELECT id,'EXPORT' AS kind,created_at AS created FROM privacy_exports
   ) r ORDER BY created DESC,id ASC LIMIT 20 OFFSET ${offset}`;
   const deletions=await tx.account_deletions.findMany({where:{id:{in:rows.filter(r=>r.kind==='DELETION').map(r=>r.id)}}});
   const exports=await tx.privacy_exports.findMany({where:{id:{in:rows.filter(r=>r.kind==='EXPORT').map(r=>r.id)}}});
   const lookup=new Map([...deletions.map(r=>this.deletion(r)),...exports.map(r=>this.exportRow(r,clock!.now))].map(r=>[r.id,r]));
   return {items:rows.map(r=>lookup.get(r.id)!),total:await tx.account_deletions.count()+await tx.privacy_exports.count()};
  },{isolationLevel:'RepeatableRead'});
 }
 private async mutate(token:string,csrf:string,key:string,path:string,input:object,work:(tx:Tx,actor:string)=>Promise<PrivacyRequestRow>){
  if(!key?.trim()||key.length>120)throw new BadRequestException({code:'VALIDATION_FAILED'});
  try{return await this.db.$transaction(async tx=>{
   const actor=await this.auth.authenticateInTransaction(tx,token,'privacy.manage',csrf);
   const requestKey=createHash('sha256').update(`privacy:${actor.id}:${key}`).digest('hex'),hash=this.hash(input);
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${requestKey},0))::text`;
   const replay=await tx.management_requests.findUnique({where:{request_key:requestKey}});
   if(replay){if(replay.path!==path||replay.request_hash!==hash)throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});return replay.response;}
   const response=await work(tx,actor.id);
   await tx.management_requests.create({data:{request_key:requestKey,admin_id:actor.id,path,request_hash:hash,response:response as unknown as Prisma.InputJsonObject}});
   return response;
  },{timeout:15000});}catch(e:unknown){if(e instanceof HttpException)throw e;throw new ServiceUnavailableException({code:'PRIVACY_WRITE_UNAVAILABLE'});}
 }
 create(token:string,csrf:string,key:string,input:PrivacyExportInput,ip?:string){return this.mutate(token,csrf,key,'privacy/export',input,async(tx,actor)=>{
  await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${input.userId},0))::text`;
  if(!await tx.users.findUnique({where:{id:input.userId}}))throw new NotFoundException({code:'SUBJECT_NOT_FOUND'});
  const request=await tx.privacy_exports.create({data:{user_id:input.userId,admin_id:actor,reason:input.reason.trim(),request_key:createHash('sha256').update(`${actor}:${key}`).digest('hex'),request_hash:this.hash(input)}});
  await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:actor,action:'SUBJECT_EXPORT_REQUESTED',entity:'privacy_exports',entity_id:request.id,after:{subjectId:input.userId,identityVerified:true},ip}});
  return this.exportRow(request,new Date());
 });}
 hold(token:string,csrf:string,key:string,id:string,input:PrivacyHoldInput,ip?:string){return this.mutate(token,csrf,key,`privacy/hold/${id}`,input,async(tx,actor)=>{
  await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended('privacy-audit-retention',0))::text`;
  const known=await tx.account_deletions.findUnique({where:{id}});if(!known)throw new NotFoundException({code:'PRIVACY_REQUEST_NOT_FOUND'});
  // Same owner -> request lock order as the erasure worker.
  await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${known.user_id},0))::text`;
  await tx.$queryRaw`SELECT id FROM account_deletions WHERE id=${id}::uuid FOR UPDATE`;
  const row=await tx.account_deletions.findUniqueOrThrow({where:{id}});
  const erased=row.status==='ERASED',held=erased?row.retention_hold_reason!==null:row.status==='HELD';
  if(row.version!==input.expectedVersion||!['PENDING_ERASURE','HELD','ERASED'].includes(row.status)||(input.action==='HOLD'?held:!held))throw new ConflictException({code:'PRIVACY_STATE_CHANGED'});
  const status=erased?'ERASED':input.action==='HOLD'?'HELD':'PENDING_ERASURE';
  const saved=await tx.account_deletions.update({where:{id},data:{status,version:{increment:1},...(erased?{
    retention_hold_reason:input.action==='HOLD'?input.reason.trim():null,retention_hold_actor:input.action==='HOLD'?actor:null,retention_hold_at:input.action==='HOLD'?new Date():null
   }:{hold_reason:status==='HELD'?input.reason.trim():null,hold_actor:status==='HELD'?actor:null,hold_at:status==='HELD'?new Date():null})}});
  await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:actor,action:`PRIVACY_${input.action}`,entity:'account_deletions',entity_id:id,before:{status:row.status,version:row.version},after:{status,version:saved.version,reason:input.reason.trim()},ip}});
  return this.deletion(saved);
 });}
 async download(token:string,id:string,ip?:string){
  return this.db.$transaction(async tx=>{
   const actor=await this.auth.authenticateInTransaction(tx,token,'privacy.manage');
   const row=await tx.privacy_exports.findUnique({where:{id}});if(!row||row.admin_id!==actor.id)throw new NotFoundException({code:'PRIVACY_EXPORT_NOT_FOUND'});
   const [clock]=await tx.$queryRaw<{now:Date}[]>`SELECT clock_timestamp() AS now`;
   if(row.expires_at<=clock!.now)throw new GoneException({code:'PRIVACY_EXPORT_EXPIRED'});
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${row.user_id},0))::text`;
   const content=await subjectSnapshot(tx,row.user_id,clock!.now);
   const json=JSON.stringify(content,(_,value:unknown)=>typeof value==='bigint'?value.toString():value,2);
   if(Buffer.byteLength(json)>4*1024*1024)throw new PayloadTooLargeException({code:'SUBJECT_EXPORT_TOO_LARGE'});
   await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:actor.id,action:'SUBJECT_EXPORT_DOWNLOADED',entity:'privacy_exports',entity_id:id,after:{subjectId:row.user_id},ip}});
   return {filename:`subject-${id}.json`,json};
  },{isolationLevel:'RepeatableRead',timeout:30000});
 }
}
