// T-161 / TC-012 / US-405: dedicated local DB and production Next BFF smoke.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash, randomBytes, randomInt, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo, createServer } from 'node:net';
import { resolve, join } from 'node:path';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { PersonalErasureService } from './personal-erasure.service';
import { ExpiredRetentionService } from './expired-retention.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
const testUrl=process.env.NATIVE_TEST_DATABASE_URL;
(testUrl?describe:describe.skip)('T-161 native privacy requests and jobs',()=>{
 const db=new PrismaService({datasources:{db:{url:testUrl}}}),env={...process.env};
 let app:INestApplication,root:{id:string;token:string},peer:{id:string;token:string},ops:{id:string;token:string},subject:string,deletion:string,exportId:string;
 const digest=(s:string)=>createHash('sha256').update(s).digest('hex');
 async function admin(role:string){
  const row=await db.admin_users.create({data:{email:`privacy-${randomUUID()}@example.invalid`,password_hash:'synthetic-unused',role}}),token=randomBytes(32).toString('base64url');
  await db.admin_sessions.create({data:{token_hash:digest(token),admin_id:row.id,csrf_hash:digest('synthetic'),expires_at:new Date(Date.now()+3600000)}});return {id:row.id,token};
 }
 async function user(){return db.users.create({data:{mobile:`+919${randomInt(0,1e9).toString().padStart(9,'0')}`,name:'Synthetic subject'}});}
 async function deleted(userId:string,expired=false){
  await db.users.update({where:{id:userId},data:{status:'DELETED'}});
  return db.account_deletions.create({data:{user_id:userId,request_key:digest(randomUUID()),request_hash:digest(randomUUID()),...(expired?{requested_at:new Date(Date.now()-31*86400000),erase_by:new Date(Date.now()-86400000)}:{})}});
 }
 const get=(path:string,token=root.token)=>request(app.getHttpServer()).get(`/api/v1/admin/data-requests${path}`).set('Authorization',`Bearer ${token}`);
 const post=(path:string,body:object,key:string=randomUUID(),token=root.token,csrf='synthetic')=>request(app.getHttpServer()).post(`/api/v1/admin/data-requests${path}`).set('Authorization',`Bearer ${token}`).set('X-CSRF-Token',csrf).set('Idempotency-Key',key).send(body);
 const body=(userId=subject)=>({userId,identityVerified:true,reason:'Synthetic verified requester'});
 beforeAll(async()=>{
  const u=new URL(testUrl!);if(u.pathname!=='/supplybiz_service_area_test'||!['localhost','127.0.0.1','[::1]'].includes(u.hostname))throw new Error('Dedicated local test DB required');
  Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:testUrl!,OTP_DELIVERY_MODE:'disabled',ADMIN_TOTP_KEY:randomBytes(32).toString('hex'),RATE_LIMIT_MAX_REQUESTS:'10000'});
  await db.$connect();const {AppModule}=await import('../../app.module');
  const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PrismaService).useValue(db).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
  app=module.createNestApplication();configureHttpApp(app);await app.init();root=await admin('SUPER_ADMIN');peer=await admin('SUPER_ADMIN');ops=await admin('OPS');subject=(await user()).id;deletion=(await deleted((await user()).id)).id;
 },60000);
 afterAll(async()=>{await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);},60000);
 it('enforces privacy.manage, strict consent/ownership/CSRF/key validation and pagination',async()=>{
  await get('','').expect(401);await get('',ops.token).expect(403);
  for(const role of ['SUPPORT','FINANCE']){const actor=await admin(role);await get('',actor.token).expect(403);await post('',body(),randomUUID(),actor.token).expect(403);}
  await post('',body(),randomUUID(),root.token,'wrong').expect(403);await post('',body(),'').expect(400);
  await post('',{...body(),identityVerified:false}).expect(400);await post('',{...body(),role:'SUPER_ADMIN'}).expect(400);
  await post('',{...body(),reason:'x  '}).expect(400);
  await post('',body(randomUUID())).expect(404);await get('?offset=-1').expect(400);await get('?offset=100000').expect(200);
 });
 it('creates exactly once, scopes download to its requester, exports exact own values and audits each read',async()=>{
  const key=randomUUID(),responses=await Promise.all([post('',body(),key),post('',body(),key)]);expect(responses.map(r=>r.status)).toEqual([200,200]);expect(responses[0]!.body).toEqual(responses[1]!.body);exportId=responses[0]!.body.id as string;
  await post('',{...body(),reason:'Changed reason'},key).expect(422);
  await get(`/${exportId}/export`,peer.token).expect(404);
  const owner=await user(),foreign=await user();await db.users.update({where:{id:foreign.id},data:{name:'Foreign private contact',email:'foreign-private@example.invalid'}});
  const category=await db.categories.create({data:{code:`PRIVACY_${randomUUID()}`,name_en:'Synthetic category',name_hi:'',type:'SUPPLY'}}),vendor=await db.vendors.create({data:{user_id:owner.id,category_id:category.id}});
  const customer=await db.vendor_customers.create({data:{user_id:subject,vendor_id:vendor.id,name:'Synthetic own customer',mobile:'+919000000000'}});
  await db.vendor_customers.create({data:{user_id:foreign.id,vendor_id:vendor.id,name:'Foreign private contact',mobile:'+919000000001',email:'foreign-private@example.invalid'}});
  await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:9007199254740993n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:owner.id,note:'Excluded free text'}});
  const result=await get(`/${exportId}/export`).expect(200),text=result.body.json as string;
  expect(text).toContain('9007199254740993');expect(text).not.toContain('foreign-private');expect(text).not.toContain('Foreign private contact');expect(text).not.toContain('Excluded free text');expect(text).not.toContain('refresh_token');expect(text).not.toContain('password_hash');
  expect(JSON.parse(text).subjectId).toBe(subject);expect(await db.audit_logs.count({where:{entity_id:exportId,action:'SUBJECT_EXPORT_REQUESTED'}})).toBe(1);
  await get(`/${exportId}/export`).expect(200);expect(await db.audit_logs.count({where:{entity_id:exportId,action:'SUBJECT_EXPORT_DOWNLOADED'}})).toBe(2);
  await db.admin_users.update({where:{id:root.id},data:{role:'SUPPORT'}});await get(`/${exportId}/export`).expect(403);await post('',body(),key).expect(403);await db.admin_users.update({where:{id:root.id},data:{role:'SUPER_ADMIN'}});
 });
 it('holds/releases atomically, rejects stale or irreversible personal states and preserves worker fencing',async()=>{
  const key=randomUUID(),input={action:'HOLD',expectedVersion:1,reason:'Synthetic legal hold'};
  const held=await post(`/${deletion}/hold`,input,key).expect(200);expect(held.body.status).toBe('HELD');expect(held.body.version).toBe(2);
  expect((await post(`/${deletion}/hold`,input,key).expect(200)).body).toEqual(held.body);
  await post(`/${deletion}/hold`,input).expect(409);
  const released=await post(`/${deletion}/hold`,{action:'RELEASE',expectedVersion:2,reason:'Synthetic release'}).expect(200);expect(released.body.version).toBe(3);
  const a=await user(),request=await deleted(a.id,true);await app.get(PersonalErasureService).runBatch();
  const completed=await db.account_deletions.findUniqueOrThrow({where:{id:request.id}});expect(completed.status).toBe('ERASED');expect(completed.version).toBe(3);
  await post(`/${request.id}/hold`,{...input,expectedVersion:1}).expect(409);
  await post(`/${request.id}/hold`,{...input,expectedVersion:3}).expect(200);expect((await db.account_deletions.findUniqueOrThrow({where:{id:request.id}})).retention_hold_reason).toBe(input.reason);
 });
 it('serializes a pending hold against the personal erasure worker',async()=>{
  const a=await user(),row=await deleted(a.id,true);
  const [held]=await Promise.all([post(`/${row.id}/hold`,{action:'HOLD',expectedVersion:1,reason:'Synthetic concurrent hold'}),app.get(PersonalErasureService).runBatch()]);
  const saved=await db.account_deletions.findUniqueOrThrow({where:{id:row.id}});
  if(held.status===200){expect(saved.status).toBe('HELD');expect(saved.erased_at).toBeNull();}
  else{expect(held.status).toBe(409);expect(['ERASING','ERASED']).toContain(saved.status);}
 });
 it('rejects expired download and preserves ordinary financial/audit mutation denial',async()=>{
  const id=(await post('',body()).expect(200)).body.id as string;await db.privacy_exports.update({where:{id},data:{expires_at:new Date(Date.now()-1000)}});await get(`/${id}/export`).expect(410);
  const audit=await db.audit_logs.create({data:{actor_type:'SYSTEM',action:'SYNTHETIC_RETENTION_CHECK',entity:'privacy_test'}});
  await expect(db.audit_logs.delete({where:{id:audit.id}})).rejects.toThrow();
  expect(await app.get(ExpiredRetentionService).runAuditBatch()).toBe(0); // Existing documented test holds conservatively preserve audit evidence.
 });
 it('expires only due financial narratives, preserves replay identities/amounts and rejects ordinary UPDATE grants',async()=>{
  const actor=await user(),owner=await user(),ancient=new Date('2010-01-01T00:00:00Z');
  const category=await db.categories.create({data:{code:`RETENTION_${randomUUID()}`,name_en:'Synthetic retained category',name_hi:'',type:'SUPPLY'}}),vendor=await db.vendors.create({data:{user_id:owner.id,category_id:category.id}});
  const customer=await db.vendor_customers.create({data:{user_id:actor.id,vendor_id:vendor.id,name:'Expired private contact',mobile:'+919000000000',created_at:ancient}});
  const old=await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:9007199254740993n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:owner.id,note:'Expired private narrative',created_at:ancient,entry_date:ancient}});
  const recent=await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:10n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:owner.id,note:'Recent protected narrative'}});
  const [boundary]=await db.$queryRaw<{day:Date}[]>`SELECT (privacy_financial_cutoff() AT TIME ZONE 'Asia/Kolkata')::date AS day`;
  const fyEnd=await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:1n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:owner.id,note:'FY end old narrative',created_at:new Date(boundary!.day.getTime()-2*86400000),entry_date:new Date(boundary!.day.getTime()-86400000)}});
  const nextFY=await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:1n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:owner.id,note:'Next FY protected narrative',created_at:new Date(boundary!.day.getTime()-2*86400000),entry_date:boundary!.day}});
  const clientRef=`payment:${digest(randomUUID())}`,receipt=await db.payments.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,created_by:owner.id,amount_paise:50n,method:'CASH',received_on:ancient,created_at:ancient,note:'Expired payment note',client_ref:clientRef}});
  const secondOwner=await user(),secondVendor=await db.vendors.create({data:{user_id:secondOwner.id,category_id:category.id}});
  const oldOnly=await db.vendor_customers.create({data:{vendor_id:secondVendor.id,user_id:actor.id,name:'Expired only contact',mobile:'+919000000001',created_at:ancient}});
  await db.ledger_entries.create({data:{vendor_id:secondVendor.id,vendor_customer_id:oldOnly.id,type:'DEBIT',amount_paise:700n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:secondOwner.id,note:'Expired old contact balance',created_at:ancient,entry_date:ancient}});
  const before=await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:customer.id}});
  await db.users.update({where:{id:actor.id},data:{status:'DELETED',name:null,mobile:`deleted:${actor.id}`}});
  const deletion=await db.account_deletions.create({data:{user_id:actor.id,status:'ERASED',erased_at:new Date(),request_key:digest(randomUUID()),request_hash:digest(randomUUID())}});
  const worker=app.get(ExpiredRetentionService);
  for(let i=0;i<5;i++){await worker.runFinancialBatch();if((await db.ledger_entries.findUniqueOrThrow({where:{id:old.id}})).note==='Expired retained record')break;}
  expect((await db.ledger_entries.findUniqueOrThrow({where:{id:old.id}})).note).toBe('Expired retained record');
  expect((await db.ledger_entries.findUniqueOrThrow({where:{id:recent.id}})).note).toBe('Recent protected narrative');
  expect((await db.ledger_entries.findUniqueOrThrow({where:{id:fyEnd.id}})).note).toBe('Expired retained record');expect((await db.ledger_entries.findUniqueOrThrow({where:{id:nextFY.id}})).note).toBe('Next FY protected narrative');
  const payment=await db.payments.findUniqueOrThrow({where:{id:receipt.id}});expect(payment.note).toBe('');expect(payment.client_ref).toBe(clientRef);expect(payment.amount_paise).toBe(50n);
  expect((await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:customer.id}})).due_paise).toBe(before.due_paise);
  const tombstone=await db.vendor_customers.findUniqueOrThrow({where:{id:oldOnly.id}});expect(tombstone.privacy_erased_at).not.toBeNull();expect(tombstone.mobile).toBe('');expect(tombstone.deleted_at).toBeNull();
  expect((await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:oldOnly.id}})).due_paise).toBe(700n);
  const [privileges]=await db.$queryRaw<{unsafe:boolean}[]>`SELECT has_any_column_privilege(current_user,'ledger_entries','UPDATE') AS unsafe`;expect(privileges!.unsafe).toBe(false);
  await expect(db.ledger_entries.update({where:{id:old.id},data:{amount_paise:1n}})).rejects.toThrow();
  await db.$transaction(async tx=>{
   const rows=await tx.$queryRaw<{privacy_redact_ledger:number}[]>`SELECT privacy_redact_ledger(${recent.id}::uuid,${actor.id}::uuid)`;
   expect(rows[0]!.privacy_redact_ledger).toBe(0);
  });
  const held=await post(`/${deletion.id}/hold`,{action:'HOLD',expectedVersion:1,reason:'Synthetic retained evidence hold'}).expect(200);expect(held.body.status).toBe('ERASED_HELD');
  const heldEntry=await db.ledger_entries.create({data:{vendor_id:vendor.id,vendor_customer_id:customer.id,type:'DEBIT',amount_paise:1n,ref_type:'OPENING',ref_id:randomUUID(),request_key:digest(randomUUID()),request_hash:digest(randomUUID()),created_by:owner.id,note:'Held old evidence',created_at:ancient,entry_date:ancient}});
  const denied=await db.$queryRaw<{privacy_redact_ledger:number}[]>`SELECT privacy_redact_ledger(${heldEntry.id}::uuid,${actor.id}::uuid)`;expect(denied[0]!.privacy_redact_ledger).toBe(0);
  expect((await db.ledger_entries.findUniqueOrThrow({where:{id:heldEntry.id}})).note).toBe('Held old evidence');
 });
 it('expires old audit payloads while retaining settlement proofs in a rollback-only scenario',async()=>{
  const heldBefore=await db.account_deletions.count({where:{OR:[{status:'HELD'},{retention_hold_reason:{not:null}}]}});
  await expect(db.$transaction(async tx=>{
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended('privacy-audit-retention',0))::text`;
   // Scenario data is uncommitted and fully rolled back; existing holds/history remain intact.
   await tx.account_deletions.updateMany({where:{status:'HELD'},data:{status:'PENDING_ERASURE',hold_reason:null,hold_actor:null,hold_at:null}});
   await tx.account_deletions.updateMany({where:{retention_hold_reason:{not:null}},data:{retention_hold_reason:null,retention_hold_actor:null,retention_hold_at:null}});
   const category=await tx.categories.findFirstOrThrow({where:{type:'SUPPLY'}}),plan=await tx.plans.findFirstOrThrow();
   const vendor=await tx.vendors.create({data:{user_id:subject,category_id:category.id}});
   const old=await tx.audit_logs.create({data:{actor_type:'SYSTEM',action:'SYNTHETIC_OLD_AUDIT',entity:'privacy_test',at:new Date('1900-01-01T00:00:00Z'),after:{private:'Synthetic expired text'}}});
   const auth=await tx.admin_auth_events.create({data:{admin_id:root.id,action:'SYNTHETIC_OLD_AUTH',at:new Date('1900-01-01T00:00:00Z')}});
   const cacheKey=digest(randomUUID());await tx.idempotency_keys.create({data:{idempotency_key:cacheKey,method:'POST',path:'privacy_test',request_hash:digest('synthetic'),response_status:200,response_body:{private:'Synthetic expired cache'},expires_at:new Date('1900-01-01T00:00:00Z')}});
   const proof=await tx.audit_logs.create({data:{actor_type:'ADMIN',actor_id:root.id,action:'PLAN_ASSIGNED',entity:'VENDOR',entity_id:vendor.id,at:new Date('1900-01-01T00:00:00Z'),after:{private:'Synthetic proof payload'},ip:'192.0.2.1'}});
   const replayKey=digest(randomUUID());await tx.management_requests.create({data:{request_key:replayKey,admin_id:root.id,path:'privacy/export',request_hash:digest('synthetic'),response:{id:randomUUID(),reason:'Synthetic expired reason',status:'READY'},created_at:new Date('1900-01-01T00:00:00Z')}});
   await tx.vendor_plan_assignments.create({data:{vendor_id:vendor.id,plan_id:plan.id,starts_at:new Date('2010-01-01T00:00:00Z'),ends_at:new Date('2011-01-01T00:00:00Z'),reason:'Synthetic old proof',granted_by_admin:root.id,audit_id:proof.id}});
   const [result]=await tx.$queryRaw<{removed:number;minimized:number}[]>`SELECT * FROM privacy_expire_audits()`;
   expect(result!.removed).toBeGreaterThan(0);expect(result!.minimized).toBeGreaterThan(0);
   const [sources]=await tx.$queryRaw<{count:number}[]>`SELECT privacy_expire_sources() AS count`;expect(sources!.count).toBeGreaterThan(0);
   expect(await tx.admin_auth_events.findUnique({where:{id:auth.id}})).toBeNull();expect(await tx.idempotency_keys.findUnique({where:{idempotency_key:cacheKey}})).toBeNull();
   expect((await tx.management_requests.findUniqueOrThrow({where:{request_key:replayKey}})).response).toMatchObject({reason:null,status:'READY'});
   expect(await tx.audit_logs.findUnique({where:{id:old.id}})).toBeNull();
   const retained=await tx.audit_logs.findUniqueOrThrow({where:{id:proof.id}});expect(retained.actor_id).toBe(root.id);expect(retained.after).toBeNull();expect(retained.ip).toBeNull();
   await expect(app.get(PlanEntitlementsService).requireOperation(tx,vendor.id,'READ_HISTORY')).resolves.toBeDefined();
   throw new Error('ROLLBACK_PRIVACY_AUDIT_SCENARIO');
  },{timeout:30000})).rejects.toThrow('ROLLBACK_PRIVACY_AUDIT_SCENARIO');
  expect(await db.account_deletions.count({where:{OR:[{status:'HELD'},{retention_hold_reason:{not:null}}]}})).toBe(heldBefore);
 });
 it('refuses oversized subject exports with no partial data or successful download audit',async()=>{
  const a=await user(),contact=await db.personal_contacts.create({data:{id:randomUUID(),user_id:a.id,name:'Synthetic private contact'}});
  await db.personal_entries.createMany({data:Array.from({length:1001},()=>({id:randomUUID(),user_id:a.id,contact_id:contact.id,direction:'GAVE',amount_paise:1n,date:new Date('2026-11-24T00:00:00Z')}))});
  const id=(await post('',body(a.id)).expect(200)).body.id as string;
  const response=await get(`/${id}/export`).expect(413);expect(JSON.stringify(response.body)).not.toContain('Synthetic private contact');
  expect(await db.audit_logs.count({where:{entity_id:id,action:'SUBJECT_EXPORT_DOWNLOADED'}})).toBe(0);
 });
 it('serves production Next privacy forms and BFF export with origin/CSRF checks',async()=>{
  await app.listen(0,'127.0.0.1');const apiPort=(app.getHttpServer().address() as AddressInfo).port;
  const reservation=createServer();await new Promise<void>(r=>reservation.listen(0,'127.0.0.1',r));const port=(reservation.address() as AddressInfo).port;await new Promise<void>(r=>reservation.close(()=>r()));
  const origin=`http://127.0.0.1:${port}`,adminRoot=resolve(__dirname,'../../../../','admin');
  const child=spawn(process.execPath,[join(adminRoot,'node_modules/next/dist/bin/next'),'start','--hostname','127.0.0.1','--port',String(port)],{cwd:adminRoot,env:{...process.env,NODE_ENV:'production',ADMIN_ORIGIN:origin,ADMIN_API_URL:`http://127.0.0.1:${apiPort}`,ADMIN_CSRF_KEY:randomBytes(32).toString('hex'),NEXT_TELEMETRY_DISABLED:'1'},stdio:'ignore',windowsHide:true});
  const call=(path:string,body?:FormData,suppliedOrigin=origin)=>fetch(`${origin}${path}`,{method:body?'POST':'GET',redirect:'manual',body,headers:{Cookie:`sb_admin=${root.token}; sb_csrf=synthetic`,...(body?{Origin:suppliedOrigin}:{})}});
  const formFrom=(html:string)=>{const form=new FormData();for(const [element] of html.matchAll(/<input\b[^>]*>/g)){const name=/name="([^"]+)"/.exec(element)?.[1];if(name)form.set(name,/value="([^"]*)"/.exec(element)?.[1]??'on');}return form;};
  try{
   let ready=false;for(let i=0;i<100;i++){try{if((await call('/privacy')).status===200){ready=true;break;}}catch{/* Native startup */}await new Promise(r=>setTimeout(r,100));}expect(ready).toBe(true);
   const html=await (await call('/privacy')).text();expect(html).toContain('Privacy requests');expect(html).not.toContain(root.token);
   const createHtml=/<form\b[^>]*>([\s\S]*?)<\/form>/.exec(html)?.[1];expect(createHtml).toBeDefined();const form=formFrom(createHtml!);form.set('userId',subject);form.set('reason','Synthetic BFF export request');form.set('identityVerified','on');
   expect((await call('/privacy/save',form,'https://foreign.example.invalid')).status).toBe(403);expect((await call('/privacy/save',form)).status).toBe(200);expect((await call('/privacy/save',form)).status).toBe(200);
   const updated=await (await call('/privacy')).text(),forms=[...updated.matchAll(/<form\b[^>]*>([\s\S]*?)<\/form>/g)].map(m=>m[1]!);
   const holdHtml=forms.find(f=>f.includes(`value="${deletion}"`)&&f.includes('value="HOLD"'));expect(holdHtml).toBeDefined();const holdForm=formFrom(holdHtml!);holdForm.set('reason','Synthetic BFF legal hold');holdForm.set('confirm','on');expect((await call('/privacy/save',holdForm)).status).toBe(200);expect((await call('/privacy/save',holdForm)).status).toBe(200);
   const heldHtml=await (await call('/privacy')).text();const releaseHtml=[...heldHtml.matchAll(/<form\b[^>]*>([\s\S]*?)<\/form>/g)].map(m=>m[1]!).find(f=>f.includes(`value="${deletion}"`)&&f.includes('value="RELEASE"'));expect(releaseHtml).toBeDefined();const release=formFrom(releaseHtml!);release.set('reason','Synthetic BFF hold released');release.set('confirm','on');expect((await call('/privacy/save',release)).status).toBe(200);
   const downloadHtml=forms.find(f=>f.includes('value="download"'));expect(downloadHtml).toBeDefined();const download=formFrom(downloadHtml!);const response=await call('/privacy/save',download);expect(response.status).toBe(200);expect(response.headers.get('content-disposition')).toContain('attachment');expect(response.headers.get('cache-control')).toBe('no-store');expect(JSON.parse(await response.text()).subjectId).toBe(subject);
   download.set('csrf','bad');expect((await call('/privacy/save',download)).status).toBe(403);
  }finally{child.kill();await new Promise<void>(r=>{if(child.exitCode!==null)r();else child.once('exit',()=>r());});}
 },60000);
});
