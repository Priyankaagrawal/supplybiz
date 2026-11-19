import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { api } from '../../lib/api';
import { Fields } from '../admin-operation-fields';
import AdminOperationForm from '../admin-operation-form';
export const dynamic='force-dynamic';
const roles=['SUPER_ADMIN','OPS','SUPPORT','FINANCE'];
const inputClass='min-h-12 max-w-full rounded border px-3';
function Role({value='SUPPORT'}:{value?:string}) {return <label className="grid gap-1">Role<select name="role" defaultValue={value} className={inputClass}>{roles.map(r=><option key={r}>{r}</option>)}</select></label>;}
export default async function Accounts({searchParams}:{searchParams:Promise<{offset?:string;result?:string}>}) {
 const token=(await cookies()).get('sb_admin')?.value;if(!token)redirect('/login');
 const query=await searchParams,offset=Number(query.offset??0);if(!Number.isInteger(offset)||offset<0||offset>100000)redirect('/admins');
 try {
  const me=await api(token).GET('/api/v1/admin/auth/me');if(!me.data)redirect('/login?error=expired');
  if(!me.data.permissions.includes('admins.manage'))return <p role="alert">Access denied.</p>;
  const result=await api(token).GET('/api/v1/admin/admins',{params:{query:{offset}}});
  if(!result.data)return <p role="alert">Accounts unavailable. Reload to retry.</p>;
  return <><a className="inline-flex min-h-12 items-center underline" href="/">Workspace</a><h1 className="text-2xl font-semibold">Admin accounts and roles</h1>
   {query.result==='saved'&&<p role="status">Account saved.</p>}
   <p>SUPER_ADMIN manages the platform. OPS handles operations and KYC. SUPPORT can read vendor, customer and order records. FINANCE manages plans and aggregate exports. Permissions are fixed. Your own role and status cannot be changed here.</p>
   <h2 className="mt-4 text-xl">Create account</h2><p>Use a unique password of 12–128 characters and share it securely with the staff member. TOTP enrollment is required at first login. Passwords are checked against known breaches.</p>
   <AdminOperationForm><Fields token={token} action="create"/><label className="grid gap-1">Email<input name="email" type="email" required maxLength={254} autoComplete="off" className={inputClass}/></label>
    <label className="grid gap-1">Initial password<input name="password" type="password" required minLength={12} maxLength={128} autoComplete="new-password" className={inputClass}/></label><Role/>
    <label className="grid gap-1">Reason<input name="reason" required minLength={3} maxLength={500} className={inputClass}/></label></AdminOperationForm>
   <h2 className="text-xl">Accounts ({result.data.total})</h2>{result.data.items.length===0&&<p>No accounts on this page.</p>}
   {result.data.items.map(row=><section key={row.id} className="my-4 break-words"><h3 className="font-semibold">{row.email}</h3><p>{row.role} · {row.status} · TOTP {row.totpEnrolled?'enrolled':'required at first login'}</p>
    {row.id===me.data.id?<p>Your current account</p>:<AdminOperationForm><Fields token={token} action="change" id={row.id}/><input type="hidden" name="expectedUpdatedAt" value={row.updatedAt}/><Role value={row.role}/>
     <label className="grid gap-1">Status<select name="status" defaultValue={row.status} className={inputClass}><option>ACTIVE</option><option>DISABLED</option></select></label>
     <p>Changing role or status signs this staff member out and cancels pending login challenges.</p><label className="grid gap-1">Reason<input name="reason" required minLength={3} maxLength={500} className={inputClass}/></label></AdminOperationForm>}</section>)}
   <nav aria-label="Account pages">{offset>0&&<a className="mr-4 inline-flex min-h-12 items-center underline" href={`/admins?offset=${Math.max(0,offset-20)}`}>Previous</a>}{offset+20<result.data.total&&<a className="inline-flex min-h-12 items-center underline" href={`/admins?offset=${offset+20}`}>Next</a>}</nav>
  </>;
 } catch(error) {if(error instanceof Error&&error.message.startsWith('NEXT_REDIRECT'))throw error;return <p role="alert">Service unavailable. Reload to retry.</p>;}
}
