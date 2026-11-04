import 'server-only';
import createClient from 'openapi-fetch';
import type { paths } from '../../../../packages/ts-client/src/generated/openapi';
export function api(token?: string) {
 const baseUrl = process.env.ADMIN_API_URL ?? 'http://127.0.0.1:3000';
 const url = new URL(baseUrl);
 if (url.protocol !== 'https:' && !['127.0.0.1', 'localhost'].includes(url.hostname)) throw new Error('API requires HTTPS');
 return createClient<paths>({ baseUrl, cache: 'no-store', headers: token ? { Authorization: `Bearer ${token}` } : {},
   fetch: request => fetch(request, { signal: AbortSignal.timeout(10000), cache: 'no-store' }) });
}
