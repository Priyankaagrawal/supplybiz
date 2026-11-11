// S-A-09 / FR-406 / T-156
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../lib/api';
import { pageOffset, rupees } from '../../lib/plans';
import { PlanFields } from './fields';
export const dynamic = 'force-dynamic';
export default async function Plans({ searchParams }: { searchParams: Promise<{ search?: string; offset?: string; result?: string }> }) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const client = api(token), query = await searchParams, offset = pageOffset(query.offset), search = (query.search ?? '').slice(0, 80);
 let me;
 try { me = await client.GET('/api/v1/admin/auth/me'); } catch { return <p role="alert">Plan service unavailable. Reload to try again.</p>; }
 if (me.response.status === 401) redirect('/login?error=expired');
 if (!me.data?.permissions.includes('plans.manage')) return <p role="alert">You do not have permission to manage plans.</p>;
 try {
  const [catalog, vendors] = await Promise.all([client.GET('/api/v1/admin/plans'), client.GET('/api/v1/admin/plan-vendors', { params: { query: { search, offset } } })]);
  if (!catalog.data || !vendors.data) return <p role="alert">Could not load plan administration. Reload to try again.</p>;
  const listing = (next: number) => `/plans?${new URLSearchParams({ search, offset: String(next) })}#vendors`;
  return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link><h1 className="text-2xl font-semibold">Plans and assignments</h1>
  {query.result === 'saved' && <p role="status" className="my-4">Plan catalog saved.</p>}
  <p className="my-4">Customer limits and feature gates follow the approved tier policy. Catalog prices are reference amounts; assigning a plan does not record a payment.</p>
  <h2 className="text-xl font-semibold">Plan catalog</h2>
  {catalog.data.items.length === 0 && <p>No plans are configured.</p>}
  {catalog.data.items.map(row => <details key={row.id} className="my-3 rounded border p-3"><summary className="min-h-12 cursor-pointer p-3">{row.name} · {row.code} · {row.status} · {row.customerLimit} customers</summary>
   <form action="/plans/save" method="post" className="grid gap-3 p-3"><PlanFields token={token} scope={`catalog:${row.id}`} />
   <input type="hidden" name="action" value="catalog" /><input type="hidden" name="planId" value={row.id} /><input type="hidden" name="expectedUpdatedAt" value={row.updatedAt} />
   <label htmlFor={`${row.id}-name`}>English name</label><input id={`${row.id}-name`} name="name" required maxLength={120} defaultValue={row.name} className="min-h-12 rounded border p-2" />
   <label htmlFor={`${row.id}-status`}>Availability</label><select id={`${row.id}-status`} name="status" defaultValue={row.status} className="min-h-12 rounded border p-2"><option>ACTIVE</option><option>INACTIVE</option></select>
   <p>Inactive plans are unavailable for assignment and their existing assignments lose active entitlements.</p>
   <label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="isPopular" defaultChecked={row.isPopular} />Mark as popular</label>
   <fieldset className="grid gap-3"><legend>Reference prices in rupees</legend>{(['MONTHLY', 'HALF_YEARLY', 'YEARLY'] as const).map(duration => <label key={duration} className="grid gap-2">{duration.replaceAll('_', ' ').toLowerCase()} (₹)<input name={duration} required inputMode="decimal" pattern="[0-9]+(\.[0-9]{1,2})?" defaultValue={rupees(row.prices.find(p => p.duration === duration)?.pricePaise ?? 0)} className="min-h-12 rounded border p-2" /></label>)}</fieldset>
   <p>Fixed customer cap: {row.customerLimit}. Features: {row.features.join(', ')}.</p>
   <label htmlFor={`${row.id}-reason`}>Reason for catalog change</label><textarea id={`${row.id}-reason`} name="reason" required maxLength={500} className="min-h-24 rounded border p-2" />
   <button className="min-h-12 rounded bg-slate-800 px-6 text-white">Save catalog</button></form></details>)}
  <h2 id="vendors" className="mt-6 text-xl font-semibold">Vendor plan assignments</h2>
  <form method="get" action="/plans" className="my-4 flex flex-wrap gap-3"><label htmlFor="vendor-search">Business name or vendor ID</label><input id="vendor-search" name="search" maxLength={80} defaultValue={search} className="min-h-12 rounded border p-2" /><button className="min-h-12 rounded border px-4">Find vendor</button></form>
  {vendors.data.items.length === 0 ? <p>No vendors match this search.</p> : <ul className="divide-y">{vendors.data.items.map(row => <li key={row.id}><Link className="inline-flex min-h-12 items-center break-all py-3 underline" href={`/plans/vendors/${row.id}`}>{row.businessName || 'Business name not set'} · {row.id}</Link></li>)}</ul>}
  <nav aria-label="Vendor pages" className="my-4 flex gap-6">{offset > 0 && <Link className="inline-flex min-h-12 items-center underline" href={listing(Math.max(0, offset - 20))}>Previous vendors</Link>}{offset + 20 < vendors.data.total && <Link className="inline-flex min-h-12 items-center underline" href={listing(offset + 20)}>Next vendors</Link>}</nav></>;
 } catch { return <p role="alert">Plan service unavailable. Reload to try again.</p>; }
}
