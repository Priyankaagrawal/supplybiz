import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { api } from '../../lib/api';
import { dashboardMoney, deliverySuccess } from '../../lib/dashboard';
export const dynamic = 'force-dynamic';
export default async function Dashboard() {
 const token = (await cookies()).get('sb_admin')?.value;
 if (!token) redirect('/login');
 let result;
 try { result = await api(token).GET('/api/v1/admin/dashboard'); }
 catch { return <Unavailable />; }
 if (result.response.status === 401) redirect('/login?error=expired');
 if (result.response.status === 403) return <><h1 className="text-2xl font-semibold">Dashboard access denied</h1><p role="alert">Your account does not have dashboard permission.</p><a className="inline-flex min-h-12 items-center underline" href="/">Back to workspace</a></>;
 const data = result.data;
 if (!data) return <Unavailable />;
 const metrics = [
  ['Vendor records', String(data.vendorsTotal)], ['Suspended vendors', String(data.vendorsSuspended)],
  ['KYC awaiting manual review', String(data.kycPending)], ['KYC verified vendors', String(data.kycVerified)],
  ['Customer accounts', String(data.customersTotal)], ['Blocked customer accounts', String(data.customersBlocked)],
  ['Recorded orders', String(data.ordersTotal)], ['Delivered orders', String(data.ordersDelivered)], ['Failed orders', String(data.ordersFailed)],
  ['Recorded delivered order value (GMV component)', dashboardMoney(data.recordedGmvPaise)],
  ['Delivery success', deliverySuccess(data.ordersDelivered, data.ordersFailed)],
  ['Audited plan grants', String(data.planAssignmentsTotal)],
 ];
 return <><h1 className="text-2xl font-semibold">Dashboard</h1>
  <p className="my-4">All-time persisted records. Updated {new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Kolkata' }).format(new Date(data.serverTime))} IST.</p>
  <nav aria-label="Dashboard navigation" className="flex flex-wrap gap-6"><a className="inline-flex min-h-12 items-center underline" href="/">Back to workspace</a><a className="inline-flex min-h-12 items-center underline" href="/dashboard">Refresh dashboard</a></nav>
  <dl className="my-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">{metrics.map(([label,value]) => <div className="min-w-0 rounded border p-4" key={label}><dt className="font-medium">{label}</dt><dd className="mt-2 break-words text-2xl" data-metric={label}>{value}</dd></div>)}</dl>
  <section aria-labelledby="metric-definitions"><h2 id="metric-definitions" className="text-xl font-semibold">Metric definitions</h2>
   <p className="my-3">The delivered-order GMV component sums stored totals of DELIVERED orders, including delivery charges and discounts. It is recorded order value, not money received or platform revenue. Pending, cancelled, rejected and failed orders are excluded. Full platform GMV also includes quick sales. That component is unavailable until quick-sale records are available; this value is not full platform GMV.</p>
   <p className="my-3">Delivery success is delivered orders divided by delivered plus failed orders. In-progress, cancelled and rejected orders are excluded.</p>
   <p className="my-3">Customer accounts have the CUSTOMER role, including blocked and deleted accounts; vendor customer links are not counted as accounts. Vendor and order history is retained. Audited plan grants include historical and superseded assignments, not purchases.</p>
  </section>
  <section aria-labelledby="plan-revenue"><h2 id="plan-revenue" className="text-xl font-semibold">Automated plan revenue</h2><p className="my-3">Unavailable: automated plan billing is not implemented. Plan grants are never counted as paid revenue.</p></section>
 </>;
}
function Unavailable() { return <><h1 className="text-2xl font-semibold">Dashboard</h1><p role="alert" className="my-4">Dashboard data is unavailable. No metrics are shown.</p><a className="inline-flex min-h-12 items-center underline" href="/dashboard">Retry dashboard</a><a className="mx-6 inline-flex min-h-12 items-center underline" href="/">Back to workspace</a></>; }
