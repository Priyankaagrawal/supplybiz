import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../lib/api';
import { adminOrigin, cookieOptions, validCsrf } from '../../../lib/security';
import { packManagementRecovery, validManagementKey } from '../../../lib/management';
import { uuid } from '../../../lib/plans';
export async function POST(request: NextRequest): Promise<NextResponse> {
 const origin = adminOrigin(), token = request.cookies.get('sb_admin')?.value;
 if (!token) return new NextResponse('Sign in to manage accounts.', { status: 401 });
 if (request.headers.get('origin') !== origin) return new NextResponse('Invalid request origin.', { status: 403 });
 const form = await request.formData(), names = ['csrf', 'key', 'signature', 'kind', 'id', 'action', 'expectedUpdatedAt', 'reason', 'badges', 'confirm'];
 const fields = Object.fromEntries(names.filter(name => form.has(name)).map(name => [name, String(form.get(name))]));
 if (Object.values(fields).some(value => value.length > 1000)) return new NextResponse('Invalid field length.', { status: 400 });
 if (!validCsrf(fields.csrf ?? '', token)) return new NextResponse('Expired form. Reload the account detail.', { status: 403 });
 const { kind, id = '', action, key = '', signature = '' } = fields;
 if (!uuid(id) || !(['vendors', 'customers'].includes(kind)) || !(kind === 'vendors' ? ['suspend', 'reinstate', 'badges'] : ['block', 'unblock']).includes(action) ||
  !validManagementKey(token, `${kind}:${id}:${action}`, key, signature)) return new NextResponse('Invalid or changed management form.', { status: 400 });
 if (['suspend', 'block'].includes(action) && fields.confirm !== 'on') return new NextResponse('Confirm this status change before submitting.', { status: 400 });
 const back = `/${kind}/${id}`, client = api(token), header = { 'Idempotency-Key': key, 'X-CSRF-Token': request.cookies.get('sb_csrf')?.value ?? '' };
 const body = { reason: fields.reason ?? '', expectedUpdatedAt: fields.expectedUpdatedAt ?? '' };
 const recover = (message: string, retry: boolean) => {
  const response = NextResponse.redirect(new URL('/management/retry', origin), 303);
  response.cookies.set('sb_management_retry', packManagementRecovery(token, { message, retry, fields, back }), { ...cookieOptions(), path: '/management', maxAge: 600 });
  response.headers.set('Cache-Control', 'no-store'); return response;
 };
 try {
  let result;
  if (action === 'badges') result = await client.PATCH('/api/v1/admin/vendors/{id}', { params: { path: { id }, header }, body: { ...body, badges: (fields.badges ?? '').split(/\r?\n/).map(s => s.trim()).filter(Boolean) } });
  else if (action === 'suspend') result = await client.POST('/api/v1/admin/vendors/{id}/suspend', { params: { path: { id }, header }, body });
  else if (action === 'reinstate') result = await client.POST('/api/v1/admin/vendors/{id}/reinstate', { params: { path: { id }, header }, body });
  else if (action === 'block') result = await client.POST('/api/v1/admin/customers/{id}/block', { params: { path: { id }, header }, body });
  else result = await client.POST('/api/v1/admin/customers/{id}/unblock', { params: { path: { id }, header }, body });
  if (result.response.status === 401) return NextResponse.redirect(new URL('/login?error=expired', origin), 303);
  if (result.data) { const response = NextResponse.redirect(new URL(`${back}?result=saved`, origin), 303); response.cookies.set('sb_management_retry', '', { ...cookieOptions(), path: '/management', maxAge: 0 }); return response; }
  const status = result.response.status;
  return recover(status === 409 ? 'This record changed or is deleted. Reload and review the current state before acting.' : status === 403 ? 'You no longer have permission for this action. Reload or sign in again.' : status >= 500 ? 'Could not confirm whether the change saved. Retry this same request safely.' : 'Check the reason, badges and current record, then reload to correct the form.', status >= 500 || status === 429);
 } catch { return recover('Connection unavailable. The change may already have saved. Retry this same request safely.', true); }
}
