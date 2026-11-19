// T-030 / TC-030: HTTP -> real PostgreSQL. Fixtures are synthetic, no provider calls.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { VendorDashboard } from './vendor-dashboard.dto';
import { VendorDashboardService } from './vendor-dashboard.service';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-030 native vendor dashboard',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,buyer:Actor,other:Actor,vendorId:string,foreignId:string,customerId:string,categoryId:string;
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`synthetic-dash-${randomUUID()}`,name:'Synthetic dashboard actor',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return{id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const get=(query='',who=owner)=>request(app.getHttpServer()).get(`/api/v1/vendor/dashboard${query}`).set('Authorization',`Bearer ${who.token}`);
  const metrics=async(query=''):Promise<VendorDashboard>=>(await get(query).expect(200)).body as VendorDashboard;
  async function order(status:string,date:string,total=15000n,completed?:string,foreign=false){
    return db.orders.create({data:{order_no:`D-${randomUUID()}`,vendor_id:foreign?foreignId:vendorId,vendor_customer_id:foreign?
      (await db.vendor_customers.create({data:{vendor_id:foreignId,name:'Synthetic foreign',mobile:'+919000000001'}})).id:customerId,
      source:'APP',status,delivery_date:new Date(`${date}T00:00:00Z`),time_slot:'07:00-08:00',address_snapshot:{synthetic:true},
      subtotal_paise:total,delivery_charge_paise:0n,discount_paise:0n,total_paise:total,payment_mode:'KHATA',payment_status:'UNPAID',
      created_at:new Date((completed?Date.parse(completed):Date.now())-60000), completed_at:completed?new Date(completed):status==='DELIVERED'?new Date():null}});
  }
  async function product(unit:string,value:string,stock:number,extra:object={}){
    return db.products.create({data:{vendor_id:vendorId,name:'Synthetic dashboard milk',product_type:'MILK',milk_type:'COW',unit_type:unit,
      unit_value:value,stock_qty:stock,selling_price_paise:100,...extra}});
  }
  beforeAll(async()=>{
    const target=new URL(url!);
    if(!target.pathname.endsWith('_test')||!['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test database required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',
      AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();const {AppModule}=await import('../../app.module');
    const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
    app=module.createNestApplication();configureHttpApp(app);await app.init();
    categoryId=(await db.categories.create({data:{code:`D-${randomUUID()}`,name_en:'Synthetic dashboard',name_hi:'',type:'SUPPLY',product_types:['MILK','CURD']}})).id;
  },60000);
  beforeEach(async()=>{
    owner=await actor('VENDOR');buyer=await actor('CUSTOMER');other=await actor('VENDOR');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic shop',city:'Synthetic city',kyc_status:'VERIFIED'}})).id;
    foreignId=(await db.vendors.create({data:{user_id:other.id,category_id:categoryId}})).id;
    customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic customer',mobile:'+919000000000'}})).id;
  });
  afterEach(()=>jest.restoreAllMocks());
  afterAll(async()=>{
    if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});
    await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);
  });
  it('returns fresh zero metrics/header/default DB IST date with no plan assignment or identity leakage',async()=>{
    const r=await get().expect(200),v=r.body as VendorDashboard;
    expect(r.headers['cache-control']).toBe('no-store');
    expect(v).toMatchObject({shopName:'Synthetic shop',city:'Synthetic city',shopPhotoMediaId:null,verified:true,
      todayOrders:0,pendingOrders:0,completedOrders:0,todaySalesPaise:'0',totalEarningsPaise:'0',activeCustomers:1,milkStockUnmeasuredProducts:0});
    expect(Number(v.milkStockLitres)).toBe(0);expect(v.date).toBe(v.businessDate);
    expect(new Date(Date.parse(v.serverTime)+19800000).toISOString().slice(0,10)).toBe(v.businessDate);
    expect(JSON.stringify(v)).not.toMatch(/mobile|token|customerId|vendorId|email|gstin/);
    await db.vendors.update({where:{id:vendorId},data:{kyc_status:'MANUAL_REVIEW',business_name:'Synthetic changed'}});
    expect(await metrics()).toMatchObject({shopName:'Synthetic changed',verified:false});
  });
  it('TC-030 five scheduled orders: two NEW, three delivered total 45000 paise; foreign vendor and other date excluded',async()=>{
    const day=(await metrics()).businessDate;
    for(const s of ['NEW','NEW','DELIVERED','DELIVERED','DELIVERED'])await order(s,day);
    await order('NEW','2020-01-01');await order('DELIVERED',day,900000n,undefined,true);
    expect(await metrics()).toMatchObject({todayOrders:5,pendingOrders:2,completedOrders:3,todaySalesPaise:'45000',totalEarningsPaise:'45000'});
    expect(await metrics('?date=2020-01-01')).toMatchObject({todayOrders:1,pendingOrders:1,completedOrders:0,todaySalesPaise:'0',totalEarningsPaise:'45000'});
    for(const s of ['ACCEPTED','PREPARING','OUT_FOR_DELIVERY','CANCELLED','REJECTED','FAILED'])await order(s,day);
    expect(await metrics()).toMatchObject({todayOrders:11,pendingOrders:5,completedOrders:3,todaySalesPaise:'45000'});
  });
  it('IST sales boundaries use actual completion, exclusive next midnight, exact huge totals and delivery charges',async()=>{
    const amount=9007199254740993n;
    for(const instant of ['2026-01-31T18:29:59.999Z','2026-01-31T18:30:00Z','2026-02-01T18:29:59.999Z','2026-02-01T18:30:00Z'])await order('DELIVERED','2026-01-30',amount,instant);
    const v=await metrics('?date=2026-02-01');
    expect(v).toMatchObject({date:'2026-02-01',todayOrders:0,completedOrders:0,todaySalesPaise:String(amount*2n),totalEarningsPaise:String(amount*4n)});
    expect((await metrics('?date=2026-01-30')).completedOrders).toBe(4);
    await order('CANCELLED','2026-02-01',amount);await order('FAILED','2026-02-01',amount);
    expect((await metrics('?date=2026-02-01')).todaySalesPaise).toBe(String(amount*2n));
    await db.orders.create({data:{order_no:`D-${randomUUID()}`,vendor_id:vendorId,vendor_customer_id:customerId,source:'APP',status:'DELIVERED',
      delivery_date:new Date('2026-02-01'),time_slot:'07:00-08:00',address_snapshot:{synthetic:true},subtotal_paise:10000n,delivery_charge_paise:1000n,discount_paise:0n,
      total_paise:11000n,payment_mode:'KHATA',payment_status:'UNPAID',created_at:new Date('2026-02-01T00:00:00Z'),completed_at:new Date('2026-02-01T01:00:00Z')}});
    expect((await metrics('?date=2026-02-01')).todaySalesPaise).toBe(String(amount*2n+11000n));
  });
  it('current milk volume is exact for L/ML, excludes inactive/deleted/nonmilk/foreign stock, discloses unknown units and counts active links',async()=>{
    await product('L','1.25',2);await product('ML','500',3);await product('ML','0.001',1);
    await product('L','100',100,{is_active:false});await product('L','100',100,{deleted_at:new Date()});
    await product('L','100',100,{product_type:'CURD',milk_type:null});await product('L','100',100,{vendor_id:foreignId});
    await product('KG','1',2);await product('PCS','1',0);
    await db.vendor_customers.createMany({data:[{vendor_id:vendorId,name:'Synthetic offline',mobile:'+919000000001'},
      {vendor_id:vendorId,name:'Synthetic inactive',mobile:'+919000000002',status:'INACTIVE'},
      {vendor_id:vendorId,name:'Synthetic deleted',mobile:'+919000000003',deleted_at:new Date()}]});
    expect(await metrics('?date=2000-01-01')).toMatchObject({milkStockLitres:'4.000001',milkStockUnmeasuredProducts:1,activeCustomers:2});
    await product('L','999999999.999',2147483647);
    const microlitres=999999999999000n*2147483647n+4000001n;
    expect((await metrics()).milkStockLitres).toBe(`${microlitres/1000000n}.${String(microlitres%1000000n).padStart(6,'0')}`);
  });
  it('actual POS writer changes sale/stock/due once; payment and permanent replay are not extra earnings; expired history remains readable',async()=>{
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    const p=await product('L','1',10),key=randomUUID();
    const input={vendorCustomerId:customerId,items:[{productId:p.id,qty:2,ratePaise:'10000'}],paidPaise:'0',paymentMethod:'CASH'};
    const post=()=>request(app.getHttpServer()).post('/api/v1/vendor/sales').set('Authorization',`Bearer ${owner.token}`).set('Idempotency-Key',key).send(input);
    const before=await metrics();await post().expect(201);await post().expect(201);
    await request(app.getHttpServer()).post('/api/v1/vendor/payments').set('Authorization',`Bearer ${owner.token}`).set('Idempotency-Key',randomUUID())
      .send({vendorCustomerId:customerId,amountPaise:'10000',method:'CASH',receivedOn:before.businessDate,note:'Synthetic payment'}).expect(201);
    expect(await metrics()).toMatchObject({todayOrders:0,todaySalesPaise:'20000',totalEarningsPaise:'20000',milkStockLitres:'8.000'});
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId},data:{starts_at:new Date('2020-01-01'),ends_at:new Date('2020-02-01')}});
    expect((await metrics()).totalEarningsPaise).toBe('20000');
  });
  it('denies anonymous/customer/switched/deheld/blocked/suspended identities and forged tenant/date selectors',async()=>{
    await request(app.getHttpServer()).get('/api/v1/vendor/dashboard').expect(401);await get('',buyer).expect(403);
    for(const query of ['?vendorId='+foreignId,'?userId='+other.id,'?date=2026-02-30','?date=0000-01-01','?date=2026-2-1','?date=2026-01-01T00:00:00Z','?date=x','?date=2026-01-01&date=2026-01-02'])await get(query).expect(400);
    expect(await metrics()).toMatchObject({shopName:'Synthetic shop'});
    await db.users.update({where:{id:owner.id},data:{active_role:'CUSTOMER'}});await get().expect(403);
    await db.users.update({where:{id:owner.id},data:{active_role:'VENDOR'}});
    await db.user_roles.deleteMany({where:{user_id:owner.id,role:'VENDOR'}});await get().expect(403);
    await db.user_roles.create({data:{user_id:owner.id,role:'VENDOR'}});await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get().expect(403);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:false}});await db.users.update({where:{id:owner.id},data:{status:'BLOCKED'}});await get().expect(403);
    const fresh=await actor('VENDOR');await get('',fresh).expect(404);
  });
  it('maps unexpected DB failure to redacted 503 and recovers with fresh values',async()=>{
    const unavailable = { $transaction: jest.fn().mockRejectedValue(new Error('Synthetic private DB detail')) } as unknown as PrismaService;
    await expect(new VendorDashboardService(unavailable).get(owner.id,{})).rejects.toMatchObject({response:{code:'DASHBOARD_UNAVAILABLE'}});
    expect((await metrics()).todaySalesPaise).toBe('0');
  });
});
