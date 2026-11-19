// T-101 / TC-097/512: real API/PostgreSQL artifacts; spreadsheet/Android UI is separate.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync,randomUUID,createHash } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { homeClock } from '../home/home.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { parseCsv } from '../../../test/fixtures/report-csv';
import { ReportsService } from './reports.service';
import { ReportExportsService } from './report-exports.service';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
type Actor={id:string;token:string};
native('T-101 native report exports',()=>{
  const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
  let app:INestApplication,owner:Actor,other:Actor,buyer:Actor,vendorId:string,otherId:string,categoryId:string,productId:string,day:string;
  async function boot(){
    const {AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
    const a=module.createNestApplication();configureHttpApp(a);await a.init();return a;
  }
  async function actor(role:'VENDOR'|'CUSTOMER'):Promise<Actor>{
    const u=await db.users.create({data:{mobile:`synthetic-export-${randomUUID()}`,active_role:role,roles:{create:{role}}}});
    const s=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return{id:u.id,token:app.get(SessionTokensService).issue(u.id,s.id,[])};
  }
  const input=()=>({from:day,to:day,format:'CSV'});
  const create=(key:string=randomUUID(),body:object=input(),who=owner)=>request(app.getHttpServer()).post('/api/v1/vendor/reports/exports').set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
  const get=(path:string,who=owner)=>request(app.getHttpServer()).get(path).set('Authorization',`Bearer ${who.token}`);
  const status=(id:string,who=owner)=>get(`/api/v1/vendor/reports/exports/${id}`,who);
  const download=(id:string,who=owner)=>get(`/api/v1/vendor/reports/exports/${id}/download`,who).buffer(true).parse((res,done)=>{const chunks:Buffer[]=[];res.on('data',(b:Buffer)=>chunks.push(b));res.on('end',()=>done(null,Buffer.concat(chunks)));res.on('error',done);});
  async function sale(rate='1000'){
    return request(app.getHttpServer()).post('/api/v1/vendor/sales').set('Authorization',`Bearer ${owner.token}`).set('Idempotency-Key',randomUUID())
      .send({items:[{productId,qty:1,ratePaise:rate}],paidPaise:rate,paymentMethod:'CASH'}).expect(201);
  }
  beforeAll(async()=>{
    const target=new URL(url!);if(!target.pathname.endsWith('_test')||!['localhost','127.0.0.1','[::1]'].includes(target.hostname))throw new Error('Dedicated local test database required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect();app=await boot();day=(await db.$transaction(tx=>homeClock(tx))).day;
    categoryId=(await db.categories.create({data:{code:`EXPORT-${randomUUID()}`,name_en:'Synthetic export',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
  },60000);
  beforeEach(async()=>{
    owner=await actor('VENDOR');other=await actor('VENDOR');buyer=await actor('CUSTOMER');
    vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,settings:{create:{}}}})).id;
    otherId=(await db.vendors.create({data:{user_id:other.id,category_id:categoryId,settings:{create:{}}}})).id;
    await db.$transaction(async tx=>{await assignPlanFixture(tx,vendorId,'BUSINESS');await assignPlanFixture(tx,otherId,'BUSINESS');});
    productId=(await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:1000,stock_qty:100}})).id;
  });
  afterEach(()=>jest.restoreAllMocks());
  afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const key of Object.keys(process.env))if(!(key in env))delete process.env[key];Object.assign(process.env,env);});
  it('TC-097 creates a ready zero-data CSV with private headers/path, fixed metadata and one audit, no ledger/stock effects',async()=>{
    const created=await create().expect(201),id=created.body.exportId as string;expect(Object.keys(created.body)).toEqual(['exportId']);
    expect(created.headers['cache-control']).toBe('no-store');const s=(await status(id).expect(200)).body;
    expect(s).toMatchObject({exportId:id,status:'READY',format:'CSV',from:day,to:day,downloadPath:`/api/v1/vendor/reports/exports/${id}/download`});
    expect(Date.parse(s.expiresAt)-Date.parse(s.createdAt)).toBe(86400000);
    const file=await download(id).expect(200),bytes=file.body as Buffer,rows=parseCsv(bytes.toString('utf8'));
    expect(file.headers['content-type']).toContain('text/csv');expect(file.headers['x-content-type-options']).toBe('nosniff');expect(file.headers['cache-control']).toBe('no-store');
    expect(file.headers['content-disposition']).toContain(`attachment; filename="supplybiz-report-${day}-${day}-${id}.csv"`);
    expect(bytes.length).toBe(s.sizeBytes);expect(createHash('sha256').update(bytes).digest('hex')).toBe(s.sha256);
    expect(rows.find(r=>r[1]==='totalSalesPaise')![9]).toBe('0');expect(rows.every(r=>r.length===11)).toBe(true);
    expect(await db.audit_logs.count({where:{entity_id:id,action:'REPORT_EXPORTED'}})).toBe(1);
    expect(await db.ledger_entries.count({where:{vendor_id:vendorId}})).toBe(0);expect((await db.products.findUniqueOrThrow({where:{id:productId}})).stock_qty).toBe(100);
    expect(JSON.stringify(s)).not.toMatch(/content|request_key|user_id|vendor_id|UPLOAD_ROOT/);
  });
  it('TC-512 exact summary/daily/all product groups match CSV including >50 groups and unsafe UTF-8 names',async()=>{
    await db.products.update({where:{id:productId},data:{name:'=1+2,"synthetic"\r\nमिल्क'}});await sale('9007199254740993');
    for(let i=0;i<51;i++){
      await db.products.update({where:{id:productId},data:{name:`Synthetic sold name ${i}`}});await sale('1');
    }
    const summary=(await get('/api/v1/vendor/reports/summary').expect(200)).body,daily=(await get('/api/v1/vendor/reports/sales-daily').expect(200)).body;
    const first=(await get('/api/v1/vendor/reports/products?limit=50').expect(200)).body,last=(await get('/api/v1/vendor/reports/products?limit=50&offset=50').expect(200)).body;
    const id=(await create().expect(201)).body.exportId as string,rows=parseCsv((await download(id).expect(200)).body.toString('utf8'));
    const sums=new Map(rows.filter(r=>r[0]==='SUMMARY').map(r=>[r[1],r[9]]));
    for(const key of ['totalSalesPaise','productSalesPaise','totalEarningsPaise','milkSoldLitres','milkSoldUnmeasuredLines','pendingPaymentsPaise','activeCustomers'])expect(sums.get(key)).toBe(String(summary[key]));
    expect(rows.filter(r=>r[0]==='PRODUCT_SALES')).toHaveLength(52);expect(first.total).toBe(52);expect(last.items).toHaveLength(2);
    const products=rows.filter(r=>r[0]==='PRODUCT_SALES');expect(products.reduce((n,r)=>n+BigInt(r[9]!),0n)).toBe(BigInt(first.totalProductSalesPaise));
    expect(products.some(r=>r[5]==='\t=1+2,"synthetic"\r\nमिल्क')).toBe(true);
    expect(rows.find(r=>r[0]==='SALES_DAY')![9]).toBe(daily.items[0].salesPaise);
    const original=(await download(id).expect(200)).body as Buffer;await sale('7');
    expect((await download(id).expect(200)).body).toEqual(original);expect((await get('/api/v1/vendor/reports/summary').expect(200)).body.totalSalesPaise).not.toBe(summary.totalSalesPaise);
  },90000);
  it('same-key concurrency and application recreation preserve one artifact/audit and mismatched input fails',async()=>{
    const key=randomUUID(),results=await Promise.all([create(key),create(key)]);expect(results.map(r=>r.status)).toEqual([201,201]);
    const id=results[0]!.body.exportId as string;expect(results[1]!.body.exportId).toBe(id);expect(await db.report_exports.count({where:{vendor_id:vendorId}})).toBe(1);
    const digest=(await status(id).expect(200)).body.sha256;await app.close();app=await boot();
    expect((await create(key).expect(201)).body.exportId).toBe(id);expect((await status(id).expect(200)).body.sha256).toBe(digest);
    await create(key,{...input(),from:'2000-01-01',to:'2000-01-01'}).expect(422);expect(await db.audit_logs.count({where:{entity_id:id,action:'REPORT_EXPORTED'}})).toBe(1);
  });
  it('rechecks owner/role/suspension and live plan on create, replay, status and download',async()=>{
    const key=randomUUID(),id=(await create(key).expect(201)).body.exportId as string;
    await status(id,other).expect(404);await download(id,other).expect(404);await create(randomUUID(),input(),buyer).expect(403);
    await request(app.getHttpServer()).get(`/api/v1/vendor/reports/exports/${id}/download`).expect(401);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
    for(const send of [()=>create(key),()=>status(id),()=>download(id)]){const r=await send().expect(403);expect((Buffer.isBuffer(r.body)?JSON.parse(r.body.toString('utf8')):r.body).code).toBe('PLAN_FEATURE_LOCKED');}
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BUSINESS',new Date('2020-01-01'),new Date('2020-02-01')));await status(id).expect(403);await download(id).expect(403);
    await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BUSINESS'));await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await download(id).expect(403);
    await db.vendors.update({where:{id:vendorId},data:{is_suspended:false}});await db.users.update({where:{id:owner.id},data:{active_role:'CUSTOMER'}});await status(id).expect(403);
  });
  it('rejects invalid range/format/scope/IDs and generation failures leave no ready artifact',async()=>{
    for(const body of [{...input(),format:'PDF'},{...input(),vendorId:otherId},{...input(),from:'2026-02-30'},
      {from:'2025-01-01',to:'2026-01-02',format:'CSV'},{to:day,format:'CSV'}])await create(randomUUID(),body).expect(400);
    await create(' ').expect(400);await status('../outside').expect(404);await status('not-a-uuid').expect(400);
    const fault=jest.spyOn(app.get(ReportsService),'exportSnapshot').mockRejectedValueOnce(new Error('Synthetic private diagnostic'));
    const r=await create().expect(503);expect(JSON.stringify(r.body)).not.toContain('Synthetic private');fault.mockRestore();
    expect(await db.report_exports.count({where:{vendor_id:vendorId}})).toBe(0);
    expect(await db.audit_logs.count({where:{actor_id:owner.id,action:'REPORT_EXPORTED'}})).toBe(0);await create().expect(201);
  });
  it('expiry immediately disables download; bounded cleanup deletes only expired derived artifacts',async()=>{
    const old=(await create().expect(201)).body.exportId as string,valid=(await create().expect(201)).body.exportId as string;
    await db.report_exports.update({where:{id:old},data:{created_at:new Date(0),expires_at:new Date(1)}});
    expect((await status(old).expect(200)).body).toMatchObject({status:'EXPIRED',downloadPath:null});await download(old).expect(410);
    await app.get(ReportExportsService).cleanupExpired();expect(await db.report_exports.findUnique({where:{id:old}})).toBeNull();await download(valid).expect(200);await status(old).expect(404);
    expect(await db.products.count({where:{vendor_id:vendorId}})).toBe(1);
  });
  it('weekly zero buckets retain the same clipped IST date range and report totals',async()=>{
    const body={from:'2026-01-01',to:'2026-03-05',format:'CSV'},id=(await create(randomUUID(),body).expect(201)).body.exportId as string;
    const rows=parseCsv((await download(id).expect(200)).body.toString('utf8')),weeks=rows.filter(r=>r[0]==='SALES_WEEK');
    expect(weeks[0]!.slice(2,4)).toEqual(['2026-01-01','2026-01-04']);expect(weeks.at(-1)![3]).toBe('2026-03-05');expect(weeks.every(r=>r[9]==='0')).toBe(true);
  });
});
