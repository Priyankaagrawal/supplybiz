import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomBytes, randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { AddressInfo, createServer } from 'node:net';
import { join, resolve } from 'node:path';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { digest } from '../admin-auth/admin-crypto';
import { AdminDashboard } from './dashboard.dto';
const databaseUrl = process.env.NATIVE_TEST_DATABASE_URL;
const native = databaseUrl ? describe : describe.skip;
native('T-154 FR-401 real dashboard snapshot and production Next.js', () => {
 const db = new PrismaService({ datasources: { db: { url: databaseUrl } } }), env = { ...process.env };
 let app: INestApplication, root: { id: string; token: string }, restricted: typeof root, vendorId: string, customerId: string;
 async function boot() {
  const { AppModule } = await import('../../app.module');
  const module = await Test.createTestingModule({ imports: [AppModule] }).overrideProvider(PinoLogger).useValue({ log: jest.fn(), warn: jest.fn(), error: jest.fn() }).compile();
  const instance = module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
 }
 async function admin(role: string) {
  const row = await db.admin_users.create({ data: { email: `dashboard-${randomUUID()}@example.invalid`, role, password_hash: 'synthetic-unused' } });
  const token = randomBytes(32).toString('base64url'); await db.admin_sessions.create({ data: { token_hash: digest(token), admin_id: row.id, csrf_hash: digest('synthetic'), expires_at: new Date(Date.now() + 3600000) } }); return { id: row.id, token };
 }
 const get = (token = root.token) => request(app.getHttpServer()).get('/api/v1/admin/dashboard').set('Authorization', `Bearer ${token}`);
 const snapshot = async (): Promise<AdminDashboard> => (await get().expect(200)).body as AdminDashboard;
 beforeAll(async () => {
  const url = new URL(databaseUrl!); if (!url.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(url.hostname)) throw new Error('Dedicated local _test database required');
  Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: 'disabled', RATE_LIMIT_MAX_REQUESTS: '10000', AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
  await db.$connect(); app = await boot(); root = await admin('SUPER_ADMIN'); restricted = await admin('SUPPORT');
 },60000);
 afterAll(async () => { await app?.close(); await db.$disconnect(); for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key]; Object.assign(process.env,env); },60000);
 it('uses explicit dashboard permission and rechecks role/disabled/expired sessions; sends no private records', async () => {
  await get('').expect(401); for (const role of ['OPS','SUPPORT','FINANCE']) await get((await admin(role)).token).expect(403);
  const result = await get().expect(200); expect(result.headers['cache-control']).toBe('no-store'); expect(result.body.planRevenueStatus).toBe('UNAVAILABLE');expect(result.body.gmvScope).toBe('DELIVERED_ORDERS_ONLY');
  expect(JSON.stringify(result.body)).not.toMatch(/email|mobile|password|token|customerId|vendorId/);
  const actor = await admin('SUPER_ADMIN'); await get(actor.token).expect(200); await db.admin_users.update({where:{id:actor.id},data:{role:'SUPPORT'}});await get(actor.token).expect(403);
  await db.admin_users.update({where:{id:actor.id},data:{role:'SUPER_ADMIN',status:'DISABLED'}});await get(actor.token).expect(401);
  await db.admin_sessions.updateMany({where:{admin_id:root.id},data:{expires_at:new Date(0)}});await get().expect(401);root=await admin('SUPER_ADMIN');
 });
 it('counts stored accounts once and excludes undelivered value while preserving paise above Number precision',async()=>{
  const before=await snapshot();
  const category=await db.categories.create({data:{code:`DASH-${randomUUID()}`,name_en:'Synthetic dashboard category',name_hi:'',type:'SUPPLY'}});
  const user=await db.users.create({data:{mobile:`synthetic-dashboard-${randomUUID()}`,active_role:'VENDOR',status:'BLOCKED',roles:{create:[{role:'VENDOR'},{role:'CUSTOMER'}]}}});
  const vendor=await db.vendors.create({data:{user_id:user.id,category_id:category.id,kyc_status:'VERIFIED',is_suspended:true}});vendorId=vendor.id;
  const customer=await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:user.id,name:'Synthetic linked',mobile:'+919000000001'}});customerId=customer.id;
  await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic offline customer',mobile:'+919000000002'}});
  for(const status of ['DELIVERED','FAILED','NEW','CANCELLED','REJECTED'])await db.orders.create({data:{order_no:`DS-${randomUUID()}`,vendor_id:vendorId,vendor_customer_id:customerId,source:'APP',status,delivery_date:new Date(),time_slot:'07:00-08:00',address_snapshot:{synthetic:true},subtotal_paise:9007199254740993n,delivery_charge_paise:10n,discount_paise:0n,total_paise:9007199254741003n,payment_mode:'POD_CASH',payment_status:'UNPAID',created_at:new Date(Date.now()-60000),completed_at:status==='DELIVERED'?new Date():null}});
  const after=await snapshot();expect(after.vendorsTotal-before.vendorsTotal).toBe(1);expect(after.vendorsSuspended-before.vendorsSuspended).toBe(1);expect(after.kycVerified-before.kycVerified).toBe(1);expect(after.customersTotal-before.customersTotal).toBe(1);expect(after.customersBlocked-before.customersBlocked).toBe(1);
  expect(after.ordersTotal-before.ordersTotal).toBe(5);expect(after.ordersDelivered-before.ordersDelivered).toBe(1);expect(after.ordersFailed-before.ordersFailed).toBe(1);expect(BigInt(after.recordedGmvPaise)-BigInt(before.recordedGmvPaise)).toBe(9007199254741003n);
  await db.vendors.update({where:{id:vendorId},data:{kyc_status:'MANUAL_REVIEW'}});expect((await snapshot()).kycPending-before.kycPending).toBe(1);
 });
 it('real audited manual plan grant changes grant count, never GMV or unavailable revenue',async()=>{
  await db.vendors.update({where:{id:vendorId},data:{is_suspended:false}});
  const before=await snapshot(),plan=await db.plans.findUniqueOrThrow({where:{code:'BASIC'}});
  await request(app.getHttpServer()).post(`/api/v1/admin/vendors/${vendorId}/plan-assignments`).set('Authorization',`Bearer ${root.token}`).set('X-CSRF-Token','synthetic').set('Idempotency-Key',randomUUID()).send({planId:plan.id,startsAt:new Date(Date.now()-60000).toISOString(),endsAt:new Date(Date.now()+86400000).toISOString(),reason:'Synthetic dashboard manual grant'}).expect(201);
  const after=await snapshot();expect(after.planAssignmentsTotal-before.planAssignmentsTotal).toBe(1);expect(after.recordedGmvPaise).toBe(before.recordedGmvPaise);expect(after.planRevenueStatus).toBe('UNAVAILABLE');
 });
 it('renders persisted values through production Next.js, denies restricted pages and recovers after real API outage',async()=>{
  await app.listen(0,'127.0.0.1');const apiPort=(app.getHttpServer().address() as AddressInfo).port;
  const reservation=createServer();await new Promise<void>(r=>reservation.listen(0,'127.0.0.1',r));const webPort=(reservation.address() as AddressInfo).port;await new Promise<void>(r=>reservation.close(()=>r()));
  const origin=`http://127.0.0.1:${webPort}`,dir=resolve(__dirname,'../../../../','admin');
  const child=spawn(process.execPath,[join(dir,'node_modules/next/dist/bin/next'),'start','--hostname','127.0.0.1','--port',String(webPort)],{cwd:dir,env:{...process.env,NODE_ENV:'production',ADMIN_ORIGIN:origin,ADMIN_API_URL:`http://127.0.0.1:${apiPort}`,ADMIN_CSRF_KEY:randomBytes(32).toString('hex'),NEXT_TELEMETRY_DISABLED:'1'},stdio:['ignore','ignore','pipe'],windowsHide:true});
  let startup='';child.stderr?.on('data',(b:Buffer)=>{startup=(startup+b.toString()).slice(-2000);});
  const page=(token=root.token,path='/dashboard')=>fetch(`${origin}${path}`,{redirect:'manual',headers:{Cookie:`sb_admin=${token}`}});
  try{
   let ready=false;for(let i=0;i<300;i++){if(child.exitCode!==null)throw new Error(startup);try{if((await fetch(`${origin}/login`)).ok){ready=true;break;}}catch{/* startup */}await new Promise(r=>setTimeout(r,100));}expect(ready).toBe(true);
   const anonymous=await page(''),anonymousHtml=await anonymous.text();
   expect(anonymous.headers.get('location') === '/login' || /url=\/login|NEXT_REDIRECT/.test(anonymousHtml)).toBe(true);expect(anonymousHtml).not.toContain('data-metric=');expect(await (await page(restricted.token)).text()).toContain('Dashboard access denied');
   expect(await (await page(root.token,'/')).text()).toContain('Open dashboard');expect(await (await page(restricted.token,'/')).text()).not.toContain('Open dashboard');
   const data=await snapshot(),html=await(await page()).text();expect(html).toContain(`data-metric="Vendor records">${data.vendorsTotal}`);expect(html).toContain('not full platform GMV');expect(html).toContain('Automated plan revenue');expect(html).toContain('Unavailable: automated plan billing');expect(html).not.toContain(root.token);
   const newUser=await db.users.create({data:{mobile:`synthetic-refresh-${randomUUID()}`,roles:{create:{role:'CUSTOMER'}}}});expect((await snapshot()).customersTotal).toBe(data.customersTotal+1);expect(await(await page()).text()).toContain(`data-metric="Customer accounts">${data.customersTotal+1}`);
   await db.users.update({where:{id:newUser.id},data:{status:'DELETED'}});expect((await snapshot()).customersTotal).toBe(data.customersTotal+1);
   await app.close();expect(await(await page()).text()).toContain('Dashboard data is unavailable');app=await boot();await app.listen(apiPort,'127.0.0.1');expect(await(await page()).text()).toContain('Recorded delivered order value (GMV component)');
  }finally{if(child.exitCode===null){const stopped=new Promise<void>(r=>child.once('exit',()=>r()));child.kill('SIGTERM');await stopped;}}
 },120000);
});
