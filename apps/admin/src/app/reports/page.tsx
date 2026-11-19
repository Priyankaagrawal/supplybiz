import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { api } from '../../lib/api';
import { Fields } from '../admin-operation-fields';
import AdminOperationForm from '../admin-operation-form';
export const dynamic='force-dynamic';
export default async function Reports() {
 const token=(await cookies()).get('sb_admin')?.value;if(!token)redirect('/login');
 try {
  const {data}=await api(token).GET('/api/v1/admin/auth/me');if(!data)redirect('/login?error=expired');
  if(!data.permissions.includes('reports.export'))return <p role="alert">Access denied.</p>;
  return <><a className="inline-flex min-h-12 items-center underline" href="/">Workspace</a><h1 className="text-2xl font-semibold">Platform CSV export</h1>
   <p>Aggregate snapshot of current accounts and KYC, retained order and POS totals, and manual plan assignments. Gross sales include delivered orders and POS sales, in exact integer paise. Gross sales are not payment receipts. Plan revenue is unavailable. No customer or KYC personal data is included.</p>
   <AdminOperationForm report><Fields token={token} action="export"/><p>The snapshot is created when you download. Retries preserve it for 24 hours; reload to request a fresh snapshot.</p></AdminOperationForm></>;
 }catch(error){if(error instanceof Error&&error.message.startsWith('NEXT_REDIRECT'))throw error;return <p role="alert">Service unavailable. Reload to retry.</p>;}
}
