// T-072 / TC-070–079: real HTTP/PostgreSQL; generation job remains T-073.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from '../home/home.service';
import { NotificationsService } from '../notifications/notifications.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { dateOnly, SubscriptionClock, subscriptionForDate, subscriptionRead } from './subscription-policy';
import { LedgerService } from '../ledger/ledger.service';
const url=process.env.NATIVE_TEST_DATABASE_URL;
const native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-072 native subscription consent/cutoff/ownership transactions',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,buyer:Actor,stranger:Actor,other:Actor;
  let categoryId:string,vendorId:string,productId:string,addressId:string,customerId:string,serial=0;
  let instant=new Date('2026-10-01T15:29:00Z');
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]})
    .overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()})
    .overrideProvider(SubscriptionClock).useValue({now:(tx:Prisma.TransactionClient)=>homeClock(tx,instant)}).compile();
    const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'CUSTOMER'|'VENDOR'):Promise<Actor>{
    const user=await db.users.create({data:{mobile:`+917${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic subscriber',active_role:role,roles:{create:{role}}}});
    const session=await db.sessions.create({data:{user_id:user.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:user.id,token:app.get(SessionTokensService).issue(user.id,session.id,[])};
  }
  const payload=()=>({vendorId,addressId,productId,qty:1,weekdays:[1,2,3,4,5,6,7],startDate:'2026-10-02',timeSlot:'AM',paymentMethod:'CASH'});
  const post=(path:string,body:object,who=buyer,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path:string,who=buyer)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  const create=(body:object=payload(),key:string=randomUUID())=>post('customer/subscriptions',body,buyer,key);
  const change=(id:string,action:string,body:object,who=buyer,key:string=randomUUID())=>post(`${who===owner?'vendor':'customer'}/subscriptions/${id}/${action}`,body,who,key);
  const edit=(id:string,body:object,who=buyer,key:string=randomUUID())=>request(app.getHttpServer()).patch(`/api/v1/${who===owner?'vendor':'customer'}/subscriptions/${id}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const read=(id:string)=>db.subscriptions.findUniqueOrThrow({where:{id},include:subscriptionRead});
  async function active(){const row=(await create().expect(201)).body;await change(row.id,'approve',{version:1},owner).expect(201);return row.id as string;}
  async function generated(id:string,status='ACCEPTED',day='2026-10-02'){
    return db.orders.create({data:{order_no:`SYN-${randomUUID()}`,vendor_id:vendorId,vendor_customer_id:customerId,source:'SUBSCRIPTION',subscription_id:id,
      status,delivery_date:dateOnly(day),time_slot:'AM',address_snapshot:{text:'Synthetic'},subtotal_paise:4800n,total_paise:4800n,
      delivery_charge_paise:0n,payment_mode:'KHATA',payment_status:'UNPAID'}});
  }
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local _test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();app=await boot();
    categoryId=(await db.categories.create({data:{code:`SUB-${randomUUID()}`,name_en:'Synthetic subscription',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
    stranger=await actor('CUSTOMER');other=await actor('VENDOR');
    await db.vendors.create({data:{user_id:other.id,category_id:categoryId,business_name:'Synthetic other',settings:{create:{time_slots:['AM']}}}});
  });
  beforeEach(async()=>{
    instant=new Date('2026-10-01T15:29:00Z');owner=await actor('VENDOR');buyer=await actor('CUSTOMER');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic subscription vendor',kyc_status:'VERIFIED',latitude:12.97,longitude:77.59,
      settings:{create:{service_radius_km:3,time_slots:['AM','PM']}}}})).id;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD'));
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:5000,subscription_price_paise:4800,stock_qty:10}})).id;
    addressId=(await db.addresses.create({data:{user_id:buyer.id,label:'Synthetic',line1:'Synthetic',line2:'Synthetic',city:'Synthetic',state:'Synthetic',pincode:'560001',latitude:12.97,longitude:77.59}})).id;
    const user=await db.users.findUniqueOrThrow({where:{id:buyer.id}});
    customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic linked customer',mobile:user.mobile,address_text:'Synthetic address'}})).id;
  });
  afterEach(()=>jest.restoreAllMocks());
  afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
  it('T-078 TC-077/FR-233 delivered snapshots and paged totals reconcile with shared ledger, payments and reversal',async()=>{
    const id=await active(),otherId=await active(),clock=await db.$transaction(tx=>homeClock(tx)),month=clock.day.slice(0,7);
    async function deliver(sub:string,paid=false,day=`${month}-02`){
      const order=await generated(sub,'ACCEPTED',day);
      await db.order_items.create({data:{order_id:order.id,product_id:productId,product_name_snapshot:'Synthetic frozen milk',unit_snapshot:{value:1,type:'L'},unit_price_paise:4800n,qty:1,line_total_paise:4800n}});
      await post(`vendor/orders/${order.id}/transitions`,{version:1,to:'OUT_FOR_DELIVERY'},owner).expect(201);
      await post(`vendor/orders/${order.id}/transitions`,{version:2,to:'DELIVERED',payment:paid?{collected:true,method:'CASH',amountPaise:'1000'}:{collected:false}},owner).expect(201);
      return order.id;
    }
    const first=await deliver(id,true);await deliver(id,false,`${month}-01`);await deliver(otherId);
    await generated(id,'CANCELLED',`${month}-03`);
    const statement=(await get(`customer/subscriptions/${id}/statement?month=${month}&limit=1`).expect(200)).body;
    expect(statement).toMatchObject({subscriptionId:id,month,total:2,deliveredQty:'2',deliveredAmountPaise:'9600'});expect(statement.items).toHaveLength(1);expect(statement.items[0]).toMatchObject({deliveryDate:`${month}-02`,productName:'Synthetic frozen milk',qty:1,amountPaise:'4800',paymentStatus:'UNPAID'});
    const vendor=(await get(`vendor/khata/${customerId}/entries?month=${month}&limit=50`,owner).expect(200)).body;
    expect({...statement.ledger,serverTime:null}).toEqual({...vendor,serverTime:null});expect(statement.ledger).toMatchObject({monthPaidPaise:'1000',closingDuePaise:'13400',duePaise:'13400'});
    const second=(await get(`customer/subscriptions/${id}/statement?month=${month}&limit=1&offset=1`).expect(200)).body;expect(second.items[0].orderId).not.toBe(statement.items[0].orderId);expect(second.deliveredAmountPaise).toBe('9600');
    const receipt=await db.payments.findUniqueOrThrow({where:{order_id:first}}),credit=await db.ledger_entries.findFirstOrThrow({where:{ref_id:receipt.id,ref_type:'PAYMENT',type:'CREDIT'}});
    await app.get(LedgerService).reverse(owner.id,randomUUID(),credit.id,'Synthetic payment correction');
    await db.products.update({where:{id:productId},data:{name:'Synthetic renamed milk'}});
    const refreshed=(await get(`customer/subscriptions/${id}/statement?month=${month}`).expect(200)).body;expect(refreshed.items[0].productName).toBe('Synthetic frozen milk');expect(refreshed.ledger).toMatchObject({monthPaidPaise:'0',closingDuePaise:'14400'});
  });
  it('T-078 FR-233 statement is accepted-link owned, role/month validated, empty and historical after expiry',async()=>{
    const id=await active(),path=`customer/subscriptions/${id}/statement?month=2026-10`;
    await get(path,stranger).expect(404);await get(path,owner).expect(403);await get(`customer/subscriptions/${id}/statement?month=2026-13`).expect(400);
    const response=await get(path).expect(200);expect(response.headers['cache-control']).toBe('no-store');expect(response.body).toMatchObject({items:[],total:0,deliveredAmountPaise:'0',deliveredQty:'0'});
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    await get(path).expect(200);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get(path).expect(200);
    await db.vendor_customers.update({where:{id:customerId},data:{user_id:null}});await get(path).expect(404);
  });
  it('TC-070/072 creates pending, approves/rejects with owned notices, exact estimates and no financial writes',async()=>{
    const created=await create().expect(201);expect(created.headers['cache-control']).toBe('no-store');expect(created.body.status).toBe('PENDING_APPROVAL');
    const id=created.body.id;
    expect(subscriptionForDate(await read(id),'2026-10-02')).toBeNull();
    await change(id,'approve',{version:1},owner).expect(201);
    const detail=(await get(`customer/subscriptions/${id}`).expect(200)).body;
    expect(detail).toMatchObject({qty:1,version:2,status:'ACTIVE',dailyAmountPaise:'4800',monthlyEstimatePaise:'144000',paymentMethod:'CASH'});
    expect(subscriptionForDate(await read(id),'2026-10-02')?.qty).toBe(1);
    const notices=await db.notifications.findMany({where:{source_key:{startsWith:`sub:${id}:`}}});
    expect(notices.map(n=>n.type).sort()).toEqual(['SUBSCRIPTION_APPROVED','SUBSCRIPTION_REQUEST']);
    expect(JSON.stringify(notices.map(n=>({title:n.title,body:n.body})))).not.toContain('Synthetic');
    expect(await db.orders.count({where:{subscription_id:id}})).toBe(0);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.payments.count({where:{vendor_id:vendorId}})).toBe(0);
    expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(10);
    const rejected=(await create().expect(201)).body.id;await change(rejected,'reject',{version:1,reason:'Synthetic capacity reason'},owner).expect(201);
    expect((await get(`customer/subscriptions/${rejected}`).expect(200)).body.status).toBe('REJECTED');
  });
  it('TC-073 BUSINESS auto-accepts; STANDARD cannot inherit AUTO_ACCEPT, BASIC cannot create; plans use exact pack sizes',async()=>{
    await db.vendor_settings.update({where:{vendor_id:vendorId},data:{auto_accept_subscriptions:true}});
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BUSINESS'));
    expect((await create().expect(201)).body.status).toBe('ACTIVE');
    const plans=(await get(`customer/vendors/${vendorId}/subscription-plans?addressId=${addressId}`).expect(200)).body;
    expect(plans.items.map((p:{kind:string})=>p.kind)).toEqual(['CUSTOM','1000_ML_DAILY','2000_ML_DAILY']);
    expect(plans.items[2]).toMatchObject({qty:2,dailyAmountPaise:'9600',mostPopular:null});
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD'));
    expect((await create().expect(201)).body.status).toBe('PENDING_APPROVAL');
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));await create().expect(403);
    await get(`customer/vendors/${vendorId}/subscription-plans?addressId=${addressId}`).expect(403);
  });
  it('TC-071 validates dates/quantity/weekdays/slots/null/ownership fields and prevents partial writes',async()=>{
    for(const bad of [{startDate:'2026-10-01'},{startDate:'2026-02-30'},{endDate:'2026-10-01'},{qty:0},{qty:1.5},{weekdays:[]},{weekdays:[1,1]},{weekdays:[0]},{weekdays:[8]},
      {qty:null},{weekdays:null},{paymentMethod:'KHATA'},{endDate:null},{timeSlot:'unconfigured'},{vendorCustomerId:customerId},{pricePaise:'1'}]) {
      const response=await create({...payload(),...bad});expect([400,422]).toContain(response.status);
    }
    await create(payload(),'').expect(400);await get('customer/subscriptions?limit=51').expect(400);
    expect(await db.subscriptions.count({where:{vendor_id:vendorId}})).toBe(0);
    await db.addresses.update({where:{id:addressId},data:{latitude:0,longitude:0}});await create().expect(422);
    await db.addresses.update({where:{id:addressId},data:{user_id:stranger.id}});await create().expect(404);
  });
  it('TC-072/500 permanent replay survives concurrent requests/application restart and later changes',async()=>{
    const key=randomUUID(),body=payload(),results=await Promise.all([create(body,key),create(body,key)]);
    expect(results.map(r=>r.status)).toEqual([201,201]);expect(results[0]!.body).toEqual(results[1]!.body);
    const id=results[0]!.body.id;await change(id,'approve',{version:1},owner).expect(201);
    await app.close();app=await boot();expect((await create(body,key).expect(201)).body).toEqual(results[0]!.body);
    await create({...body,qty:2},key).expect(422);
    expect(await db.subscriptions.count({where:{vendor_id:vendorId}})).toBe(1);
    const changes=await Promise.all([edit(id,{version:2,qty:2}),edit(id,{version:2,qty:3})]);
    expect(changes.map(r=>r.status).sort()).toEqual([200,409]);expect((await read(id)).version).toBe(3);
    await expect(db.subscription_requests.updateMany({where:{user_id:buyer.id},data:{path:'forged'}})).rejects.toThrow();
    await expect(db.subscription_revisions.updateMany({where:{subscription_id:id},data:{qty:99}})).rejects.toThrow();
  });
  it('TC-064/072 scope denies other account/vendor/role/revoked sessions and cached replay after suspension',async()=>{
    const key=randomUUID(),body=payload(),id=(await create(body,key).expect(201)).body.id;
    await get(`customer/subscriptions/${id}`,stranger).expect(404);await get(`vendor/subscriptions/${id}`,other).expect(404);
    await change(id,'pause',{version:1},stranger).expect(404);
    await get('customer/subscriptions',owner).expect(403);await request(app.getHttpServer()).get('/api/v1/customer/subscriptions').expect(401);
    await post(`customer/subscriptions/${id}/approve`,{version:1}).expect(404);
    await db.users.update({where:{id:buyer.id},data:{active_role:'VENDOR'}});await create(body,key).expect(403);
    await db.users.update({where:{id:buyer.id},data:{active_role:'CUSTOMER'}});
    await db.sessions.updateMany({where:{user_id:buyer.id},data:{status:'REVOKED'}});await get(`customer/subscriptions/${id}`).expect(401);
    const owned=await post('vendor/subscriptions',{productId,qty:1,weekdays:[1],startDate:'2026-10-02',timeSlot:'AM',paymentMethod:'UPI',vendorCustomerId:customerId},owner).expect(201);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get(`vendor/subscriptions/${owned.body.id}`,owner).expect(403);
  });
  it('TC-074 range pause resumes after inclusive end, open pause/resume preserves past and references protect products',async()=>{
    const id=await active();
    await change(id,'pause',{version:2,fromDate:'2026-10-10',toDate:'2026-10-12'}).expect(201);
    let row=await read(id);expect(subscriptionForDate(row,'2026-10-10')).toBeNull();expect(subscriptionForDate(row,'2026-10-12')).toBeNull();expect(subscriptionForDate(row,'2026-10-13')).not.toBeNull();
    await change(id,'pause',{version:3,fromDate:'2026-10-15'}).expect(201);
    instant=new Date('2026-10-16T14:00:00Z');await change(id,'resume',{version:4}).expect(201);
    row=await read(id);expect(subscriptionForDate(row,'2026-10-16')).toBeNull();expect(subscriptionForDate(row,'2026-10-17')).not.toBeNull();
    expect((await db.customer_subscription_links.findUniqueOrThrow({where:{subscription_id:id}})).status).toBe('ACTIVE');
    await request(app.getHttpServer()).delete(`/api/v1/vendor/products/${productId}`).set('Authorization',`Bearer ${owner.token}`).set('Idempotency-Key',randomUUID()).expect(409);
    expect((await get('vendor/customers?filter=SUBSCRIPTION',owner).expect(200)).body.total).toBe(1);
  });
  it('TC-079/ADR-029 expiry preserves owned history and reducing changes while blocking new/resumed business',async()=>{
    const id=await active();await change(id,'pause',{version:2}).expect(201);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    await get(`vendor/subscriptions/${id}`,owner).expect(200);await get(`customer/subscriptions/${id}`).expect(200);
    await create().expect(403);await edit(id,{version:3,qty:2}).expect(403);await change(id,'resume',{version:3}).expect(403);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});
    await get(`customer/subscriptions/${id}`).expect(200);
    await change(id,'cancel',{version:3}).expect(201);
    await get(`vendor/subscriptions/${id}`,owner).expect(403);
  });
  it('TC-075–077 cutoff freezes qty, rejects explicit frozen customer skip; vendor can atomically cancel a seeded generated order',async()=>{
    const id=await active();
    await edit(id,{version:2,qty:2}).expect(200);
    instant=new Date('2026-10-01T15:30:00Z');const changed=await edit(id,{version:3,qty:3,timeSlot:'PM'}).expect(200);
    expect(changed.body.effectiveFrom).toBe('2026-10-03');
    expect(subscriptionForDate(await read(id),'2026-10-02')?.qty).toBe(2);expect(subscriptionForDate(await read(id),'2026-10-03')?.qty).toBe(3);
    const late=await change(id,'skip',{version:4,date:'2026-10-02'}).expect(422);
    expect(late.body.code).toBe('PAST_CUTOFF');expect(late.body.detail).toContain('21:00 IST');
    const latePause=await change(id,'pause',{version:4,fromDate:'2026-10-02'}).expect(422);
    expect(latePause.body.detail).toContain('2026-10-03');
    const order=await generated(id);await change(id,'skip',{version:4,date:'2026-10-02'},owner).expect(201);
    expect((await db.orders.findUniqueOrThrow({where:{id:order.id}})).status).toBe('CANCELLED');
    expect(await db.order_status_events.count({where:{order_id:order.id,status:'CANCELLED'}})).toBe(1);
    expect(subscriptionForDate(await read(id),'2026-10-02')).toBeNull();
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.stock_movements.count({where:{ref_id:order.id}})).toBe(0);
    await expect(db.order_status_events.deleteMany({where:{order_id:order.id}})).rejects.toThrow();
  });
  it('TC-075/079 before-cutoff skip works; progressed generated orders cannot be skipped; cancel is effective-dated',async()=>{
    const id=await active();await change(id,'skip',{version:2,date:'2026-10-03'}).expect(201);
    expect(subscriptionForDate(await read(id),'2026-10-03')).toBeNull();
    await generated(id,'OUT_FOR_DELIVERY');instant=new Date('2026-10-01T15:31:00Z');
    await change(id,'skip',{version:3,date:'2026-10-02'},owner).expect(409);
    const cancel=await change(id,'cancel',{version:3}).expect(201);expect(cancel.body.effectiveFrom).toBe('2026-10-03');
    expect(subscriptionForDate(await read(id),'2026-10-02')).not.toBeNull();expect(subscriptionForDate(await read(id),'2026-10-04')).toBeNull();
    await change(id,'resume',{version:4}).expect(409);
  });
  it('TC-072/077 rollback includes customer/reference/inbox/request and generated-order cancellation on enqueue failure',async()=>{
    await db.vendor_customers.delete({where:{id:customerId}});
    const notice=app.get(NotificationsService),original=notice.enqueue.bind(notice);
    const failure=jest.spyOn(notice,'enqueue').mockImplementationOnce(async(tx,event)=>{await original(tx,event);throw new Error('synthetic private diagnostic');});
    const key=randomUUID();const failed=await create(payload(),key).expect(503);expect(JSON.stringify(failed.body)).not.toContain('private');failure.mockRestore();
    expect(await db.subscriptions.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.subscription_requests.count({where:{user_id:buyer.id}})).toBe(0);
    expect(await db.vendor_customers.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.product_subscription_links.count({where:{product_id:productId}})).toBe(0);
    const id=(await create(payload(),key).expect(201)).body.id;await change(id,'approve',{version:1},owner).expect(201);
    customerId=(await read(id)).vendor_customer_id;
    const order=await generated(id);
    jest.spyOn(notice,'enqueue').mockImplementationOnce(async(tx,event)=>{await original(tx,event);throw new Error('synthetic');});
    await change(id,'skip',{version:2,date:'2026-10-02'},owner).expect(503);
    expect((await db.orders.findUniqueOrThrow({where:{id:order.id}})).status).toBe('ACCEPTED');
    expect(await db.subscription_skips.count({where:{subscription_id:id}})).toBe(0);expect((await read(id)).version).toBe(2);
  });
  it('TC-064/071 vendor can create existing/new offline customers; mobile matching needs consent and capacity stays atomic',async()=>{
    const input={productId,qty:1,weekdays:[1],startDate:'2026-10-02',timeSlot:'AM',paymentMethod:'CASH'};
    const fresh=await post('vendor/subscriptions',{...input,newCustomer:{name:'Synthetic offline',mobile:'9000000000',address:'Synthetic street'}},owner).expect(201);
    expect((await get(`vendor/subscriptions/${fresh.body.id}`,owner).expect(200)).body.status).toBe('ACTIVE');
    const offline=(await read(fresh.body.id)).customer;expect(offline.user_id).toBeNull();
    await db.vendor_customers.update({where:{id:customerId},data:{user_id:null}});await create().expect(409);
    await post(`customer/link-requests/${customerId}/accept`,{}).expect(201);await create().expect(201);
    await db.vendor_customers.createMany({data:Array.from({length:247},(_,i)=>({vendor_id:vendorId,name:'Synthetic cap',mobile:`+918${String(i).padStart(9,'0')}`}))});
    const finalSlot=await Promise.all(['9000000001','9000000002'].map(mobile=>post('vendor/subscriptions',{...input,newCustomer:{name:'Synthetic last slot',mobile}},owner)));
    expect(finalSlot.map(r=>r.status).sort()).toEqual([201,422]);
    expect(await db.vendor_customers.count({where:{vendor_id:vendorId}})).toBe(250);
    // Downgrade retains over-limit existing rows and grants no subscription feature.
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    await post('vendor/subscriptions',{...input,newCustomer:{name:'Synthetic blocked',mobile:'9000000001'}},owner).expect(403);
    expect(await db.vendor_customers.count({where:{vendor_id:vendorId}})).toBe(250);
  });
});
