// T-082 / TC-250–255: real HTTP/PostgreSQL, consent and exact financial effects.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync,randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { LedgerService } from '../ledger/ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from '../home/home.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-082 native customer Khata/personal/claims',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,categoryId:string,owner:Actor,buyer:Actor,stranger:Actor,other:Actor,vendorId:string,otherVendorId:string,customerId:string,otherCustomerId:string,productId:string,day:string,month:string,previousDay:string,serial=0;
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'CUSTOMER'|'VENDOR'):Promise<Actor>{const u=await db.users.create({data:{mobile:`+919${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic Khata actor',active_role:role,roles:{create:{role}}}});const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});return{id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};}
  const get=(path:string,who=buyer)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
  const post=(path:string,body:object,who=buyer,key:string=randomUUID())=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const patch=(path:string,body:object,who=buyer,key:string=randomUUID())=>request(app.getHttpServer()).patch(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const del=(path:string,version:number,who=buyer,key:string=randomUUID())=>request(app.getHttpServer()).delete(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send({version});
  async function debit(value=10000n,entryDate=day){await app.get(LedgerService).opening(owner.id,randomUUID(),customerId,{type:'DEBIT',amountPaise:value,note:'Synthetic opening',entryDate});}
  const claim=(amount='6000',key:string=randomUUID())=>post(`customer/khata/vendors/${vendorId}/claims`,{vendorCustomerId:customerId,amountPaise:amount,method:'CASH'},buyer,key);
  const confirm=(id:string,key:string=randomUUID(),who=owner,version=1)=>post(`vendor/payment-claims/${id}/confirm`,{version},who,key);
  const due=async()=> (await db.ledger_balances.findUniqueOrThrow({where:{vendor_customer_id:customerId}})).due_paise;
  async function contact(who=buyer){return (await post('customer/personal-contacts',{name:'Synthetic personal',mobile:'+919000000000'},who).expect(201)).body.id as string;}
  async function entry(id:string,amount='20000',direction='GAVE',who=buyer){return (await post('customer/personal-entries',{contactId:id,direction,amountPaise:amount,date:day,note:'Synthetic note'},who).expect(201)).body.id as string;}
  beforeAll(async()=>{const target=new URL(url!);if(!target.pathname.endsWith('_test')||!['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});await db.$connect();app=await boot();day=(await db.$transaction(tx=>homeClock(tx))).day;month=day.slice(0,7);previousDay=new Date(new Date(`${month}-01T00:00:00Z`).getTime()-86400000).toISOString().slice(0,10);
    categoryId=(await db.categories.create({data:{code:`KH-${randomUUID()}`,name_en:'Synthetic Khata',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;});
  beforeEach(async()=>{owner=await actor('VENDOR');buyer=await actor('CUSTOMER');stranger=await actor('CUSTOMER');other=await actor('VENDOR');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic Khata vendor',settings:{create:{time_slots:['AM']}}}})).id;otherVendorId=(await db.vendors.create({data:{user_id:other.id,category_id:categoryId,business_name:'Synthetic second Khata vendor',settings:{create:{}}}})).id;
    await db.$transaction(async tx=>{await assignPlanFixture(tx,vendorId,'BASIC');await assignPlanFixture(tx,otherVendorId,'BASIC');});
    const user=await db.users.findUniqueOrThrow({where:{id:buyer.id}});customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic linked Khata',mobile:user.mobile}})).id;otherCustomerId=(await db.vendor_customers.create({data:{vendor_id:otherVendorId,user_id:buyer.id,name:'Synthetic second link',mobile:user.mobile}})).id;
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic immutable milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:3000,stock_qty:100}})).id;});
  afterEach(()=>jest.restoreAllMocks());afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);});
  it('T-081 TC-110 vendor tabs/search/page preserve positive receivables, advances, exact credits and zero settlement',async()=>{
    await post(`vendor/khata/${customerId}/opening`,{type:'DEBIT',amountPaise:'10000',note:'Synthetic opening'},owner).expect(201);
    const advance=await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic advance',mobile:'+919000000001'}}),settled=await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic settled',mobile:'+919000000002'}});
    await post(`vendor/khata/${advance.id}/opening`,{type:'CREDIT',amountPaise:'5000',note:'Synthetic advance'},owner).expect(201);
    const all=(await get('vendor/khata',owner).expect(200)).body;expect(all).toMatchObject({total:3,totalReceivablePaise:'10000',thisMonthReceivedPaise:'0',canAdjust:true,canRecordPayment:true});expect(all.items.find((r:{id:string})=>r.id===advance.id)).toMatchObject({duePaise:'-5000',totalCreditPaise:'5000',totalPaidPaise:'0'});
    const paid=(await get('vendor/khata?tab=PAID&limit=1',owner).expect(200)).body;expect(paid.total).toBe(1);expect(paid.items[0].id).toBe(settled.id);expect(paid.totalReceivablePaise).toBe('10000');
    expect((await get('vendor/khata?tab=RECEIVABLE',owner).expect(200)).body.total).toBe(1);expect((await get('vendor/khata?q=%25',owner).expect(200)).body).toMatchObject({total:0,totalReceivablePaise:'10000'});
    await get('vendor/khata',buyer).expect(403);await get(`vendor/khata/${otherCustomerId}/entries`,owner).expect(404);
  });
  it('T-081 TC-112/116 opening/reversal concurrency replays minimal acknowledgements, retains originals and chains corrections',async()=>{
    const key=randomUUID(),body={type:'DEBIT',amountPaise:'9007199254740993',note:'Synthetic private opening'};
    const [a,b]=await Promise.all([post(`vendor/khata/${customerId}/opening`,body,owner,key).expect(201),post(`vendor/khata/${customerId}/opening`,body,owner,key).expect(201)]);expect(a.body).toEqual(b.body);expect(Object.keys(a.body)).toEqual(['id']);expect(await due()).toBe(9007199254740993n);
    await post(`vendor/khata/${customerId}/opening`,{...body,note:'Synthetic changed'},owner,key).expect(422);await post(`vendor/khata/${otherCustomerId}/opening`,body,owner).expect(404);await post(`vendor/khata/${customerId}/opening`,{...body,note:''},owner).expect(400);await post(`vendor/khata/${customerId}/opening`,{...body,entryDate:day},owner).expect(400);
    const reverseKey=randomUUID(),path=`vendor/ledger-entries/${a.body.id}/reverse`;
    const [r,s]=await Promise.all([post(path,{reason:'Synthetic correction'},owner,reverseKey).expect(201),post(path,{reason:'Synthetic correction'},owner,reverseKey).expect(201)]);expect(r.body).toEqual(s.body);expect(await due()).toBe(0n);await post(path,{reason:'Synthetic another correction'},owner).expect(409);await post(path,{reason:'Synthetic foreign'},other).expect(404);
    await post(`vendor/ledger-entries/${r.body.id}/reverse`,{reason:'Synthetic restore'},owner).expect(201);expect(await due()).toBe(9007199254740993n);expect((await db.ledger_entries.findUniqueOrThrow({where:{id:a.body.id}})).amount_paise).toBe(9007199254740993n);
    const requests=await db.khata_requests.findMany({where:{user_id:owner.id}});expect(JSON.stringify(requests)).not.toContain('Synthetic private opening');expect(await db.audit_logs.count({where:{entity_id:a.body.id,actor_id:owner.id}})).toBeGreaterThan(0);
  });
  it('T-081 TC-111/114/116 net collections unify POS, payment and claim credits including correction chains',async()=>{
    await debit(10000n);
    await post('vendor/sales',{vendorCustomerId:customerId,items:[{productId,qty:1}],paidPaise:'1000',paymentMethod:'CASH'},owner).expect(201);
    const payment=(await post('vendor/payments',{vendorCustomerId:customerId,amountPaise:'2000',method:'CASH',receivedOn:day},owner).expect(201)).body;
    const c=(await claim('1000').expect(201)).body;await confirm(c.id).expect(201);
    expect((await get('vendor/khata',owner).expect(200)).body.thisMonthReceivedPaise).toBe('4000');const list=(await get(`vendor/khata/collections?month=${month}&limit=1`,owner).expect(200)).body;expect(list.total).toBe(3);expect(list.items).toHaveLength(1);
    const credit=await db.ledger_entries.findFirstOrThrow({where:{ref_id:payment.id,ref_type:'PAYMENT',type:'CREDIT'}}),reversed=(await post(`vendor/ledger-entries/${credit.id}/reverse`,{reason:'Synthetic correction'},owner).expect(201)).body;
    expect((await get('vendor/khata',owner).expect(200)).body.thisMonthReceivedPaise).toBe('2000');await post(`vendor/ledger-entries/${reversed.id}/reverse`,{reason:'Synthetic restore correction'},owner).expect(201);
    const entries=(await get(`customer/khata/vendors/${vendorId}/entries?month=${month}`).expect(200)).body;expect(entries.monthPaidPaise).toBe('4000');expect((await get('vendor/khata',owner).expect(200)).body.thisMonthReceivedPaise).toBe(entries.monthPaidPaise);
    const receipts=(await get(`vendor/khata/collections?month=${month}`,owner).expect(200)).body;expect(receipts.total).toBe(5);expect(receipts.items.some((r:{amountPaise:string})=>r.amountPaise==='-2000')).toBe(true);expect(receipts.items.every((r:{method:string})=>r.method==='CASH')).toBe(true);
  });
  it('T-081 public adjustments roll back append/audit/replay together and active-plan gate preserves expiry reads/replay',async()=>{
    const key=randomUUID(),path=`vendor/khata/${customerId}/opening`,body={type:'DEBIT',amountPaise:'10000',note:'Synthetic opening'};
    const ledger=app.get(LedgerService),append=ledger.opening.bind(ledger);
    jest.spyOn(ledger,'opening').mockImplementationOnce(async(user,key,id,input,tx)=>{await append(user,key,id,input,tx);throw new Error('Synthetic failure after actual append');});
    await post(path,body,owner,key).expect(503);expect(await db.ledger_entries.count({where:{vendor_customer_id:customerId}})).toBe(0);expect(await db.ledger_balances.findUnique({where:{vendor_customer_id:customerId}})).toBeNull();
    const entry=(await post(path,body,owner,key).expect(201)).body;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    expect((await get('vendor/khata',owner).expect(200)).body).toMatchObject({canAdjust:false,canRecordPayment:true});await post(path,body,owner,key).expect(201);await post(path,body,owner).expect(403);await post(`vendor/ledger-entries/${entry.id}/reverse`,{reason:'Synthetic correction'},owner).expect(403);
    await post('vendor/payments',{vendorCustomerId:customerId,amountPaise:'100',method:'CASH',receivedOn:day},owner).expect(201);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get('vendor/khata',owner).expect(403);
  });
  it('TC-250 global totals combine vendor payables/advances and personal signed balances; tabs/page do not alter totals',async()=>{
    await debit();await app.get(LedgerService).opening(other.id,randomUUID(),otherCustomerId,{type:'CREDIT',amountPaise:2000n,note:'Synthetic advance'});const c=await contact();await entry(c);await entry(c,'5000','GOT');
    const all=(await get('customer/khata/summary?limit=1').expect(200)).body;expect(all).toMatchObject({totalReceivablePaise:'17000',totalPayablePaise:'10000',netBalancePaise:'7000',total:3});expect(all.items).toHaveLength(1);
    const vendors=(await get('customer/khata/summary?tab=VENDORS').expect(200)).body;expect(vendors.total).toBe(2);expect(vendors.totalReceivablePaise).toBe('17000');expect(vendors.items.every((r:{kind:string})=>r.kind==='VENDOR')).toBe(true);
    expect((await get('customer/khata/summary?tab=CUSTOMERS').expect(200)).body.items[0]).toMatchObject({kind:'PERSONAL',balancePaise:'15000',status:'RECEIVABLE'});expect((await get('customer/khata/summary',stranger).expect(200)).body.total).toBe(0);
  });
  it('TC-251/252 customer month view equals vendor ledger, includes POS snapshots and reversals without invented payment allocation',async()=>{
    await debit(10000n,previousDay);const sale=(await post('vendor/sales',{vendorCustomerId:customerId,items:[{productId,qty:1}],paidPaise:'1000',paymentMethod:'CASH'},owner).expect(201)).body;
    const customer=(await get(`customer/khata/vendors/${vendorId}/entries?month=${month}`).expect(200)).body,vendor=(await get(`vendor/khata/${customerId}/entries?month=${month}`,owner).expect(200)).body;expect({...customer,serverTime:null}).toEqual({...vendor,serverTime:null});expect(customer).toMatchObject({duePaise:'12000',openingDuePaise:'10000',closingDuePaise:'12000',monthDebitPaise:'3000',monthCreditPaise:'1000',monthPaidPaise:'1000',total:2});expect(customer.items[0].productSummary).toBe('Synthetic immutable milk × 1');
    await db.products.update({where:{id:productId},data:{name:'Synthetic changed name'}});expect((await get(`customer/khata/vendors/${vendorId}/entries?month=${month}`).expect(200)).body.items[0].productSummary).toBe('Synthetic immutable milk × 1');
    const credit=await db.ledger_entries.findFirstOrThrow({where:{ref_type:'SALE',ref_id:sale.id,type:'CREDIT'}});await app.get(LedgerService).reverse(owner.id,randomUUID(),credit.id,'Synthetic payment correction');
    expect((await get(`customer/khata/vendors/${vendorId}/entries?month=${month}`).expect(200)).body).toMatchObject({duePaise:'13000',monthPaidPaise:'0'});expect((await get(`customer/khata/vendors/${vendorId}/entries?month=${previousDay.slice(0,7)}`).expect(200)).body.total).toBe(1);
  });
  it('TC-251 linkage uses accepted user ID only, never mobile; foreign roles/links/details do not disclose history',async()=>{
    await debit();await get(`customer/khata/vendors/${vendorId}/entries`,stranger).expect(404);await get(`vendor/khata/${customerId}/entries`,other).expect(404);await get('customer/khata/summary',owner).expect(403);
    await db.vendor_customers.update({where:{id:customerId},data:{user_id:null}});await get(`customer/khata/vendors/${vendorId}/entries`).expect(404);await claim().expect(404);expect((await get('customer/khata/summary').expect(200)).body.items.some((r:{id:string})=>r.id===vendorId)).toBe(false);
  });
  it('TC-253 personal give/get edit/delete is owned/versioned, refreshes totals, clears mobile and never changes vendor ledger',async()=>{
    const c=await contact(),e=await entry(c);expect((await get(`customer/personal-contacts/${c}`).expect(200)).body.balancePaise).toBe('20000');await get(`customer/personal-entries/${e}`,stranger).expect(404);await patch(`customer/personal-entries/${e}`,{version:1,amountPaise:'5000'},stranger).expect(404);
    await patch(`customer/personal-entries/${e}`,{version:1,direction:'GOT',amountPaise:'5000'}).expect(200);await patch(`customer/personal-entries/${e}`,{version:1,note:'Stale'}).expect(409);expect((await get(`customer/personal-contacts/${c}`).expect(200)).body.balancePaise).toBe('-5000');
    await patch(`customer/personal-contacts/${c}`,{version:1,clearMobile:true}).expect(200);expect((await get(`customer/personal-contacts/${c}`).expect(200)).body.mobile).toBeNull();const key=randomUUID();await del(`customer/personal-entries/${e}`,2,buyer,key).expect(200);await del(`customer/personal-entries/${e}`,2,buyer,key).expect(200);expect((await get(`customer/personal-contacts/${c}`).expect(200)).body.balancePaise).toBe('0');
    await entry(c);await del(`customer/personal-contacts/${c}`,2).expect(200);expect((await get(`customer/personal-entries?contactId=${c}`)).status).toBe(404);expect((await get('customer/khata/summary?tab=CUSTOMERS').expect(200)).body.total).toBe(0);expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);
  });
  it('TC-253 personal same-key replay survives deletion/recreation and remains isolated with no persistent contact PII in acknowledgements',async()=>{
    const key=randomUUID(),body={name:'Synthetic replay contact',mobile:'+919000000000'},r=(await post('customer/personal-contacts',body,buyer,key).expect(201)).body;await del(`customer/personal-contacts/${r.id}`,1).expect(200);await app.close();app=await boot();expect((await post('customer/personal-contacts',body,buyer,key).expect(201)).body).toEqual(r);expect(await db.personal_contacts.count({where:{user_id:buyer.id}})).toBe(1);
    const requests=await db.khata_requests.findMany({where:{user_id:buyer.id}});expect(JSON.stringify(requests.map(r=>r.response))).not.toContain('Synthetic replay');expect(JSON.stringify(requests.map(r=>r.response))).not.toContain('+919');await post('customer/personal-contacts',{...body,name:'Changed'},buyer,key).expect(422);
  });
  it('TC-255 claim amount is positive and at most current account/vendor due; pending claims post no money and exact replay creates one notice/source',async()=>{
    await debit();await claim('10001').expect(422);await claim('0').expect(400);const key=randomUUID(),r=await Promise.all([claim('6000',key),claim('6000',key)]);expect(r.map(v=>v.status)).toEqual([201,201]);expect(r[0]!.body).toEqual(r[1]!.body);expect(await due()).toBe(10000n);expect(await db.payment_claims.count({where:{vendor_customer_id:customerId}})).toBe(1);expect(await db.ledger_entries.count({where:{ref_type:'CLAIM',ref_id:r[0]!.body.id}})).toBe(0);expect(await db.notifications.count({where:{user_id:owner.id,type:'PAYMENT_CLAIM'}})).toBe(1);
    await post(`customer/khata/vendors/${vendorId}/claims`,{vendorCustomerId:otherCustomerId,amountPaise:'1',method:'CASH'}).expect(404);expect((await get(`customer/khata/vendors/${vendorId}/claims`).expect(200)).body.items[0]).toMatchObject({amountPaise:'6000',status:'PENDING'});
  });
  it('TC-255 confirmation posts one CREDIT, serializes alternate keys and recreates safely; rejection never credits',async()=>{
    await debit();const first=(await claim().expect(201)).body.id,second=(await claim().expect(201)).body.id;await confirm(first,randomUUID(),other).expect(404);const key=randomUUID();const results=await Promise.all([confirm(first,key),confirm(first,key)]);expect(results.map(r=>r.status)).toEqual([201,201]);expect(await due()).toBe(4000n);await confirm(first).expect(409);await confirm(second).expect(422);
    await post(`vendor/payment-claims/${second}/reject`,{version:1,reason:'Synthetic wrong payment'},owner).expect(201);expect(await due()).toBe(4000n);expect(await db.ledger_entries.count({where:{ref_type:'CLAIM',ref_id:first}})).toBe(1);expect(await db.ledger_entries.count({where:{ref_type:'CLAIM',ref_id:second}})).toBe(0);
    await app.close();app=await boot();await confirm(first,key).expect(201);expect(await due()).toBe(4000n);expect(await db.notifications.count({where:{user_id:buyer.id,type:'PAYMENT_CLAIM_CONFIRMED'}})).toBe(1);expect(await db.notifications.count({where:{user_id:buyer.id,type:'PAYMENT_CLAIM_REJECTED'}})).toBe(1);
  });
  it('TC-255 current due is rechecked after standalone payment; vendor cannot over-credit a stale claim',async()=>{
    await debit();const id=(await claim().expect(201)).body.id;await post('vendor/payments',{vendorCustomerId:customerId,amountPaise:'5000',method:'CASH',receivedOn:day},owner).expect(201);await confirm(id).expect(422);expect(await due()).toBe(5000n);expect((await db.payment_claims.findUniqueOrThrow({where:{id}})).status).toBe('PENDING');
  });
  it('TC-255 rollback after the real credit/inbox insertion leaves claim pending and allows safe same-key recovery',async()=>{
    await debit();const id=(await claim().expect(201)).body.id,key=randomUUID(),notices=app.get(NotificationsService),real=notices.enqueue.bind(notices);
    const fault=jest.spyOn(notices,'enqueue').mockImplementation(async(tx,event)=>{const value=await real(tx,event);if(event.type==='PAYMENT_CLAIM_CONFIRMED')throw new Error('Synthetic private claim diagnostic');return value;});
    const r=await confirm(id,key).expect(503);expect(JSON.stringify(r.body)).not.toContain('private');expect(await due()).toBe(10000n);expect((await db.payment_claims.findUniqueOrThrow({where:{id}})).status).toBe('PENDING');expect(await db.ledger_entries.count({where:{ref_type:'CLAIM',ref_id:id}})).toBe(0);fault.mockRestore();await confirm(id,key).expect(201);expect(await due()).toBe(4000n);
  });
  it('ADR-029 expired/inactive customer history and settlement remain; source claim amount and terminal decision are immutable',async()=>{
    await debit();await db.vendor_customers.update({where:{id:customerId},data:{status:'INACTIVE'}});await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC',new Date(Date.now()-2*86400000),new Date(Date.now()-86400000)));
    await get(`customer/khata/vendors/${vendorId}/entries`).expect(200);const id=(await claim('3000').expect(201)).body.id;await confirm(id).expect(201);expect(await due()).toBe(7000n);await expect(db.payment_claims.update({where:{id},data:{amount_paise:1n}})).rejects.toThrow();await expect(db.payment_claims.delete({where:{id}})).rejects.toThrow();
  });
  it('FR-253 default UPI unavailable, explicit vendor publication is linked-only, shared-version fenced and reversible without KYC reuse',async()=>{
    await debit();const path=`customer/khata/vendors/${vendorId}/settlement-options`;
    expect((await get(path).expect(200)).body).toMatchObject({upiId:null,upiAvailable:false,cashAvailable:true,duePaise:'10000'});await get(path,stranger).expect(404);
    const upiClaim=()=>post(`customer/khata/vendors/${vendorId}/claims`,{vendorCustomerId:customerId,amountPaise:'100',method:'UPI'});
    expect((await upiClaim().expect(422)).body.code).toBe('UPI_NOT_AVAILABLE');
    expect(await db.payment_claims.count({where:{vendor_customer_id:customerId}})).toBe(0);
    await patch('vendor/khata/payment-details',{version:1,publish:true,upiId:'synthetic.pay@okbank'},owner).expect(200);
    await upiClaim().expect(201);
    await patch('vendor/khata/payment-details',{version:2,publish:false},owner).expect(200);
    expect((await get(path).expect(200)).body).toMatchObject({upiId:null,upiAvailable:false,cashAvailable:true});
    expect((await upiClaim().expect(422)).body.code).toBe('UPI_NOT_AVAILABLE');
    await claim('100').expect(201);
    await patch('vendor/khata/payment-details',{version:3,publish:true,upiId:'synthetic.pay@okbank'},owner).expect(200);
    expect((await get(path).expect(200)).body).toMatchObject({upiId:'synthetic.pay@okbank',upiAvailable:true,payeeName:'Synthetic Khata vendor'});await patch('vendor/khata/payment-details',{version:1,publish:false},owner).expect(409);await patch('vendor/khata/payment-details',{version:4,publish:false},owner).expect(200);expect((await get(path).expect(200)).body.upiId).toBeNull();
    const notices=await db.audit_logs.findMany({where:{entity_id:vendorId,action:'PAYMENT_DETAILS_PUBLICATION'}});expect(JSON.stringify(notices)).not.toContain('synthetic.pay');
  });
  it('TC-250/255 existing unique accepted account guard holds and advances reduce the current claim limit',async()=>{
    await debit();await expect(db.vendor_customers.create({data:{vendor_id:vendorId,user_id:buyer.id,name:'Synthetic duplicate account',mobile:'+919000000000'}})).rejects.toThrow();await app.get(LedgerService).opening(owner.id,randomUUID(),customerId,{type:'CREDIT',amountPaise:2000n,note:'Synthetic account advance'});
    const response=(await get(`customer/khata/vendors/${vendorId}/entries`).expect(200)).body;expect(response.duePaise).toBe('8000');expect(response.accounts.find((r:{vendorCustomerId:string})=>r.vendorCustomerId===customerId).maxClaimPaise).toBe('8000');await claim('8001').expect(422);await claim('8000').expect(201);
  });
  it('TC-250/253 exact large amounts, bounds, calendar validation, whitelist, empty edits and role isolation are enforced',async()=>{
    const c=await contact();await entry(c,'9007199254740993');expect((await get('customer/khata/summary?tab=CUSTOMERS').expect(200)).body.totalReceivablePaise).toBe('9007199254740993');await post('customer/personal-entries',{contactId:c,direction:'GAVE',amountPaise:'9223372036854775808',date:day}).expect(400);await post('customer/personal-entries',{contactId:c,direction:'GAVE',amountPaise:'1',date:'2026-02-30'}).expect(400);
    await post('customer/personal-contacts',{name:'Synthetic',userId:stranger.id}).expect(400);await patch(`customer/personal-contacts/${c}`,{version:1}).expect(400);await post('customer/personal-contacts',{name:'Synthetic'},owner).expect(403);await get(`customer/khata/vendors/${vendorId}/entries?month=2026-13`).expect(400);await get('customer/khata/summary?limit=51').expect(400);
  });
});
