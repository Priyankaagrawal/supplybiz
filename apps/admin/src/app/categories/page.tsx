// S-A-08 / FR-405 / T-153
import { randomUUID } from 'node:crypto';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../lib/api';
import { csrf } from '../../lib/security';
import type { components } from '../../../../../packages/ts-client/src/generated/openapi';
export const dynamic = 'force-dynamic';
type Category = components['schemas']['CategoryRow'];
function CategoryForm({ row, token }: { row?: Category; token: string }) {
 const prefix = row?.id ?? 'new';
 return <form action="/categories/save" method="post" className="my-4 grid gap-3 rounded border bg-white p-4">
 <input type="hidden" name="csrf" value={csrf(token)} /><input type="hidden" name="key" value={randomUUID()} />
 <input type="hidden" name="id" value={row?.id ?? ''} />
 <label htmlFor={`${prefix}-code`}>Code</label><input className="min-h-12 rounded border p-2" id={`${prefix}-code`} name="code" required maxLength={64} pattern="[A-Z][A-Z0-9_]*" defaultValue={row?.code} />
 <label htmlFor={`${prefix}-name`}>English name</label><input className="min-h-12 rounded border p-2" id={`${prefix}-name`} name="name" required maxLength={120} defaultValue={row?.name} />
 <label htmlFor={`${prefix}-icon`}>Icon identifier</label><input className="min-h-12 rounded border p-2" id={`${prefix}-icon`} name="icon" maxLength={120} pattern="[a-zA-Z0-9_-]*" defaultValue={row?.icon} />
 <label htmlFor={`${prefix}-type`}>Type</label><select className="min-h-12 rounded border p-2" id={`${prefix}-type`} name="type" defaultValue={row?.type ?? 'SUPPLY'}><option>SUPPLY</option><option>BILL</option></select>
 <label htmlFor={`${prefix}-status`}>Availability</label><select className="min-h-12 rounded border p-2" id={`${prefix}-status`} name="status" defaultValue={row?.status ?? 'COMING_SOON'}><option>ENABLED</option><option>COMING_SOON</option><option>HIDDEN</option></select>
 <label htmlFor={`${prefix}-order`}>Display order</label><input className="min-h-12 rounded border p-2" id={`${prefix}-order`} name="sortOrder" type="number" required min={0} max={2147483647} step={1} defaultValue={row?.sortOrder ?? 0} />
 <label htmlFor={`${prefix}-products`}>Product types (one per line, up to 50)</label><textarea className="min-h-24 rounded border p-2" id={`${prefix}-products`} name="productTypes" maxLength={4050} defaultValue={row?.productTypes.join('\n')} />
 <button className="min-h-12 rounded bg-slate-800 px-6 text-white">{row ? 'Save category' : 'Create category'}</button>
 </form>;
}
export default async function Categories({ searchParams }: { searchParams: Promise<{ result?: string }> }) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const client = api(token);
 let me;
 try { me = await client.GET('/api/v1/admin/auth/me'); } catch { return <p role="alert">Category service unavailable. Reload to try again.</p>; }
 if (me.response.status === 401) redirect('/login?error=expired');
 if (!me.data?.permissions.includes('categories.manage')) return <p role="alert">You do not have permission to manage categories.</p>;
 let result;
 try { result = await client.GET('/api/v1/admin/categories'); } catch { return <p role="alert">Category service unavailable. Reload to try again.</p>; }
 if (!result.data) return <p role="alert">Could not load categories. Reload to try again.</p>;
 const query = await searchParams;
 return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link><h1 className="text-2xl font-semibold">Categories</h1>
 <p className="my-4">Use Hidden to remove a category from selection while keeping existing vendor records. Bill payments remain unavailable.</p>
 {query.result === 'saved' && <p role="status">Category saved.</p>}
 <h2 className="text-xl font-semibold">Create category</h2><CategoryForm token={token} />
 <h2 className="text-xl font-semibold">Existing categories</h2>
 {result.data.items.length === 0 ? <p>No categories yet.</p> : result.data.items.map(row => <details className="my-3 rounded border p-3" key={row.id}>
 <summary className="min-h-12 cursor-pointer break-words p-3">{row.name} · {row.code} · {row.status} · Order {row.sortOrder}</summary><CategoryForm row={row} token={token} />
 </details>)}</>;
}
