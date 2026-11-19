import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../lib/api';
import { adminOrigin, validCsrf } from '../../../lib/security';
import { validContentKey } from '../../../lib/content';
export async function POST(request:NextRequest):Promise<NextResponse> {
 const fail=(status:number)=>NextResponse.json({saved:false},{status,headers:{'Cache-Control':'no-store'}});
 const token=request.cookies.get('sb_admin')?.value;if(!token)return fail(401);
 if(request.headers.get('origin')!==adminOrigin())return fail(403);
 if(Number(request.headers.get('content-length')??0)>20000)return fail(413);
 let form:FormData;try{form=await request.formData();}catch{return fail(400);}
 if([...form.values()].some(v=>typeof v!=='string'||v.length>1000))return fail(400);
 const field=(name:string)=>String(form.get(name)??'');
 if(!validCsrf(field('csrf'),token))return fail(403);
 const action=field('action'),id=field('id'),key=field('key');
 if(!validContentKey(token,`accounts:${action}:${id}`,key,field('signature')))return fail(400);
 const header={'Idempotency-Key':key,'X-CSRF-Token':request.cookies.get('sb_csrf')?.value??''},client=api(token);
 try {
  if(action==='export'&&id==='new') {
   const result=await client.POST('/api/v1/admin/reports/exports',{params:{header},body:{kind:'PLATFORM_SUMMARY'}});
   if(!result.data)return fail(result.response.status);
   if(!/^platform-summary-\d{4}-\d{2}-\d{2}\.csv$/.test(result.data.filename)||Buffer.byteLength(result.data.csv)>65536)return fail(502);
   return new NextResponse(result.data.csv,{headers:{'Content-Type':'text/csv; charset=utf-8','Content-Disposition':`attachment; filename="${result.data.filename}"`,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'}});
  }
  const role=field('role'),status=field('status');
  if(role!=='SUPER_ADMIN'&&role!=='OPS'&&role!=='SUPPORT'&&role!=='FINANCE')return fail(400);
  let result;
  if(action==='create'&&id==='new')result=await client.POST('/api/v1/admin/admins',{params:{header},body:{email:field('email'),password:field('password'),role,reason:field('reason')}});
  else if(action==='change'&&/^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/.test(id)&&(status==='ACTIVE'||status==='DISABLED'))result=await client.PATCH('/api/v1/admin/admins/{id}',{params:{header,path:{id}},body:{role,status,expectedUpdatedAt:field('expectedUpdatedAt'),reason:field('reason')}});
  else return fail(400);
  return result.data?NextResponse.json({saved:true},{headers:{'Cache-Control':'no-store'}}):fail(result.response.status);
 }catch{return fail(503);}
}
