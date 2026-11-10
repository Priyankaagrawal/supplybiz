// S-A-03 / FR-402 / T-151
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../lib/api';
export const dynamic = 'force-dynamic';
export default async function KycQueue({ searchParams }: { searchParams: Promise<{ beforeId?: string }> }) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const client = api(token), query = await searchParams;
 let me;
 try { me = await client.GET('/api/v1/admin/auth/me'); }
 catch { return <p role="alert">KYC service unavailable. Reload to try again.</p>; }
 if (me.response.status === 401) redirect('/login?error=expired');
 if (!me.data?.permissions.includes('kyc.review')) return <p role="alert">You do not have permission to review KYC.</p>;
 let result;
 try { result = await client.GET('/api/v1/admin/kyc', { params: { query: { beforeId: query.beforeId } } }); }
 catch { return <p role="alert">KYC service unavailable. Reload to try again.</p>; }
 const page = result.data, last = page?.items.at(-1);
 return <><Link className="inline-flex min-h-12 items-center underline" href="/">Admin workspace</Link>
 <h1 className="text-2xl font-semibold">Manual KYC queue</h1>
 <p className="my-4">Oldest submissions first. Verification method: MANUAL_REVIEW. Provider checks: NOT_RUN.</p>
 {!page ? <p role="alert">Could not load this queue. <Link className="inline-flex min-h-12 items-center underline" href="/kyc">Retry from first page</Link></p>
 : page.items.length === 0 ? <p>No cases await manual review.</p>
 : <ol className="space-y-4">{page.items.map(row => <li className="break-words rounded border bg-white p-4" key={row.id}>
 <Link prefetch={false} className="inline-flex min-h-12 items-center underline" href={`/kyc/${row.id}`}>Review case {row.id}</Link>
 <p>Vendor: {row.vendorId}</p><p>Status: {row.status}</p><p>Submitted (UTC): <time dateTime={row.submittedAt}>{row.submittedAt}</time></p>
 </li>)}</ol>}
 {page?.hasMore && last && <Link prefetch={false} className="my-4 inline-flex min-h-12 items-center underline" href={`/kyc?beforeId=${encodeURIComponent(last.id)}`}>Next cases</Link>}
 </>;
}
