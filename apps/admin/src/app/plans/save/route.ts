import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../lib/api';
import { adminOrigin, cookieOptions, validCsrf } from '../../../lib/security';
import { istTimestamp, packPlanRetry, paise, uuid, validPlanKey } from '../../../lib/plans';
import type { components } from '../../../../../../packages/ts-client/src/generated/openapi';
export async function POST(request: NextRequest): Promise<NextResponse> {
 const origin = adminOrigin(), token = request.cookies.get('sb_admin')?.value;
 if (!token) return new NextResponse('Sign in to manage plans.', { status: 401 });
 const failure = (message: string, _status: number, fields: Record<string, string>, back: string, retry: boolean) => {
  const response = NextResponse.redirect(new URL('/plans/retry', origin), 303);
  response.cookies.set('sb_plan_retry', packPlanRetry(token, { message, fields, back, retry }), { ...cookieOptions(), path: '/plans', maxAge: 600 });
  response.headers.set('Cache-Control', 'no-store');
  return response;
 };
 if (request.headers.get('origin') !== origin) return new NextResponse('Invalid request origin.', { status: 403 });
 const form = await request.formData();
 const names = ['action', 'csrf', 'key', 'signature', 'planId', 'vendorId', 'assignmentId', 'expectedUpdatedAt', 'name', 'status', 'isPopular', 'MONTHLY', 'HALF_YEARLY', 'YEARLY', 'reason', 'startsAt', 'endsAt'];
 const fields = Object.fromEntries(names.filter(n => form.has(n)).map(n => [n, String(form.get(n))]));
 if (Object.values(fields).some(value => value.length > 1000)) return new NextResponse('Invalid plan field length.', { status: 400 });
 if (!validCsrf(fields.csrf ?? '', token)) return new NextResponse('Expired form. Reload plan administration.', { status: 403 });
 const { action, planId = '', vendorId = '', assignmentId = '', key = '', signature = '' } = fields;
 if (!['catalog', 'assign', 'extend'].includes(action) || (action === 'catalog' || action === 'assign') && !uuid(planId) || action !== 'catalog' && !uuid(vendorId) || action === 'extend' && !uuid(assignmentId)) return new NextResponse('Invalid plan form.', { status: 400 });
 const scope = action === 'catalog' ? `catalog:${planId}` : action === 'assign' ? `assign:${vendorId}` : `extend:${vendorId}:${assignmentId}`;
 if (!validPlanKey(token, scope, key, signature)) return new NextResponse('Invalid or changed plan form. Reload plan administration.', { status: 400 });
 const back = action === 'catalog' ? '/plans' : `/plans/vendors/${vendorId}`;
 const header = { 'Idempotency-Key': key, 'X-CSRF-Token': request.cookies.get('sb_csrf')?.value ?? '' }, client = api(token);
 try {
  let result;
  if (action === 'catalog') {
   const status = fields.status;
   if (status !== 'ACTIVE' && status !== 'INACTIVE') return failure('Choose valid catalog availability.', 400, fields, back, false);
   const prices = (['MONTHLY', 'HALF_YEARLY', 'YEARLY'] as const).map(duration => ({ duration, pricePaise: paise(fields[duration] ?? '') }));
   if (prices.some(p => p.pricePaise === null)) return failure('Enter non-negative rupee prices with at most two decimal places.', 400, fields, back, false);
   const body: components['schemas']['CatalogPlanInput'] = { name: fields.name ?? '', status, isPopular: fields.isPopular === 'on', expectedUpdatedAt: fields.expectedUpdatedAt ?? '', reason: fields.reason ?? '', prices: prices.map(p => ({ duration: p.duration, pricePaise: p.pricePaise! })) };
   result = await client.PUT('/api/v1/admin/plans/{id}', { params: { path: { id: planId }, header }, body });
  } else {
   const endsAt = istTimestamp(fields.endsAt ?? ''), startsAt = istTimestamp(fields.startsAt ?? '');
   if (!endsAt || action === 'assign' && !startsAt) return failure('Enter complete start/end dates in IST.', 400, fields, back, false);
   result = action === 'assign'
    ? await client.POST('/api/v1/admin/vendors/{id}/plan-assignments', { params: { path: { id: vendorId }, header }, body: { planId, startsAt: startsAt!, endsAt, reason: fields.reason ?? '' } })
    : await client.POST('/api/v1/admin/vendors/{id}/plan-assignments/{assignmentId}/extend', { params: { path: { id: vendorId, assignmentId }, header }, body: { endsAt, reason: fields.reason ?? '' } });
  }
  if (result.response.status === 401) return NextResponse.redirect(new URL('/login?error=expired', origin), 303);
  if (result.data) {
   const response = NextResponse.redirect(new URL(`${back}?result=saved`, origin), 303);
   response.cookies.set('sb_plan_retry', '', { ...cookieOptions(), path: '/plans', maxAge: 0 });
   return response;
  }
  const status = result.response.status;
  return failure(status === 409 ? 'The catalog changed or the plan is unavailable. Reload and review the current values.' : status === 403 ? 'Permission or session security changed. Reload and sign in again if needed.' : status === 404 ? 'This vendor or assignment is no longer available. Reload the current assignment.' : status >= 500 ? 'Could not confirm whether this request saved. Retry this same request safely.' : 'Check the dates, reason and fields. End must be later than start/current end and the current time. Reload to correct the form.', status, fields, back, status >= 500 || status === 429);
 } catch { return failure('Connection unavailable. This request may already have saved. Retry this same request safely.', 503, fields, back, true); }
}
