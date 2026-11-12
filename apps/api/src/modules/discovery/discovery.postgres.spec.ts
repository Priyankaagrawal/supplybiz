import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { generateKeyPairSync, randomUUID } from 'node:crypto';
import request from 'supertest';
import sharp from 'sharp';
import { configureHttpApp } from '../../bootstrap';
import { PinoLogger } from '../../common/logging/pino.logger';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionTokensService } from '../auth/session-tokens.service';
import { assignPlanFixture } from '../../../test/fixtures/plans';
const url = process.env.NATIVE_TEST_DATABASE_URL;
const native = url ? describe : describe.skip;
native('T-041 TC-202/204/206/209/210 native discovery', () => {
  const db = new PrismaService({datasources:{db:{url}}}), env = {...process.env};
  let app:INestApplication, categoryId:string, customer:{id:string;token:string}, other:typeof customer;
  let serial = 0;
  const q = {lat:12.97,lng:77.59,pincode:'560001'};
  async function boot() {
    const {AppModule} = await import('../../app.module');
    const module = await Test.createTestingModule({imports:[AppModule]}).overrideProvider(PinoLogger).useValue({log:jest.fn(),warn:jest.fn(),error:jest.fn()}).compile();
    const instance=module.createNestApplication(); configureHttpApp(instance); await instance.init(); return instance;
  }
  async function account(role:'CUSTOMER'|'VENDOR'='CUSTOMER') {
    const u=await db.users.create({data:{mobile:`synthetic-discovery-${randomUUID()}`,active_role:role,roles:{create:{role}}}});
    const session=await db.sessions.create({data:{user_id:u.id,family_id:randomUUID(),refresh_token_hash:'synthetic-unused',expires_at:new Date(Date.now()+86400000)}});
    return {id:u.id,token:app.get(SessionTokensService).issue(u.id,session.id,[])};
  }
  async function vendor(name:string,lng=q.lng,grant=true) {
    const actor=await account('VENDOR');
    const v=await db.vendors.create({data:{user_id:actor.id,category_id:categoryId,business_name:name,latitude:q.lat,longitude:lng,kyc_status:'VERIFIED',settings:{create:{service_radius_km:3}}}});
    if(grant) await db.$transaction(tx=>assignPlanFixture(tx,v.id,'BASIC'));
    return {...v,actor};
  }
  const get=(path='vendors',query:object={},actor=customer)=>request(app.getHttpServer()).get(`/api/v1/customer/${path}`).set('Authorization',`Bearer ${actor.token}`).query({...q,category:categoryId,...query});
  const favorite=(id:string,enabled=true,key:string=randomUUID(),actor=customer)=>{
    const r=request(app.getHttpServer());
    return (enabled?r.put(`/api/v1/customer/favorites/${id}`):r.delete(`/api/v1/customer/favorites/${id}`)).set('Authorization',`Bearer ${actor.token}`).set('Idempotency-Key',key).query(q);
  };
  async function complete(vendorId:string,days:number,status='DELIVERED') {
    const c=await db.vendor_customers.create({data:{vendor_id:vendorId,name:'Synthetic',mobile:`+91${9000000000 + ++serial}`}});
    const time=new Date(Date.now()-days*86400000);
    return db.orders.create({data:{vendor_id:vendorId,vendor_customer_id:c.id,order_no:`SYN-${randomUUID()}`,source:'APP',status,
      delivery_date:time,time_slot:'Synthetic',address_snapshot:{synthetic:true},subtotal_paise:1000n,delivery_charge_paise:0n,total_paise:1000n,
      payment_mode:'POD_CASH',payment_status:'UNPAID',created_at:new Date(time.getTime()-1000),completed_at:status==='DELIVERED'?time:null}});
  }
  beforeAll(async()=>{
    const parsed=new URL(url!); if(!parsed.pathname.endsWith('_test') || !['localhost','127.0.0.1','[::1]'].includes(parsed.hostname)) throw new Error('Dedicated local test DB required');
    Object.assign(process.env,{NODE_ENV:'test',DATABASE_URL:url,OTP_DELIVERY_MODE:'disabled',RATE_LIMIT_MAX_REQUESTS:'10000',AUTH_SIGNING_PRIVATE_KEY:generateKeyPairSync('ed25519').privateKey.export({type:'pkcs8',format:'pem'}).toString()});
    await db.$connect(); app=await boot(); customer=await account(); other=await account();
    categoryId=(await db.categories.create({data:{code:`DISCOVERY-${randomUUID()}`,name_en:'Synthetic',name_hi:'',type:'SUPPLY'}})).id;
  });
  afterAll(async()=>{
    if(categoryId) await db.categories.update({where:{id:categoryId},data:{status:'HIDDEN'}});
    // Retain synthetic audited fixtures in this isolated database; never delete audit history.
    await app?.close(); await db.$disconnect();
    for(const key of Object.keys(process.env)) if(!(key in env)) delete process.env[key]; Object.assign(process.env,env);
  });
  it('TC-202/206 excludes unverified/suspended/outside/unassigned/expired/blocked vendors across every read',async()=>{
    const good=await vendor('Eligible'), bad=await vendor('Unverified'), suspended=await vendor('Suspended'), outside=await vendor('Outside',80), unassigned=await vendor('Unassigned',q.lng,false), expired=await vendor('Expired'), blocked=await vendor('Blocked');
    await db.vendors.update({where:{id:bad.id},data:{kyc_status:'NOT_VERIFIED'}});
    await db.vendors.update({where:{id:suspended.id},data:{is_suspended:true}});
    await db.users.update({where:{id:blocked.user_id},data:{status:'BLOCKED'}});
    await db.vendor_plan_assignments.updateMany({where:{vendor_id:expired.id},data:{starts_at:new Date(Date.now()-120000),ends_at:new Date(Date.now()-1000)}});
    const result=await get().expect(200); expect(result.body.items.map((r:{id:string})=>r.id)).toEqual([good.id]);
    for(const v of [bad,suspended,outside,unassigned,expired,blocked]) {
      await get(`vendors/${v.id}`).expect(404); await get(`vendors/${v.id}/products`).expect(404); await favorite(v.id).expect(404);
    }
    await db.vendor_service_pincodes.create({data:{vendor_id:outside.id,pincode:q.pincode}});
    await get(`vendors/${outside.id}`).expect(200);
  });
  it('ADR-031 ranks real DELIVERED completions in 30 days, with favorites first and distance ties',async()=>{
    const near=await vendor('Rank near'), popular=await vendor('Rank popular',77.60), old=await vendor('Rank old',77.61);
    await complete(popular.id,1); await complete(popular.id,2); await complete(near.id,1);
    await complete(old.id,31); await complete(old.id,1,'NEW');
    const result=await get('vendors',{q:'Rank',sort:'POPULAR'}).expect(200);
    expect(result.body.items.map((r:{id:string})=>r.id)).toEqual([popular.id,near.id,old.id]);
    expect(result.body.items.map((r:{completedOrders30Days:number})=>r.completedOrders30Days)).toEqual([2,1,0]);
    await favorite(old.id).expect(200);
    expect((await get('vendors',{q:'Rank',sort:'POPULAR'}).expect(200)).body.items[0].id).toBe(old.id);
    expect((await get('vendors',{q:'Rank',sort:'NEARBY'}).expect(200)).body.items.map((r:{id:string})=>r.id)).toEqual([old.id,near.id,popular.id]);
    await favorite(old.id,false).expect(200);
  });
  it('TC-209 scopes durable favorites and rejects replay mismatches, role abuse and stale eligibility',async()=>{
    const v=await vendor('Favorite'),key=randomUUID(); await favorite(v.id,true,key).expect(200); await favorite(v.id,true,key).expect(200);
    await favorite(v.id,false,key).expect(422);
    expect((await get('favorites').expect(200)).body.items.map((r:{id:string})=>r.id)).toContain(v.id);
    expect((await get('favorites',{},other).expect(200)).body.items).toEqual([]);
    await app.close(); app=await boot(); await favorite(v.id,true,key).expect(200);
    await db.vendors.update({where:{id:v.id},data:{is_suspended:true}}); await favorite(v.id,true,key).expect(404);
    await favorite(v.id,false).expect(200);
    await get('vendors',{},v.actor).expect(403); await get('vendors',{}, {id:'',token:''}).expect(401);
    await db.users.update({where:{id:other.id},data:{active_role:'VENDOR'}}); await get('vendors',{},other).expect(403);
  });
  it('TC-210 paginates 45 tied vendors without duplicates; cursors bind user/location/query and reject tampering',async()=>{
    for(let i=0;i<45;i++) await vendor(`Page ${i}`);
    const first=await get('vendors',{q:'Page'}).expect(200), second=await get('vendors',{q:'Page',cursor:first.body.nextCursor}).expect(200), third=await get('vendors',{q:'Page',cursor:second.body.nextCursor}).expect(200);
    expect([first.body.items.length,second.body.items.length,third.body.items.length]).toEqual([20,20,5]);
    expect(new Set([...first.body.items,...second.body.items,...third.body.items].map((r:{id:string})=>r.id)).size).toBe(45);
    expect(third.body.nextCursor).toBeNull();
    await get('vendors',{q:'Page',cursor:`${first.body.nextCursor}x`}).expect(400);
    await get('vendors',{q:'Changed',cursor:first.body.nextCursor}).expect(400);
    await get('vendors',{q:'Page',cursor:first.body.nextCursor},await account()).expect(400);
    for(const query of [{lat:91},{lat:''},{lng:'NaN'},{pincode:'000000'},{sort:'RATING'},{limit:51},{vendorId:randomUUID()}]) await get('vendors',query).expect(400);
  });
  it('search and products expose only published data and scoped attachments; private KYC remains inaccessible',async()=>{
    const v=await vendor('Product shop');
    const p=await db.products.create({data:{vendor_id:v.id,name:'Synthetic milk',product_type:'MILK',milk_type:'TONED',unit_value:1,unit_type:'L',selling_price_paise:12345,subscription_price_paise:12000,moq:2}});
    expect((await get('search',{q:'Synthetic milk'}).expect(200)).body.items.map((r:{id:string})=>r.id)).toContain(v.id);
    expect((await get(`vendors/${v.id}/products/${p.id}`).expect(200)).body.items[0]).toMatchObject({sellingPricePaise:12345,moq:2});
    const png=await sharp({create:{width:2,height:2,channels:3,background:'red'}}).png().toBuffer();
    const upload=async(purpose:string)=>(await request(app.getHttpServer()).post('/api/v1/media').set('Authorization',`Bearer ${v.actor.token}`).set('Idempotency-Key',randomUUID()).field('purpose',purpose).attach('file',png,{filename:'synthetic.png',contentType:'image/png'}).expect(201)).body.mediaId as string;
    const image=await upload('PRODUCT_IMAGE'), privateId=await upload('KYC_DOC');
    await db.products.update({where:{id:p.id},data:{image_media_id:image}});
    await get(`vendors/${v.id}/media/${image}/content`).expect(200); await get(`vendors/${v.id}/media/${privateId}/content`).expect(404);
    await db.products.update({where:{id:p.id},data:{is_active:false}});
    await get(`vendors/${v.id}/products/${p.id}`).expect(404); await get(`vendors/${v.id}/media/${image}/content`).expect(404);
    const about=(await get(`vendors/${v.id}`).expect(200)).body; expect(about.holidays).toEqual([]); expect(about).not.toHaveProperty('gstin'); expect(about).not.toHaveProperty('rating');
  });
});
