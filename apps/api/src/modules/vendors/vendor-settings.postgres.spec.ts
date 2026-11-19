// T-106 / TC-130/131 / ADR-034. Real local PostgreSQL and HTTP, synthetic data only.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createDecipheriv, generateKeyPairSync, randomBytes, randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { digest } from '../admin-auth/admin-crypto';
import { assignPlanFixture } from '../../../test/fixtures/plans';
import { homeClock } from '../home/home.service';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
native('T-106 vendor settings and re-verification',()=>{
 const db=new PrismaService({datasources:{db:{url}}}),env={...process.env},enc=randomBytes(32);
 let app:INestApplication,categoryId:string,owner:{id:string;token:string},buyer:typeof owner,other:typeof owner,vendorId:string,kycId:string,adminToken:string;
 let documents:string[];
 let serial=0;
 async function actor(role:'VENDOR'|'CUSTOMER'){
  const user=await db.users.create({data:{mobile:`+919${String(Date.now()%10000000).padStart(7,'0')}${String(++serial).padStart(2,'0')}`,active_role:role,roles:{create:{role}}}});
  const session=await db.sessions.create({data:{user_id:user.id,family_id:randomUUID(),refresh_token_hash:randomUUID(),expires_at:new Date(Date.now()+86400000)}});
  return{id:user.id,token:app.get(SessionTokensService).issue(user.id,session.id,[])};
 }
 const get=(path='vendor/settings/profile',who=owner)=>request(app.getHttpServer()).get(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`);
 const put=(path:string,body:object,key:string=randomUUID(),who=owner)=>request(app.getHttpServer()).put(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',key).send(body);
 const post=(path:string,body:object,who=owner)=>request(app.getHttpServer()).post(`/api/v1/${path}`).set('Authorization',`Bearer ${who.token}`).set('Idempotency-Key',randomUUID()).send(body);
 const business=(version=1)=>({version,businessName:'Synthetic unchanged',gstin:null,addressLine:'Synthetic street',city:'Synthetic city',state:'Synthetic state',pincode:'560001',latitude:12.97,longitude:77.59,shopPhotoMediaId:null});
 const delivery=(version=1)=>({version,deliveryChargePaise:505,minOrderPaise:0,timeSlots:['07:00-08:00','08:00-09:00'],acceptingToday:true,sameDayCutoff:'21:00'});
 const bank=()=>({aadhaarFrontMediaId:documents[0],aadhaarBackMediaId:documents[1],panMediaId:documents[2],pan:'ABCDE1234F',holderName:'Synthetic holder',bankName:'Synthetic bank',accountNumber:'000000000001',accountNumberConfirmation:'000000000001',ifsc:'SBIN0001234'});
 const decision=(id:string)=>request(app.getHttpServer()).post(`/api/v1/admin/kyc/${id}/decision`).set('Authorization',`Bearer ${adminToken}`).set('X-CSRF-Token','synthetic').set('Idempotency-Key',randomUUID()).send({decision:'VERIFIED',reason:'Synthetic review approval'});
 beforeAll(async()=>{
  const parsed=new URL(url!);if(parsed.pathname!=='/supplybiz_service_area_test'||!['localhost','127.0.0.1','[::1]'].includes(parsed.hostname))throw new Error('Dedicated local test DB required');
  Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',FIELD_ENCRYPTION_KEY:enc.toString('hex'),AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
  await db.$connect();const{AppModule}=await import('../../app.module');
  const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PrismaService).useValue(db).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
  app=module.createNestApplication();configureHttpApp(app);await app.init();
  categoryId=(await db.categories.create({data:{code:`SETTINGS-${randomUUID()}`,name_en:'Synthetic settings',name_hi:'',type:'SUPPLY',product_types:['MILK']}})).id;
  const admin=await db.admin_users.create({data:{email:`settings-${randomUUID()}@example.invalid`,role:'OPS',password_hash:'synthetic-unused'}});adminToken=randomBytes(32).toString('base64url');
  await db.admin_sessions.create({data:{token_hash:digest(adminToken),csrf_hash:digest('synthetic'),admin_id:admin.id,expires_at:new Date(Date.now()+3600000)}});
  buyer=await actor('CUSTOMER');other=await actor('VENDOR');
  await db.vendors.create({data:{user_id:other.id,category_id:categoryId,business_name:'Synthetic other',settings:{create:{}}}});
 },60000);
 beforeEach(async()=>{
  owner=await actor('VENDOR');vendorId=(await db.vendors.create({data:{user_id:owner.id,category_id:categoryId,business_name:'Synthetic unchanged',onboarding_step:4,latitude:12.97,longitude:77.59,settings:{create:{}}}})).id;
  await db.$transaction(tx=>assignPlanFixture(tx,vendorId,'BASIC'));
  documents=[];for(let i=0;i<3;i++){const id=randomUUID();await db.media_files.create({data:{id,owner_user_id:owner.id,purpose:'KYC_DOC',relative_storage_key:`synthetic-${id}`,mime:'image/png',size:100,sha256:'a'.repeat(64),request_key:randomBytes(32).toString('hex'),request_hash:'a'.repeat(64)}});documents.push(id);}
  kycId=(await post('vendor/kyc',bank()).expect(201)).body.id;await decision(kycId).expect(201);
 });
 afterAll(async()=>{if(categoryId)await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
 it('rejects role/suspension/forged fields and validates exact money, cutoff and slots',async()=>{
  await get('vendor/settings/profile',buyer).expect(403);
  await put('vendor/settings/delivery',delivery(),'').expect(400);
  for(const change of [{vendorId},{allowKhataOrders:true},{deliveryChargePaise:1.5},{deliveryChargePaise:-1},{acceptingToday:true,sameDayCutoff:null},{timeSlots:['08:00-07:00']},{timeSlots:['07:00-09:00','08:00-10:00']}])await put('vendor/settings/delivery',{...delivery(),...change}).expect(400);
  await db.vendors.update({where:{id:vendorId},data:{is_suspended:true}});await put('vendor/settings/delivery',delivery()).expect(403);
 });
 it('concurrent settings retries save and audit once; stale versions, changed body, and cross-owner snapshots cannot overwrite',async()=>{
  const key=randomUUID(),results=await Promise.all([put('vendor/settings/delivery',delivery(),key),put('vendor/settings/delivery',delivery(),key)]);
  expect(results.map(r=>r.status)).toEqual([200,200]);expect(results[0]!.body).toEqual(results[1]!.body);
  expect(results[0]!.body.settings).toMatchObject({version:2,deliveryChargePaise:505,sameDayCutoff:'21:00'});
  expect(await db.audit_logs.count({where:{entity_id:vendorId,action:'VENDOR_DELIVERY_SETTINGS_UPDATED'}})).toBe(1);
  await put('vendor/settings/delivery',delivery()).expect(409);await put('vendor/settings/delivery',{...delivery(),minOrderPaise:10},key).expect(422);
  expect((await get('vendor/settings/profile',other).expect(200)).body.settings.deliveryChargePaise).toBe(0);
 });
 it('delivery charge reaches a new customer quote and later settings do not alter an existing bill',async()=>{
  await put('vendor/settings/delivery',delivery()).expect(200);
  const product=await db.products.create({data:{vendor_id:vendorId,name:'Synthetic milk',product_type:'MILK',milk_type:'COW',unit_value:1,unit_type:'L',selling_price_paise:10000,stock_qty:20,moq:1}});
  const address=await db.addresses.create({data:{user_id:buyer.id,label:'Synthetic home',line1:'Synthetic house',line2:'Synthetic street',city:'Synthetic city',state:'Synthetic state',pincode:'560001',latitude:12.97,longitude:77.59}});
  const {day}=await db.$transaction(tx=>homeClock(tx)),date=new Date(`${day}T00:00:00Z`);date.setUTCDate(date.getUTCDate()+1);
  const input={vendorId,addressId:address.id,deliveryDate:date.toISOString().slice(0,10),timeSlot:'07:00-08:00',paymentMode:'POD_CASH',items:[{productId:product.id,qty:1}]};
  const quote=(await post('customer/orders/quote',input,buyer).expect(201)).body;expect(quote.deliveryChargePaise).toBe('505');expect(quote.totalPaise).toBe('10505');
  const order=(await post('customer/orders',{...input,expectedTotalPaise:quote.totalPaise},buyer).expect(201)).body;
  await put('vendor/settings/delivery',{...delivery(2),deliveryChargePaise:999}).expect(200);
  expect((await db.orders.findUniqueOrThrow({where:{id:order.id}})).total_paise.toString()).toBe('10505');
 });
 it('business-name edit creates one pending review, pauses discovery and returns only after approval',async()=>{
  const about=()=>get(`customer/vendors/${vendorId}?lat=12.97&lng=77.59&pincode=560001`,buyer);
  await about().expect(200);const key=randomUUID();
  const response=await put('vendor/settings/business',{...business(),businessName:'Synthetic revised'},key).expect(200);
  expect(response.body.kycStatus).toBe('PENDING');await about().expect(404);
  const revision=await db.vendor_kyc.findFirstOrThrow({where:{vendor_id:vendorId,status:'PENDING'}});
  expect(revision.business_name).toBe('Synthetic revised');expect((await db.vendor_kyc.findUniqueOrThrow({where:{id:kycId}})).status).toBe('VERIFIED');
  await put('vendor/settings/business',{...business(),businessName:'Synthetic revised'},key).expect(200);
  expect(await db.vendor_kyc.count({where:{vendor_id:vendorId}})).toBe(2);
  await decision(revision.id).expect(201);await about().expect(200);
 });
 it('non-name business edits retain verified status; foreign photos and stale editors fail',async()=>{
  const edited=await put('vendor/settings/business',business()).expect(200);expect(edited.body.kycStatus).toBe('VERIFIED');
  expect(await db.vendor_kyc.count({where:{vendor_id:vendorId}})).toBe(1);
  await put('vendor/settings/business',business()).expect(409);
  await put('vendor/settings/business',{...business(2),shopPhotoMediaId:documents[0]}).expect(404);
 });
 it('KYC edit encrypts new bank data, preserves the old approved revision, rejects stale review and supersedes pending work',async()=>{
  const key=randomUUID(),body={...bank(),expectedSubmissionId:kycId,accountNumber:'000000000002',accountNumberConfirmation:'000000000002'};
  const first=(await put('vendor/kyc',body,key).expect(200)).body;expect(first.status).toBe('PENDING');expect(first.accountLast4).toBe('0002');expect(JSON.stringify(first)).not.toContain('000000000002');
  expect((await put('vendor/kyc',body,key).expect(200)).body.id).toBe(first.id);
  const row=await db.vendor_kyc.findUniqueOrThrow({where:{id:first.id}}),bytes=Buffer.from(row.account_number_enc.split(':')[1],'base64');
  const cipher=createDecipheriv('aes-256-gcm',enc,bytes.subarray(0,12));cipher.setAAD(Buffer.from(`supplybiz:kyc:v1:${vendorId}:account`));cipher.setAuthTag(bytes.subarray(12,28));expect(Buffer.concat([cipher.update(bytes.subarray(28)),cipher.final()]).toString()).toBe('000000000002');
  await put('vendor/kyc',body).expect(409);
  const second=(await put('vendor/kyc',{...body,expectedSubmissionId:first.id}).expect(200)).body;
  expect((await db.vendor_kyc.findUniqueOrThrow({where:{id:first.id}})).status).toBe('SUPERSEDED');await decision(first.id).expect(409);await decision(second.id).expect(201);
 });
 it('audit failure rolls business/KYC changes and replay back atomically',async()=>{
  await db.$executeRaw`ALTER TABLE audit_logs ADD CONSTRAINT settings_test_reject CHECK (action <> 'VENDOR_BUSINESS_UPDATED') NOT VALID`;
  try{await put('vendor/settings/business',{...business(),businessName:'Synthetic must rollback'}).expect(503);}finally{await db.$executeRaw`ALTER TABLE audit_logs DROP CONSTRAINT settings_test_reject`;}
  expect((await get().expect(200)).body).toMatchObject({businessName:'Synthetic unchanged',kycStatus:'VERIFIED'});expect(await db.vendor_kyc.count({where:{vendor_id:vendorId}})).toBe(1);
 });
});
