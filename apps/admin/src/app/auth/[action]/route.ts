import { NextRequest, NextResponse } from 'next/server';
import { randomUUID } from 'node:crypto';
import { api } from '../../../lib/api';
import { adminOrigin, cookieOptions, validCsrf } from '../../../lib/security';
export async function POST(request: NextRequest, context: { params: Promise<{ action: string }> }): Promise<NextResponse> {
 const { action } = await context.params;
 if (!['login', 'verify', 'logout'].includes(action)) return new NextResponse(null, { status: 404 });
 const origin = adminOrigin();
 if (request.headers.get('origin') !== origin) return new NextResponse('Invalid request origin.', { status: 403 });
 const pending = request.cookies.get('sb_pending')?.value ?? '';
 const session = request.cookies.get('sb_admin')?.value ?? '';
 const credential = action === 'login' ? 'login' : action === 'verify' ? pending : session;
 const form = await request.formData();
 if (!validCsrf(String(form.get('csrf') ?? ''), credential)) return new NextResponse('Invalid or expired form. Reload and try again.', { status: 403 });
 const redirect = (path: string) => NextResponse.redirect(new URL(path, origin), 303);
 const headers = { 'Idempotency-Key': randomUUID() };
 try {
   if (action === 'login') {
     const { data } = await api().POST('/api/v1/admin/auth/login', { body: {
       email: String(form.get('email') ?? ''), password: String(form.get('password') ?? '') }, params: { header: headers } });
     if (!data) return redirect('/login?error=failed');
     const response = redirect('/totp');
     response.cookies.set('sb_pending', data.challengeToken, { ...cookieOptions(), maxAge: 300 });
     return response;
   }
   if (action === 'verify') {
     const { data } = await api().POST('/api/v1/admin/auth/totp/verify', { body: {
       challengeToken: pending, code: String(form.get('code') ?? '') }, params: { header: headers } });
     if (!data) return redirect('/totp?error=failed');
     const response = redirect('/');
     response.cookies.set('sb_admin', data.sessionToken, { ...cookieOptions(), maxAge: 8 * 3600 });
     response.cookies.set('sb_csrf', data.csrfToken, { ...cookieOptions(), maxAge: 8 * 3600 });
     response.cookies.set('sb_pending', '', { ...cookieOptions(), maxAge: 0 });
     return response;
   }
   const result = await api(session).POST('/api/v1/admin/auth/logout', { params: { header: {
     ...headers, 'X-CSRF-Token': request.cookies.get('sb_csrf')?.value ?? '' } } });
   if (result.response.status !== 204 && result.response.status !== 401) return new NextResponse('Sign out unavailable. Try again.', { status: 503 });
   const response = redirect('/login');
   for (const name of ['sb_admin', 'sb_csrf', 'sb_pending']) response.cookies.set(name, '', { ...cookieOptions(), maxAge: 0 });
   return response;
 } catch { return new NextResponse('Admin service unavailable. Reload and try again.', { status: 503 }); }
}
