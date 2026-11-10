import { NextRequest, NextResponse } from 'next/server';
import { api } from '../../../../../lib/api';
import { documentFields, documentKind } from '../../../../../lib/kyc';
export async function GET(request: NextRequest, context: { params: Promise<{ id: string; kind: string }> }): Promise<NextResponse> {
 const token = request.cookies.get('sb_admin')?.value, { id, kind } = await context.params;
 if (!token) return new NextResponse('Sign in to view private documents.', { status: 401 });
 if (!documentKind(kind)) return new NextResponse('Document not found.', { status: 404 });
 try {
  const client = api(token);
  const detail = await client.GET('/api/v1/admin/kyc/{id}', { params: { path: { id } } });
  if (!detail.data) return new NextResponse('Case unavailable.', { status: detail.response.status });
  const result = await client.GET('/api/v1/admin/media/{id}/content', {
   params: { path: { id: detail.data[documentFields[kind]] } }, parseAs: 'arrayBuffer',
  });
  if (!result.data) return new NextResponse('Document unavailable. Return to the case and retry.', { status: result.response.status });
  const mime = result.response.headers.get('content-type')?.split(';')[0] ?? '';
  if (!['image/jpeg', 'image/png', 'application/pdf'].includes(mime)) return new NextResponse('Unsupported document.', { status: 415 });
  return new NextResponse(result.data, { headers: { 'Content-Type': mime, 'Content-Disposition': 'inline',
   'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'SAMEORIGIN',
   'Content-Security-Policy': "default-src 'none'; frame-ancestors 'self'", 'Referrer-Policy': 'no-referrer' } });
 } catch { return new NextResponse('Document service unavailable. Return to the case and retry.', { status: 503 }); }
}
