// S-A-10 / FR-406 / TC-510 / T-156
import { cookies } from 'next/headers';
import { notFound, redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../../../lib/api';
import { istInput, pageOffset, uuid } from '../../../../lib/plans';
import { PlanFields } from '../../fields';
export const dynamic = 'force-dynamic';
const field = 'min-h-12 rounded border p-2';
const showDate = (value: string) => new Date(value).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });
export default async function VendorPlan({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ result?: string; offset?: string }> }) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const { id } = await params;
 if (!uuid(id)) notFound();
 const client = api(token), query = await searchParams, offset = pageOffset(query.offset);
 let me;
 try { me = await client.GET('/api/v1/admin/auth/me'); } catch { return <p role="alert">Plan service unavailable. Reload to try again.</p>; }
 if (me.response.status === 401) redirect('/login?error=expired');
 if (!me.data?.permissions.includes('plans.manage')) return <p role="alert">You do not have permission to manage plans.</p>;
 const [current, catalog, history] = await Promise.all([
  client.GET('/api/v1/admin/vendors/{id}/plan', { params: { path: { id } } }), client.GET('/api/v1/admin/plans'),
  client.GET('/api/v1/admin/vendors/{id}/plan-history', { params: { path: { id }, query: { offset } } }),
 ]).catch(() => [null, null, null] as const);
 if (current?.response.status === 404) notFound();
 if (!current?.data || !catalog?.data || !history?.data) return <p role="alert">Could not load this vendor plan. Check availability and reload.</p>;
 const row = current.data, assignment = row.assignment, options = catalog.data.items.filter(p => p.status === 'ACTIVE');
 return <><Link className="inline-flex min-h-12 items-center underline" href="/plans">Plans and vendors</Link><h1 className="text-2xl font-semibold">Vendor plan</h1>
 <p className="my-4 break-all">Vendor ID: {id}</p>{query.result === 'saved' && <p role="status">Request saved. The current assignment is shown below.</p>}
 <section aria-labelledby="current-plan" className="my-4 rounded border bg-white p-4"><h2 id="current-plan" className="text-xl font-semibold">Current assignment</h2>
 <p>Status: {row.status}. Active customers: {row.activeCustomers} / {row.customerLimit}.</p><p>{row.canAddCustomer ? 'Customer additions are available within the cap.' : 'Customer additions and reactivations are restricted.'}</p>
 {assignment ? <><p>Tier: {assignment.code}</p><p>Start: {showDate(assignment.startsAt)} IST. End: {showDate(assignment.endsAt)} IST.</p><p className="break-all">Assignment: {assignment.id}</p></> : <p>No plan assigned. The 50-customer setup allowance grants no paid features.</p>}
 <p>Effective features: {row.features.length ? row.features.join(', ') : 'None'}.</p>
 <p className="mt-3">No automatic trial or grace. Expiry blocks new business and customer growth while preserving history, permitted settlement and existing-order operations. A downgrade keeps every customer and restricts growth when above the cap.</p></section>
 <h2 className="text-xl font-semibold">Assign or replace a plan</h2><p className="my-3">A new assignment replaces the current one immediately. A future start locks new business until that time. All dates below use India Standard Time (IST).</p>
 {options.length === 0 ? <p>No active catalog plans are available for assignment.</p> : <form action="/plans/save" method="post" className="my-4 grid gap-3 rounded border bg-white p-4"><PlanFields token={token} scope={`assign:${id}`} />
 <input type="hidden" name="action" value="assign" /><input type="hidden" name="vendorId" value={id} />
 <label htmlFor="assign-plan">Plan</label><select id="assign-plan" name="planId" required className={field}>{options.map(plan => <option key={plan.id} value={plan.id}>{plan.name} · {plan.customerLimit} customers</option>)}</select>
 <label htmlFor="assign-start">Start (IST)</label><input id="assign-start" name="startsAt" type="datetime-local" required defaultValue={istInput(new Date().toISOString())} className={field} />
 <label htmlFor="assign-end">End (IST)</label><input id="assign-end" name="endsAt" type="datetime-local" required className={field} />
 <label htmlFor="assign-reason">Reason for assignment</label><textarea id="assign-reason" name="reason" required maxLength={500} className="min-h-24 rounded border p-2" />
 <button className="min-h-12 rounded bg-slate-800 px-6 text-white">Assign plan</button></form>}
 {assignment && <><h2 className="text-xl font-semibold">Extend current assignment</h2><form action="/plans/save" method="post" className="my-4 grid gap-3 rounded border bg-white p-4"><PlanFields token={token} scope={`extend:${id}:${assignment.id}`} />
 <input type="hidden" name="action" value="extend" /><input type="hidden" name="vendorId" value={id} /><input type="hidden" name="assignmentId" value={assignment.id} />
 <label htmlFor="extend-end">New end (IST), later than the current end</label><input id="extend-end" name="endsAt" type="datetime-local" required className={field} />
 <label htmlFor="extend-reason">Reason for extension</label><textarea id="extend-reason" name="reason" required maxLength={500} className="min-h-24 rounded border p-2" />
 <button className="min-h-12 rounded bg-slate-800 px-6 text-white">Extend plan</button></form></>}
 <h2 className="text-xl font-semibold">Assignment history and audit</h2>
 {history.data.items.length === 0 ? <p className="my-4">No assignment history.</p> : <ol className="my-4 grid gap-3">{history.data.items.map(item => <li key={item.id} className="break-words rounded border p-4">
 <h3 className="font-semibold">{item.code} · {item.supersededAt ? 'Superseded' : 'Current record'}</h3><p>{showDate(item.startsAt)} – {showDate(item.endsAt)} IST</p><p>Reason: {item.reason}</p>
 <p className="break-all">Assignment: {item.id}. Admin: {item.grantedByAdmin}. Audit: {item.auditId}.</p>
 {me.data.permissions.includes('audit.read') && <Link className="inline-flex min-h-12 items-center underline" href={`/audit-logs?action=PLAN_ASSIGNED&actorId=${item.grantedByAdmin}`}>Open assignment audit events</Link>}</li>)}</ol>}
 <nav aria-label="Assignment history pages" className="flex gap-6">{offset > 0 && <Link className="inline-flex min-h-12 items-center underline" href={`/plans/vendors/${id}?offset=${Math.max(0, offset - 20)}`}>Previous assignments</Link>}{offset + 20 < history.data.total && <Link className="inline-flex min-h-12 items-center underline" href={`/plans/vendors/${id}?offset=${offset + 20}`}>Next assignments</Link>}</nav></>;
}
