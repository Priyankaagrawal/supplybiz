// T-073 / TC-080–084: real worker services, HTTP, PostgreSQL and isolated child-process recovery.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { spawn, ChildProcess } from 'node:child_process';
import { once } from 'node:events';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from '../home/home.service';
import { NotificationsService } from '../notifications/notifications.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { addDays, dateOnly, SubscriptionClock } from './subscription-policy';
import { GENERATION_BATCH, GENERATION_SCAN, GenerationClock } from './subscription-generation.policy';
import { SubscriptionGenerationService } from './subscription-generation.service';
const url=process.env.NATIVE_TEST_DATABASE_URL;
const native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-073 native bounded generation and worker recovery',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  const log={log:jest.fn(),warn:jest.fn(),error:jest.fn()};
  let app:INestApplication,engine:SubscriptionGenerationService,dispatcher:OutboxDispatcherService;
  let categoryId:string,owner:Actor,buyer:Actor,vendorId:string,productId:string,customerId:string,date:string,creationInstant:Date,serial=0;
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]})
    .overrideProvider(PinoLogger).useValue(log).overrideProvider(SubscriptionClock).useValue({now:(tx:Prisma.TransactionClient)=>homeClock(tx,creationInstant)}).compile();
    const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`+919${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic generation actor',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const post=(path:string,body:object,who=owner,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path:string,who=owner)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  const input=()=>({vendorCustomerId:customerId,productId,qty:1,weekdays:[1,2,3,4,5,6,7],startDate:date,timeSlot:'AM',paymentMethod:'CASH'});
  async function sub(overrides:object={}){return (await post('vendor/subscriptions',{...input(),...overrides}).expect(201)).body.id as string;}
  async function firstJob(id:string,day=date) {
    const job=await db.job_runs.findUnique({where:{job_type_business_date_scope_id:{job_type:GENERATION_BATCH,business_date:dateOnly(day),scope_id:`FIRST:${id}`}}});
    if(!job)throw new Error('Expected overdue first-delivery work');return job.event_id;
  }
  async function work(id:string) {return dispatcher.dispatchPendingBatch(1,await firstJob(id));}
  async function orders(id:string){return db.orders.findMany({where:{subscription_id:id},include:{items:true,timeline:true}});}
  async function drain(day:string) {
    for(let i=0;i<1000;i++) {
      const pending=await db.job_runs.findFirst({where:{business_date:dateOnly(day),job_type:{in:[GENERATION_SCAN,GENERATION_BATCH]},event:{status:'PENDING',available_at:{lte:new Date()}}},orderBy:{event:{available_at:'asc'}}});
      if(!pending)return;await dispatcher.dispatchPendingBatch(1,pending.event_id);
    }
    throw new Error('Generation drain bound exceeded');
  }
  async function eventually(test:()=>Promise<boolean>) {
    for(let i=0;i<400;i++){if(await test())return;await new Promise(resolve=>setTimeout(resolve,50));}
    throw new Error('Process/lease did not reach the expected state');
  }
  function probe(eventId:string) {
    const child=spawn(process.execPath,['-r','ts-node/register','test/fixtures/subscription-generation-probe.ts',eventId],{cwd:process.cwd(),env:{...process.env},stdio:['ignore','pipe','pipe'],windowsHide:true});
    let output='';child.stdout!.on('data',b=>{output+=String(b);});child.stderr!.on('data',b=>{output+=String(b);});
    const exited=once(child,'exit').then(([code])=>({code,output}));
    return {child,exited};
  }
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();date=(await db.$transaction(tx=>homeClock(tx))).day;creationInstant=new Date(`${addDays(date,-1)}T04:00:00Z`);app=await boot();
    categoryId=(await db.categories.create({data:{code:`GEN-${randomUUID()}`,name_en:'Synthetic generation',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
  });
  beforeEach(async()=>{
    creationInstant=new Date(`${addDays(date,-1)}T04:00:00Z`);owner=await actor('VENDOR');buyer=await actor('CUSTOMER');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic generator',kyc_status:'VERIFIED',settings:{create:{time_slots:['AM']}}}})).id;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD'));
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:5000,subscription_price_paise:4800,stock_qty:100}})).id;
    const user=await db.users.findUniqueOrThrow({where:{id:buyer.id}});
    customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic linked',mobile:user.mobile,address_text:'Synthetic address'}})).id;
    engine=app.get(SubscriptionGenerationService);dispatcher=app.get(OutboxDispatcherService);
  });
  afterEach(()=>jest.restoreAllMocks());
  afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
  it('TC-081 scheduler scans bounded pages to success; both roles see one unpaid dated order and no setup money/stock',async()=>{
    const id=await sub();await engine.ensureScheduled();await drain(date);
    const rows=await orders(id);expect(rows).toHaveLength(1);const order=rows[0]!;
    expect(order).toMatchObject({source:'SUBSCRIPTION',status:'NEW',payment_mode:'KHATA',payment_status:'UNPAID',total_paise:4800n});
    expect(order.items[0]).toMatchObject({product_name_snapshot:'Synthetic milk',qty:1,unit_price_paise:4800n,milk_quantity_ml:new Prisma.Decimal(1000),milk_quantity_known:true});
    expect((await get('customer/orders',buyer).expect(200)).body.items.some((o:{id:string})=>o.id===order.id)).toBe(true);
    expect((await get('vendor/orders').expect(200)).body.items.some((o:{id:string})=>o.id===order.id)).toBe(true);
    expect((await get('customer/home',buyer).expect(200)).body.deliveries.some((o:{id:string})=>o.id===order.id)).toBe(true);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.payments.count({where:{vendor_id:vendorId}})).toBe(0);
    expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(100);
    const run=await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(date)}});
    // Other retained fixtures can deliberately leave this shared date incomplete.
    expect(run.scan_complete).toBe(true);
    expect((await db.job_runs.findUniqueOrThrow({where:{event_id:await firstJob(id)}})).finished_at).not.toBeNull();
    await engine.ensureScheduled();await drain(date);expect(await orders(id)).toHaveLength(1);
  });
  it('TC-080 exclusions cover weekdays, future starts, ranges, skips, pending/cancelled state and inactive products/customers',async()=>{
    const selected=await sub(),otherDay=(dateOnly(date).getUTCDay()+6)%7+1;
    const excluded=[await sub({weekdays:[otherDay===7?1:otherDay+1]}),await sub({startDate:addDays(date,2)})];
    const paused=await sub();await post(`vendor/subscriptions/${paused}/pause`,{version:1,fromDate:date,toDate:date}).expect(201);excluded.push(paused);
    const skipped=await sub();await post(`vendor/subscriptions/${skipped}/skip`,{version:1,date}).expect(201);excluded.push(skipped);
    const cancelled=await sub();await post(`vendor/subscriptions/${cancelled}/cancel`,{version:1}).expect(201);excluded.push(cancelled);
    const inactiveSku=await db.products.create({data:{vendor_id:vendorId,name:'Synthetic inactive',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:5000,stock_qty:100}});
    const unavailable=await sub({productId:inactiveSku.id});await db.products.update({where:{id:inactiveSku.id},data:{is_active:false}});excluded.push(unavailable);
    const inactive=await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic inactive',mobile:'+919000000000'}});
    const inactiveSub=await sub({vendorCustomerId:inactive.id});await db.vendor_customers.update({where:{id:inactive.id},data:{status:'INACTIVE'}});excluded.push(inactiveSub);
    for(const id of [selected,...excluded]) {
      await db.$transaction(tx=>engine.scheduleCreated(tx,id,vendorId,date));await work(id);
    }
    expect(await orders(selected)).toHaveLength(1);for(const id of excluded)expect(await orders(id)).toHaveLength(0);
  });
  it('TC-081 durable scan resumes beyond 100 rows and vendor batches never exceed 25',async()=>{
    let target=addDays(date,100);
    while(await db.subscription_generation_runs.findUnique({where:{delivery_date:dateOnly(target)}}))target=addDays(target,1);
    const ids:string[]=[];for(let i=0;i<101;i++)ids.push(await sub({startDate:target}));
    jest.spyOn(app.get(GenerationClock),'now').mockImplementation(tx=>homeClock(tx,new Date(`${addDays(target,-1)}T22:00:01+05:30`)));
    // Accelerate only these synthetic future events; the production due-date guard remains active.
    for(let i=0;i<1000;i++) {
      const pending=await db.job_runs.findFirst({where:{business_date:dateOnly(target),job_type:{in:[GENERATION_SCAN,GENERATION_BATCH]},event:{status:'PENDING'}},orderBy:{event:{created_at:'asc'}}});
      if(!pending)break;
      await db.outbox_events.update({where:{id:pending.event_id},data:{available_at:new Date(Date.now()-1000)}});
      expect(await dispatcher.dispatchPendingBatch(1,pending.event_id)).toBe(1);
    }
    const jobs=await db.job_runs.findMany({where:{business_date:dateOnly(target),job_type:{in:[GENERATION_SCAN,GENERATION_BATCH]}},include:{event:true}});
    expect(jobs.filter(j=>j.job_type===GENERATION_SCAN).length).toBeGreaterThan(1);
    for(const job of jobs.filter(j=>j.job_type===GENERATION_BATCH))expect((job.event.payload as {ids:string[]}).ids.length).toBeLessThanOrEqual(25);
    expect(await db.orders.count({where:{subscription_id:{in:ids},delivery_date:dateOnly(target)}})).toBe(101);
    const run=await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(target)}});
    expect(run.scan_complete).toBe(true);expect(run.completed_work).toBe(run.expected_work);expect(run.finished_at).not.toBeNull();
    const late=await sub({startDate:target});
    expect((await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(target)}})).finished_at).toBeNull();
    const event=await firstJob(late,target);
    await db.outbox_events.update({where:{id:event},data:{available_at:new Date(Date.now()-1000)}});
    expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(1);
    expect((await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(target)}})).finished_at).not.toBeNull();
  });
  it('TC-080/078 holiday, global pause/availability, plan expiry and suspension block production consumers',async()=>{
    const id=await sub(),event=await firstJob(id);
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{pause_all_subscriptions:true}});await dispatcher.dispatchPendingBatch(1,event);expect(await orders(id)).toHaveLength(0);
    // Each new subscription is a fresh independently leased work unit, not a reset of finished work.
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{pause_all_subscriptions:false,subscription_delivery_available:false}});
    const unavailable=await sub();await work(unavailable);expect(await orders(unavailable)).toHaveLength(0);
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{subscription_delivery_available:true}});
    const holiday=await sub();await db.vendor_holidays.create({data:{vendor_id:vendorId,date:dateOnly(date),reason:'Synthetic holiday'}});await work(holiday);expect(await orders(holiday)).toHaveLength(0);
    await db.vendor_holidays.delete({where:{vendor_id_date:{vendor_id:vendorId,date:dateOnly(date)}}});
    const expired=await sub();await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    await work(expired);expect(await orders(expired)).toHaveLength(0);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD'));const suspended=await sub();await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});
    await work(suspended);expect(await orders(suspended)).toHaveLength(0);
  });
  it('TC-083 BUSINESS auto-accepts, current prices snapshot once, then actual delivery posts exactly one debit/stock movement',async()=>{
    const id=await sub();await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BUSINESS'));
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{auto_accept_subscriptions:true,delivery_charge_paise:50}});
    await db.products.update({where:{id:productId},data:{subscription_price_paise:4900}});
    const event=await firstJob(id);expect((await Promise.all([dispatcher.dispatchPendingBatch(1,event),dispatcher.dispatchPendingBatch(1,event)])).reduce((a,b)=>a+b,0)).toBe(1);
    const order=(await orders(id))[0]!;expect(order).toMatchObject({status:'ACCEPTED',total_paise:4950n,version:1});
    await db.products.update({where:{id:productId},data:{subscription_price_paise:4000,name:'Synthetic changed'}});
    expect((await orders(id))[0]!.items[0]).toMatchObject({unit_price_paise:4900n,product_name_snapshot:'Synthetic milk'});
    await post(`vendor/orders/${order.id}/transitions`,{to:'OUT_FOR_DELIVERY',version:1}).expect(201);
    const key=randomUUID(),body={to:'DELIVERED',version:2,payment:{collected:false}};
    await post(`vendor/orders/${order.id}/transitions`,body,owner,key).expect(201);await post(`vendor/orders/${order.id}/transitions`,body,owner,key).expect(201);
    const entries=await db.ledger_entries.findMany({where:{ref_type:'ORDER',ref_id:order.id}});expect(entries).toHaveLength(1);expect(entries[0]!.amount_paise).toBe(4950n);
    expect(await db.stock_movements.count({where:{ref_id:order.id,reason:'ORDER'}})).toBe(1);
    expect(await db.payments.count({where:{order_id:order.id}})).toBe(0);
  });
  it('TC-083 zero-priced subscriptions deliver stock once without an invalid zero ledger entry',async()=>{
    const id=await sub();await db.products.update({where:{id:productId},data:{subscription_price_paise:0}});await work(id);
    const order=(await orders(id))[0]!;expect(order.total_paise).toBe(0n);expect(order.payment_status).toBe('PAID');
    await post(`vendor/orders/${order.id}/transitions`,{to:'ACCEPTED',version:1}).expect(201);
    await post(`vendor/orders/${order.id}/transitions`,{to:'OUT_FOR_DELIVERY',version:2}).expect(201);
    const key=randomUUID(),body={to:'DELIVERED',version:3,payment:{collected:false}};
    await post(`vendor/orders/${order.id}/transitions`,body,owner,key).expect(201);await post(`vendor/orders/${order.id}/transitions`,body,owner,key).expect(201);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.stock_movements.count({where:{ref_id:order.id}})).toBe(1);
    expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(99);
  });
  it('TC-081 late enrolment remains eligible and live shared caps serialize with checkout',async()=>{
    await drain(date);const id=await sub();expect((await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(date)}})).finished_at).toBeNull();
    await work(id);expect(await orders(id)).toHaveLength(1);
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{max_daily_orders:1}});
    const full=await sub();await work(full);expect(await orders(full)).toHaveLength(0);
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{max_daily_orders:null,daily_milk_capacity_ml:1500}});
    const milk=await sub();await work(milk);expect(await orders(milk)).toHaveLength(0);
    expect((await db.job_runs.findUniqueOrThrow({where:{event_id:await firstJob(milk)}})).finished_at).not.toBeNull();
  });
  it('TC-084 retries roll back order/inbox/counters, exhaust safely, and recovery does not duplicate effects',async()=>{
    const id=await sub(),event=await firstJob(id),notice=app.get(NotificationsService),original=notice.enqueue.bind(notice);
    const before=await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(date)}});
    const fault=jest.spyOn(notice,'enqueue').mockImplementation(async(tx,input)=>{await original(tx,input);throw new Error('synthetic private diagnostic');});
    for(let i=0;i<5;i++) {
      await db.outbox_events.update({where:{id:event},data:{available_at:new Date(Date.now()-1000)}});expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(0);
      expect(await orders(id)).toHaveLength(0);
    }
    const failed=await db.outbox_events.findUniqueOrThrow({where:{id:event}});expect(failed.status).toBe('FAILED');expect(failed.attempt_count).toBe(5);expect(failed.last_error).not.toContain('private');
    const progress=await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(date)}});expect(progress.generated_orders).toBe(before.generated_orders);
    await engine.alertOverdue();
    expect(await db.audit_logs.count({where:{action:'SUBSCRIPTION_GENERATION_INCOMPLETE',after:{path:['deliveryDate'],equals:date}}})).toBe(1);
    fault.mockRestore();await db.outbox_events.update({where:{id:event},data:{status:'PENDING',attempt_count:0,available_at:new Date(Date.now()-1000)}});
    expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(1);expect(await orders(id)).toHaveLength(1);
  });
  it('TC-084 alert is absent before 22:30 and durably deduplicated at the deadline',async()=>{
    // Use a fresh future root: a real run may already have alerted tonight after 22:30.
    let tomorrow=addDays(date,30);
    while(await db.subscription_generation_runs.findUnique({where:{delivery_date:dateOnly(tomorrow)}}))tomorrow=addDays(tomorrow,1);
    await sub({startDate:tomorrow});const evening=addDays(tomorrow,-1);
    const clock=jest.spyOn(app.get(GenerationClock),'now');
    clock.mockImplementation(tx=>homeClock(tx,new Date(`${evening}T22:29:59+05:30`)));
    await engine.alertOverdue();expect((await db.subscription_generation_runs.findUniqueOrThrow({where:{delivery_date:dateOnly(tomorrow)}})).alerted_at).toBeNull();
    clock.mockImplementation(tx=>homeClock(tx,new Date(`${evening}T22:30:00+05:30`)));
    await engine.alertOverdue();await engine.alertOverdue();
    expect(await db.audit_logs.count({where:{action:'SUBSCRIPTION_GENERATION_INCOMPLETE',after:{path:['deliveryDate'],equals:tomorrow}}})).toBe(1);
  });
  it('TC-081 worker tenant guards reject a forged vendor payload and background generation survives UI role switch',async()=>{
    const id=await sub(),event=await firstJob(id),saved=await db.outbox_events.findUniqueOrThrow({where:{id:event}});
    await db.outbox_events.update({where:{id:event},data:{payload:{date,vendorId:randomUUID(),ids:[id]}}});
    expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(0);expect(await orders(id)).toHaveLength(0);
    await db.outbox_events.update({where:{id:event},data:{payload:saved.payload as Prisma.InputJsonObject,available_at:new Date(Date.now()-1000)}});
    await db.users.update({where:{id:owner.id},data:{roles:{create:{role:'CUSTOMER'}},active_role:'CUSTOMER'}});
    expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(1);expect(await orders(id)).toHaveLength(1);
  });
  it('TC-081 actual process death after durable claim is fenced until lease expiry; a new process completes once',async()=>{
    const id=await sub(),event=await firstJob(id);let release!:()=>void,locked!:()=>void;
    const ready=new Promise<void>(r=>{locked=r;}),gate=new Promise<void>(r=>{release=r;});
    const hold=db.$transaction(async tx=>{await tx.$queryRaw`SELECT id FROM vendors WHERE id=${vendorId}::uuid FOR UPDATE`;locked();await gate;},{timeout:90000});
    let child:ChildProcess|undefined;
    try {
      await ready;const worker=probe(event);child=worker.child;
      await eventually(async()=>!!(await db.outbox_events.findUniqueOrThrow({where:{id:event}})).lease_token);
      child.kill('SIGKILL');await worker.exited;child=undefined;
      release();await hold;
      expect(await orders(id)).toHaveLength(0);expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(0);
      await db.outbox_events.update({where:{id:event},data:{lease_until:new Date(Date.now()-1000),available_at:new Date(Date.now()-1000)}});
      const restarted=probe(event);child=restarted.child;const result=await restarted.exited;child=undefined;
      expect(result.code).toBe(0);expect(result.output).toContain('GENERATION_PROBE_DONE:1');expect(await orders(id)).toHaveLength(1);
      expect(await dispatcher.dispatchPendingBatch(1,event)).toBe(0);
      expect((await db.outbox_events.findUniqueOrThrow({where:{id:event}})).attempt_count).toBe(2);
    } finally {release();if(child)child.kill('SIGKILL');await hold;}
  });
});
