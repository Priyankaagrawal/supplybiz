import { INestApplication, ServiceUnavailableException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { homeClock } from '../home/home.service';
import { LedgerService } from './ledger.service';
const url=process.env.NATIVE_TEST_DATABASE_URL;
const native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-071 native payment source/credit integration',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,foreign:Actor,buyer:Actor,categoryId:string,vendorId:string,customerId:string,foreignCustomerId:string,day:string;
  let serial=0;
  async function boot(){const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;}
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`+918${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,name:'Synthetic payment actor',active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const payload=(amountPaise='50000',receivedOn=day)=>({vendorCustomerId:customerId,amountPaise,method:'CASH',receivedOn,note:'Synthetic receipt'});
  const post=(body:object,who=owner,key:string=randomUUID())=>request(app.getHttpServer()).post('/api/v1/vendor/payments').set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path='',who=owner)=>request(app.getHttpServer()).get(`/api/v1/vendor/payments${path}`).set('Authorization',`Bearer ${who.token}`);
  async function effects(){return {receipts:await db.payments.count({where:{vendor_id:vendorId}}),credits:await db.ledger_entries.count({where:{vendor_id:vendorId,type:'CREDIT'}})};}
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(target.hostname)) throw new Error('Dedicated local _test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();app=await boot();await app.get(LedgerService).assertPrivileges(db);
    categoryId=(await db.categories.create({data:{code:`PAYMENT-${randomUUID()}`,name_en:'Synthetic payment',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
    foreign=await actor('VENDOR');buyer=await actor('CUSTOMER');
    const v=await db.vendors.create({data:{user_id:foreign.id,category_id:categoryId,business_name:'Synthetic other vendor'}});
    await db.$transaction(tx=>assignPlanFixture(tx,v.id,'BASIC'));
    foreignCustomerId=(await db.vendor_customers.create({data:{vendor_id:v.id,name:'Synthetic other customer',mobile:'+919100000001'}})).id;
  });
  beforeEach(async()=>{
    owner=await actor('VENDOR');vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic payment vendor'}})).id;
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    customerId=(await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic customer',mobile:'+919100000002'}})).id;
    day=(await db.$transaction(tx=>homeClock(tx))).day;
  });
  afterAll(async()=>{jest.restoreAllMocks();if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
  it('TC-111 records cash receipt + one CREDIT, reduces due, and reloads recent/month summary from DB',async()=>{
    await app.get(LedgerService).opening(owner.id,randomUUID(),customerId,{type:'DEBIT',amountPaise:100000n,note:'Synthetic opening'});
    const response=await post(payload()).expect(201);expect(response.headers['cache-control']).toBe('no-store');
    expect(response.body).toMatchObject({vendorCustomerId:customerId,amountPaise:'50000',method:'CASH',receivedOn:day,orderId:null});
    const receipt=await db.payments.findUniqueOrThrow({where:{id:response.body.id}});
    const credit=await db.ledger_entries.findMany({where:{ref_type:'PAYMENT',ref_id:receipt.id}});
    expect(credit).toHaveLength(1);expect(credit[0]).toMatchObject({type:'CREDIT',amount_paise:50000n,vendor_customer_id:customerId,created_by:owner.id});
    expect((await app.get(LedgerService).balance(owner.id,customerId)).duePaise).toBe('50000');
    expect((await get().expect(200)).body).toMatchObject({total:1,items:[response.body]});
    expect((await get('/summary').expect(200)).body).toMatchObject({businessDate:day,totalReceivablePaise:'50000',thisMonthReceivedPaise:'50000'});
    await expect(db.payments.update({where:{id:receipt.id},data:{request_hash:'changed'}})).rejects.toThrow();
    await expect(db.payments.delete({where:{id:receipt.id}})).rejects.toThrow();
  });
  it('TC-111/500 concurrent same-key receipts replay exactly across application recreation and reject mismatch',async()=>{
    const key=randomUUID(),body=payload();const responses=await Promise.all([post(body,owner,key),post(body,owner,key)]);
    expect(responses.map(r=>r.status)).toEqual([201,201]);expect(responses[0]!.body).toEqual(responses[1]!.body);
    await app.close();app=await boot();expect((await post(body,owner,key).expect(201)).body).toEqual(responses[0]!.body);
    await post({...body,amountPaise:'50001'},owner,key).expect(422);expect(await effects()).toEqual({receipts:1,credits:1});
    await db.users.update({where:{id:owner.id},data:{active_role:'CUSTOMER'}});await post(body,owner,key).expect(403);
  });
  it('TC-111 validates amount/date/method/key/extra ownership fields and isolates all reads',async()=>{
    for(const amountPaise of ['0','-1','1.5','01','9223372036854775808',50000]) await post({...payload(),amountPaise}).expect(400);
    for(const receivedOn of ['2026-02-30','not-a-date'])await post({...payload(),receivedOn}).expect(400);
    await post({...payload(),method:'SETTLEMENT'}).expect(400);await post({...payload(),vendorId}).expect(400);await post({...payload(),note:null}).expect(400);
    await post(payload(),owner,'').expect(400);await post({...payload(),vendorCustomerId:foreignCustomerId}).expect(404);
    await post(payload(),foreign).expect(404);await post(payload(),buyer).expect(403);await get('',buyer).expect(403);
    await get(`?vendorCustomerId=${foreignCustomerId}`).expect(404);await get('?limit=51').expect(400);
    await post(payload()).expect(201);expect((await get('',foreign).expect(200)).body).toEqual({items:[],total:0});
    expect((await get('/summary',foreign).expect(200)).body.thisMonthReceivedPaise).toBe('0');
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await get().expect(403);
  });
  it('TC-111 rolls back receipt on CREDIT failure, preserves safe retry and fails closed on grants',async()=>{
    const key=randomUUID(),ledger=app.get(LedgerService);
    const failure=jest.spyOn(ledger,'post').mockRejectedValueOnce(new Error('synthetic private DB diagnostic'));
    const denied=await post(payload(),owner,key).expect(503);expect(JSON.stringify(denied.body)).not.toContain('private DB');failure.mockRestore();
    expect(await effects()).toEqual({receipts:0,credits:0});await post(payload(),owner,key).expect(201);
    const grants=jest.spyOn(ledger,'assertPrivileges').mockRejectedValueOnce(new ServiceUnavailableException({code:'LEDGER_GRANTS_NOT_APPLIED'}));
    await post(payload('1')).expect(503);grants.mockRestore();expect(await effects()).toEqual({receipts:1,credits:1});
  });
  it('TC-111 exact large paise survive; aggregate overflow rolls back, zero/negative balance advances are valid',async()=>{
    const maximum='9223372036854775807';await post({...payload(maximum),method:'WALLET'}).expect(201);
    expect((await app.get(LedgerService).balance(owner.id,customerId)).duePaise).toBe(`-${maximum}`);
    const key=randomUUID();await post(payload('1'),owner,key).expect(503);expect(await effects()).toEqual({receipts:1,credits:1});
    expect((await get('/summary').expect(200)).body).toMatchObject({totalReceivablePaise:'0',thisMonthReceivedPaise:maximum});
  });
  it('TC-111 current-month totals use receipt dates; pagination is scoped and advances do not offset another receivable',async()=>{
    const previous=new Date(`${day.slice(0,7)}-01T00:00:00Z`);previous.setUTCDate(0);
    await post({...payload('100',previous.toISOString().slice(0,10)),method:'BANK'}).expect(201);
    await post({...payload('200'),method:'UPI'}).expect(201);
    const other=(await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic debtor',mobile:'+919100000003',status:'INACTIVE'}})).id;
    await app.get(LedgerService).opening(owner.id,randomUUID(),other,{type:'DEBIT',amountPaise:1000n,note:'Synthetic opening'});
    expect((await get('/summary').expect(200)).body).toMatchObject({totalReceivablePaise:'1000',thisMonthReceivedPaise:'200'});
    const first=(await get('?limit=1').expect(200)).body,second=(await get('?limit=1&offset=1').expect(200)).body;
    expect(first.total).toBe(2);expect(first.items[0].method).toBe('UPI');expect(second.items[0].method).toBe('BANK');
    await post({...payload('100'),vendorCustomerId:other}).expect(201);
    expect((await get(`?vendorCustomerId=${other}`).expect(200)).body.total).toBe(1);
  });
  it('ADR-029 settlement/history survive expiry, but a first scheduled plan grants no early access',async()=>{
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:vendorId},data:{starts_at:new Date(Date.now()-60000),ends_at:new Date(Date.now()-1000)}});
    await post(payload()).expect(201);await get().expect(200);await get('/summary').expect(200);
    const a=await actor('VENDOR'),v=await db.vendors.create({data:{user_id:a.id,category_id:categoryId,business_name:'Synthetic future vendor'}});
    await db.$transaction(tx=>assignPlanFixture(tx,v.id,'BASIC'));
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:v.id},data:{starts_at:new Date(Date.now()+60000),ends_at:new Date(Date.now()+120000)}});
    const c=await db.vendor_customers.create({data:{vendor_id:v.id,name:'Synthetic future customer',mobile:'+919100000004'}});
    await post({...payload(),vendorCustomerId:c.id},a).expect(403);await get('',a).expect(403);
    expect(await db.payments.count({where:{vendor_id:v.id}})).toBe(0);
  });
});
