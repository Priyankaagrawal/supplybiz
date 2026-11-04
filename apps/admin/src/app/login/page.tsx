// S-A-01: password stage. Server-rendered; credentials never enter client state.
import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { csrf } from '../../lib/security';
import { api } from '../../lib/api';
export const dynamic = 'force-dynamic';
export default async function Login({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
 const jar = await cookies();
 const token = jar.get('sb_admin')?.value;
 if (token) { const { data } = await api(token).GET('/api/v1/admin/auth/me').catch(() => ({ data: undefined })); if (data) redirect('/'); }
 const error = (await searchParams).error;
 return <section className="mx-auto max-w-md rounded-xl border bg-white p-6 shadow-sm">
 <h1 className="text-2xl font-semibold">Supply Biz Admin</h1><p className="my-4">Sign in with your staff account. An authenticator code is required next.</p>
 {error && <p role="alert" className="mb-4 text-red-800">Sign in failed. Check your details or try again later.</p>}
 <form action="/auth/login" method="post" className="space-y-4">
 <input type="hidden" name="csrf" value={csrf('login')} />
 <label className="block">Email<input name="email" type="email" autoComplete="username" required maxLength={254} className="mt-1 min-h-12 w-full rounded border p-3" /></label>
 <label className="block">Password<input name="password" type="password" autoComplete="current-password" required minLength={12} maxLength={128} className="mt-1 min-h-12 w-full rounded border p-3" /></label>
 <button className="min-h-12 rounded bg-blue-800 px-6 text-white">Continue</button></form></section>;
}
