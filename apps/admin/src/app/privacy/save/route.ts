import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../lib/api';
import { adminOrigin, validCsrf } from '../../../lib/security';
import { validContentKey } from '../../../lib/content';
export async function POST(request:NextRequest):Promise<NextResponse>{
 const fail=(status:number)=>NextResponse.json({saved:false},{status,headers:{'Cache-Control':'no-store'}});
 const token=request.cookies.get('sb_admin')?.value;if(!token)return fail(401);if(request.headers.get('origin')!==adminOrigin())return fail(403);
 if(Number(request.headers.get('content-length')??0)>20000)return fail(413);
 let form:FormData;try{form=await request.formData();}catch{return fail(400);}
 if([...form.values()].some(v=>typeof v!=='string'||v.length>1000))return fail(400);
 const field=(key:string)=>String(form.get(key)??'');if(!validCsrf(field('csrf'),token))return fail(403);
 const action=field('action'),id=field('id'),key=field('key');if(!validContentKey(token,`privacy:${action}:${id}`,key,field('signature')))return fail(400);
 const header={'Idempotency-Key':key,'X-CSRF-Token':request.cookies.get('sb_csrf')?.value??''},client=api(token),uuid=/^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/;
 try{
  if(action==='download'&&uuid.test(id)){
   const result=await client.GET('/api/v1/admin/data-requests/{id}/export',{params:{path:{id}}});if(!result.data)return fail(result.response.status);
   if(!/^subject-[a-f0-9-]{36}\.json$/.test(result.data.filename)||Buffer.byteLength(result.data.json)>4*1024*1024)return fail(502);
   return new NextResponse(result.data.json,{headers:{'Content-Type':'application/json; charset=utf-8','Content-Disposition':`attachment; filename="${result.data.filename}"`,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}});
  }
  let result;
  if(action==='create'&&id==='new'&&field('identityVerified')==='on'&&uuid.test(field('userId')))result=await client.POST('/api/v1/admin/data-requests',{params:{header},body:{userId:field('userId'),reason:field('reason'),identityVerified:true}});
  else if((action==='HOLD'||action==='RELEASE')&&uuid.test(id)&&field('confirm')==='on'&&/^\d{1,9}$/.test(field('version')))result=await client.POST('/api/v1/admin/data-requests/{id}/hold',{params:{header,path:{id}},body:{action,expectedVersion:Number(field('version')),reason:field('reason')}});
  else return fail(400);
  return result.data?NextResponse.json({saved:true},{headers:{'Cache-Control':'no-store'}}):fail(result.response.status);
 }catch{return fail(503);}
}
