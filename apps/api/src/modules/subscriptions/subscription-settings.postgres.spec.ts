// T-075 / TC-078: real HTTP/PostgreSQL settings, feature gates and shared order caps.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash, generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from '../home/home.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { addDays, SubscriptionClock, subscriptionForDate, subscriptionRead } from './subscription-policy';
const url=process.env.NATIVE_TEST_DATABASE_URL;
const native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-075 native owned subscription settings',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,buyer:Actor,other:Actor,categoryId:string,vendorId:string,productId:string,customerId:string,addressId:string,day:string;
  let instant=new Date(),serial=0;
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]})
    .overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
    const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`+916${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic settings actor',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const get=(path='',who=owner)=>request(app.getHttpServer()).get(`/api/v1/vendor/settings${path}`).set('Authorization',`Bearer ${who.token}`);
  const patch=(body:object,key:string=randomUUID(),who=owner)=>request(app.getHttpServer()).patch('/api/v1/vendor/settings').set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const post=(path:string,body:object,who=owner,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const subscription=(customer=customerId)=>post('vendor/subscriptions',{vendorCustomerId:customer,productId,qty:1,weekdays:[1,2,3,4,5,6,7],startDate:addDays(day,1),timeSlot:'AM',paymentMethod:'CASH'});
  async function candidate(id:string,date:string){const row=await db.subscriptions.findUniqueOrThrow({where:{id},include:subscriptionRead});
    const settings=await db.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}});return subscriptionForDate(row,date,settings);}
  const orderBody=()=>({vendorId,addressId,deliveryDate:addDays(day,1),timeSlot:'AM',paymentMode:'POD_CASH',items:[{productId,qty:2}],expectedTotalPaise:'9600'});
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();app=await boot();categoryId=(await db.categories.create({data:{code:`SETTINGS-${randomUUID()}`,name_en:'Synthetic settings',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
    other=await actor('VENDOR');const vendor=await db.vendors.create({data:{user_id:other.id,category_id:categoryId,business_name:'Synthetic other',settings:{create:{time_slots:['AM']}}}});
    await db.$transaction(tx=>assignPlanFixture(tx,vendor.id,'STANDARD'));
  });
  beforeEach(async()=>{
    instant=new Date();owner=await actor('VENDOR');buyer=await actor('CUSTOMER');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic settings vendor',kyc_status:'VERIFIED',latitude:12.97,longitude:77.59,
      settings:{create:{time_slots:['AM'],service_radius_km:3}}}})).id;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD'));
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic half litre',product_type:'MILK',milk_type:'COW',unit_value:0.5,unit_type:'L',selling_price_paise:4800,stock_qty:100}})).id;
    const user=await db.users.findUniqueOrThrow({where:{id:buyer.id}});
    customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic Alpha',mobile:user.mobile}})).id;
    addressId=(await db.addresses.create({data:{user_id:buyer.id,label:'Synthetic',line1:'Synthetic',line2:'Synthetic',city:'Synthetic',state:'Synthetic',pincode:'560001',latitude:12.97,longitude:77.59}})).id;
    day=(await db.$transaction(tx=>homeClock(tx))).day;
  });
  afterEach(()=>jest.restoreAllMocks());
  afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
  it('FR-075 persists versioned caps/window, scoped audit and summary while preserving unrelated settings',async()=>{
    const initial=await get().expect(200);expect(initial.headers['cache-control']).toBe('no-store');
    expect(initial.body).toMatchObject({version:1,deliveryAvailable:true,deliveryStartTime:null,deliveryEndTime:null,pauseAllSubscriptions:false,dailyMilkCapacityLitres:null,canAutoAccept:false,canEditSubscriptions:true});
    const saved=await patch({version:1,deliveryStartTime:'06:00',deliveryEndTime:'09:00',dailyMilkCapacityLitres:'1.500',maxDailyOrders:20}).expect(200);
    expect(saved.body).toMatchObject({version:2,deliveryStartTime:'06:00',deliveryEndTime:'09:00',dailyMilkCapacityLitres:'1.5',maxDailyOrders:20});
    const row=await db.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}});expect(row.daily_milk_capacity_ml).toBe(1500);expect(row.time_slots).toEqual(['AM']);expect(row.service_radius_km).toBe(3);
    const audit=await db.audit_logs.findMany({where:{entity_id:vendorId,action:'SUBSCRIPTION_SETTINGS_UPDATED'}});expect(audit).toHaveLength(1);
    expect(audit[0]).toMatchObject({actor_type:'USER',actor_id:owner.id});expect(JSON.stringify(audit[0]!.after)).not.toContain('Synthetic');
    await patch({version:2,deliveryStartTime:'22:00',deliveryEndTime:'02:00'}).expect(200);
    await patch({version:3,deliveryStartTime:null,deliveryEndTime:null,dailyMilkCapacityLitres:null,maxDailyOrders:null}).expect(200);
    expect((await get().expect(200)).body.dailyMilkCapacityLitres).toBeNull();
    await patch({version:4,deliveryStartTime:'05:00',deliveryEndTime:'08:00',maxDailyOrders:1,dailyMilkCapacityLitres:'0.001'}).expect(200);
    const cleared=await patch({version:5,clearDeliveryWindow:true,clearMaxDailyOrders:true,clearDailyMilkCapacity:true}).expect(200);
    expect(cleared.body).toMatchObject({deliveryStartTime:null,deliveryEndTime:null,maxDailyOrders:null,dailyMilkCapacityLitres:null});
  });
  it('FR-075 BUSINESS alone enables auto-accept; downgrade exposes effective locks and permits reducing controls',async()=>{
    await patch({version:1,autoAcceptSubscriptions:true}).expect(403);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BUSINESS'));
    expect((await patch({version:1,autoAcceptSubscriptions:true}).expect(200)).body.effectiveAutoAcceptSubscriptions).toBe(true);
    const body={vendorId,addressId,productId,qty:1,weekdays:[1,2,3,4,5,6,7],startDate:addDays(day,1),timeSlot:'AM',paymentMethod:'CASH'};
    expect((await post('customer/subscriptions',body,buyer).expect(201)).body.status).toBe('ACTIVE');
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD'));
    expect((await get().expect(200)).body).toMatchObject({autoAcceptSubscriptions:true,effectiveAutoAcceptSubscriptions:false,canAutoAccept:false});
    expect((await post('customer/subscriptions',body,buyer).expect(201)).body.status).toBe('PENDING_APPROVAL');
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    await patch({version:2,maxDailyOrders:1}).expect(403);
    await patch({version:2,autoAcceptSubscriptions:false,pauseAllSubscriptions:true,deliveryAvailable:false}).expect(200);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'STANDARD',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    expect((await get().expect(200)).body.canReduceActivity).toBe(true);await patch({version:3,pauseAllSubscriptions:false}).expect(403);
  });
  it('TC-078 saved pause-all/availability gates every subscription without erasing individual pauses or orders',async()=>{
    const id=(await subscription().expect(201)).body.id,target=addDays(day,3);
    await post(`vendor/subscriptions/${id}/pause`,{version:1,fromDate:target,toDate:target}).expect(201);
    expect(await candidate(id,addDays(day,4))).not.toBeNull();expect(await candidate(id,target)).toBeNull();
    await patch({version:1,pauseAllSubscriptions:true}).expect(200);
    expect(await candidate(id,addDays(day,4))).toBeNull();
    const before=await db.subscriptions.findUniqueOrThrow({where:{id}});
    await patch({version:2,pauseAllSubscriptions:false,deliveryAvailable:false}).expect(200);expect(await candidate(id,addDays(day,4))).toBeNull();
    await patch({version:3,deliveryAvailable:true}).expect(200);
    expect(await candidate(id,addDays(day,4))).not.toBeNull();expect(await candidate(id,target)).toBeNull();
    expect((await db.subscriptions.findUniqueOrThrow({where:{id}})).version).toBe(before.version);
    expect(await db.orders.count({where:{subscription_id:id}})).toBe(0);expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);
  });
  it('FR-046/075 exact milk cap reaches real checkout; concurrent orders admit one final litre, null clears limit',async()=>{
    await patch({version:1,dailyMilkCapacityLitres:'1.5'}).expect(200);
    const result=await Promise.all([post('customer/orders',orderBody(),buyer),post('customer/orders',orderBody(),buyer)]);
    expect(result.map(r=>r.status).sort()).toEqual([201,422]);expect(result.find(r=>r.status===422)!.body.code).toBe('CAPACITY_REACHED');
    expect(await db.orders.count({where:{vendor_id:vendorId}})).toBe(1);
    await patch({version:2,dailyMilkCapacityLitres:null,maxDailyOrders:1}).expect(200);await post('customer/orders',orderBody(),buyer).expect(422);
    await patch({version:3,maxDailyOrders:null}).expect(200);await post('customer/orders',orderBody(),buyer).expect(201);
    await patch({version:4,maxDailyOrders:0}).expect(400);
  });
  it('FR-075 summary/customer pagination derives ended/paused states and never reads a foreign vendor',async()=>{
    const first=(await subscription().expect(201)).body.id;
    const next=await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic Beta',mobile:'+919000000001'}});
    const second=(await subscription(next.id).expect(201)).body.id;
    await post(`vendor/subscriptions/${second}/pause`,{version:1,fromDate:addDays(day,3),toDate:addDays(day,5)}).expect(201);
    instant=new Date(`${addDays(day,4)}T04:00:00Z`);jest.spyOn(app.get(SubscriptionClock),'now').mockImplementation(tx=>homeClock(tx,instant));
    const response=await get().expect(200);expect(response.body.summary).toMatchObject({totalSubscriptions:2,active:1,paused:1,subscriptionCustomers:2});
    const page=await get('/subscription-customers?limit=1&offset=1').expect(200);expect(page.body.total).toBe(2);expect(page.body.items).toMatchObject([{id:next.id,pausedSubscriptions:1}]);
    expect((await get('/subscription-customers',other).expect(200)).body.items).toEqual([]);
    // End-date projection is evaluated by the DB date even before T-073 retires references.
    await db.subscriptions.update({where:{id:first},data:{end_date:new Date(`${addDays(day,2)}T00:00:00Z`)}});
    expect((await get().expect(200)).body.summary).toMatchObject({completed:1,active:0,paused:1,subscriptionCustomers:1});
  });
  it('FR-075 validation and actor/tenant/session checks reject forged fields without writes',async()=>{
    for(const bad of [{autoAcceptSubscriptions:null},{pauseAllSubscriptions:'true'},{maxDailyOrders:-1},{maxDailyOrders:1.5},{dailyMilkCapacityLitres:1.5},
      {dailyMilkCapacityLitres:'0'},{dailyMilkCapacityLitres:'2147483.648'},{dailyMilkCapacityLitres:'0.0001'},{deliveryStartTime:'24:00',deliveryEndTime:'09:00'},
      {deliveryStartTime:'06:00'},{deliveryStartTime:'06:00',deliveryEndTime:'06:00'},{clearMaxDailyOrders:false},{clearMaxDailyOrders:true,maxDailyOrders:1},
      {clearDailyMilkCapacity:true,dailyMilkCapacityLitres:'1'},{clearDeliveryWindow:true,deliveryStartTime:'01:00'},{vendorId},{customerId}]) await patch({version:1,...bad}).expect(400);
    await patch({version:1}).expect(400);await patch({version:1,pauseAllSubscriptions:true},'').expect(400);
    await get('',buyer).expect(403);await patch({version:1,pauseAllSubscriptions:true},randomUUID(),buyer).expect(403);
    await request(app.getHttpServer()).get('/api/v1/vendor/settings').expect(401);await get('/subscription-customers?limit=51').expect(400);
    await patch({version:1,pauseAllSubscriptions:true},randomUUID(),other).expect(200);expect((await get().expect(200)).body.pauseAllSubscriptions).toBe(false);
    await db.users.update({where:{id:owner.id},data:{active_role:'CUSTOMER'}});await get().expect(403);
    await db.users.update({where:{id:owner.id},data:{active_role:'VENDOR'}});await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get().expect(403);
    await db.sessions.updateMany({where:{user_id:other.id},data:{status:'REVOKED'}});await get('',other).expect(401);
  });
  it('FR-075 same-key replay survives restart, stale/version races and expired cache cannot reapply old intent',async()=>{
    const key=randomUUID(),input={version:1,pauseAllSubscriptions:true},responses=await Promise.all([patch(input,key),patch(input,key)]);
    expect(responses.map(r=>r.status)).toEqual([200,200]);expect(responses[0]!.body).toEqual(responses[1]!.body);
    await app.close();app=await boot();expect((await patch(input,key).expect(200)).body).toEqual(responses[0]!.body);
    await patch({...input,pauseAllSubscriptions:false},key).expect(422);
    const changed=await Promise.all([patch({version:2,maxDailyOrders:1}),patch({version:2,maxDailyOrders:2})]);expect(changed.map(r=>r.status).sort()).toEqual([200,409]);
    const requestKey=`subscription-settings:${createHash('sha256').update(`${owner.id}:${key}`).digest('hex')}`;
    await db.idempotency_keys.update({where:{idempotency_key:requestKey},data:{expires_at:new Date(Date.now()-1000)}});await patch(input,key).expect(409);
    expect(await db.audit_logs.count({where:{entity_id:vendorId,action:'SUBSCRIPTION_SETTINGS_UPDATED'}})).toBe(2);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await patch(input,key).expect(403);
  });
  it('FR-075 a clock/readback failure rolls back settings, audit and retry cache together',async()=>{
    const key=randomUUID(),input={version:1,pauseAllSubscriptions:true};
    jest.spyOn(app.get(SubscriptionClock),'now').mockRejectedValueOnce(new Error('synthetic private diagnostic'));
    const result=await patch(input,key).expect(503);expect(JSON.stringify(result.body)).not.toContain('private');
    expect((await db.vendor_settings.findUniqueOrThrow({where:{vendor_id:vendorId}})).version).toBe(1);
    expect(await db.audit_logs.count({where:{entity_id:vendorId,action:'SUBSCRIPTION_SETTINGS_UPDATED'}})).toBe(0);
    expect(await db.idempotency_keys.count({where:{user_id:owner.id,path:'subscription-settings'}})).toBe(0);
    await patch(input,key).expect(200);
  });
});
