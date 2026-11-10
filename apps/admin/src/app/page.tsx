import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { api } from '../lib/api';
import { csrf } from '../lib/security';
export const dynamic = 'force-dynamic';
const labels: Record<string, string> = { 'dashboard.read': 'Dashboard', 'admins.manage': 'Admin accounts and permissions', 'config.manage': 'App configuration', 'audit.read': 'Audit logs', 'privacy.manage': 'Privacy requests', 'kyc.review': 'Manual KYC review', 'kyc.documents': 'Private KYC documents', 'vendors.read': 'View vendors', 'vendors.manage': 'Manage vendors', 'customers.read': 'View customers', 'customers.manage': 'Manage customers', 'orders.read': 'View orders', 'categories.manage': 'Categories', 'cms.manage': 'Help and legal content', 'plans.manage': 'Plans and assignments', 'reports.read': 'Reports', 'reports.export': 'Report CSV export' };
export default async function Home() {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 let data;
 try { data = (await api(token).GET('/api/v1/admin/auth/me')).data; } catch { return <p role="alert">Service unavailable. Reload to try again.</p>; }
 if (!data) redirect('/login?error=expired');
 return <><h1 className="text-2xl font-semibold">Admin workspace</h1><p className="my-4">Signed in as {data.role}. Sessions end after 30 minutes of inactivity or eight hours.</p>
 {data.permissions.includes('audit.read') && <a className="inline-flex min-h-12 items-center underline" href="/audit-logs">Open audit log</a>}
 {data.permissions.includes('kyc.review') && <a className="mx-4 inline-flex min-h-12 items-center underline" href="/kyc">Open manual KYC queue</a>}
 {data.permissions.includes('categories.manage') && <a className="inline-flex min-h-12 items-center underline" href="/categories">Manage categories</a>}
 <h2 className="text-xl font-semibold">Your account permissions</h2><ul className="my-4 list-inside list-disc">{data.permissions.map(permission => <li key={permission}>{labels[permission]}</li>)}</ul>
 <form action="/auth/logout" method="post"><input type="hidden" name="csrf" value={csrf(token)} /><button className="min-h-12 rounded bg-slate-800 px-6 text-white">Sign out</button></form></>;
}
