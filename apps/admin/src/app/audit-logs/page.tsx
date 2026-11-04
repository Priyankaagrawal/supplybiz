// S-A-16 / FR-411: server-rendered, read-only audit viewer.
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../lib/api';
export const dynamic = 'force-dynamic';
type Search = { action?: string; actorId?: string; beforeId?: string };
export default async function AuditLogs({ searchParams }: { searchParams: Promise<Search> }) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const query = await searchParams;
 const client = api(token);
 let me;
 try { me = await client.GET('/api/v1/admin/auth/me'); }
 catch { return <p role="alert">Audit service unavailable. Reload to try again.</p>; }
 if (me.response.status === 401) redirect('/login?error=expired');
 if (!me.data?.permissions.includes('audit.read')) return <p role="alert">You do not have permission to view audit logs.</p>;
 let result;
 try { result = await client.GET('/api/v1/admin/audit-logs', { params: { query } }); }
 catch { return <p role="alert">Audit service unavailable. Reload to try again.</p>; }
 const page = result.data;
 const last = page?.items.at(-1);
 const next = new URLSearchParams({ ...(query.action ? { action: query.action } : {}),
   ...(query.actorId ? { actorId: query.actorId } : {}), ...(last ? { beforeId: last.id } : {}) });
 return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link>
 <h1 className="text-2xl font-semibold">Audit log</h1><p className="my-4">Read-only history, newest first. Personal data and credentials are excluded from snapshots. Unavailable historical values appear as “Not recorded”.</p>
 <form className="my-4 flex flex-wrap items-end gap-3" method="get">
 <label className="flex flex-col">Action<input className="min-h-12 rounded border p-2" name="action" maxLength={64} defaultValue={query.action} placeholder="LOGIN_SUCCEEDED" /></label>
 <label className="flex flex-col">Actor ID<input className="min-h-12 rounded border p-2" name="actorId" defaultValue={query.actorId} /></label>
 <button className="min-h-12 rounded bg-slate-800 px-4 text-white">Filter</button>
 <Link className="inline-flex min-h-12 items-center underline" href="/audit-logs">Clear filters</Link></form>
 {!page ? <p role="alert">{result.response.status === 400 ? 'Invalid filter. Use an uppercase action and a valid actor UUID.' : 'Could not load audit logs. Reload to try again.'}</p> : page.items.length === 0 ? <p>No audit records match these filters.</p> :
 <ol className="space-y-4">{page.items.map(row => <li key={row.id} className="rounded border bg-white p-4">
 <h2 className="break-words font-semibold">{row.action}</h2>
 <dl className="my-2 space-y-2 break-words">
 <dt className="font-semibold">Time (UTC)</dt><dd><time dateTime={row.at}>{row.at}</time></dd>
 <dt className="font-semibold">Actor</dt><dd>{row.actor_type}: {row.actor_id ?? 'Not recorded'}</dd>
 <dt className="font-semibold">Entity</dt><dd>{row.entity}: {row.entity_id ?? 'Not recorded'}</dd>
 <dt className="font-semibold">IP</dt><dd>{row.ip ?? 'Not recorded'}</dd>
 <dt className="font-semibold">Before</dt><dd><pre className="whitespace-pre-wrap break-words">{row.before == null ? 'Not recorded' : JSON.stringify(row.before, null, 2)}</pre></dd>
 <dt className="font-semibold">After</dt><dd><pre className="whitespace-pre-wrap break-words">{row.after == null ? 'Not recorded' : JSON.stringify(row.after, null, 2)}</pre></dd>
 </dl></li>)}</ol>}
 {page?.hasMore && <Link className="my-4 inline-flex min-h-12 items-center underline" href={`/audit-logs?${next}`}>Older records</Link>}
 </>;
}
