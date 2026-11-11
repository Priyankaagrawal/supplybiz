import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { readManagementRecovery } from '../../../lib/management';
export const dynamic = 'force-dynamic';
export default async function RetryManagement() {
 const jar = await cookies(), token = jar.get('sb_admin')?.value;
 if (!token) redirect('/login');
 const state = readManagementRecovery(token, jar.get('sb_management_retry')?.value ?? '');
 if (!state) return <p role="alert">This recovery form expired. Return to the admin workspace and review the current state.</p>;
 return <><h1 className="text-2xl font-semibold">Management request could not be completed</h1><p role="alert" className="my-4">{state.message}</p>
 {state.retry && <form action="/management/save" method="post">{Object.entries(state.fields).map(([name, value]) => <input key={name} type="hidden" name={name} value={value} />)}<button className="min-h-12 rounded bg-slate-800 px-6 text-white">Retry this request safely</button></form>}
 <Link className="my-4 inline-flex min-h-12 items-center underline" href={state.back}>Return to the current record</Link></>;
}
