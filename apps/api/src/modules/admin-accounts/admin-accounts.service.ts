import { BadRequestException, ConflictException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma, admin_users } from '@prisma/client';
import { createHash, createHmac } from 'node:crypto';
import * as argon2 from 'argon2';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { assertUnbreached } from '../admin-auth/admin-password';
import { auditContext } from '../audit/audit-context';
import { csvNumber, csvText } from '../reports/report-csv';
import { AdminAccountResponse, ChangeAdminInput, CreateAdminInput, PlatformExportInput, PlatformExportResponse } from './admin-accounts.dto';
@Injectable()
export class AdminPasswordCheck { check(password:string) { return assertUnbreached(password); } }
type Tx = Prisma.TransactionClient;
@Injectable()
export class AdminAccountsService {
 constructor(private readonly db:PrismaService, private readonly auth:AdminAuthService, private readonly config:ConfigService, private readonly passwords:AdminPasswordCheck) {}
 private view(row:admin_users):AdminAccountResponse { return {id:row.id,email:row.email,role:row.role,status:row.status,totpEnrolled:row.totp_secret_enc!==null,updatedAt:row.updated_at.toISOString()}; }
 async list(offset:number) {
  return this.db.$transaction(async tx => ({items:(await tx.admin_users.findMany({orderBy:[{created_at:'desc'},{id:'asc'}],take:20,skip:offset})).map(row=>this.view(row)),total:await tx.admin_users.count()}),{isolationLevel:'RepeatableRead'});
 }
 private async transaction<T>(work:(tx:Tx)=>Promise<T>):Promise<T> {
  try { return await this.db.$transaction(work,{timeout:15000}); }
  catch(error:unknown) { if(error instanceof HttpException)throw error; if(error instanceof Prisma.PrismaClientKnownRequestError && error.code==='P2002')throw new ConflictException({code:'ADMIN_EMAIL_EXISTS'}); throw new ServiceUnavailableException({code:'ADMIN_OPERATION_UNAVAILABLE'}); }
 }
 private async request(tx:Tx,token:string,csrf:string,key:string,path:string,input:object,permission:string) {
  if(!key?.trim()||key.length>120)throw new BadRequestException({code:'VALIDATION_FAILED'});
  // Serialize before acquiring the actor row: two super admins cannot demote each other concurrently.
  if(permission==='admins.manage')await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended('admin-account-management',0))::text`;
  const actor=await this.auth.authenticateInTransaction(tx,token,permission,csrf);
  const secret=this.config.get<string>('ADMIN_TOTP_KEY');
  if(!secret||!/^[a-f0-9]{64}$/i.test(secret))throw new ServiceUnavailableException({code:'ADMIN_OPERATION_UNAVAILABLE'});
  const requestKey=createHash('sha256').update(`admin-accounts:${actor.id}:${key}`).digest('hex');
  // Keyed digest prevents offline guessing of creation passwords from a replay record.
  const hash=createHmac('sha256',secret).update(JSON.stringify(input,Object.keys(input).sort())).digest('hex');
  await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${requestKey},0))::text`;
  const cached=await tx.idempotency_keys.findUnique({where:{idempotency_key:requestKey}});
  if(cached && (cached.path!==path||cached.request_hash!==hash))throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
  if(cached && cached.expires_at<=new Date())await tx.idempotency_keys.delete({where:{idempotency_key:requestKey}});
  return {actor,requestKey,hash,cached:cached && cached.expires_at>new Date()?cached.response_body:null};
 }
 private save(tx:Tx,r:{requestKey:string;hash:string},path:string,response:object) {
  return tx.idempotency_keys.create({data:{idempotency_key:r.requestKey,method:'POST',path,request_hash:r.hash,response_status:200,response_body:response as Prisma.InputJsonObject,expires_at:new Date(Date.now()+86400000)}});
 }
 async create(token:string,csrf:string,key:string,input:CreateAdminInput,ip?:string) {
  const body={email:input.email.trim().toLowerCase(),password:input.password,role:input.role,reason:input.reason.trim()},path='admin/admins';
  const replay=await this.transaction(async tx=>(await this.request(tx,token,csrf,key,path,body,'admins.manage')).cached);
  if(replay)return replay;
  // Never hold database locks during network breach checking or password hashing.
  try { await this.passwords.check(body.password); }
  catch(error:unknown) { if(error instanceof Error && error.message==='Password appears in a breach')throw new BadRequestException({code:'PASSWORD_BREACHED'}); throw new ServiceUnavailableException({code:'PASSWORD_CHECK_UNAVAILABLE'}); }
  let passwordHash:string;
  try { passwordHash=await argon2.hash(body.password,{type:argon2.argon2id}); } catch { throw new ServiceUnavailableException({code:'PASSWORD_HASH_UNAVAILABLE'}); }
  return this.transaction(async tx=>{
   const r=await this.request(tx,token,csrf,key,path,body,'admins.manage'); if(r.cached)return r.cached;
   await auditContext(tx,r.actor.id,ip);
   // Existing database trigger records safe role/status snapshots, never credentials.
   const row=await tx.admin_users.create({data:{email:body.email,role:body.role,password_hash:passwordHash}}),response=this.view(row);
   await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:r.actor.id,action:'ADMIN_ACCOUNT_REASON',entity:'admin_users',entity_id:row.id,after:{reason:body.reason},ip}});
   await this.save(tx,r,path,response);return response;
  });
 }
 async change(token:string,csrf:string,key:string,id:string,input:ChangeAdminInput,ip?:string) {
  const path=`admin/admins/${id}`;
  return this.transaction(async tx=>{
   const r=await this.request(tx,token,csrf,key,path,input,'admins.manage');if(r.cached)return r.cached;
   if(r.actor.id===id)throw new ConflictException({code:'ADMIN_SELF_CHANGE_FORBIDDEN'});
   await auditContext(tx,r.actor.id,ip);
   await tx.$queryRaw`SELECT id FROM admin_users WHERE id=${id}::uuid FOR UPDATE`;
   const before=await tx.admin_users.findUnique({where:{id}});if(!before)throw new NotFoundException({code:'ADMIN_NOT_FOUND'});
   if(before.updated_at.getTime()!==new Date(input.expectedUpdatedAt).getTime())throw new ConflictException({code:'ADMIN_CHANGED'});
   const row=await tx.admin_users.update({where:{id},data:{role:input.role,status:input.status,updated_at:new Date(Math.max(Date.now(),before.updated_at.getTime()+1))}});
   if(before.role!==row.role||before.status!==row.status) {
    await tx.admin_sessions.deleteMany({where:{admin_id:id}});
    await tx.admin_auth_challenges.deleteMany({where:{admin_id:id}});
   }
   await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:r.actor.id,action:'ADMIN_ACCOUNT_REASON',entity:'admin_users',entity_id:id,after:{reason:input.reason.trim()},ip}});
   const response=this.view(row);await this.save(tx,r,path,response);return response;
  });
 }
 async export(token:string,csrf:string,key:string,input:PlatformExportInput,ip?:string) {
  const path='admin/reports/exports';
  return this.transaction(async tx=>{
   const r=await this.request(tx,token,csrf,key,path,input,'reports.export');if(r.cached)return r.cached;
   const [row]=await tx.$queryRaw<{now:Date;vendors:string;pending:string;customers:string;orders:string;delivered:string;orderGross:string;posGross:string;assignments:string}[]>`
    SELECT statement_timestamp() AS now,
     (SELECT count(*)::text FROM vendors) AS vendors,
     (SELECT count(*)::text FROM vendors WHERE kyc_status IN ('PENDING','MANUAL_REVIEW')) AS pending,
     (SELECT count(*)::text FROM users u WHERE EXISTS(SELECT 1 FROM user_roles r WHERE r.user_id=u.id AND r.role='CUSTOMER')) AS customers,
     (SELECT count(*)::text FROM orders) AS orders,
     (SELECT count(*)::text FROM orders WHERE status='DELIVERED') AS delivered,
     (SELECT coalesce(sum(total_paise),0)::text FROM orders WHERE status='DELIVERED') AS "orderGross",
     (SELECT coalesce(sum(total_paise),0)::text FROM sales) AS "posGross",
     (SELECT count(*)::text FROM vendor_plan_assignments) AS assignments`;
   const s=row!,snapshotAt=s.now.toISOString();
   const lines=[['metric','value','unit','scope'].map(csvText).join(','),['snapshot_at',snapshotAt,'UTC','CURRENT_STATE'].map(csvText).join(',')];
   for(const [metric,value,unit,scope] of [
    ['vendors',s.vendors,'count','CURRENT_STATE'],['kyc_pending',s.pending,'count','CURRENT_STATE'],['customers',s.customers,'count','CURRENT_STATE'],
    ['orders',s.orders,'count','ALL_TIME_RETAINED'],['delivered_orders',s.delivered,'count','ALL_TIME_RETAINED'],
    ['delivered_order_gross',s.orderGross,'paise','ALL_TIME_RETAINED'],['pos_gross',s.posGross,'paise','ALL_TIME_RETAINED'],
    ['recorded_gross',String(BigInt(s.orderGross)+BigInt(s.posGross)),'paise','DELIVERED_ORDERS_AND_POS'],['plan_assignments',s.assignments,'count','ALL_TIME_RETAINED'],
   ])lines.push([csvText(metric!),csvNumber(value!),csvText(unit!),csvText(scope!)].join(','));
   lines.push(['plan_revenue','UNAVAILABLE','paise','MANUAL_ASSIGNMENTS_ARE_NOT_REVENUE'].map(csvText).join(','));
   const response:PlatformExportResponse={filename:`platform-summary-${snapshotAt.slice(0,10)}.csv`,snapshotAt,csv:'\ufeff'+lines.join('\r\n')+'\r\n'};
   await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:r.actor.id,action:'PLATFORM_REPORT_EXPORTED',entity:'platform_reports',after:{kind:input.kind,snapshotAt},ip}});
   await this.save(tx,r,path,response);return response;
  });
 }
}
