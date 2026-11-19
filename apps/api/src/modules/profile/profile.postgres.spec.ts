// T-126 / TC-291. Native HTTP/PostgreSQL ownership, validation, replay and rollback.
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync,randomBytes,randomUUID } from 'node:crypto';
import request from 'supertest';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
const url=process.env.NATIVE_TEST_DATABASE_URL,native=url?describe:describe.skip;
native('T-126 native owned account profile',()=>{
 const db=new PrismaService({datasources:{db:{url}}}),env={...process.env};
 let app:INestApplication,owner:{id:string;token:string},other:typeof owner;
 async function boot(){const{AppModule}=await import('../../app.module');const module=await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PrismaService).useValue(db).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();const next=module.createNestApplication();configureHttpApp(next);await next.init();return next;}
 async function actor(){const user=await db.users.create({data:{mobile:`synthetic-profile-${randomUUID()}`,active_role:'CUSTOMER',roles:{create:{role:'CUSTOMER'}}}});const s=await db.sessions.create({data:{user_id:user.id,family_id:randomUUID(),refresh_token_hash:randomUUID(),expires_at:new Date(Date.now()+86400000)}});return{id:user.id,token:app.get(SessionTokensService).issue(user.id,s.id,[])};}
 const get=(token=owner.token)=>request(app.getHttpServer()).get('/api/v1/me/profile').set('Authorization',`Bearer ${token}`);
 const save=(body:object,key:string=randomUUID(),token=owner.token)=>request(app.getHttpServer()).put('/api/v1/me/profile').set('Authorization',`Bearer ${token}`).set('Idempotency-Key',key).send(body);
 async function body(){return{expectedUpdatedAt:(await get().expect(200)).body.updatedAt,name:'Synthetic name',email:'synthetic@example.invalid',photoMediaId:null};}
 async function media(id:string,purpose='PROFILE',user=owner.id){await db.media_files.create({data:{id,owner_user_id:user,purpose,relative_storage_key:`synthetic-${id}`,mime:'image/png',size:10,sha256:'a'.repeat(64),request_key:randomBytes(32).toString('hex'),request_hash:'a'.repeat(64)}});}
 beforeAll(async()=>{const parsed=new URL(url!);if(parsed.pathname!=='/supplybiz_service_area_test'||!['localhost','127.0.0.1','[::1]'].includes(parsed.hostname))throw new Error('Dedicated local test DB required');Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});await db.$connect();app=await boot();other=await actor();},60000);
 beforeEach(async()=>{owner=await actor();});
 afterAll(async()=>{await app?.close();await db.$disconnect();for(const k of Object.keys(process.env))if(!(k in env))delete process.env[k];Object.assign(process.env,env);});
 it('requires auth/key and rejects mobile/role/status/owner mutation, invalid email and blank names',async()=>{
  const input=await body();await get('').expect(401);await save(input,'').expect(400);
  for(const patch of [{mobile:'+919000000000'},{roles:['VENDOR']},{status:'ACTIVE'},{userId:other.id},{name:' '},{email:'not-an-email'},{photoMediaId:'not-a-uuid'}])await save({...input,...patch}).expect(400);
  expect((await get().expect(200)).body.name).toBeNull();
 });
 it('saves exact reviewed fields once under concurrency, preserves mobile, isolates account and rejects stale/change-body retries',async()=>{
  const input=await body(),key=randomUUID(),before=(await get().expect(200)).body;
  const results=await Promise.all([save(input,key),save(input,key)]);expect(results.map(r=>r.status)).toEqual([200,200]);expect(results[0]!.body).toEqual(results[1]!.body);
  expect(results[0]!.body).toMatchObject({name:input.name,email:input.email,mobile:before.mobile});expect(await db.audit_logs.count({where:{actor_id:owner.id,action:'PROFILE_UPDATED'}})).toBe(1);
  expect(JSON.stringify((await db.audit_logs.findFirstOrThrow({where:{actor_id:owner.id,action:'PROFILE_UPDATED'}})).after)).not.toContain(input.email);
  await save(input).expect(409);await save({...input,name:'Different'},key).expect(422);
  expect((await get(other.token).expect(200)).body.id).toBe(other.id);expect((await get(other.token).expect(200)).body.name).toBeNull();
 });
 it('accepts only own READY PROFILE media and allows clearing photo/email',async()=>{
  const input=await body(),valid=randomUUID(),foreign=randomUUID(),wrong=randomUUID();await media(valid);await media(foreign,'PROFILE',other.id);await media(wrong,'KYC_DOC');
  await save({...input,photoMediaId:foreign}).expect(404);await save({...input,photoMediaId:wrong}).expect(404);
  await save({...input,photoMediaId:valid}).expect(200);expect((await get().expect(200)).body.photoMediaId).toBe(valid);
  await save({...await body(),email:null,photoMediaId:null}).expect(200);expect((await get().expect(200)).body).toMatchObject({email:null,photoMediaId:null});
 });
 it('rechecks blocked accounts even for saved-key replay and persists through API recreation',async()=>{
  const input=await body(),key=randomUUID();await save(input,key).expect(200);
  await db.users.update({where:{id:owner.id},data:{status:'BLOCKED'}});await save(input,key).expect(403);await db.users.update({where:{id:owner.id},data:{status:'ACTIVE'}});
  await app.close();app=await boot();expect((await get().expect(200)).body.name).toBe(input.name);
 });
 it('audit failure rolls profile and idempotency back without leaking private fields',async()=>{
  const input=await body();await db.$executeRaw`ALTER TABLE audit_logs ADD CONSTRAINT profile_test_reject CHECK(action<>'PROFILE_UPDATED') NOT VALID`;
  try{const response=await save(input).expect(503);expect(JSON.stringify(response.body)).not.toContain(input.email);}finally{await db.$executeRaw`ALTER TABLE audit_logs DROP CONSTRAINT profile_test_reject`;}
  expect((await get().expect(200)).body.name).toBeNull();
 });
});
