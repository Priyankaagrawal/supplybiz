import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { homeClock } from '../home/home.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderPlaceInput } from './orders.dto';
const url = process.env.NATIVE_TEST_DATABASE_URL;
const native = url ? describe : describe.skip;
type Actor = { id: string; token: string; mobile: string };
native('T-045 native order HTTP/DB critical checks',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication, categoryId:string, buyer:Actor, owner:Actor, stranger:Actor, otherVendor:Actor;
  let vendorId:string,productId:string,addressId:string,input:OrderPlaceInput;
  let serial=0;
  async function boot() {
    const {AppModule}=await import('../../app.module');
    const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
    const instance=module.createNestApplication();configureHttpApp(instance);await instance.init();return instance;
  }
  async function actor(role:'CUSTOMER'|'VENDOR'='CUSTOMER'):Promise<Actor> {
    const mobile=`+919${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`;
    const u=await db.users.create({data:{mobile,name:'Synthetic customer',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:u.id,mobile,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const post=(path:string,body:object,who=buyer,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path:string,who=buyer)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  const place=(body:object=input,key:string=randomUUID())=>post('customer/orders',body,buyer,key);
  const transition=(id:string,body:object,who=owner,key:string=randomUUID())=>post(`vendor/orders/${id}/transitions`,body,who,key);
  const expectCode=async(result:PromiseLike<{body:{code:string}}>,code:string)=>expect((await result).body.code).toBe(code);
  async function settings(data:object) {await db.vendor_settings.update({where:{vendor_id:vendorId},data});}
  beforeAll(async()=>{
    const parsed=new URL(url!);if(!parsed.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(parsed.hostname))throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();app=await boot();
    categoryId=(await db.categories.create({data:{code:`ORDERS-${randomUUID()}`,name_en:'Synthetic orders',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
    stranger=await actor();otherVendor=await actor('VENDOR');
    await db.vendors.create({data:{user_id:otherVendor.id,category_id:categoryId,business_name:'Synthetic other',settings:{create:{}}}});
  });
  beforeEach(async()=>{
    buyer=await actor();owner=await actor('VENDOR');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic shop',kyc_status:'VERIFIED',latitude:12.97,longitude:77.59,
      settings:{create:{service_radius_km:3,time_slots:['07:00-08:00'],delivery_charge_paise:500}}}})).id;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk snapshot',product_type:'MILK',milk_type:'COW',unit_value:0.5,unit_type:'L',selling_price_paise:12345,stock_qty:10,moq:2}})).id;
    addressId=(await db.addresses.create({data:{user_id:buyer.id,label:'Synthetic home',line1:'Synthetic house',line2:'Synthetic street',city:'Synthetic city',state:'Synthetic state',pincode:'560001',latitude:12.97,longitude:77.59}})).id;
    const {day}=await db.$transaction(tx=>homeClock(tx));const date=new Date(`${day}T00:00:00Z`);date.setUTCDate(date.getUTCDate()+1);
    input={vendorId,addressId,deliveryDate:date.toISOString().slice(0,10),timeSlot:'07:00-08:00',paymentMode:'POD_CASH',items:[{productId,qty:2}],expectedTotalPaise:'25190'};
  });
  afterAll(async()=>{
    if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});
    await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);
  });
  it('TC-220/226/227 quotes without writes; snapshots, exact totals, atomic notices and permanent restart replay',async()=>{
    const {expectedTotalPaise:_,...quote}=input;
    const result=await post('customer/orders/quote',quote).expect(201);
    expect(result.body).toMatchObject({subtotalPaise:'24690',deliveryChargePaise:'500',discountPaise:'0',totalPaise:'25190'});
    expect(await db.orders.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.vendor_customers.count({where:{vendor_id:vendorId}})).toBe(0);
    const changed=await place({...input,expectedTotalPaise:'1'}).expect(409);
    expect(changed.body).toMatchObject({code:'PRICE_CHANGED',quote:{totalPaise:'25190'}});
    const key=randomUUID();const responses=await Promise.all([place(input,key).expect(201),place(input,key).expect(201)]);
    expect(responses[0]!.body).toEqual(responses[1]!.body);const id=responses[0]!.body.id as string;
    expect(responses[0]!.body.orderNo).toMatch(/^ORD\d{8,}$/);
    expect(await db.orders.count({where:{vendor_id:vendorId}})).toBe(1);
    expect(await db.notifications.count({where:{source_key:`order:${id}:new`}})).toBe(1);
    expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(10);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);
    await db.products.update({where:{id:productId},data:{name:'Changed name',selling_price_paise:20000}});
    await db.addresses.update({where:{id:addressId},data:{line1:'Changed house'}});
    const detail=(await get(`customer/orders/${id}`).expect(200)).body;
    expect(detail.items[0]).toMatchObject({name:'Synthetic milk snapshot',unitPricePaise:'12345'});expect(detail.address.line1).toBe('Synthetic house');
    expect(detail.timeline.map((e:{status:string})=>e.status)).toEqual(['NEW']);
    await app.close();app=await boot();expect((await place(input,key).expect(201)).body).toEqual(responses[0]!.body);
    await expectCode(place({...input,paymentMode:'POD_UPI'},key).expect(422),'IDEMPOTENCY_MISMATCH');
    await expect(db.order_requests.deleteMany({where:{user_id:buyer.id}})).rejects.toThrow();
  });
  it('TC-222/223/224/225/229/231 validates MOQ/stock/ownership/coverage/date/slots/pause/minimum/POD and unknown fields',async()=>{
    const below=await place({...input,items:[{productId,qty:1}]}).expect(422);expect(below.body).toMatchObject({code:'BELOW_MOQ',productId});
    await expectCode(place({...input,items:[{productId,qty:11}]}).expect(422),'OUT_OF_STOCK');
    for(const bad of [{paymentMode:'KHATA'},{items:[...input.items,...input.items]},{items:[{productId,qty:1.5}]},{vendorId:1},{discountPaise:1},{totalPaise:1}])await place({...input,...bad}).expect(400);
    await settings({allow_khata_orders:true});await place({...input,paymentMode:'KHATA'}).expect(400);
    await expectCode(place({...input,addressId:randomUUID()}).expect(404),'ADDRESS_NOT_FOUND');
    await db.addresses.update({where:{id:addressId},data:{user_id:stranger.id}});await place().expect(404);
    await db.addresses.update({where:{id:addressId},data:{user_id:buyer.id,longitude:80}});await expectCode(place().expect(422),'NOT_SERVICEABLE');
    await db.vendor_service_pincodes.create({data:{vendor_id:vendorId,pincode:'560001'}});await place().expect(201);
    await place({...input,deliveryDate:'2026-02-30'}).expect(400);await place({...input,deliveryDate:'1900-01-01'}).expect(422);await place({...input,deliveryDate:'9999-01-01'}).expect(422);
    const {day}=await db.$transaction(tx=>homeClock(tx));await expectCode(place({...input,deliveryDate:day}).expect(422),'PAST_CUTOFF');
    await settings({accepting_today:true});await place({...input,deliveryDate:day}).expect(422);
    await settings({same_day_cutoff:new Date('1970-01-01T00:00:00Z')});await place({...input,deliveryDate:day}).expect(422);
    await expectCode(place({...input,timeSlot:'09:00-10:00'}).expect(422),'INVALID_TIME_SLOT');
    await settings({min_order_paise:30000});await expectCode(place().expect(422),'MIN_ORDER_NOT_MET');
    await settings({min_order_paise:0,delivery_paused:true});await expectCode(place().expect(422),'DELIVERY_PAUSED');
    await settings({delivery_paused:false});await db.vendor_holidays.create({data:{vendor_id:vendorId,date:new Date(input.deliveryDate),reason:'Synthetic holiday'}});await expectCode(place().expect(422),'VENDOR_HOLIDAY');
  });
  it('TC-206/228 enforces self-order, KYC/suspension/owner status and active assignment at placement',async()=>{
    await db.users.update({where:{id:owner.id},data:{active_role:'CUSTOMER',roles:{create:{role:'CUSTOMER'}}}});
    await expectCode(post('customer/orders',input,owner).expect(422),'SELF_ORDER_NOT_ALLOWED');
    await db.vendors.update({where:{id:vendorId},data:{kyc_status:'NOT_VERIFIED'}});await place().expect(404);
    await db.vendors.update({where:{id:vendorId},data:{kyc_status:'VERIFIED',is_suspended:true}});await place().expect(404);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:false}});
    await db.users.update({where:{id:owner.id},data:{status:'BLOCKED'}});await place().expect(404);
    await db.users.update({where:{id:owner.id},data:{status:'ACTIVE'}});
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId},data:{ends_at:new Date(Date.now()-1000),starts_at:new Date(Date.now()-60000)}});await place().expect(403);
  });
  it('TC-051 serializes distinct buyers at the daily cap and releases capacity on NEW cancellation',async()=>{
    await settings({max_daily_orders:1});
    const alt=await actor(),address=await db.addresses.create({data:{user_id:alt.id,label:'Synthetic',line1:'Synthetic',line2:'Synthetic',city:'Synthetic',state:'Synthetic',pincode:'560001',latitude:12.97,longitude:77.59}});
    const results=await Promise.all([place(),post('customer/orders',{...input,addressId:address.id},alt)]);
    expect(results.map(r=>r.status).sort()).toEqual([201,422]);expect(results.find(r=>r.status===422)!.body.code).toBe('CAPACITY_REACHED');
    const success=results[0]!.status===201?buyer:alt,id=results.find(r=>r.status===201)!.body.id as string;
    await post(`customer/orders/${id}/cancel`,{version:1},success).expect(201);await place().expect(201);
  });
  it('TC-051 snapshots exact milk pack volumes; later product edits do not alter booked capacity',async()=>{
    await settings({daily_milk_capacity_ml:1500});await place().expect(201);
    await db.products.update({where:{id:productId},data:{unit_value:0.001}});
    const second=await place().expect(201);expect((await db.order_items.findFirstOrThrow({where:{order_id:second.body.id as string}})).milk_quantity_ml.toString()).toBe('2');
    await settings({daily_milk_capacity_ml:1001});await expectCode(place().expect(422),'CAPACITY_REACHED');
  });
  it('TC-046/047/048/049 enforces versioned transitions, reasons, exact replay and delivery boundary',async()=>{
    const id=(await place().expect(201)).body.id as string,key=randomUUID();
    await transition(id,{to:'REJECTED',version:1}).expect(400);await transition(id,{to:'REJECTED',version:1,reason:'OTHER',reasonText:'abc'}).expect(400);
    const accepted=(await transition(id,{to:'ACCEPTED',version:1},owner,key).expect(201)).body;
    expect(accepted.status).toBe('ACCEPTED');expect((await transition(id,{to:'ACCEPTED',version:1},owner,key).expect(201)).body).toEqual(accepted);
    await expectCode(transition(id,{to:'ACCEPTED',version:1}).expect(409),'VERSION_CONFLICT');
    await expectCode(transition(id,{to:'PREPARING',version:1}).expect(409),'VERSION_CONFLICT');
    await transition(id,{to:'PREPARING',version:2}).expect(201);await transition(id,{to:'OUT_FOR_DELIVERY',version:3}).expect(201);
    await transition(id,{to:'DELIVERED',version:4}).expect(400);await transition(id,{to:'FAILED',version:4}).expect(400);
    await expectCode(transition(id,{to:'ACCEPTED',version:4}).expect(409),'INVALID_STATE_TRANSITION');
    expect(await db.notifications.count({where:{user_id:buyer.id,type:{in:['ORDER_ACCEPTED','OUT_FOR_DELIVERY']}}})).toBe(2);
    const rejectId=(await place().expect(201)).body.id as string;
    await transition(rejectId,{to:'REJECTED',version:1,reason:'OTHER',reasonText:'Synthetic rejection'}).expect(201);
    expect((await get(`customer/orders/${rejectId}`).expect(200)).body.rejectReason).toBe('Synthetic rejection');
  });
  it('TC-242/243 atomically races cancel against accept; expiry permits existing NEW cancellation with no financial entries',async()=>{
    const id=(await place().expect(201)).body.id as string;
    const results=await Promise.all([transition(id,{to:'ACCEPTED',version:1}),post(`customer/orders/${id}/cancel`,{version:1})]);
    expect(results.map(r=>r.status).sort()).toEqual([201,409]);
    const next=(await place().expect(201)).body.id as string;
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId},data:{ends_at:new Date(Date.now()-1000),starts_at:new Date(Date.now()-60000)}});
    await post(`customer/orders/${next}/cancel`,{version:1}).expect(201);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);
  });
  it('TC-045/IDOR guards lists/details/mutations and combines literal search/status/date with stable pagination',async()=>{
    const first=(await place().expect(201)).body,second=(await place().expect(201)).body;
    await transition(second.id as string,{to:'REJECTED',version:1,reason:'OUT_OF_STOCK'}).expect(201);
    const list=await get(`vendor/orders?status=CANCELLED&q=${second.orderNo as string}&date=${input.deliveryDate}`,owner).expect(200);expect(list.body.items.map((i:{id:string})=>i.id)).toEqual([second.id]);
    const a=(await get('vendor/orders?limit=1',owner).expect(200)).body,b=(await get('vendor/orders?limit=1&offset=1',owner).expect(200)).body;
    expect(new Set([a.items[0].id,b.items[0].id]).size).toBe(2);expect(a.total).toBe(2);
    expect((await get('vendor/orders?q=%25',owner).expect(200)).body.items).toEqual([]);
    expect((await get('customer/orders',stranger).expect(200)).body.items).toEqual([]);
    for(const path of [`customer/orders/${first.id as string}`,`vendor/orders/${first.id as string}`])await get(path,path.startsWith('vendor')?otherVendor:stranger).expect(404);
    await transition(first.id as string,{to:'ACCEPTED',version:1},otherVendor).expect(404);
    await post(`customer/orders/${first.id as string}/cancel`,{version:1},stranger).expect(404);
    await get('vendor/orders',buyer).expect(403);await get('customer/orders',owner).expect(403);
    await request(app.getHttpServer()).get('/api/v1/customer/orders').expect(401);
    await get('vendor/orders?date=2026-02-30',owner).expect(400);await get('customer/orders?userId=forged').expect(400);
  });
  it('TC-064/225 never auto-links offline history and respects inactive customers and customer-growth caps',async()=>{
    const row=await db.vendor_customers.create({data:{vendor_id:vendorId,mobile:buyer.mobile,name:'Synthetic offline'}});
    await expectCode(place().expect(409),'CUSTOMER_LINK_REQUIRED');expect((await db.vendor_customers.findUniqueOrThrow({where:{id:row.id}})).user_id).toBeNull();
    await post(`customer/link-requests/${row.id}/accept`,{}).expect(201);await place().expect(201);
    await db.vendor_customers.update({where:{id:row.id},data:{status:'INACTIVE'}});await place().expect(403);
    const other=await actor();await db.addresses.update({where:{id:addressId},data:{user_id:other.id}});
    await db.vendor_customers.createMany({data:Array.from({length:100},(_,i)=>({vendor_id:vendorId,name:'Synthetic cap',mobile:`+918${String(i).padStart(9,'0')}`}))});
    await expectCode(post('customer/orders',input,other).expect(422),'PLAN_CUSTOMER_LIMIT');
  });
  it('TC-220 preserves paise beyond JS safe integers and rejects BIGINT overflow before writing',async()=>{
    const max=2147483647;
    await db.products.update({where:{id:productId},data:{selling_price_paise:max,stock_qty:max}});
    const total=String(BigInt(max)*BigInt(max)+500n);
    const large={...input,items:[{productId,qty:max}],expectedTotalPaise:total};
    expect((await place(large).expect(201)).body.totalPaise).toBe(total);
    const extra=await Promise.all([1,2].map(()=>db.products.create({data:{vendor_id:vendorId,name:'Synthetic overflow',product_type:'OTHER',unit_type:'PCS',unit_value:1,selling_price_paise:max,stock_qty:max}})));
    await expectCode(place({...large,items:[...large.items,...extra.map(p=>({productId:p.id,qty:max}))]}).expect(422),'ORDER_TOTAL_TOO_LARGE');
    expect(await db.orders.count({where:{vendor_id:vendorId}})).toBe(1);
  });
  it('TC-227 rolls back order/customer/items/history/replay if the transactional notification fails; missing keys never write',async()=>{
    await request(app.getHttpServer()).post('/api/v1/customer/orders').set('Authorization',`Bearer ${buyer.token}`).send(input).expect(400);
    const producer=jest.spyOn(app.get(NotificationsService),'enqueue').mockRejectedValueOnce(new Error('Synthetic producer failure'));
    const key=randomUUID();
    try {await expectCode(place(input,key).expect(503),'ORDERS_UNAVAILABLE');} finally {producer.mockRestore();}
    expect(await db.orders.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.vendor_customers.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.order_requests.count({where:{user_id:buyer.id}})).toBe(0);
    await place(input,key).expect(201);
  });
  it('T-046 TC-229 options expose configured server dates/slots and enforce address/role/plan/coverage',async()=>{
    const path=`customer/orders/options?vendorId=${vendorId}&addressId=${addressId}`;
    const result=await get(path).expect(200);
    expect(result.body.availableDates).toHaveLength(7);expect(result.body.timeSlots).toEqual(['07:00-08:00']);
    expect(result.body.availableDates).not.toContain(result.body.businessDate);
    await db.vendor_holidays.create({data:{vendor_id:vendorId,date:new Date(input.deliveryDate),reason:'Synthetic'}});
    expect((await get(path).expect(200)).body.availableDates).not.toContain(input.deliveryDate);
    await get(path,stranger).expect(404);await get(path,owner).expect(403);
    await db.addresses.update({where:{id:addressId},data:{longitude:80}});await get(path).expect(422);
    await db.addresses.update({where:{id:addressId},data:{longitude:77.59}});
    await settings({delivery_paused:true});expect((await get(path).expect(200)).body.availableDates).toEqual([]);
    await settings({delivery_paused:false,time_slots:[]});expect((await get(path).expect(200)).body.timeSlots).toEqual([]);
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId},data:{starts_at:new Date(Date.now()-60000),ends_at:new Date(Date.now()-1000)}});await get(path).expect(403);
  });
});
