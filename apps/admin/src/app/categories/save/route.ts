import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../lib/api';
import { adminOrigin, validCsrf } from '../../../lib/security';
import type { components } from '../../../../../../packages/ts-client/src/generated/openapi';
export async function POST(request: NextRequest): Promise<NextResponse> {
 const origin = adminOrigin(), token = request.cookies.get('sb_admin')?.value;
 if (!token) return new NextResponse('Sign in to manage categories.', { status: 401 });
 if (request.headers.get('origin') !== origin) return new NextResponse('Invalid request origin.', { status: 403 });
 const form = await request.formData();
 if (!validCsrf(String(form.get('csrf') ?? ''), token)) return new NextResponse('Expired form. Return to categories and reload.', { status: 403 });
 const key = String(form.get('key') ?? ''), id = String(form.get('id') ?? '');
 if (!/^[a-f0-9-]{36}$/.test(key) || (id && !/^[a-f0-9-]{36}$/.test(id))) return new NextResponse('Invalid category form.', { status: 400 });
 const type = String(form.get('type')), status = String(form.get('status'));
 if ((type !== 'SUPPLY' && type !== 'BILL') || (status !== 'ENABLED' && status !== 'COMING_SOON' && status !== 'HIDDEN')) return new NextResponse('Invalid type or availability.', { status: 400 });
 const body: components['schemas']['CategoryInput'] = { code: String(form.get('code') ?? ''), name: String(form.get('name') ?? ''), icon: String(form.get('icon') ?? ''), type, status,
  sortOrder: Number(form.get('sortOrder')), productTypes: String(form.get('productTypes') ?? '').split(/\r?\n/).map(value => value.trim()).filter(Boolean) };
 const header = { 'Idempotency-Key': key, 'X-CSRF-Token': request.cookies.get('sb_csrf')?.value ?? '' };
 try {
  const result = id ? await api(token).PUT('/api/v1/admin/categories/{id}', { params: { path: { id }, header }, body })
   : await api(token).POST('/api/v1/admin/categories', { params: { header }, body });
  if (result.response.status === 401) return NextResponse.redirect(new URL('/login?error=expired', origin), 303);
  if (result.data) return NextResponse.redirect(new URL('/categories?result=saved', origin), 303);
  return new NextResponse(result.response.status === 409 ? 'Code already exists or category type is used by vendors. Go back to correct the form.'
   : 'Category could not be saved. Check your permission and fields, then go back to correct the form.', { status: result.response.status });
 } catch { return new NextResponse('Service unavailable. Go back and retry the same form; your request may already have saved.', { status: 503 }); }
}
