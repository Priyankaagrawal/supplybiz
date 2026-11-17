// T-074 / TC-089–091: actual HTTP/PostgreSQL cancellation + production generation consumers.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from '../home/home.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SubscriptionClock,dateOnly } from '../subscriptions/subscription-policy';
import { GenerationClock,GENERATION_BATCH } from '../subscriptions/subscription-generation.policy';
import { assignPlanFixture } from '../../../test/fixtures/plans';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-074 native vendor holidays/availability',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,categoryId:string,owner:Actor,buyer:Actor,other:Actor,vendorId:string,customerId:string,productId:string,serial=0;
  let instant=new Date('2026-10-01T04:00:00Z'),generationInstant=new Date('2026-10-01T16:31:00Z');
  async function boot(){const {AppModule}=await import('../../app.module');const m=await Test.createTestingModule({imports:[AppModule]})
    .overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()})
    .overrideProvider(SubscriptionClock).useValue({now:(tx:Prisma.TransactionClient)=>homeClock(tx,instant)})
    .overrideProvider(GenerationClock).useValue({now:(tx:Prisma.TransactionClient)=>homeClock(tx,generationInstant)}).compile();const a=m.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'CUSTOMER'|'VENDOR'):Promise<Actor>{const u=await db.users.create({data:{mobile:`+916${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic availability',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});return {id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};}
  const get=(path:string,who=owner)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  const post=(path:string,body:object,who=owner,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const patch=(body:object,key:string=randomUUID())=>request(app.getHttpServer()).patch('/api/v1/vendor/availability').set('Authorization',`Bearer ${owner.token}`).set('Idempotency-Key',key).send(body);
  const del=(id:string,who=owner,key:string=randomUUID())=>request(app.getHttpServer()).delete(`/api/v1/vendor/holidays/${id}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key);
  const holiday=(key:string=randomUUID())=>post('vendor/holidays',{date:'2026-10-02',reason:'Synthetic holiday'},owner,key);
  async function order(status:string,day='2026-10-02') {return db.orders.create({data:{order_no:`SYN-${randomUUID()}`,vendor_id:vendorId,vendor_customer_id:customerId,source:'APP',status,created_at:new Date(Date.now()-1000),completed_at:status==='DELIVERED'?new Date():null,delivery_date:dateOnly(day),time_slot:'AM',address_snapshot:{text:'Synthetic'},subtotal_paise:0n,total_paise:0n,delivery_charge_paise:0n,payment_mode:'POD_CASH',payment_status:'PAID'}});}
  async function sub(day='2026-10-02'){return (await post('vendor/subscriptions',{vendorCustomerId:customerId,productId,qty:1,weekdays:[1,2,3,4,5,6,7],startDate:day,timeSlot:'AM',paymentMethod:'CASH'}).expect(201)).body.id as string;}
  async function generate(id:string,day='2026-10-02') {const job=await db.job_runs.findUniqueOrThrow({where:{job_type_business_date_scope_id:{job_type:GENERATION_BATCH,business_date:dateOnly(day),scope_id:`FIRST:${id}`}}});expect(await app.get(OutboxDispatcherService).dispatchPendingBatch(1,job.event_id)).toBe(1);}
  beforeAll(async()=>{const target=new URL(url!);if(!target.pathname.endsWith('_test')||!['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});await db.$connect();app=await boot();categoryId=(await db.categories.create({data:{code:`AV-${randomUUID()}`,name_en:'Synthetic availability',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;});
  beforeEach(async()=>{instant=new Date('2026-10-01T04:00:00Z');generationInstant=new Date('2026-10-01T16:31:00Z');owner=await actor('VENDOR');buyer=await actor('CUSTOMER');other=await actor('VENDOR');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic vendor',kyc_status:'VERIFIED',settings:{create:{time_slots:['AM'],accepting_today:true}}}})).id;
    const otherVendor=await db.vendors.create({data:{user_id:other.id,category_id:categoryId,business_name:'Synthetic other',settings:{create:{}}}});await db.$transaction(async tx=>{await assignPlanFixture(tx,vendorId,'STANDARD');await assignPlanFixture(tx,otherVendor.id,'BASIC');});
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:5000,stock_qty:100}})).id;
    const user=await db.users.findUniqueOrThrow({where:{id:buyer.id}});customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic customer',mobile:user.mobile,address_text:'Synthetic address'}})).id;});
  afterEach(()=>jest.restoreAllMocks());afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);});
  it('TC-089 cancels NEW/3 ACCEPTED/PREPARING only, preserves progressed dates, snapshots and money; customer deep links read CANCELLED',async()=>{
    const eligible=await Promise.all(['NEW','ACCEPTED','ACCEPTED','ACCEPTED','PREPARING'].map(s=>order(s))),kept=await Promise.all(['OUT_FOR_DELIVERY','DELIVERED','FAILED','REJECTED','CANCELLED'].map(s=>order(s))),later=await order('ACCEPTED','2026-10-03');
    const id=await sub();expect((await get('vendor/holidays/impact?date=2026-10-02').expect(200)).body.affectedOrders).toBe(5);
    const result=await holiday().expect(201);expect(result.body.cancelledOrders).toBe(5);
    for(const o of eligible){const row=await db.orders.findUniqueOrThrow({where:{id:o.id}});expect(row).toMatchObject({status:'CANCELLED',version:2,total_paise:0n,payment_status:'PAID',cancel_reason:'Vendor holiday'});expect(await db.order_status_events.count({where:{order_id:o.id,status:'CANCELLED'}})).toBe(1);}
    for(const o of [...kept,later])expect((await db.orders.findUniqueOrThrow({where:{id:o.id}})).status).toBe(o.status);
    const inbox=(await get('notifications',buyer).expect(200)).body;expect(JSON.stringify(inbox)).toContain('ORDER_CANCELLED_CUSTOMER');
    expect((await get(`customer/orders/${eligible[0]!.id}`,buyer).expect(200)).body.status).toBe('CANCELLED');
    await generate(id);expect(await db.orders.count({where:{subscription_id:id}})).toBe(0);
    expect(await db.notifications.count({where:{user_id:buyer.id,type:'VENDOR_HOLIDAY'}})).toBe(1);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.payments.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.stock_movements.count({where:{product_id:productId}})).toBe(0);
  });
  it('TC-089 permanent replay survives concurrency, application recreation and holiday deletion without recreating state',async()=>{
    await order('ACCEPTED');const key=randomUUID(),responses=await Promise.all([holiday(key),holiday(key)]);expect(responses.map(r=>r.status)).toEqual([201,201]);expect(responses[0]!.body).toEqual(responses[1]!.body);const id=responses[0]!.body.holiday.id;
    expect((await post('vendor/holidays',{date:'2026-10-03',reason:'Synthetic holiday'},owner,key)).status).toBe(422);
    await del(id,other).expect(404);await app.close();app=await boot();expect((await holiday(key).expect(201)).body).toEqual(responses[0]!.body);
    const deleteKey=randomUUID();await del(id,owner,deleteKey).expect(200);await del(id,owner,deleteKey).expect(200);await holiday(key).expect(201);expect(await db.vendor_holidays.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.notifications.count({where:{user_id:buyer.id,type:'ORDER_CANCELLED_CUSTOMER'}})).toBe(1);
  });
  it('TC-090 pause cancels today onward; resume allows the next dated production generation and never resurrects cancelled orders',async()=>{
    const old=await order('ACCEPTED','2026-09-30'),today=await order('PREPARING','2026-10-01'),future=await order('ACCEPTED','2026-10-03'),out=await order('OUT_FOR_DELIVERY');const blocked=await sub();
    expect((await get('vendor/availability/impact').expect(200)).body.affectedOrders).toBe(2);
    const paused=await patch({version:1,deliveryPaused:true}).expect(200);expect(paused.body.cancelledOrders).toBe(2);await generate(blocked);expect(await db.orders.count({where:{subscription_id:blocked}})).toBe(0);
    await patch({version:2,deliveryPaused:false}).expect(200);generationInstant=new Date('2026-10-02T16:31:00Z');const next=await sub('2026-10-03');await generate(next,'2026-10-03');expect(await db.orders.count({where:{subscription_id:next}})).toBe(1);
    for(const o of [today,future])expect((await db.orders.findUniqueOrThrow({where:{id:o.id}})).status).toBe('CANCELLED');for(const o of [old,out])expect((await db.orders.findUniqueOrThrow({where:{id:o.id}})).status).toBe(o.status);
  });
  it('TC-091 future deletion before generation removes exclusion; today cannot be deleted and list is owned/paginated',async()=>{
    const id=await sub(),h=(await holiday().expect(201)).body.holiday;expect((await get('vendor/holidays?limit=1&offset=0').expect(200)).body.items).toHaveLength(1);expect((await get('vendor/holidays',other).expect(200)).body.total).toBe(0);
    await del(h.id).expect(200);await generate(id);expect(await db.orders.count({where:{subscription_id:id}})).toBe(1);
    const today=(await post('vendor/holidays',{date:'2026-10-01',reason:'Synthetic today'}).expect(201)).body.holiday;await del(today.id).expect(409);
  });
  it('TC-089/090 concurrent production generation and holiday serialize to no active affected order',async()=>{
    const id=await sub();await Promise.all([generate(id),holiday().expect(201)]);
    const rows=await db.orders.findMany({where:{subscription_id:id}});expect(rows.length).toBeLessThanOrEqual(1);for(const row of rows)expect(row.status).toBe('CANCELLED');
  });
  it('TC-089 notification failure rolls back holiday, cancellations, audit and replay; the same key can recover',async()=>{
    const o=await order('ACCEPTED'),key=randomUUID(),notices=app.get(NotificationsService),real=notices.enqueue.bind(notices);
    const fault=jest.spyOn(notices,'enqueue').mockImplementation(async(tx,event)=>{await real(tx,event);throw new Error('Synthetic private failure');});
    await holiday(key).expect(503);expect(await db.vendor_holidays.count({where:{vendor_id:vendorId}})).toBe(0);expect((await db.orders.findUniqueOrThrow({where:{id:o.id}})).status).toBe('ACCEPTED');expect(await db.vendor_operation_requests.count({where:{user_id:owner.id}})).toBe(0);expect(await db.notifications.count({where:{user_id:buyer.id}})).toBe(0);
    await patch({version:1,deliveryPaused:true},key).expect(503);expect((await db.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}})).version).toBe(1);
    fault.mockRestore();await holiday(key).expect(201);expect((await db.orders.findUniqueOrThrow({where:{id:o.id}})).version).toBe(2);
  });
  it('FR-082 availability-off keeps existing orders, shares settings version, and expiry retains reducing/history controls',async()=>{
    const existing=await order('NEW','2026-10-01');await patch({version:1,acceptingToday:false}).expect(200);expect((await db.orders.findUniqueOrThrow({where:{id:existing.id}})).status).toBe('NEW');await patch({version:1,deliveryPaused:true}).expect(409);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    expect((await get('vendor/availability').expect(200)).body.canResume).toBe(false);await patch({version:2,deliveryPaused:true}).expect(200);await patch({version:3,deliveryPaused:false}).expect(403);await holiday().expect(201);
  });
  it('TC-089 rejects foreign role, unknown fields, missing key, invalid/past IST dates and empty reason',async()=>{
    await holiday(' ').expect(400);await post('vendor/holidays',{date:'2026-09-30',reason:'Synthetic'}).expect(422);await post('vendor/holidays',{date:'2026-02-30',reason:'Synthetic'}).expect(400);await post('vendor/holidays',{date:'2026-10-02',reason:'  '}).expect(400);await post('vendor/holidays',{date:'2026-10-02',reason:'Synthetic',vendorId:randomUUID()}).expect(400);
    await get('vendor/availability',buyer).expect(403);await get('vendor/holidays?limit=51').expect(400);
    instant=new Date('2026-10-01T18:30:00Z');expect((await get('vendor/availability').expect(200)).body.businessDate).toBe('2026-10-02');await post('vendor/holidays',{date:'2026-10-01',reason:'Synthetic'}).expect(422);
  });
});
