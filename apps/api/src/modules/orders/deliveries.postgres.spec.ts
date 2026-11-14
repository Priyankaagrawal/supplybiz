import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createHash, generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { homeClock } from '../home/home.service';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
const url=process.env.NATIVE_TEST_DATABASE_URL;
const native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-049 native delivery/stock/receipt/ledger atomicity',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,buyer:Actor,foreign:Actor,categoryId:string,vendorId:string,foreignVendorId:string,productId:string,addressId:string,day:string;
  let serial=0;
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`+919${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic delivery customer',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const post=(path:string,body:object,who=owner,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path:string,who=owner)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  async function placed(items=[{productId,qty:2}],total='25190'){
    return (await post('customer/orders',{vendorId,addressId,deliveryDate:day,timeSlot:'07:00-08:00',paymentMode:'POD_CASH',items,expectedTotalPaise:total},buyer).expect(201)).body.id as string;
  }
  async function prepared(target='OUT_FOR_DELIVERY',items=[{productId,qty:2}],total='25190'){
    const id=await placed(items,total);await post(`vendor/orders/${id}/transitions`,{to:'ACCEPTED',version:1}).expect(201);
    if(target!=='ACCEPTED')await post(`vendor/orders/${id}/transitions`,{to:target,version:2}).expect(201);return id;
  }
  const delivered=(id:string,payment:object={collected:false},key:string=randomUUID())=>post(`vendor/orders/${id}/transitions`,{to:'DELIVERED',version:3,payment},owner,key);
  async function effects(id:string){
    const o=await db.orders.findUniqueOrThrow({where:{id}});
    return {o,movements:await db.stock_movements.count({where:{ref_id:id,reason:'ORDER'}}),entries:await db.ledger_entries.findMany({where:{vendor_id:vendorId}}),receipts:await db.payments.findMany({where:{order_id:id}}),events:await db.order_status_events.count({where:{order_id:id,status:'DELIVERED'}})};
  }
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local _test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();app=await boot();await app.get(LedgerService).assertPrivileges(db);
    categoryId=(await db.categories.create({data:{code:`DELIVERY-${randomUUID()}`,name_en:'Synthetic delivery',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
    foreign=await actor('VENDOR');foreignVendorId=(await db.vendors.create({data:{user_id:foreign.id,category_id:categoryId,business_name:'Synthetic other vendor',settings:{create:{}}}})).id;
  });
  beforeEach(async()=>{
    owner=await actor('VENDOR');buyer=await actor('CUSTOMER');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic vendor',kyc_status:'VERIFIED',latitude:12.97,longitude:77.59,settings:{create:{service_radius_km:3,time_slots:['07:00-08:00'],delivery_charge_paise:500}}}})).id;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_type:'L',unit_value:1,selling_price_paise:12345,stock_qty:12}})).id;
    addressId=(await db.addresses.create({data:{user_id:buyer.id,label:'Synthetic',line1:'Synthetic house',line2:'Synthetic street',city:'Synthetic city',state:'Synthetic state',pincode:'560001',latitude:12.97,longitude:77.59}})).id;
    const clock=await db.$transaction(tx=>homeClock(tx));day=new Date(new Date(clock.day).getTime()+86400000).toISOString().slice(0,10);
  });
  afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
  it('TC-087 unpaid delivery uses price snapshots and atomically posts one debit/stock movement/history/notice',async()=>{
    const id=await prepared();await db.products.update({where:{id:productId},data:{selling_price_paise:20000,is_active:false}});
    const result=await delivered(id).expect(201);expect(result.body).toMatchObject({status:'DELIVERED',version:4,totalPaise:'25190',paymentStatus:'UNPAID'});
    const e=await effects(id);expect(e.movements).toBe(1);expect(e.entries).toHaveLength(1);expect(e.entries[0]).toMatchObject({type:'DEBIT',amount_paise:25190n,ref_type:'ORDER',ref_id:id});expect(e.receipts).toEqual([]);expect(e.events).toBe(1);expect(e.o.completed_at).not.toBeNull();
    expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(10);
    expect((await app.get(LedgerService).balance(owner.id,e.o.vendor_customer_id)).duePaise).toBe('25190');
    expect((await get('vendor/payments/summary').expect(200)).body).toMatchObject({totalReceivablePaise:'25190',thisMonthReceivedPaise:'0'});
    await expect(db.payments.create({data:{vendor_id:foreignVendorId,vendor_customer_id:e.o.vendor_customer_id,order_id:id,created_by:foreign.id,
      amount_paise:1n,method:'CASH',received_on:new Date(day),note:'Synthetic foreign scope',client_ref:randomUUID()}})).rejects.toThrow(/Payment scope mismatch/);
    expect(await db.notifications.count({where:{source_key:`order:${id}:4`,type:'ORDER_DELIVERED',user_id:buyer.id}})).toBe(1);
    expect(await db.outbox_events.count({where:{aggregate_id:productId,event_type:'STOCK_LOW'}})).toBe(1);
  });
  it('TC-087 records full/partial/advance receipts under positive payment rules and preserves exact BIGINT paise',async()=>{
    for(const [amount,method,paid,due] of [['10000','CASH','UNPAID','15190'],['25190','UPI','PAID','0'],['30000','BANK','PAID','-4810']] as const){
      const id=await prepared();await delivered(id,{collected:true,method,amountPaise:amount}).expect(201);
      const e=await effects(id),receipt=e.receipts[0]!;expect(receipt.amount_paise).toBe(BigInt(amount));expect(receipt.method).toBe(method);expect(e.o.payment_status).toBe(paid);
      const credits=e.entries.filter(x=>x.ref_id===receipt.id);expect(credits).toHaveLength(1);expect(credits[0]!.amount_paise).toBe(BigInt(amount));
      const orderDebit=e.entries.find(x=>x.ref_id===id)!;expect(String(orderDebit.amount_paise-receipt.amount_paise)).toBe(due);
      expect((await get(`vendor/payments?vendorCustomerId=${e.o.vendor_customer_id}`).expect(200)).body.items).toEqual(expect.arrayContaining([expect.objectContaining({id:receipt.id,orderId:id,amountPaise:amount})]));
      await expect(db.payments.update({where:{id:receipt.id},data:{amount_paise:1n}})).rejects.toThrow();await expect(db.payments.delete({where:{id:receipt.id}})).rejects.toThrow();
    }
    expect((await get('vendor/payments/summary').expect(200)).body).toMatchObject({totalReceivablePaise:'10380',thisMonthReceivedPaise:'65190'});
    const max=2147483647;await db.products.update({where:{id:productId},data:{selling_price_paise:max,stock_qty:max}});
    const total=String(BigInt(max)*BigInt(max)+500n),id=await prepared('OUT_FOR_DELIVERY',[{productId,qty:max}],total);
    await delivered(id,{collected:true,method:'WALLET',amountPaise:total}).expect(201);
    expect((await db.payments.findUniqueOrThrow({where:{order_id:id}})).amount_paise.toString()).toBe(total);
    expect((await db.ledger_entries.findFirstOrThrow({where:{ref_type:'ORDER',ref_id:id}})).amount_paise.toString()).toBe(total);
  });
  it('TC-500/087 serializes alternate keys, replays after API restart, and rejects payment mismatch without duplicates',async()=>{
    const id=await prepared(),key=randomUUID(),alternate=randomUUID(),payment={collected:true,method:'CASH',amountPaise:'25190'};
    const results=await Promise.all([delivered(id,payment,key),delivered(id,payment,alternate)]);expect(results.map(r=>r.status).sort()).toEqual([201,409]);
    const winner=results[0]!.status===201?0:1,original=results[winner]!.body,winningKey=winner===0?key:alternate;
    await app.close();app=await boot();expect((await delivered(id,payment,winningKey).expect(201)).body).toEqual(original);
    await delivered(id,{...payment,amountPaise:'1'},winningKey).expect(422);const e=await effects(id);expect(e.entries).toHaveLength(2);expect(e.movements).toBe(1);expect(e.receipts).toHaveLength(1);
    await post(`vendor/orders/${id}/transitions`,{to:'DELIVERED',version:4,payment}).expect(409);
    await expect(db.stock_movements.create({data:{product_id:productId,delta:-2,reason:'ORDER',note:'Synthetic duplicate',ref_id:id,created_by:owner.id}})).rejects.toThrow();
  });
  it('TC-087 rolls back all products and low-stock jobs on a later insufficient-stock line',async()=>{
    const p=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic second',product_type:'OTHER',unit_value:1,unit_type:'PCS',selling_price_paise:100,stock_qty:2}}));
    const id=await prepared('OUT_FOR_DELIVERY',[{productId,qty:2},{productId:p.id,qty:2}],'25390');
    // Synthetic concurrent-stock fixture, not a claim of a completed sale.
    await db.products.update({where:{id:p.id},data:{stock_qty:1}});await delivered(id).expect(409);
    const e=await effects(id);expect(e.o.status).toBe('OUT_FOR_DELIVERY');expect(e.entries).toHaveLength(0);expect(e.movements).toBe(0);expect(e.receipts).toHaveLength(0);
    expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(12);expect(await db.outbox_events.count({where:{aggregate_id:productId,event_type:'STOCK_LOW'}})).toBe(0);
  });
  it('TC-087 inconsistent stored bill snapshots cannot create a delivery debit or stock movement',async()=>{
    const id=await prepared();
    // Synthetic malformed legacy source: no client route can alter these snapshots.
    await db.orders.update({where:{id},data:{subtotal_paise:{increment:1n},total_paise:{increment:1n}}});
    await delivered(id).expect(409);const e=await effects(id);
    expect(e.o.status).toBe('OUT_FOR_DELIVERY');expect(e.entries).toHaveLength(0);expect(e.movements).toBe(0);expect(e.receipts).toHaveLength(0);
  });
  it('TC-087 rollback covers debit, receipt/credit and notification failures; retrying the rolled-back key is safe',async()=>{
    const id=await prepared(),key=randomUUID(),ledger=app.get(LedgerService),postEntry=ledger.post.bind(ledger),notices=app.get(NotificationsService);
    for(const stage of ['DEBIT','CREDIT','NOTICE']){
      const spy=stage==='NOTICE'?jest.spyOn(notices,'enqueue').mockRejectedValueOnce(new Error('Synthetic notice failure')):
        jest.spyOn(ledger,'post').mockImplementation((tx,p)=>p.type===stage?Promise.reject(new Error('Synthetic ledger failure')):postEntry(tx,p));
      try{await delivered(id,{collected:true,method:'CASH',amountPaise:'25190'},key).expect(503);}finally{spy.mockRestore();}
      const e=await effects(id);expect(e.o).toMatchObject({status:'OUT_FOR_DELIVERY',version:3,completed_at:null,payment_status:'UNPAID'});expect(e.entries).toHaveLength(0);expect(e.receipts).toHaveLength(0);expect(e.movements).toBe(0);expect(e.events).toBe(0);
      expect(await db.order_requests.findUnique({where:{request_key:createHash('sha256').update(`${owner.id}:${key}`).digest('hex')}})).toBeNull();
      expect(await db.audit_logs.count({where:{actor_id:owner.id,entity:'ledger_entries'}})).toBe(0);
    }
    await delivered(id,{collected:true,method:'CASH',amountPaise:'25190'},key).expect(201);
  });
  it('TC-088/245 validates explicit payment/failure input, enforces ownership/state and FAILED has no financial effect',async()=>{
    const id=await prepared();
    for(const body of [{to:'DELIVERED',version:3},{to:'DELIVERED',version:3,payment:{collected:true}},{to:'DELIVERED',version:3,payment:{collected:false,amountPaise:'1'}},{to:'DELIVERED',version:3,payment:{collected:true,method:'CASH',amountPaise:1}},{to:'DELIVERED',version:3,payment:{collected:true,method:'CASH',amountPaise:'9223372036854775808'}},{to:'FAILED',version:3},{to:'FAILED',version:3,reason:' '}])await post(`vendor/orders/${id}/transitions`,body).expect(400);
    const invalidReason=await placed();await post(`vendor/orders/${invalidReason}/transitions`,{to:'REJECTED',version:1,reason:'NOT_A_LISTED_REASON'}).expect(400);
    const payment={collected:false};await post(`vendor/orders/${id}/transitions`,{to:'DELIVERED',version:3,payment,vendorId:foreignVendorId}).expect(400);
    await post(`vendor/orders/${id}/transitions`,{to:'DELIVERED',version:3,payment},buyer).expect(403);await post(`vendor/orders/${id}/transitions`,{to:'DELIVERED',version:3,payment},foreign).expect(404);
    const cancelled=await placed();await post(`customer/orders/${cancelled}/cancel`,{version:1},buyer).expect(201);await delivered(cancelled).expect(409);
    await post(`vendor/orders/${id}/transitions`,{to:'FAILED',version:3,reason:'Away'}).expect(201);
    const e=await effects(id);expect(e.o.fail_reason).toBe('Away');expect(e.entries).toHaveLength(0);expect(e.movements).toBe(0);expect(e.receipts).toHaveLength(0);
    expect(await db.notifications.count({where:{source_key:`order:${id}:4`,type:'DELIVERY_FAILED'}})).toBe(1);
  });
  it('TC-085 delivery tabs/counts/date/card fields are owned and snapshot-consistent; excludes NEW/rejected/cancelled',async()=>{
    await placed();const pending=await prepared('ACCEPTED');await prepared('PREPARING');await prepared();const done=await prepared();await delivered(done).expect(201);
    const failed=await prepared();await post(`vendor/orders/${failed}/transitions`,{to:'FAILED',version:3,reason:'Synthetic failure'}).expect(201);
    const rejected=await placed();await post(`vendor/orders/${rejected}/transitions`,{to:'REJECTED',version:1,reason:'OUT_OF_STOCK'}).expect(201);
    const cancelled=await placed();await post(`customer/orders/${cancelled}/cancel`,{version:1},buyer).expect(201);
    const path=`vendor/deliveries?date=${day}`;const result=(await get(path).expect(200)).body;
    expect(result.counts).toEqual({ALL:5,PENDING:1,PREPARING:1,OUT_FOR_DELIVERY:1,DELIVERED:1,FAILED:1});expect(result.total).toBe(5);expect(result.items[0]).toHaveProperty('customerMobile');expect(result.items[0].items[0]).toMatchObject({qty:2,name:'Synthetic milk'});
    expect((await get(`${path}&status=PENDING`).expect(200)).body.items.map((o:{id:string})=>o.id)).toEqual([pending]);
    const ids:string[]=[];for(const offset of [0,2,4]){ids.push(...(await get(`${path}&limit=2&offset=${offset}`).expect(200)).body.items.map((o:{id:string})=>o.id));}expect(new Set(ids).size).toBe(5);
    const today=(await get('vendor/deliveries').expect(200)).body;expect(today.businessDate).toBe((await db.$transaction(tx=>homeClock(tx))).day);expect(today.total).toBe(0);
    expect((await get(path,foreign).expect(200)).body.items).toEqual([]);await get(path,buyer).expect(403);await get(`${path}&vendorId=${vendorId}`).expect(400);await get('vendor/deliveries?date=2026-02-30').expect(400);
  });
  it('ADR-029 preserves completion at expiry and archived product stock; overflow leaves the order untouched',async()=>{
    const id=await prepared();await db.products.update({where:{id:productId},data:{deleted_at:new Date(),is_active:false}});
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId},data:{starts_at:new Date(Date.now()-60000),ends_at:new Date(Date.now()-1000)}});
    await delivered(id).expect(201);expect((await db.products.findUniqueOrThrow({where:{id:productId}})).deleted_at).not.toBeNull();expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(10);
    await get(`vendor/products/${productId}`).expect(404);
    await post(`vendor/products/${productId}/stock-adjustments`,{delta:1,reason:'Synthetic adjustment'}).expect(404);
    await get(`vendor/deliveries?date=${day}`).expect(200);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));await db.products.update({where:{id:productId},data:{deleted_at:null,is_active:true}});
    const next=await prepared(),customer=(await db.orders.findUniqueOrThrow({where:{id:next}})).vendor_customer_id;
    const balance=await app.get(LedgerService).balance(owner.id,customer),maximum=9223372036854775807n;
    await app.get(LedgerService).opening(owner.id,randomUUID(),customer,{type:'DEBIT',amountPaise:maximum-BigInt(balance.totalDebitPaise),note:'Synthetic maximum opening'});
    await delivered(next).expect(503);expect((await effects(next)).o.status).toBe('OUT_FOR_DELIVERY');expect((await effects(next)).movements).toBe(0);
  });
});
