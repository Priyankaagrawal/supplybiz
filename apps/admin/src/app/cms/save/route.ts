import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../lib/api';
import { adminOrigin, validCsrf } from '../../../lib/security';
import { validContentKey } from '../../../lib/content';
export async function POST(request: NextRequest): Promise<NextResponse> {
 const token = request.cookies.get('sb_admin')?.value;
 const fail = (status: number) => NextResponse.json({ saved: false }, { status, headers: { 'Cache-Control': 'no-store' } });
 if (!token) return fail(401);
 if (request.headers.get('origin') !== adminOrigin()) return fail(403);
 if (Number(request.headers.get('content-length') ?? 0) > 120000) return fail(413);
 let form: FormData;
 try { form = await request.formData(); } catch { return fail(400); }
 const field = (name: string) => String(form.get(name) ?? '');
 if ([...form.values()].some(v => typeof v !== 'string' || v.length > 50000)) return fail(400);
 if (!validCsrf(field('csrf'),token)) return fail(403);
 const action = field('action'), id = field('id'), key = field('key');
 if (!validContentKey(token,`${action}:${id}`,key,field('signature'))) return fail(400);
 const header = { 'Idempotency-Key': key, 'X-CSRF-Token': request.cookies.get('sb_csrf')?.value ?? '' }, client = api(token);
 try {
  let result;
  if (action === 'faq' && /^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/.test(id)) {
   result = await client.PUT('/api/v1/admin/faqs/{id}', { params: { path: { id }, header }, body: { expectedUpdatedAt: field('expectedUpdatedAt') || null, topic: field('topic'), question: field('question'), answer: field('answer'), published: field('published') === 'on' } });
  } else if (action === 'legal' && (id === 'TERMS' || id === 'PRIVACY') && field('confirm') === 'on') {
   result = await client.PUT('/api/v1/admin/legal/{type}', { params: { path: { type: id }, header }, body: { expectedVersion: field('expectedVersion') || null, version: field('version'), title: field('title'), text: field('text') } });
  } else if (action === 'config' && id === 'mobile' && field('confirm') === 'on') {
   let flags: unknown;
   try { flags = JSON.parse(field('flags')); } catch { return fail(400); }
   if (!flags || typeof flags !== 'object' || Array.isArray(flags) || Object.keys(flags).length > 50 || !Object.values(flags).every(v => typeof v === 'boolean')) return fail(400);
   result = await client.PUT('/api/v1/admin/config', { params: { header }, body: { expectedUpdatedAt: field('expectedUpdatedAt') || null, minVersionAndroid: field('minVersionAndroid'), flags: flags as Record<string,boolean> } });
  } else return fail(400);
  return result.data ? NextResponse.json({ saved: true }, { headers: { 'Cache-Control': 'no-store' } }) : fail(result.response.status);
 } catch { return fail(503); }
}
