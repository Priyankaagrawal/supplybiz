// S-A-13 / T-158. Presentation flags never grant feature permissions.
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../lib/api';
import { ContentFields } from '../content-fields';
import ContentForm from '../content-form';
export const dynamic = 'force-dynamic';
export default async function Configuration({ searchParams }: { searchParams: Promise<{result?: string}> }) {
 const token = (await cookies()).get('sb_admin')?.value; if (!token) redirect('/login');
 try {
  const client = api(token), me = await client.GET('/api/v1/admin/auth/me');
  if (me.response.status === 401) redirect('/login?error=expired');
  if (!me.data?.permissions.includes('config.manage')) return <p role="alert">You do not have permission to manage app configuration.</p>;
  const result = await client.GET('/api/v1/admin/config');
  if (!result.data) return <p role="alert">Could not load current configuration. Reload to try again.</p>;
  const row = result.data, query = await searchParams;
  return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link><h1 className="text-2xl font-semibold">App configuration</h1>
  {query.result === 'saved' && <p role="status">Configuration saved.</p>}
  <p className="my-4">Raising the Android minimum immediately blocks older versions at the API. The app refreshes configuration within five minutes while running. Flags configure presentation only; they cannot grant plans, permissions or deferred features.</p>
  <p>Updated: {row.updatedAt ?? 'Not configured yet; values below are unsaved suggestions.'}</p>
  <ContentForm back="/config" label="Save app configuration"><ContentFields token={token} action="config" id="mobile" />
   <input type="hidden" name="expectedUpdatedAt" value={row.updatedAt ?? ''} />
   <label htmlFor="minimum">Minimum Android version (major.minor.patch)</label><input className="min-h-12 rounded border p-2" id="minimum" name="minVersionAndroid" required defaultValue={row.minVersionAndroid} />
   <label htmlFor="flags">Simple flags (JSON object of boolean values, at most 50)</label><textarea className="min-h-48 rounded border p-2 font-mono" id="flags" name="flags" required maxLength={6000} defaultValue={JSON.stringify(row.flags,null,2)} />
   <label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="confirm" required />I reviewed the minimum version and flags.</label>
  </ContentForm></>;
 } catch (e) { if (e instanceof Error && 'digest' in e) throw e; return <p role="alert">Configuration service unavailable. Reload to try again.</p>; }
}
