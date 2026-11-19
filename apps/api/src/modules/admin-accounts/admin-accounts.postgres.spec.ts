// T-162 / US-400 / FR-413: isolated native PostgreSQL and production BFF smoke.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomBytes, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo, createServer } from 'node:net';
import { join, resolve } from 'node:path';
import request from 'supertest';
import * as argon2 from 'argon2';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { digest, totp } from '../admin-auth/admin-crypto';
import { AdminPasswordCheck } from './admin-accounts.service';
const testUrl=process.env.NATIVE_TEST_DATABASE_URL;
(testUrl?describe:describe.skip)('T-162 native accounts, RBAC and platform export',()=>{
 const db=new PrismaService({datasources:{db:{url:testUrl}}}),env={...process.env};
 const checker={check:jest.fn(async (_password:string)=>{})};
 let app:INestApplication;
 let root:{id:string;token:string},finance:{id:string;token:string},ops:{id:string;token:string},support:{id:string;token:string};
 async function admin(role:string) {
  const row=await db.admin_users.create({data:{email:`roles-${randomUUID()}@example.invalid`,role,password_hash:'synthetic-unused'}}),token=randomBytes(32).toString('base64url');
  await db.admin_sessions.create({data:{token_hash:digest(token),admin_id:row.id,csrf_hash:digest('synthetic'),expires_at:new Date(Date.now()+3600000)}});
  return {id:row.id,token};
 }
 const get=(path:string,token=root.token)=>request(app.getHttpServer()).get(`/api/v1/admin/${path}`).set('Authorization',`Bearer ${token}`);
 const write=(path:string,body:object,key:string=randomUUID(),token=root.token,csrf='synthetic',patch=false)=>{
  const agent=request(app.getHttpServer()),call=patch?agent.patch(`/api/v1/admin/${path}`):agent.post(`/api/v1/admin/${path}`);
  return call.set('Authorization',`Bearer ${token}`).set('X-CSRF-Token',csrf).set('Idempotency-Key',key).send(body);
 };
 const creation=()=>({email:`created-${randomUUID()}@example.invalid`,password:`Synthetic-${randomUUID()}`,role:'SUPPORT',reason:'Synthetic account test'});
 beforeAll(async()=>{
  const url=new URL(testUrl!);if(url.pathname!=='/supplybiz_service_area_test'||!['localhost','127.0.0.1','[::1]'].includes(url.hostname))throw new Error('Dedicated local test DB required');
  Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url.toString(),ADMIN_TOTP_KEY:randomBytes(32).toString('hex'),OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000'});
  await db.$connect();const {AppModule}=await import('../../app.module');
  const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PrismaService).useValue(db).overrideProvider(AdminPasswordCheck).useValue(checker)
   .overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
  app=module.createNestApplication();configureHttpApp(app);await app.init();
  root=await admin('SUPER_ADMIN');finance=await admin('FINANCE');ops=await admin('OPS');support=await admin('SUPPORT');
 },60000);
 afterAll(async()=>{await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);},60000);
 it('default denies role escalation, personal data exports, invalid fields and missing CSRF/keys',async()=>{
  await get('admins','').expect(401);
  for(const actor of [finance,ops,support]){await get('admins',actor.token).expect(403);await write('admins',creation(),randomUUID(),actor.token).expect(403);}
  for(const actor of [ops,support])await write('reports/exports',{kind:'PLATFORM_SUMMARY'},randomUUID(),actor.token).expect(403);
  await write('admins',creation(),'').expect(400);await write('admins',creation(),randomUUID(),root.token,'wrong').expect(403);
  await write('admins',{...creation(),role:'CUSTOM'}).expect(400);await write('admins',{...creation(),totpSecret:'bad'}).expect(400);
  await write('reports/exports',{kind:'CUSTOMERS'}).expect(400);await get('admins?offset=-1').expect(400);
 });
 it('creates once on concurrent retry, hashes passwords, requires TOTP and redacts replay/audit',async()=>{
  const body=creation(),key=randomUUID(),responses=await Promise.all([write('admins',body,key),write('admins',body,key)]);
  expect(responses.map(r=>r.status)).toEqual([200,200]);expect(responses[0]!.body).toEqual(responses[1]!.body);
  const id=responses[0]!.body.id as string,row=await db.admin_users.findUniqueOrThrow({where:{id}});
  expect(await argon2.verify(row.password_hash,body.password)).toBe(true);expect(row.totp_secret_enc).toBeNull();
  expect(await db.audit_logs.count({where:{entity_id:id,action:'ADMIN_ACCOUNT_INSERT'}})).toBe(1);
  checker.check.mockRejectedValueOnce(new Error('Breach check unavailable'));
  await write('admins',body,key).expect(200); // Replay does not need external availability.
  await write('admins',creation()).expect(503);
  await write('admins',{...body,role:'OPS'},key).expect(422);await write('admins',body).expect(409);
  const audits=await db.audit_logs.findMany({where:{entity_id:id}}),cache=await db.idempotency_keys.findMany({where:{path:'admin/admins'}});
  expect(JSON.stringify([audits,cache])).not.toContain(body.password);expect(JSON.stringify(audits)).not.toContain(body.email);
  expect(responses[0]!.body).not.toHaveProperty('password_hash');expect(responses[0]!.body).not.toHaveProperty('totp_secret_enc');
  const login=await request(app.getHttpServer()).post('/api/v1/admin/auth/login').set('Idempotency-Key',randomUUID()).send({email:body.email,password:body.password}).expect(200);
  expect(login.body).not.toHaveProperty('sessionToken');
  const challenge=await request(app.getHttpServer()).get('/api/v1/admin/auth/challenge').set('Authorization',`Bearer ${login.body.challengeToken}`).expect(200);
  const code=totp(challenge.body.enrollmentSecret as string,Math.floor(Date.now()/30000));
  const verified=await request(app.getHttpServer()).post('/api/v1/admin/auth/totp/verify').set('Idempotency-Key',randomUUID()).send({challengeToken:login.body.challengeToken,code}).expect(200);
  await get('admins',verified.body.sessionToken as string).expect(403);
 });
 it('fails closed for breached passwords and unavailable checks without creating accounts',async()=>{
  const body=creation();checker.check.mockRejectedValueOnce(new Error('Password appears in a breach'));await write('admins',body).expect(400);
  expect(await db.admin_users.count({where:{email:body.email}})).toBe(0);
 });
 it('rejects self/stale edits, atomically revokes sessions/challenges, and rechecks permission on replay',async()=>{
  const target=await admin('FINANCE'),before=await db.admin_users.findUniqueOrThrow({where:{id:target.id}});
  await db.admin_auth_challenges.create({data:{token_hash:digest(randomUUID()),admin_id:target.id,secret_enc:'synthetic-unused',enrolling:true,expires_at:new Date(Date.now()+60000)}});
  const body={role:'OPS',status:'DISABLED',expectedUpdatedAt:before.updated_at.toISOString(),reason:'Synthetic revoke'},key=randomUUID();
  await write(`admins/${root.id}`,body,randomUUID(),root.token,'synthetic',true).expect(409);
  const changed=await write(`admins/${target.id}`,body,key,root.token,'synthetic',true).expect(200);
  expect(await db.admin_sessions.count({where:{admin_id:target.id}})).toBe(0);expect(await db.admin_auth_challenges.count({where:{admin_id:target.id}})).toBe(0);
  await get('auth/me',target.token).expect(401);await write(`admins/${target.id}`,body,randomUUID(),root.token,'synthetic',true).expect(409);
  expect((await write(`admins/${target.id}`,body,key,root.token,'synthetic',true).expect(200)).body).toEqual(changed.body);
  await db.admin_users.update({where:{id:root.id},data:{role:'SUPPORT'}});
  await write(`admins/${target.id}`,body,key,root.token,'synthetic',true).expect(403);
  await db.admin_users.update({where:{id:root.id},data:{role:'SUPER_ADMIN'}});
 });
 it('exports private aggregate exact CSV snapshots once per key, refreshes and rechecks live roles',async()=>{
  const key=randomUUID(),body={kind:'PLATFORM_SUMMARY'},first=await write('reports/exports',body,key,finance.token).expect(200);
  expect(first.body.csv).toContain('"recorded_gross"');expect(first.body.csv).toContain('"MANUAL_ASSIGNMENTS_ARE_NOT_REVENUE"');
  expect(first.body.csv).not.toContain('@');expect(first.body.csv).not.toContain('password');
  expect(first.body.csv).toContain('\r\n');expect(first.body.filename).toMatch(/^platform-summary-\d{4}-\d{2}-\d{2}\.csv$/);
  const [total]=await db.$queryRaw<{value:string}[]>`SELECT ((SELECT coalesce(sum(total_paise),0) FROM orders WHERE status='DELIVERED')+(SELECT coalesce(sum(total_paise),0) FROM sales))::text AS value`;
  expect(first.body.csv).toContain(`"recorded_gross","${total!.value}","paise"`);
  expect((await write('reports/exports',body,key,finance.token).expect(200)).body).toEqual(first.body);
  expect(await db.audit_logs.count({where:{actor_id:finance.id,action:'PLATFORM_REPORT_EXPORTED'}})).toBe(1);
  await db.admin_users.update({where:{id:finance.id},data:{role:'SUPPORT'}});
  await write('reports/exports',body,key,finance.token).expect(403);
  await db.admin_users.update({where:{id:finance.id},data:{role:'FINANCE'}});
 });
 it('serializes reciprocal super-admin demotions and keeps an active super admin',async()=>{
  const a=await admin('SUPER_ADMIN'),b=await admin('SUPER_ADMIN');
  const [ra,rb]=await Promise.all([db.admin_users.findUniqueOrThrow({where:{id:a.id}}),db.admin_users.findUniqueOrThrow({where:{id:b.id}})]);
  const body=(updatedAt:Date)=>({role:'SUPPORT',status:'DISABLED',expectedUpdatedAt:updatedAt.toISOString(),reason:'Synthetic reciprocal change'});
  const responses=await Promise.all([write(`admins/${b.id}`,body(rb.updated_at),randomUUID(),a.token,'synthetic',true),write(`admins/${a.id}`,body(ra.updated_at),randomUUID(),b.token,'synthetic',true)]);
  expect(responses.filter(r=>r.status===200)).toHaveLength(1);expect(responses.every(r=>[200,401,403].includes(r.status))).toBe(true);
  expect(await db.admin_users.count({where:{id:{in:[a.id,b.id]},role:'SUPER_ADMIN',status:'ACTIVE'}})).toBe(1);
 });
 it('serves production Next pages and authenticated CSV BFF with origin/CSRF safeguards',async()=>{
  await app.listen(0,'127.0.0.1');const apiPort=(app.getHttpServer().address() as AddressInfo).port;
  const reservation=createServer();await new Promise<void>(r=>reservation.listen(0,'127.0.0.1',r));const port=(reservation.address() as AddressInfo).port;await new Promise<void>(r=>reservation.close(()=>r()));
  const origin=`http://127.0.0.1:${port}`,adminRoot=resolve(__dirname,'../../../../','admin');
  const child=spawn(process.execPath,[join(adminRoot,'node_modules/next/dist/bin/next'),'start','--hostname','127.0.0.1','--port',String(port)],{cwd:adminRoot,env:{...process.env,NODE_ENV:'production',ADMIN_ORIGIN:origin,ADMIN_API_URL:`http://127.0.0.1:${apiPort}`,ADMIN_CSRF_KEY:randomBytes(32).toString('hex'),NEXT_TELEMETRY_DISABLED:'1'},stdio:'ignore',windowsHide:true});
  const call=(path:string,body?:FormData,suppliedOrigin=origin,token=root.token)=>fetch(`${origin}${path}`,{method:body?'POST':'GET',redirect:'manual',body,headers:{Cookie:`sb_admin=${token}; sb_csrf=synthetic`,...(body?{Origin:suppliedOrigin}:{})}});
  try {
   let ready=false;for(let i=0;i<100;i++){try{if((await call('/admins')).status===200){ready=true;break;}}catch{/* Startup */}await new Promise(r=>setTimeout(r,100));}expect(ready).toBe(true);
   const accounts=await (await call('/admins')).text();expect(accounts).toContain('Admin accounts and roles');expect(accounts).not.toContain(root.token);
   const formFrom=(html:string)=>{
    const form=new FormData();for(const [element] of html.matchAll(/<input\b[^>]*>/g)){const name=/name="([^"]+)"/.exec(element)?.[1];if(name)form.set(name,/value="([^"]*)"/.exec(element)?.[1]??'');}return form;
   };
   const createHtml=/<form\b[^>]*>([\s\S]*?)<\/form>/.exec(accounts)?.[1];expect(createHtml).toBeDefined();
   const createForm=formFrom(createHtml!),body=creation();for(const [name,value] of Object.entries(body))createForm.set(name,value);
   expect((await call('/admins/save',createForm)).status).toBe(200);expect((await call('/admins/save',createForm)).status).toBe(200);
   const created=await db.admin_users.findUniqueOrThrow({where:{email:body.email}});expect(await argon2.verify(created.password_hash,body.password)).toBe(true);
   const updatedHtml=await (await call('/admins')).text();
   const editHtml=[...updatedHtml.matchAll(/<form\b[^>]*>([\s\S]*?)<\/form>/g)].map(m=>m[1]!).find(form=>form.includes(`value="${created.id}"`));expect(editHtml).toBeDefined();
   const editForm=formFrom(editHtml!);editForm.set('role','FINANCE');editForm.set('status','DISABLED');editForm.set('reason','Synthetic BFF disable');
   expect((await call('/admins/save',editForm)).status).toBe(200);expect((await db.admin_users.findUniqueOrThrow({where:{id:created.id}})).status).toBe('DISABLED');
   const html=await (await call('/reports')).text(),form=new FormData();
   for(const [element] of html.matchAll(/<input\b[^>]*>/g)){const name=/name="([^"]+)"/.exec(element)?.[1];if(name)form.set(name,/value="([^"]*)"/.exec(element)?.[1]??'');}
   expect((await call('/admins/save',form,'https://foreign.example.invalid')).status).toBe(403);
   const csv=await call('/admins/save',form);expect(csv.status).toBe(200);expect(csv.headers.get('content-type')).toContain('text/csv');expect(csv.headers.get('cache-control')).toBe('no-store');
   const bytes=await csv.text();expect(bytes).toContain('"recorded_gross"');expect(await (await call('/admins/save',form)).text()).toBe(bytes);
   form.set('csrf','wrong');expect((await call('/admins/save',form)).status).toBe(403);
   expect(await (await call('/reports',undefined,origin,support.token)).text()).toContain('Access denied.');
  }finally{child.kill();await new Promise<void>(r=>{if(child.exitCode!==null)r();else child.once('exit',()=>r());});}
 },60000);
});
