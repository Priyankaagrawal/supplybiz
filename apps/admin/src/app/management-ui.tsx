// S-A-05/06/07 / FR-403/404 / T-155. Credentials and data access stay server-side.
import { randomUUID } from 'node:crypto';
import { cookies } from 'next/headers';
import { notFound, redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../lib/api';
import { csrf } from '../lib/security';
import { managementKey } from '../lib/management';
import { pageOffset, uuid } from '../lib/plans';
export type Kind = 'vendors' | 'customers';
export type ManagementSearch = { search?: string; offset?: string; result?: string };
async function access(kind: Kind) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const result = await api(token).GET('/api/v1/admin/auth/me').catch(() => null);
 if (result?.response.status === 401) redirect('/login?error=expired');
 return { token, me: result?.data, permitted: !!result?.data?.permissions.includes(`${kind}.read`) };
}
export async function ManagementList({ kind, query }: { kind: Kind; query: ManagementSearch }) {
 const auth = await access(kind), title = kind === 'vendors' ? 'Vendors' : 'Customers';
 if (!auth.me) return <p role="alert">Management service unavailable. Reload to try again.</p>;
 if (!auth.permitted) return <p role="alert">You do not have permission to view {kind}.</p>;
 const client = api(auth.token), search = (query.search ?? '').slice(0, 80), offset = pageOffset(query.offset);
 let rows: { id: string; title: string; description: string }[], total: number;
 if (kind === 'vendors') {
  const result = await client.GET('/api/v1/admin/vendors', { params: { query: { search, offset } } }).catch(() => null);
  if (!result?.data) return <p role="alert">Could not load vendors. Reload to try again.</p>;
  total = result.data.total; rows = result.data.items.map(row => ({ id: row.id, title: row.businessName || 'Business name not set', description: `${row.account.mobile} · ${row.isSuspended ? 'SUSPENDED' : 'NOT SUSPENDED'} · Account ${row.account.status}` }));
 } else {
  const result = await client.GET('/api/v1/admin/customers', { params: { query: { search, offset } } }).catch(() => null);
  if (!result?.data) return <p role="alert">Could not load customers. Reload to try again.</p>;
  total = result.data.total; rows = result.data.items.map(row => ({ id: row.id, title: row.name || 'Name not set', description: `${row.mobile} · ${row.status}` }));
 }
 const page = (next: number) => `/${kind}?${new URLSearchParams({ search, offset: String(next) })}`;
 return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link><h1 className="text-2xl font-semibold">{title}</h1>
 <form method="get" action={`/${kind}`} className="my-4 flex flex-wrap gap-3"><label htmlFor="management-search">Search name, mobile or ID</label><input id="management-search" name="search" maxLength={80} defaultValue={search} className="min-h-12 rounded border p-2" /><button className="min-h-12 rounded border px-4">Search</button></form>
 {rows.length === 0 ? <p>No {kind} match this search.</p> : <ul className="divide-y">{rows.map(row => <li key={row.id} className="py-3"><Link className="inline-flex min-h-12 items-center break-words underline" href={`/${kind}/${row.id}`}>{row.title}</Link><p>{row.description}</p><p className="break-all">{row.id}</p></li>)}</ul>}
 <nav aria-label={`${title} pages`} className="my-4 flex gap-6">{offset > 0 && <Link className="inline-flex min-h-12 items-center underline" href={page(Math.max(0, offset - 20))}>Previous</Link>}{offset + 20 < total && <Link className="inline-flex min-h-12 items-center underline" href={page(offset + 20)}>Next</Link>}</nav></>;
}
function ChangeForm({ kind, id, version, action, token, name, badges }: { kind: Kind; id: string; version: string; action: string; token: string; name: string; badges?: string[] }) {
 const key = randomUUID(), label = action === 'badges' ? 'Save display badges' : `${action[0].toUpperCase()}${action.slice(1)} ${name}`;
 return <form action="/management/save" method="post" className="my-4 grid gap-3 rounded border bg-white p-4">
 <input type="hidden" name="csrf" value={csrf(token)} /><input type="hidden" name="key" value={key} /><input type="hidden" name="signature" value={managementKey(token, `${kind}:${id}:${action}`, key)} />
 <input type="hidden" name="kind" value={kind} /><input type="hidden" name="id" value={id} /><input type="hidden" name="action" value={action} /><input type="hidden" name="expectedUpdatedAt" value={version} />
 {badges && <label className="grid gap-2">Admin display badges (one per line, up to 10 labels of 40 characters)<textarea name="badges" maxLength={409} defaultValue={badges.join('\n')} className="min-h-24 rounded border p-2" /></label>}
 <label className="grid gap-2">Reason<textarea name="reason" required maxLength={500} className="min-h-24 rounded border p-2" /></label>
 {['suspend', 'block'].includes(action) && <label className="flex min-h-12 items-center gap-3"><input type="checkbox" name="confirm" required />Confirm {action} for {name}.</label>}
 <button className="min-h-12 rounded bg-slate-800 px-6 text-white">{label}</button></form>;
}
export async function ManagementDetail({ kind, id, result }: { kind: Kind; id: string; result?: string }) {
 const auth = await access(kind);
 if (!auth.me) return <p role="alert">Management service unavailable. Reload to try again.</p>;
 if (!auth.permitted) return <p role="alert">You do not have permission to view {kind}.</p>;
 if (!uuid(id)) notFound();
 const client = api(auth.token), manage = auth.me.permissions.includes(`${kind}.manage`);
 if (kind === 'vendors') {
  const response = await client.GET('/api/v1/admin/vendors/{id}', { params: { path: { id } } }).catch(() => null);
  if (response?.response.status === 404) notFound();
  if (!response?.data) return <p role="alert">Could not load this vendor. Reload to try again.</p>;
  const row = response.data, name = row.businessName || 'this vendor';
  return <><Link className="inline-flex min-h-12 items-center underline" href="/vendors">Vendors</Link><h1 className="text-2xl font-semibold">{name}</h1>{result === 'saved' && <p role="status">Request saved. Current state is shown below.</p>}
  <div className="my-4 grid gap-2 break-words"><p>Vendor ID: {row.id}</p><p>Registered account: {row.account.name || 'Name not set'} · {row.account.mobile} · {row.account.status}</p><p>Category: {row.category}. City: {row.city || 'Not set'}.</p>
  <p>Vendor status: {row.isSuspended ? 'SUSPENDED' : 'NOT SUSPENDED'}. KYC: {row.kycStatus}.</p><p>Display badges: {row.badges.length ? row.badges.join(', ') : 'None'}.</p><p>Plan: {row.planCode || 'None'} · {row.planStatus} · Customer cap {row.customerLimit}.</p>{row.planStartsAt && <p>Validity: {new Date(row.planStartsAt).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })} – {new Date(row.planEndsAt!).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })} IST.</p>}</div>
  <p>Suspension restricts vendor business access. Display badges do not change KYC verification or plan eligibility.</p>
  {auth.me.permissions.includes('plans.manage') && <Link className="inline-flex min-h-12 items-center underline" href={`/plans/vendors/${id}`}>Manage plan assignment</Link>}
  {auth.me.permissions.includes('kyc.review') && <Link className="mx-4 inline-flex min-h-12 items-center underline" href="/kyc">Open KYC review queue</Link>}
  {manage && row.account.status !== 'DELETED' && <><ChangeForm kind={kind} id={id} version={row.updatedAt} action={row.isSuspended ? 'reinstate' : 'suspend'} token={auth.token} name={name} /><ChangeForm kind={kind} id={id} version={row.updatedAt} action="badges" token={auth.token} name={name} badges={row.badges} /></>}</>;
 }
 const response = await client.GET('/api/v1/admin/customers/{id}', { params: { path: { id } } }).catch(() => null);
 if (response?.response.status === 404) notFound();
 if (!response?.data) return <p role="alert">Could not load this customer. Reload to try again.</p>;
 const row = response.data;
 return <><Link className="inline-flex min-h-12 items-center underline" href="/customers">Customers</Link><h1 className="text-2xl font-semibold">{row.name || 'Customer account'}</h1>{result === 'saved' && <p role="status">Request saved. Current state is shown below.</p>}
 <p className="my-4 break-all">Account ID: {row.id}. Mobile: {row.mobile}. Status: {row.status}.</p><p>Blocking prevents sign-in across this account’s roles and revokes current sessions. Unblocking requires a fresh sign-in; deleted accounts cannot be reactivated here.</p>
 {manage && row.status !== 'DELETED' && <ChangeForm kind={kind} id={id} version={row.updatedAt} action={row.status === 'BLOCKED' ? 'unblock' : 'block'} token={auth.token} name={row.name || 'this customer'} />}</>;
}
