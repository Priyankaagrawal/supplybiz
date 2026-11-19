// T-158 / TC-407. Only the isolated local test database; no main DB mutations.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo, createServer } from 'node:net';
import { join, resolve } from 'node:path';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { digest } from '../admin-auth/admin-crypto';

const testUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = testUrl ? describe : describe.skip;
native('T-158 native CMS/config/production Next BFF', () => {
 const db = new PrismaService({ datasources: { db: { url: testUrl } } }), env = { ...process.env };
 const run = randomUUID(), faqId = randomUUID(), rollbackId = randomUUID();
 const version1 = `test-${run}`, version2 = `v2-${run}`;
 let app: INestApplication, root: {id: string; token: string}, ops: {id: string; token: string}, support: {id: string; token: string};
 let previous: Awaited<ReturnType<typeof db.app_config.findMany>> = [];
 async function boot() {
  const { AppModule } = await import('../../app.module');
  const module = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PrismaService).useValue(db)
   .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() }).compile();
  const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
 }
 async function admin(role: string) {
  const row = await db.admin_users.create({ data: { email: `content-${randomUUID()}@example.invalid`, role, password_hash: 'synthetic-unused' } });
  const token = randomBytes(32).toString('base64url');
  await db.admin_sessions.create({ data: { token_hash: digest(token), admin_id: row.id, csrf_hash: digest('synthetic'), expires_at: new Date(Date.now()+3600000) } });
  return {id: row.id, token};
 }
 const get = (path: string, token = root.token) => request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization', `Bearer ${token}`);
 const put = (path: string, body: object, key: string = randomUUID(), token = root.token, csrf = 'synthetic') => request(app.getHttpServer()).put(`/api/v1/admin/${path}`)
  .set('Authorization', `Bearer ${token}`).set('X-CSRF-Token',csrf).set('Idempotency-Key',key).send(body);
 const faq = (extra: object = {}) => ({ expectedUpdatedAt: null, topic: 'general', question: `Synthetic FAQ ${run}`, answer: '<script>synthetic()</script> & plain text', published: false, ...extra });
 beforeAll(async () => {
  const url = new URL(testUrl!);
  if (url.pathname !== '/supplybiz_service_area_test' || !['localhost','127.0.0.1','[::1]'].includes(url.hostname)) throw new Error('Use the dedicated local supplybiz_service_area_test database');
  Object.assign(process.env,{ NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000' });
  await db.$connect();
  previous = await db.app_config.findMany({ where: { key: { in: ['mobile','cms:current:TERMS','cms:current:PRIVACY'] } } });
  app = await boot(); root = await admin('SUPER_ADMIN'); ops = await admin('OPS'); support = await admin('SUPPORT');
 },60000);
 afterAll(async () => {
  await db.app_config.deleteMany({ where: { key: { in: ['mobile','cms:current:TERMS','cms:current:PRIVACY',`cms:faq:${faqId}`,`cms:faq:${rollbackId}`,`cms:legal:TERMS:${version1}`,`cms:legal:TERMS:${version2}`] } } });
  for (const row of previous) await db.app_config.create({data: {...row,value: row.value ?? Prisma.JsonNull}});
  await app?.close(); await db.$disconnect();
  for (const k of Object.keys(process.env)) if (!(k in env)) delete process.env[k]; Object.assign(process.env,env);
 },60000);
 it('enforces CMS/config RBAC, session, CSRF, key, strict fields and bounded boolean flags', async () => {
  await get('admin/faqs',ops.token).expect(200); await get('admin/config',ops.token).expect(403);
  await get('admin/legal',support.token).expect(403); await get('admin/config','').expect(401);
  await put(`faqs/${faqId}`,faq(),randomUUID(),ops.token,'wrong').expect(403);
  await put(`faqs/${faqId}`,faq(),'').expect(400);
  await put(`faqs/${faqId}`,faq({ actorId: root.id })).expect(400);
  for (const flags of [{wallet: 'true'}, {'bad-key':true}, Object.fromEntries(Array.from({length:51},(_,i)=>[`flag${i}`,true]))]) {
   await put('config',{ expectedUpdatedAt:null,minVersionAndroid:'0.1.0',flags }).expect(400);
  }
  await get('content/legal/OTHER').expect(400);
 });
 it('creates one hidden FAQ/audit for concurrent replay, publishes safely and refuses stale overwrite', async () => {
  const key = randomUUID(), body = faq();
  const responses = await Promise.all([put(`faqs/${faqId}`,body,key,ops.token),put(`faqs/${faqId}`,body,key,ops.token)]);
  expect(responses.map(r=>r.status)).toEqual([200,200]); expect(responses[0]!.body).toEqual(responses[1]!.body);
  expect(await db.audit_logs.count({where:{actor_id:ops.id,entity:'cms'}})).toBe(1);
  expect((await get('content/faqs?topic=general').expect(200)).body.items.some((r:{id:string})=>r.id===faqId)).toBe(false);
  const updated = await put(`faqs/${faqId}`,faq({expectedUpdatedAt:responses[0]!.body.updatedAt,published:true})).expect(200);
  await put(`faqs/${faqId}`,body).expect(409);
  await put(`faqs/${faqId}`,faq({answer:'Different payload'}),key,ops.token).expect(422);
  expect((await get('content/faqs?topic=general').expect(200)).body.items).toEqual(expect.arrayContaining([expect.objectContaining({id:faqId,answer:body.answer,published:true})]));
  await app.close(); app = await boot(); expect((await get('admin/faqs').expect(200)).body.items.some((r:{id:string})=>r.id===faqId)).toBe(true);
  expect(updated.body.updatedAt).not.toBe(responses[0]!.body.updatedAt);
 });
 it('persists config, immediately exposes the public policy, blocks old Android and preserves replay auth', async () => {
  const current = (await get('admin/config').expect(200)).body;
  const body = {expectedUpdatedAt:current.updatedAt,minVersionAndroid:'0.2.0',flags:{operationalNotice:true}}, key = randomUUID();
  const saved = (await put('config',body,key).expect(200)).body;
  expect((await get('config').expect(200)).body).toEqual({minVersionAndroid:'0.2.0',flags:{operationalNotice:true}});
  await get('content/faqs').set('X-Platform','android').set('X-App-Version','0.1.0').expect(426);
  await get('config').set('X-Platform','android').set('X-App-Version','0.1.0').expect(200);
  await get('content/faqs').set('X-Platform','android').set('X-App-Version','0.2.0').expect(200);
  await put('config',body).expect(409);
  await db.admin_users.update({where:{id:root.id},data:{role:'OPS'}});
  await put('config',body,key).expect(403);
  await db.admin_users.update({where:{id:root.id},data:{role:'SUPER_ADMIN'}});
  expect((await put('config',body,key).expect(200)).body).toEqual(saved);
 });
 it('publishes immutable legal versions and returns exact current or historical text/hash', async () => {
  const current = await get('admin/legal/TERMS');
  const body = {expectedVersion:current.status===404?null:current.body.version,version:version1,title:'Synthetic test terms',text:'Synthetic test only. <script>plain text</script>\nSecond line.'};
  const first = (await put('legal/TERMS',body).expect(200)).body;
  expect(first.sha256).toBe(createHash('sha256').update(body.text).digest('hex'));
  const second = {...body,expectedVersion:version1,version:version2,text:'Second synthetic legal version.'};
  await put('legal/TERMS',second).expect(200);
  expect((await get('content/legal/TERMS').expect(200)).body.version).toBe(version2);
  expect((await get(`content/legal/TERMS?version=${version1}`).expect(200)).body).toEqual(first);
  await put('legal/TERMS',{...second,expectedVersion:version2,version:version1}).expect(409);
  await put('legal/TERMS',{...body,version:'../invalid'}).expect(400);
 });
 it('rolls back content and replay if audit persistence fails, without exposing database text', async () => {
  await db.$executeRaw`ALTER TABLE audit_logs ADD CONSTRAINT content_test_reject CHECK (entity <> 'cms') NOT VALID`;
  try {
   const response = await put(`faqs/${rollbackId}`,faq()).expect(503);
   expect(JSON.stringify(response.body)).not.toContain('private database');
   expect(await db.app_config.findUnique({where:{key:`cms:faq:${rollbackId}`}})).toBeNull();
  } finally {await db.$executeRaw`ALTER TABLE audit_logs DROP CONSTRAINT content_test_reject`;}
 });
 it('rechecks CMS role on saved-key replay and paginates/filter-publishes only matching records', async () => {
  const current = (await get('admin/faqs').expect(200)).body.items.find((r:{id:string})=>r.id===faqId), key = randomUUID();
  const body = faq({expectedUpdatedAt:current.updatedAt,published:false});
  await put(`faqs/${faqId}`,body,key,ops.token).expect(200);
  await db.admin_users.update({where:{id:ops.id},data:{role:'SUPPORT'}});
  await put(`faqs/${faqId}`,body,key,ops.token).expect(403);
  await db.admin_users.update({where:{id:ops.id},data:{role:'OPS'}});
  expect((await get('content/faqs?topic=general').expect(200)).body.items.some((r:{id:string})=>r.id===faqId)).toBe(false);
  expect((await get('admin/faqs?offset=100000').expect(200)).body.items).toEqual([]);
  await get('content/faqs?offset=-1').expect(400);
 });
 it('serves production Next forms, escapes content, checks BFF origin/CSRF and updates config via BFF/API/DB', async () => {
  await app.listen(0,'127.0.0.1'); const apiPort = (app.getHttpServer().address() as AddressInfo).port;
  const reservation = createServer(); await new Promise<void>(r=>reservation.listen(0,'127.0.0.1',r));
  const webPort = (reservation.address() as AddressInfo).port; await new Promise<void>(r=>reservation.close(()=>r()));
  const origin = `http://127.0.0.1:${webPort}`, adminRoot = resolve(__dirname,'../../../../','admin');
  const child = spawn(process.execPath,[join(adminRoot,'node_modules/next/dist/bin/next'),'start','--hostname','127.0.0.1','--port',String(webPort)],{
   cwd:adminRoot,env:{...process.env,NODE_ENV:'production',ADMIN_ORIGIN:origin,ADMIN_API_URL:`http://127.0.0.1:${apiPort}`,ADMIN_CSRF_KEY:randomBytes(32).toString('hex'),NEXT_TELEMETRY_DISABLED:'1'},stdio:'ignore',windowsHide:true,
  });
  const call = (path:string,body?:FormData,suppliedOrigin=origin) => fetch(`${origin}${path}`,{method:body?'POST':'GET',redirect:'manual',body,headers:{Cookie:`sb_admin=${root.token}; sb_csrf=synthetic`,...(body?{Origin:suppliedOrigin}:{})}});
  try {
   let ready = false;
   for(let i=0;i<100;i++){try { const r=await call('/config'); if(r.status===200){ready=true;break;} } catch { /* Native startup only. */ } await new Promise(r=>setTimeout(r,100));}
   expect(ready).toBe(true);
   const cms = await (await call('/cms')).text(); expect(cms).toContain('Help and legal content');
   expect(cms).toContain('&lt;script&gt;synthetic()&lt;/script&gt;'); expect(cms).not.toContain('<script>synthetic()</script>');
   const html = await (await call('/config')).text(); const form = new FormData();
   for(const [element] of html.matchAll(/<input\b[^>]*>/g)) {
    const name=/name="([^"]+)"/.exec(element)?.[1]; if(name) form.set(name,/value="([^"]*)"/.exec(element)?.[1]??'on');
   }
   form.set('minVersionAndroid','0.3.0'); form.set('flags','{"operationalNotice":false}'); form.set('confirm','on');
   expect((await call('/cms/save',form,'https://foreign.example.invalid')).status).toBe(403);
   expect((await call('/cms/save',form)).status).toBe(200);
   expect((await call('/cms/save',form)).status).toBe(200);
   expect((await get('config').expect(200)).body).toEqual({minVersionAndroid:'0.3.0',flags:{operationalNotice:false}});
   form.set('csrf','bad'); expect((await call('/cms/save',form)).status).toBe(403);
  } finally { child.kill(); await new Promise<void>(r=>{if(child.exitCode!==null)r();else child.once('exit',()=>r());}); }
 },60000);
});
