import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../../lib/api';
import { adminOrigin, validCsrf } from '../../../../lib/security';
import { validDecisionKey } from '../../../../lib/kyc';
export async function POST(request: NextRequest, context: { params: Promise<{ id: string }> }): Promise<NextResponse> {
 const origin = adminOrigin(), { id } = await context.params;
 const token = request.cookies.get('sb_admin')?.value;
 if (!token) return new NextResponse('Sign in to review KYC.', { status: 401 });
 if (request.headers.get('origin') !== origin) return new NextResponse('Invalid request origin.', { status: 403 });
 const form = await request.formData(), key = String(form.get('key') ?? '');
 if (!validCsrf(String(form.get('csrf') ?? ''), token) || !validDecisionKey(token, id, key, String(form.get('signature') ?? ''))) {
  return new NextResponse('Invalid or expired form. Reload the case.', { status: 403 });
 }
 const decision = String(form.get('decision') ?? ''), reason = String(form.get('reason') ?? '').trim();
 if (!['VERIFIED', 'REJECTED'].includes(decision) || reason.length < 3 || reason.length > 500) return new NextResponse('Select a decision and provide a reason of 3–500 characters.', { status: 400 });
 let saved = false;
 try {
  const result = await api(token).POST('/api/v1/admin/kyc/{id}/decision', { params: { path: { id }, header: {
   'Idempotency-Key': key, 'X-CSRF-Token': request.cookies.get('sb_csrf')?.value ?? '',
  } }, body: { decision: decision as 'VERIFIED' | 'REJECTED', reason } });
  if (result.response.status === 401) return NextResponse.redirect(new URL('/login?error=expired', origin), 303);
  saved = !!result.data;
 } catch { /* The request may have committed; reload persisted state before retrying. */ }
 return NextResponse.redirect(new URL(`/kyc/${encodeURIComponent(id)}?result=${saved ? 'saved' : 'failed'}`, origin), 303);
}
