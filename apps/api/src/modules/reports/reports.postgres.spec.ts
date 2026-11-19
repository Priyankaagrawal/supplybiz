// T-100 / TC-095/096. Native HTTP/PostgreSQL; no live payment/provider claim.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { plan_code } from '@prisma/client';
import { generateKeyPairSync,randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { LedgerService } from '../ledger/ledger.service';
import { homeClock } from '../home/home.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { ReportDailySales,ReportProducts,ReportSummary } from './reports.dto';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-100 native reports',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,buyer:Actor,other:Actor,vendorId:string,otherId:string,customerId:string,productId:string,categoryId:string,day:string;
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`synthetic-report-${randomUUID()}`,name:'Synthetic report actor',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return{id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const get=(path='summary',query='',who=owner)=>request(app.getHttpServer()).get(`/api/v1/vendor/reports/${path}${query}`).set('Authorization',`Bearer ${who.token}`);
  const summary=async(query=''):Promise<ReportSummary>=>(await get('summary',query).expect(200)).body as ReportSummary;
  const products=async(query=''):Promise<ReportProducts>=>(await get('products',query).expect(200)).body as ReportProducts;
  const daily=async(query=''):Promise<ReportDailySales>=>(await get('sales-daily',query).expect(200)).body as ReportDailySales;
  const post=(path:string,body:object,key=randomUUID(),who=owner)=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const plan=(code:plan_code)=>db.$transaction(tx=>assignPlanFixture(tx,vendorId,code));
  async function sale(paid='0',linked=true,key=randomUUID(),qty=2,rate='5000'){
    return post('vendor/sales',{...(linked?{vendorCustomerId:customerId}:{}),items:[{productId,qty,ratePaise:rate}],paidPaise:paid,paymentMethod:'CASH'},key).expect(201);
  }
  async function order(date=day,completed=new Date().toISOString(),amount=10150n,known=true,status='DELIVERED'){
    return db.orders.create({data:{order_no:`R-${randomUUID()}`,vendor_id:vendorId,vendor_customer_id:customerId,source:'APP',status,
      delivery_date:new Date(date),time_slot:'AM',address_snapshot:{synthetic:true},subtotal_paise:amount-150n,delivery_charge_paise:150n,
      total_paise:amount,payment_mode:'KHATA',payment_status:'UNPAID',created_at:new Date(Date.parse(completed)-60000),completed_at:status==='DELIVERED'?new Date(completed):null,
      items:{create:{product_id:productId,product_name_snapshot:'Synthetic milk',unit_snapshot:{value:'500',type:'ML'},unit_price_paise:(amount-150n)/2n,qty:2,
        line_total_paise:amount-150n,milk_quantity_ml:known?1000:0,milk_quantity_known:known}}}});
  }
  async function opening(customer=customerId,type:'DEBIT'|'CREDIT'='DEBIT',amount='10000'){
    return (await post(`vendor/khata/${customer}/opening`,{type,amountPaise:amount,note:'Synthetic opening'}).expect(201)).body.id as string;
  }
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test')||!['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test database required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();const {AppModule}=await import('../../app.module');
    const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
    app=module.createNestApplication();configureHttpApp(app);await app.init();day=(await db.$transaction(tx=>homeClock(tx))).day;
    categoryId=(await db.categories.create({data:{code:`REPORT-${randomUUID()}`,name_en:'Synthetic report',name_hi:'',type:'SUPPLY',product_types:['MILK','CURD']}})).id;
  },60000);
  beforeEach(async()=>{
    owner=await actor('VENDOR');buyer=await actor('CUSTOMER');other=await actor('VENDOR');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,settings:{create:{}}}})).id;
    otherId=(await db.vendors.create({data:{user_id:other.id,category_id:categoryId,settings:{create:{}}}})).id;
    await db.$transaction(async tx=>{await assignPlanFixture(tx,vendorId,'BUSINESS');await assignPlanFixture(tx,otherId,'BUSINESS');});
    customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic linked',mobile:'+919000000000'}})).id;
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_value:500,unit_type:'ML',selling_price_paise:5000,stock_qty:1000}})).id;
  });
  afterEach(()=>jest.restoreAllMocks());
  afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);});
  it('TC-095 returns explicit zero ranges and zero periods without private records',async()=>{
    const r=await get().expect(200),v=r.body as ReportSummary;expect(r.headers['cache-control']).toBe('no-store');
    expect(v).toMatchObject({from:day,to:day,totalSalesPaise:'0',totalOrders:0,deliveredOrders:0,cancelledOrders:0,milkSoldLitres:'0',milkSoldUnmeasuredLines:0,
      totalEarningsPaise:'0',pendingPaymentsPaise:'0',activeCustomers:1,productSalesPaise:'0',deliveryChargesPaise:'0',discountPaise:'0',unitemizedSalesPaise:'0'});
    expect(JSON.stringify(v)).not.toMatch(/mobile|token|customerId|vendorId|address/);
    expect(await daily()).toMatchObject({bucket:'DAY',items:[{from:day,to:day,salesPaise:'0'}]});expect(await products()).toMatchObject({items:[],total:0,totalProductSalesPaise:'0'});
  });
  it('TC-095 actual linked/walk-in POS, stored delivered orders and receipts reconcile without credit duplication',async()=>{
    const o=await order();await db.$transaction(tx=>app.get(LedgerService).post(tx,{vendorId,customerId,actorId:owner.id,type:'DEBIT',amountPaise:10150n,refType:'ORDER',refId:o.id,entryDate:day}));
    const key=randomUUID();await sale('4000',true,key);await sale('4000',true,key);await sale('10000',false);
    await order(day,new Date().toISOString(),10150n,true,'CANCELLED');await order(day,new Date().toISOString(),10150n,true,'NEW');
    await post('vendor/payments',{vendorCustomerId:customerId,amountPaise:'2000',method:'CASH',receivedOn:day,note:'Synthetic standalone receipt'}).expect(201);
    const claim=(await post(`customer/khata/vendors/${vendorId}/claims`,{vendorCustomerId:customerId,amountPaise:'1000',method:'CASH'},randomUUID(),buyer).expect(201)).body;
    expect((await summary()).totalEarningsPaise).toBe('16000');
    const confirmKey=randomUUID();for(let n=0;n<2;n++)await post(`vendor/payment-claims/${claim.id}/confirm`,{version:1},confirmKey).expect(201);
    const s=await summary(),d=await daily(),p=await products();
    expect(s).toMatchObject({totalSalesPaise:'30150',productSalesPaise:'30000',deliveryChargesPaise:'150',discountPaise:'0',unitemizedSalesPaise:'0',
      totalOrders:3,deliveredOrders:1,cancelledOrders:1,milkSoldLitres:'3',milkSoldUnmeasuredLines:0,totalEarningsPaise:'17000',pendingPaymentsPaise:'13150'});
    expect(d.items[0].salesPaise).toBe(s.totalSalesPaise);expect(p.totalProductSalesPaise).toBe(s.productSalesPaise);
    expect(p.items[0]).toMatchObject({quantityPacks:'6',salesPaise:'30000'});
    const [oracle]=await db.$queryRaw<{received:string}[]>`SELECT ((SELECT COALESCE(SUM(amount_paise),0) FROM payments WHERE vendor_id=${vendorId}::uuid)
      +(SELECT COALESCE(SUM(paid_paise),0) FROM sales WHERE vendor_id=${vendorId}::uuid)
      +(SELECT COALESCE(SUM(amount_paise),0) FROM payment_claims WHERE vendor_customer_id=${customerId}::uuid AND status='CONFIRMED'))::text AS received`;
    expect(s.totalEarningsPaise).toBe(oracle!.received);
  });
  it('immutable POS/order milk and product snapshots survive catalog edits; legacy/unknown milk is disclosed',async()=>{
    await sale('10000',false);await order();
    await db.products.update({where:{id:productId},data:{name:'Synthetic renamed curd',product_type:'CURD',milk_type:null,unit_value:1,unit_type:'KG'}});
    await sale('10000',false);
    expect(await summary()).toMatchObject({milkSoldLitres:'2',milkSoldUnmeasuredLines:0,totalSalesPaise:'30150'});
    const p=await products();expect(p.total).toBe(2);expect(p.items.find(x=>x.name==='Synthetic milk')).toMatchObject({unitValue:'500',unitType:'ML',quantityPacks:'4',salesPaise:'20000'});
    const first=await products('?limit=1'),second=await products('?limit=1&offset=1');
    expect(first.items).toHaveLength(1);expect(second.items).toHaveLength(1);expect(first.items[0]!.name).not.toBe(second.items[0]!.name);
    expect(first.totalProductSalesPaise).toBe('30000');expect(second.totalProductSalesPaise).toBe('30000');
    // A legacy POS line has no frozen classification; creating its old shape is intentional.
    await db.sales.create({data:{sale_no:`R-${randomUUID()}`,vendor_id:vendorId,created_by:owner.id,total_paise:100n,paid_paise:100n,balance_paise:0n,payment_method:'CASH',sale_date:new Date(day),request_key:randomUUID(),request_hash:randomUUID(),
      items:{create:{product_id:productId,name_snapshot:'Synthetic legacy',unit_value_snapshot:'500',unit_type_snapshot:'ML',qty:1,rate_paise:100n,amount_paise:100n}}}});
    await order(day,new Date().toISOString(),10150n,false);
    expect(await summary()).toMatchObject({milkSoldLitres:'2',milkSoldUnmeasuredLines:2});
    await db.products.update({where:{id:productId},data:{product_type:'MILK',milk_type:'COW'}});await sale('10000',false);
    expect((await summary()).milkSoldUnmeasuredLines).toBe(3);
    await expect(db.sale_items.updateMany({where:{product_id:productId},data:{milk_quantity_ml:999}})).rejects.toThrow();
  });
  it('IST completion bounds, large exact paise, scheduled counts and product pages reconcile to daily/weekly totals',async()=>{
    const amount=9007199254740994n;
    for(const instant of ['2026-01-31T18:29:59.999Z','2026-01-31T18:30:00Z','2026-02-01T18:29:59.999Z','2026-02-01T18:30:00Z'])await order('2026-01-30',instant,amount);
    const q='?from=2026-02-01&to=2026-02-01',s=await summary(q),d=await daily(q),p=await products(q+'&limit=1');
    expect(s).toMatchObject({totalSalesPaise:String(amount*2n),totalOrders:0,deliveredOrders:0,deliveryChargesPaise:'300',milkSoldLitres:'2'});
    expect(d.items[0].salesPaise).toBe(s.totalSalesPaise);expect(p.totalProductSalesPaise).toBe(s.productSalesPaise);
    expect(BigInt(p.totalProductSalesPaise)+BigInt(s.deliveryChargesPaise)-BigInt(s.discountPaise)+BigInt(s.unitemizedSalesPaise)).toBe(BigInt(s.totalSalesPaise));
    const wide='?from=2026-01-01&to=2026-03-03';expect((await daily(wide)).bucket).toBe('DAY');
    const weeks=await daily('?from=2026-01-01&to=2026-03-05');expect(weeks.bucket).toBe('WEEK');
    expect(weeks.items[0]).toMatchObject({from:'2026-01-01',to:'2026-01-04'});expect(weeks.items.at(-1)!.to).toBe('2026-03-05');
    expect(weeks.items.reduce((n,r)=>n+BigInt(r.salesPaise),0n)).toBe(amount*4n);
    const empty=await products(q+'&limit=1&offset=99');expect(empty.items).toEqual([]);expect(empty.totalProductSalesPaise).toBe(p.totalProductSalesPaise);
  });
  it('current receivable clips advances per customer, includes archived balances and excludes opening credits from earnings',async()=>{
    await opening();const advance=await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic advance',mobile:'+919000000001'}});
    await opening(advance.id,'CREDIT','5000');await db.vendor_customers.update({where:{id:customerId},data:{status:'INACTIVE',deleted_at:new Date()}});
    expect(await summary('?from=2000-01-01&to=2000-01-01')).toMatchObject({pendingPaymentsPaise:'10000',totalEarningsPaise:'0',activeCustomers:1});
  });
  it('net payment reversal chains use correction value date, preserve originals and never change gross sales',async()=>{
    await opening();const r=await post('vendor/payments',{vendorCustomerId:customerId,amountPaise:'5000',method:'CASH',receivedOn:'2026-01-01',note:'Synthetic backdated receipt'}).expect(201);
    const original=await db.ledger_entries.findFirstOrThrow({where:{ref_type:'PAYMENT',ref_id:r.body.id}});
    expect((await summary('?from=2026-01-01&to=2026-01-01')).totalEarningsPaise).toBe('5000');
    const reversal=(await post(`vendor/ledger-entries/${original.id}/reverse`,{reason:'Synthetic correction'}).expect(201)).body;
    expect(await summary()).toMatchObject({totalSalesPaise:'0',totalEarningsPaise:'-5000',pendingPaymentsPaise:'10000'});
    await post(`vendor/ledger-entries/${reversal.id}/reverse`,{reason:'Synthetic restore'}).expect(201);
    expect((await summary()).totalEarningsPaise).toBe('0');expect((await summary('?from=2026-01-01&to=2026-01-01')).totalEarningsPaise).toBe('5000');
  });
  it('TC-096 BASIC/STANDARD summary only, BUSINESS/PREMIUM tables, no pre-assignment or expired advanced access',async()=>{
    for(const tier of ['BASIC','STANDARD','BUSINESS','PREMIUM'] as const){await plan(tier);await get().expect(200);
      for(const path of ['sales-daily','products']){const r=await get(path).expect(['BASIC','STANDARD'].includes(tier)?403:200);if(r.status===403)expect(r.body.code).toBe('PLAN_FEATURE_LOCKED');}}
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId,superseded_at:null},data:{starts_at:new Date('2020-01-01'),ends_at:new Date('2020-02-01')}});
    await get().expect(200);await get('products').expect(403);
    const fresh=await actor('VENDOR');await db.vendors.create({data:{user_id:fresh.id,category_id:categoryId}});await get('summary','',fresh).expect(403);
  });
  it('rejects forged scope, invalid ranges/paging and wrong roles without leaking foreign aggregates',async()=>{
    await sale('10000',false);expect((await get('summary','',other).expect(200)).body.totalSalesPaise).toBe('0');
    await request(app.getHttpServer()).get('/api/v1/vendor/reports/summary').expect(401);await get('summary','',buyer).expect(403);
    for(const q of ['?from=2026-01-01','?to=2026-01-01','?from=2026-02-30&to=2026-03-01','?from=0000-01-01&to=0000-01-02',
      '?from=2026-02-01&to=2026-01-01','?from=2025-01-01&to=2026-01-02','?vendorId='+otherId,'?from=2026-01-01&from=2026-02-01&to=2026-02-02'])await get('summary',q).expect(400);
    await get('products','?limit=51').expect(400);await get('products','?offset=-1').expect(400);
    await get('sales-daily','?from=2024-01-01&to=2024-12-31').expect(200);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get().expect(403);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:false}});await db.users.update({where:{id:owner.id},data:{active_role:'CUSTOMER'}});await get().expect(403);
  });
});
