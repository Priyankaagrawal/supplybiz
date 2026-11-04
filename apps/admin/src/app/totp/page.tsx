// S-A-01: enrolment and mandatory TOTP. No session exists before verification.
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { api } from '../../lib/api';
import { csrf } from '../../lib/security';
export const dynamic = 'force-dynamic';
export default async function Totp({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
 const token = (await cookies()).get('sb_pending')?.value;
 if (!token) redirect('/login');
 let data;
 try { data = (await api(token).GET('/api/v1/admin/auth/challenge')).data; } catch { return <p role="alert">Service unavailable. <a href="/login" className="underline">Return to sign in</a></p>; }
 if (!data) redirect('/login?error=expired');
 return <section className="mx-auto max-w-md rounded-xl border bg-white p-6">
 <h1 className="text-2xl font-semibold">{data.enrollmentSecret ? 'Set up your authenticator' : 'Authenticator code'}</h1>
 {data.enrollmentSecret && <><p className="my-4">Add a time-based account named Supply Biz in your authenticator. Enter this setup key, then the six-digit code. Keep the key private.</p><code className="block break-all rounded bg-slate-100 p-4">{data.enrollmentSecret}</code></>}
 {(await searchParams).error && <p role="alert" className="my-4 text-red-800">Code rejected. Try a fresh code. After five failures, sign in is locked for 30 minutes.</p>}
 <form action="/auth/verify" method="post" className="mt-4 space-y-4"><input type="hidden" name="csrf" value={csrf(token)} />
 <label className="block">Six-digit code<input name="code" inputMode="numeric" pattern="[0-9]{6}" autoComplete="one-time-code" required minLength={6} maxLength={6} className="mt-1 min-h-12 w-full rounded border p-3" /></label>
 <button className="min-h-12 rounded bg-blue-800 px-6 text-white">Verify and sign in</button></form><a href="/login" className="mt-4 inline-block min-h-12 py-3 underline">Start again</a></section>;
}
