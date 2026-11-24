// T-019 / TC-012. Real isolated PostgreSQL, real OTP HMAC/store; delivery captured in memory.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash, generateKeyPairSync, randomBytes, randomInt, randomUUID } from 'node:crypto';
import { access, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { ConsoleOtpProvider } from '../auth/otp.providers';
import { OTP_PROVIDERS } from '../auth/otp.types';
import { OtpService } from '../auth/otp.service';
import { LocalStorageService } from '../../storage/local-storage.service';
import { PersonalErasureService } from './personal-erasure.service';
import { SessionTokensService } from '../auth/session-tokens.service';
const url=process.env.NATIVE_TEST_DATABASE_URL;
(url?describe:describe.skip)('T-019 account deletion HTTP/PostgreSQL',()=>{
 const db=new PrismaService({datasources:{db:{url}}}),env={...process.env},codes=new Map<string,string>();
 const provider=new ConsoleOtpProvider('test',async delivery=>{codes.set(delivery.mobile,delivery.code);});
 let app:INestApplication;
 async function actor(){
  const mobile=`+919${randomInt(0,1e9).toString().padStart(9,'0')}`;
  const user=await db.users.create({data:{mobile,roles:{create:{role:'CUSTOMER'}}}}),refresh=randomBytes(32).toString('base64url');
  const device=await db.devices.create({data:{user_id:user.id,platform:'ANDROID',push_token:`synthetic-${randomUUID()}`}});
  const session=await db.sessions.create({data:{user_id:user.id,device_id:device.id,family_id:randomUUID(),refresh_token_hash:createHash('sha256').update(refresh).digest('hex'),expires_at:new Date(Date.now()+3600000)}});
  return {id:user.id,mobile,refresh,token:app.get(SessionTokensService).issue(user.id,session.id,['CUSTOMER'])};
 }
 const read=(token:string)=>request(app.getHttpServer()).get('/api/v1/me/deletion').set('Authorization',`Bearer ${token}`);
 const send=(token:string)=>request(app.getHttpServer()).post('/api/v1/me/deletion/otp').set('Authorization',`Bearer ${token}`).set('X-Device-Id',randomUUID()).set('Idempotency-Key',randomUUID()).send({});
 const confirm=(token:string,code:string,extra:object={},key:string=randomUUID())=>request(app.getHttpServer()).post('/api/v1/me/deletion').set('Authorization',`Bearer ${token}`).set('Idempotency-Key',key).send({code,acknowledgeReceivables:true,...extra});
 beforeAll(async()=>{
  const parsed=new URL(url!);if(parsed.pathname!=='/supplybiz_service_area_test'||!['127.0.0.1','localhost','[::1]'].includes(parsed.hostname))throw new Error('Dedicated local test database required');
  Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url!,FIELD_ENCRYPTION_KEY:randomBytes(32).toString('hex'),OTP_DELIVERY_MODE:'console',OTP_HMAC_PEPPER:randomBytes(32).toString('hex'),RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_KEY_ID:'synthetic-deletion',AUTH_PREVIOUS_PUBLIC_KEYS:'{}',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
  await db.$connect();const {AppModule}=await import('../../app.module');
  const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PrismaService).useValue(db).overrideProvider(OTP_PROVIDERS).useValue({SMS:provider,WHATSAPP:provider}).overrideProvider(PinoLogger).useValue({log:jest.fn(),error:jest.fn(),warn:jest.fn()}).compile();
  app=module.createNestApplication();configureHttpApp(app);await app.init();
 },60000);
 afterAll(async()=>{await app?.close();await db.$disconnect();codes.clear();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);},60000);
 it('requires a live owned session, strict body, valid OTP and mutation key',async()=>{
  const a=await actor();await read('').expect(401);await read(a.token).expect(200);
  await confirm(a.token,'123456',{userId:a.id}).expect(400);await confirm(a.token,'123456',{},'').expect(400);
  await confirm(a.token,'123456').expect(410);expect((await db.users.findUniqueOrThrow({where:{id:a.id}})).status).toBe('ACTIVE');
 });
 it('separates deletion OTP from login/other account OTP and shares send cooldown budgets',async()=>{
  const a=await actor(),b=await actor();await send(a.token).expect(200);const code=codes.get(a.mobile)!;
  await expect(app.get(OtpService).verify(a.mobile,code)).rejects.toMatchObject({status:410});
  await expect(app.get(OtpService).verify(a.mobile,code,`DELETE_ACCOUNT:${b.id}`)).rejects.toMatchObject({status:410});
  await send(a.token).expect(429);
  await confirm(b.token,code).expect(410);
  expect(await db.account_deletions.count({where:{user_id:{in:[a.id,b.id]}}})).toBe(0);
 });
 it('confirms once, revokes all sessions/push, records 30-day deadline and prevents old account access',async()=>{
  const a=await actor();
  await db.sessions.create({data:{user_id:a.id,family_id:randomUUID(),refresh_token_hash:randomBytes(32).toString('hex'),expires_at:new Date(Date.now()+3600000)}});
  await send(a.token).expect(200);const code=codes.get(a.mobile)!;
  const wrong=code==='000000'?'111111':'000000';await confirm(a.token,wrong).expect(422);
  const result=await confirm(a.token,code).expect(200);
  expect(result.body.status).toBe('PENDING_ERASURE');expect(new Date(result.body.eraseBy).getTime()-new Date(result.body.requestedAt).getTime()).toBeGreaterThanOrEqual(30*86400000);
  expect((await db.users.findUniqueOrThrow({where:{id:a.id}})).status).toBe('DELETED');
  expect(await db.sessions.count({where:{user_id:a.id,status:'ACTIVE'}})).toBe(0);
  expect(await db.devices.count({where:{user_id:a.id,OR:[{push_enabled:true},{push_token:{not:null}}]}})).toBe(0);
  await read(a.token).expect(401);await confirm(a.token,code).expect(401);
  await request(app.getHttpServer()).post('/api/v1/auth/refresh').set('Idempotency-Key',randomUUID()).send({refreshToken:a.refresh}).expect(401);
  expect(await db.account_deletions.count({where:{user_id:a.id}})).toBe(1);
  const audit=await db.audit_logs.findMany({where:{actor_id:a.id,action:'ACCOUNT_DELETION_REQUESTED'}});expect(audit).toHaveLength(1);expect(JSON.stringify(audit)).not.toContain(a.mobile);expect(JSON.stringify(audit)).not.toContain(code);
 });
 it('a failing durable write rolls deactivation back and leaves sessions usable',async()=>{
  const a=await actor();await send(a.token).expect(200);const code=codes.get(a.mobile)!;
  // A pre-existing queue record forces the unique-user constraint to fail after OTP.
  await db.account_deletions.create({data:{user_id:a.id,request_key:randomBytes(32).toString('hex'),request_hash:randomBytes(32).toString('hex')}});
  await confirm(a.token,code).expect(503);
  expect((await db.users.findUniqueOrThrow({where:{id:a.id}})).status).toBe('ACTIVE');await read(a.token).expect(200);
 });
 it('warns about exact vendor receivables and preserves all ledger entries and balances',async()=>{
  const a=await actor();await db.user_roles.create({data:{user_id:a.id,role:'VENDOR'}});
  const category=await db.categories.create({data:{code:`DELETE_${randomUUID()}`,name_en:'Synthetic deletion fixture',name_hi:'',type:'SUPPLY'}});
  const vendor=await db.vendors.create({data:{user_id:a.id,category_id:category.id}});
  const customer=await db.vendor_customers.create({data:{vendor_id:vendor.id,name:'Synthetic counterparty',mobile:'+919000000000'}});
  const amount=9007199254740993n;
  const entry=await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:amount,ref_type:'OPENING',request_key:randomBytes(32).toString('hex'),request_hash:randomBytes(32).toString('hex'),ref_id:randomUUID(),created_by:a.id,note:'Synthetic deletion retention fixture'}});
  expect((await read(a.token).expect(200)).body).toEqual({vendor:true,outstandingReceivablesPaise:String(amount)});
  await send(a.token).expect(200);const code=codes.get(a.mobile)!;
  await confirm(a.token,code,{acknowledgeReceivables:false}).expect(409);
  await confirm(a.token,code).expect(200);
  expect((await db.vendors.findUniqueOrThrow({where:{id:vendor.id}})).is_suspended).toBe(true);
  expect((await db.ledger_entries.findUniqueOrThrow({where:{id:entry.id}})).amount_paise).toBe(amount);
  expect((await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:customer.id}})).due_paise).toBe(amount);
 });
 it('erases due profile/KYC files, resumes after a file failure, and honors a documented legal hold',async()=>{
  const a=await actor(),held=await actor();
  const reviewer=await db.admin_users.create({data:{email:`retention-${randomUUID()}@example.invalid`,password_hash:'synthetic-unused',role:'SUPER_ADMIN'}});
  const category=await db.categories.create({data:{code:`ERASE_${randomUUID()}`,name_en:'Synthetic erasure',name_hi:'',type:'SUPPLY'}});
  const vendor=await db.vendors.create({data:{user_id:a.id,category_id:category.id,business_name:'Synthetic business',is_suspended:true}});
  const mediaId=randomUUID(),key=`kyc/${mediaId}.pdf`,file=join(app.get(LocalStorageService).root,key);
  await writeFile(file,Buffer.from('synthetic KYC fixture'),{flag:'wx',mode:0o600});
  await db.media_files.create({data:{id:mediaId,owner_user_id:a.id,purpose:'KYC_DOC',relative_storage_key:key,mime:'application/pdf',size:21,sha256:'0'.repeat(64),request_key:randomBytes(32).toString('hex'),request_hash:randomBytes(32).toString('hex')}});
  const kyc=await db.vendor_kyc.create({data:{vendor_id:vendor.id,aadhaar_front_media_id:mediaId,aadhaar_back_media_id:mediaId,pan_media_id:mediaId,pan_enc:'synthetic-cipher',pan_last4:'0000',account_number_enc:'synthetic-cipher',account_last4:'0000',holder_name:'Synthetic holder',bank_name:'Synthetic bank',ifsc:'TEST0000000'}});
  const earlier=new Date(Date.now()-31*86400000),due=new Date(Date.now()-86400000);
  const data=(userId:string)=>({user_id:userId,requested_at:earlier,erase_by:due,request_key:randomBytes(32).toString('hex'),request_hash:randomBytes(32).toString('hex')});
  await db.users.updateMany({where:{id:{in:[a.id,held.id]}},data:{status:'DELETED',name:'Synthetic personal name',email:'synthetic@example.invalid'}});
  const adminToken=randomBytes(32).toString('base64url');
  await db.admin_sessions.create({data:{admin_id:reviewer.id,token_hash:createHash('sha256').update(adminToken).digest('hex'),csrf_hash:createHash('sha256').update('synthetic').digest('hex'),expires_at:new Date(Date.now()+3600000)}});
  await request(app.getHttpServer()).post(`/api/v1/admin/kyc/${kyc.id}/decision`).set('Authorization',`Bearer ${adminToken}`).set('X-CSRF-Token','synthetic').set('Idempotency-Key',randomUUID()).send({decision:'VERIFIED',reason:'Synthetic deleted account review'}).expect(409);
  const deletion=await db.account_deletions.create({data:data(a.id)});
  const cacheKey=randomUUID(),replayKey=randomBytes(32).toString('hex');
  await db.idempotency_keys.create({data:{idempotency_key:cacheKey,method:'GET',path:'/synthetic/profile',request_hash:'0'.repeat(64),response_status:200,response_body:{id:a.id,name:'Synthetic cached name'},expires_at:due}});
  await db.management_requests.create({data:{request_key:replayKey,admin_id:reviewer.id,path:`BLOCK/${a.id}`,request_hash:'0'.repeat(64),response:{id:a.id,name:'Synthetic cached name',mobile:a.mobile,status:'DELETED'}}});
  await expect(db.management_requests.update({where:{request_key:replayKey},data:{response:{id:a.id,status:'ACTIVE'}}})).rejects.toThrow('append-only');
  const hold=await db.account_deletions.create({data:{...data(held.id),status:'HELD',hold_actor:reviewer.id,hold_reason:'Synthetic legal hold',hold_at:new Date()}});
  const worker=app.get(PersonalErasureService),storage=app.get(LocalStorageService);
  const check=jest.spyOn(storage,'check').mockRejectedValue(new Error('Synthetic disk failure'));
  await expect(worker.runBatch()).rejects.toThrow('Synthetic disk failure');check.mockRestore();
  expect((await db.account_deletions.findUniqueOrThrow({where:{id:deletion.id}})).status).toBe('ERASING');
  await worker.runBatch();await worker.runBatch();
  expect((await db.account_deletions.findUniqueOrThrow({where:{id:deletion.id}})).status).toBe('ERASED');
  expect((await db.account_deletions.findUniqueOrThrow({where:{id:hold.id}})).status).toBe('HELD');
  expect(await db.idempotency_keys.findUnique({where:{idempotency_key:cacheKey}})).toBeNull();
  expect((await db.management_requests.findUniqueOrThrow({where:{request_key:replayKey}})).response).toEqual({id:a.id,name:null,mobile:'',status:'DELETED'});
  const erased=await db.users.findUniqueOrThrow({where:{id:a.id}});expect(erased.mobile).toBe(`deleted:${a.id}`);expect(erased.name).toBeNull();expect(erased.email).toBeNull();
  expect((await db.vendor_kyc.findUniqueOrThrow({where:{id:kyc.id}})).pan_enc).toBe('');
  await expect(db.vendor_kyc.update({where:{id:kyc.id},data:{pan_enc:'cannot restore erased identity'}})).rejects.toThrow();
  expect((await db.media_files.findUniqueOrThrow({where:{id:mediaId}})).status).toBe('ERASED');
  await expect(access(file)).rejects.toMatchObject({code:'ENOENT'});
  expect((await db.users.findUniqueOrThrow({where:{id:held.id}})).name).toBe('Synthetic personal name');
  // Re-registration uses a distinct ID; no existing ownership/FK is reassigned.
  const fresh=await db.users.create({data:{mobile:a.mobile}});expect(fresh.id).not.toBe(a.id);
  expect(await db.vendors.count({where:{user_id:fresh.id}})).toBe(0);
 });
});
