// S-A-04 / FR-402 / T-151
import { randomUUID } from 'node:crypto';
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { api } from '../../../lib/api';
import { csrf } from '../../../lib/security';
import { decisionSignature, documentKind } from '../../../lib/kyc';
export const dynamic = 'force-dynamic';
export default async function KycCase({ params, searchParams }: {
 params: Promise<{ id: string }>; searchParams: Promise<{ document?: string; result?: string }>;
}) {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 const { id } = await params, query = await searchParams, client = api(token);
 let me, result;
 try { me = await client.GET('/api/v1/admin/auth/me'); }
 catch { return <p role="alert">KYC service unavailable. Reload to try again.</p>; }
 if (me.response.status === 401) redirect('/login?error=expired');
 if (!me.data?.permissions.includes('kyc.review')) return <p role="alert">You do not have permission to review KYC.</p>;
 try { result = await client.GET('/api/v1/admin/kyc/{id}', { params: { path: { id } } }); }
 catch { return <p role="alert">KYC service unavailable. Reload to try again.</p>; }
 const row = result.data;
 if (!row) return <p role="alert">Case unavailable. <Link className="inline-flex min-h-12 items-center underline" href="/kyc">Return to queue</Link></p>;
 const key = randomUUID(), kind = query.document;
 return <><Link className="inline-flex min-h-12 items-center underline" href="/kyc">KYC queue</Link>
 <h1 className="break-words text-2xl font-semibold">KYC case {row.id}</h1>
 {query.result && <p className="my-4" role="status">{query.result === 'saved' ? 'Decision saved. Vendor status, audit and in-app notification were recorded.' : 'Decision could not be confirmed. Check the current status before retrying; another reviewer may have decided this case.'}</p>}
 <dl className="my-4 space-y-2 break-words">
 {Object.entries({ Vendor: row.vendorId, Status: row.status, 'Verification method': row.verificationMethod,
 'Provider checks': row.providerChecks, 'Submitted (UTC)': row.submittedAt, 'Account holder': row.holderName,
 Bank: row.bankName, IFSC: row.ifsc, 'Account ending': `•••• ${row.accountLast4}`, 'PAN ending': `•••• ${row.panLast4}`,
 'UPI ID': row.upiId ?? 'Not provided', Reviewer: row.reviewerId ?? 'Not reviewed',
 'Reviewed (UTC)': row.reviewedAt ?? 'Not reviewed', Reason: row.reason ?? 'Not reviewed' }).map(([label, value]) =>
 <div key={label}><dt className="font-semibold">{label}</dt><dd>{value}</dd></div>)}
 </dl>
 <h2 className="text-xl font-semibold">Private documents</h2>
 <p className="my-2">Aadhaar must already be masked. Each document view is audited. Manual approval does not represent automated provider verification.</p>
 {me.data.permissions.includes('kyc.documents') ? <>
 <nav aria-label="KYC documents" className="flex flex-wrap gap-4">{([['front', 'Masked Aadhaar front'], ['back', 'Masked Aadhaar back'], ['pan', 'PAN']] as const).map(([value, label]) =>
 <Link prefetch={false} className="inline-flex min-h-12 items-center underline" key={value} href={`/kyc/${id}?document=${value}`}>{label}</Link>)}</nav>
 {kind && documentKind(kind) && <div className="relative my-4 border bg-white">
 <iframe className="h-[36rem] w-full" title={`Private ${kind} document`} src={`/kyc/${id}/documents/${kind}#toolbar=0`} />
 <div aria-hidden="true" className="pointer-events-none absolute inset-0 flex items-center justify-center overflow-hidden"><p className="rotate-[-25deg] break-all bg-white/80 p-4 text-lg font-bold text-slate-700">CONFIDENTIAL · {me.data.id} · {new Date().toISOString()}</p></div>
 </div>}</> : <p>You do not have permission to view private documents.</p>}
 {row.status === 'MANUAL_REVIEW' ? <form className="my-6 space-y-4" action={`/kyc/${id}/decision`} method="post">
 <input type="hidden" name="csrf" value={csrf(token)} /><input type="hidden" name="key" value={key} />
 <input type="hidden" name="signature" value={decisionSignature(token, id, key)} />
 <label className="flex flex-col gap-2">Decision<select className="min-h-12 rounded border p-2" name="decision" required defaultValue=""><option value="" disabled>Select a decision</option><option value="VERIFIED">Approve manual KYC</option><option value="REJECTED">Reject KYC</option></select></label>
 <label className="flex flex-col gap-2">Reason (required for approval or rejection)<textarea className="min-h-24 rounded border p-2" name="reason" required minLength={3} maxLength={500} /></label>
 <p>The decision is final for this submission. Rejection allows a fresh vendor submission. An in-app notice will be recorded; push delivery is not confirmed.</p>
 <button className="min-h-12 rounded bg-slate-800 px-6 text-white">Record decision and notify vendor</button>
 </form> : <p>This submission has been reviewed. No further decision can be recorded.</p>}
 </>;
}
