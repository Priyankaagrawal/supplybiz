import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { api } from '../../lib/api';
import PrivacyForm from '../privacy-form';
import { PrivacyFields } from '../privacy-fields';
export const dynamic='force-dynamic';
const input='min-h-12 max-w-full rounded border px-3';
export default async function Privacy({searchParams}:{searchParams:Promise<{offset?:string;result?:string}>}){
 const token=(await cookies()).get('sb_admin')?.value;if(!token)redirect('/login');
 const params=await searchParams,offset=Number(params.offset??0);if(!Number.isInteger(offset)||offset<0||offset>100000)redirect('/privacy');
 try{
  const me=(await api(token).GET('/api/v1/admin/auth/me')).data;if(!me)redirect('/login?error=expired');if(!me.permissions.includes('privacy.manage'))return <p role="alert">Access denied.</p>;
  const result=await api(token).GET('/api/v1/admin/data-requests',{params:{query:{offset}}});if(!result.data)return <p role="alert">Privacy requests unavailable. Reload to retry.</p>;
  return <><a className="inline-flex min-h-12 items-center underline" href="/">Workspace</a><h1 className="text-2xl font-semibold">Privacy requests</h1>{params.result==='saved'&&<p role="status">Privacy request saved.</p>}
   <p>Deletion begins only after the user confirms a deletion OTP. Holds pause future erasure and require a documented legal reason. Releasing an overdue hold makes it eligible for the worker; completed or in-progress erasure cannot be undone.</p>
   <h2 className="mt-4 text-xl font-semibold">Prepare subject export</h2><p>Verify the requester&apos;s identity and exact account ID before creating an export. Share the file only with that verified subject through an appropriate private channel. It contains structured account/transaction data; credentials, document bytes, full encrypted bank/PAN identifiers and third-party contacts/free-text notes are excluded. This does not send a file automatically.</p>
   <PrivacyForm><PrivacyFields token={token} action="create"/><label className="grid gap-1">Subject user ID<input className={input} name="userId" required maxLength={36}/></label><label className="grid gap-1">Request reason<input className={input} name="reason" required minLength={3} maxLength={500}/></label><label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="identityVerified" required/>I verified the requester&apos;s identity and account ID.</label></PrivacyForm>
   <h2 className="text-xl font-semibold">Requests ({result.data.total})</h2>{result.data.items.length===0&&<p>No privacy requests on this page.</p>}
   {result.data.items.map(row=><section className="my-4 break-words rounded border p-4" key={row.id}><h3 className="font-semibold">{row.kind}: {row.status}</h3>{row.status.startsWith('ERASED')&&<p>Personal erasure is complete. A new hold applies only to remaining retained financial/audit evidence and cannot restore erased data.</p>}<p>Request: {row.id}</p><p>Subject: {row.userId}</p><p>Created: {row.createdAt}</p><p>{row.kind==='DELETION'?'Erasure deadline':'Download expires'}: {row.deadline}</p>{row.reason&&<p>Reason: {row.reason}</p>}
    {row.kind==='DELETION'&&['PENDING_ERASURE','HELD','ERASED','ERASED_HELD'].includes(row.status)&&<PrivacyForm><PrivacyFields token={token} action={row.status.endsWith('HELD')?'RELEASE':'HOLD'} id={row.id}/><input type="hidden" name="version" value={row.version}/><label className="grid gap-1">{row.status.endsWith('HELD')?'Release reason':'Legal hold reason'}<input className={input} name="reason" required minLength={3} maxLength={500}/></label><label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="confirm" required/>I confirm this {row.status.endsWith('HELD')?'release; overdue erasure may start immediately':'documented legal hold'}.</label></PrivacyForm>}
    {row.kind==='EXPORT'&&row.status==='READY'&&<><p>Only the requesting administrator can download. Each download creates a fresh current snapshot and an audit event. Download is limited to 1,000 rows per collection and 4 MiB; oversized exports fail without partial content.</p><PrivacyForm download><PrivacyFields token={token} action="download" id={row.id}/></PrivacyForm></>}
   </section>)}
   <nav aria-label="Privacy request pages">{offset>0&&<a className="mr-4 inline-flex min-h-12 items-center underline" href={`/privacy?offset=${Math.max(0,offset-20)}`}>Previous</a>}{offset+20<result.data.total&&<a className="inline-flex min-h-12 items-center underline" href={`/privacy?offset=${offset+20}`}>Next</a>}</nav>
  </>;
 }catch(e){if(e instanceof Error&&e.message.startsWith('NEXT_REDIRECT'))throw e;return <p role="alert">Service unavailable. Reload to retry.</p>;}
}
