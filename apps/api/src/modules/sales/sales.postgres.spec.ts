// T-079 / TC-055â€“059: real HTTP/PostgreSQL financial writes and permanent replay.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync,randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { LedgerService } from '../ledger/ledger.service';
import { CatalogService } from '../catalog/catalog.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-079 native quick sale',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,categoryId:string,owner:Actor,buyer:Actor,other:Actor,vendorId:string,otherVendorId:string,customerId:string,foreignCustomerId:string,productId:string,foreignProductId:string,serial=0;
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{const u=await db.users.create({data:{mobile:`+918${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic POS actor',active_role:role,roles:{create:{role}}}});const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});return{id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};}
  const input=()=>({items:[{productId,qty:2}],paidPaise:'13000',paymentMethod:'CASH'});
  const post=(body:object=input(),key:string=randomUUID(),who=owner)=>request(app.getHttpServer()).post('/api/v1/vendor/sales').set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path='vendor/sales',who=owner)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  const stock=async()=> (await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty;
  beforeAll(async()=>{const target=new URL(url!);if(!target.pathname.endsWith('_test')||!['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});await db.$connect();app=await boot();categoryId=(await db.categories.create({data:{code:`POS-${randomUUID()}`,name_en:'Synthetic POS',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;});
  beforeEach(async()=>{owner=await actor('VENDOR');buyer=await actor('CUSTOMER');other=await actor('VENDOR');vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic POS',kyc_status:'VERIFIED',settings:{create:{}}}})).id;otherVendorId=(await db.vendors.create({data:{user_id:other.id,category_id:categoryId,business_name:'Synthetic other POS',settings:{create:{}}}})).id;
    await db.$transaction(async tx=>{await assignPlanFixture(tx,vendorId,'BASIC');await assignPlanFixture(tx,otherVendorId,'BASIC');});
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic POS milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:6500,stock_qty:12,moq:3}})).id;
    foreignProductId=(await db.products.create({data:{vendor_id:otherVendorId,name:'Synthetic other milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:6500,stock_qty:12}})).id;
    const user=await db.users.findUniqueOrThrow({where:{id:buyer.id}});customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic POS customer',mobile:user.mobile}})).id;
    foreignCustomerId=(await db.vendor_customers.create({data:{vendor_id:otherVendorId,name:'Synthetic foreign POS customer',mobile:'+919000000000'}})).id;});
  afterEach(()=>jest.restoreAllMocks());afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);});
  it('TC-055 fully-paid walk-in creates one immutable receipt and stock decrement, without a fabricated customer or ledger',async()=>{
    const before=await db.vendor_customers.count({where:{vendor_id:vendorId}}),r=await post().expect(201);expect(r.headers['cache-control']).toBe('no-store');expect(r.body).toMatchObject({vendorCustomerId:null,totalPaise:'13000',paidPaise:'13000',balancePaise:'0',paymentStatus:'PAID'});
    expect(r.body.items[0]).toMatchObject({name:'Synthetic POS milk',unitValue:'1',unitType:'L',qty:2,ratePaise:'6500',amountPaise:'13000'});expect(await stock()).toBe(10);expect(await db.vendor_customers.count({where:{vendor_id:vendorId}})).toBe(before);expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.stock_movements.count({where:{product_id:productId,ref_id:r.body.id,reason:'SALE'}})).toBe(1);
    const stored=await db.sales.findUniqueOrThrow({where:{id:r.body.id}});expect(stored.sale_date.toISOString().slice(0,10)).toBe(r.body.businessDate);
    await expect(db.sales.update({where:{id:r.body.id},data:{paid_paise:0n}})).rejects.toThrow();await expect(db.sales.delete({where:{id:r.body.id}})).rejects.toThrow();await expect(db.sale_items.updateMany({where:{sale_id:r.body.id},data:{qty:9}})).rejects.toThrow();
    // Direct DB callers cannot commit an inconsistent bill or a cross-tenant line.
    for(const foreign of [false,true])await expect(db.$transaction(async tx=>{
      await tx.sales.create({data:{...stored,id:randomUUID(),sale_no:`SYN-${randomUUID()}`,request_key:randomUUID().replaceAll('-','').repeat(2),items:{create:{product_id:foreign?foreignProductId:productId,name_snapshot:'Synthetic',unit_value_snapshot:'1',unit_type_snapshot:'L',qty:foreign?2:1,rate_paise:6500n,amount_paise:foreign?13000n:6500n}}}});
      await tx.$executeRaw`SET CONSTRAINTS sales_total, sale_items_total IMMEDIATE`;
    })).rejects.toThrow();
  });
  it('TC-056 walk-in partial and overpayment reject without any source/stock/financial writes',async()=>{
    expect((await post({...input(),paidPaise:'10000'}).expect(422)).body.code).toBe('WALKIN_MUST_BE_PAID');expect((await post({...input(),vendorCustomerId:customerId,paidPaise:'13001'}).expect(422)).body.code).toBe('PAID_EXCEEDS_TOTAL');expect(await stock()).toBe(12);expect(await db.sales.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);
  });
  it('TC-057 customer partial payment atomically posts gross SALE debit and paid SALE credit, due +3000',async()=>{
    const r=await post({...input(),vendorCustomerId:customerId,paidPaise:'10000',paymentMethod:'OTHER'}).expect(201);expect(r.body).toMatchObject({totalPaise:'13000',paidPaise:'10000',balancePaise:'3000',paymentMethod:'OTHER',paymentStatus:'UNPAID'});
    const entries=await db.ledger_entries.findMany({where:{ref_type:'SALE',ref_id:r.body.id},orderBy:{type:'asc'}});expect(entries).toHaveLength(2);expect(entries.find(e=>e.type==='DEBIT')!.amount_paise).toBe(13000n);expect(entries.find(e=>e.type==='CREDIT')!.amount_paise).toBe(10000n);expect((await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:customerId}})).due_paise).toBe(3000n);expect(await stock()).toBe(10);expect(await db.payments.count({where:{vendor_id:vendorId}})).toBe(0);
  });
  it('TC-057 unpaid, fully paid and zero-price customer sales keep positive-only ledger entries and exact rates',async()=>{
    for(const [rate,paid] of [['6500','0'],['6500','6500'],['0','0']])await post({vendorCustomerId:customerId,items:[{productId,qty:1,ratePaise:rate}],paidPaise:paid,paymentMethod:'UPI'}).expect(201);
    const b=await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:customerId}});expect(b).toMatchObject({total_debit_paise:13000n,total_credit_paise:6500n,due_paise:6500n});expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(3);expect(await stock()).toBe(9);
  });
  it('TC-058 override/default rates and names are server snapshots; exact BIGINT arithmetic rejects overflow and ignores audit time for posting',async()=>{
    const rate='9007199254740993',r=await post({items:[{productId:productId.toUpperCase(),qty:1,ratePaise:rate}],paidPaise:rate,paymentMethod:'CASH',clientCreatedAt:'2000-01-01T00:00:00+05:30'}).expect(201);expect(r.body.totalPaise).toBe(rate);expect(r.body.businessDate).not.toBe('2000-01-01');
    await db.products.update({where:{id:productId},data:{name:'Synthetic changed',selling_price_paise:100}});expect((await get(`vendor/sales/${r.body.id}`).expect(200)).body.items[0]).toMatchObject({name:'Synthetic POS milk',ratePaise:rate});
    expect((await post({items:[{productId,qty:2,ratePaise:'9223372036854775807'}],paidPaise:'0',paymentMethod:'CASH',vendorCustomerId:customerId}).expect(400)).body.code).toBe('AMOUNT_OVERFLOW');expect(await stock()).toBe(11);
  });
  it('TC-059 concurrent same-key requests and application recreation replay once even after price/plan expiry changes',async()=>{
    const key=randomUUID(),body={...input(),clientCreatedAt:'2026-01-01T00:00:00Z'},responses=await Promise.all([post(body,key),post(body,key)]);expect(responses.map(r=>r.status)).toEqual([201,201]);expect(responses[0]!.body).toEqual(responses[1]!.body);expect(await stock()).toBe(10);
    await app.close();app=await boot();await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));expect((await post(body,key).expect(201)).body).toEqual(responses[0]!.body);await post(body).expect(403);await get().expect(200);await post({...body,clientCreatedAt:'2026-01-02T00:00:00Z'},key).expect(422);expect(await db.sales.count({where:{vendor_id:vendorId}})).toBe(1);
  });
  it('TC-054/059 failure after the real CREDIT rolls back sale/items, both ledger entries, stock, low-stock event and replay identity',async()=>{
    const ledger=app.get(LedgerService),real=ledger.post.bind(ledger),fault=jest.spyOn(ledger,'post').mockImplementation(async(tx,entry)=>{const row=await real(tx,entry);if(entry.type==='CREDIT')throw new Error('Synthetic private financial diagnostic');return row;});
    const body={...input(),vendorCustomerId:customerId,paidPaise:'10000'},key=randomUUID(),before=await db.outbox_events.count({where:{aggregate_id:productId,event_type:'STOCK_LOW'}});const response=await post(body,key).expect(503);expect(JSON.stringify(response.body)).not.toContain('private');expect(await db.sales.count({where:{vendor_id:vendorId}})).toBe(0);expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect(await stock()).toBe(12);expect(await db.outbox_events.count({where:{aggregate_id:productId,event_type:'STOCK_LOW'}})).toBe(before);
    fault.mockRestore();await post(body,key).expect(201);expect(await stock()).toBe(10);
  });
  it('TC-059 concurrent distinct sales cannot oversell and a later stock failure rolls back earlier line effects',async()=>{
    await db.products.update({where:{id:productId},data:{stock_qty:2}});const responses=await Promise.all([post(),post()]);expect(responses.map(r=>r.status).sort()).toEqual([201,409]);expect(await stock()).toBe(0);
    await db.products.update({where:{id:productId},data:{stock_qty:12}});
    const second=await db.products.create({data:{vendor_id:vendorId,name:'Synthetic second milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:6500,stock_qty:12}});
    const catalog=app.get(CatalogService),real=catalog.changeStock.bind(catalog);let calls=0;
    const fault=jest.spyOn(catalog,'changeStock').mockImplementation(async(tx,change)=>{const value=await real(tx,change);if(++calls===2)throw new Error('Synthetic stock failure');return value;});
    await post({items:[{productId,qty:2},{productId:second.id,qty:2}],paidPaise:'26000',paymentMethod:'CASH'}).expect(503);expect(await stock()).toBe(12);expect((await db.products.findUniqueOrThrow({where:{id:second.id}})).stock_qty).toBe(12);fault.mockRestore();
  });
  it('TC-055/057 role, tenant, archived/inactive, paid bounds, duplicate/empty lines, unknown totals and malformed audit metadata fail closed',async()=>{
    await post(input(),randomUUID(),buyer).expect(403);await post({...input(),vendorCustomerId:foreignCustomerId}).expect(404);await post({...input(),items:[{productId:foreignProductId,qty:2}]}).expect(404);
    for(const body of [{...input(),totalPaise:'1'},{...input(),items:[]},{...input(),items:[{productId,qty:1},{productId,qty:1}]},{...input(),paidPaise:13000},{...input(),paymentMethod:'BANK'},{...input(),clientCreatedAt:'2026-01-01T00:00:00'}])await post(body).expect(400);
    await db.products.update({where:{id:productId},data:{is_active:false}});await post().expect(404);await db.products.update({where:{id:productId},data:{is_active:true}});await db.vendor_customers.update({where:{id:customerId},data:{status:'INACTIVE'}});await post({...input(),vendorCustomerId:customerId}).expect(404);await post(input(),' ').expect(400);
  });
  it('TC-055 owned list/detail uses persisted server business dates and stable bounded filters without foreign disclosure',async()=>{
    const r=(await post().expect(201)).body;expect((await get(`vendor/sales?date=${r.businessDate}&limit=1&offset=0`).expect(200)).body).toMatchObject({total:1,items:[{id:r.id}]});expect((await get('vendor/sales',other).expect(200)).body.total).toBe(0);await get(`vendor/sales/${r.id}`,other).expect(404);await get(`vendor/sales?vendorCustomerId=${foreignCustomerId}`).expect(404);await get('vendor/sales?date=2026-02-30').expect(400);await get('vendor/sales?limit=51').expect(400);
  });
});
