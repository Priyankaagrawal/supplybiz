import { createHmac, timingSafeEqual } from 'node:crypto';
export const managementKey = (session: string, scope: string, key: string) => createHmac('sha256', session).update(`management:${scope}:${key}`).digest('hex');
export function validManagementKey(session: string, scope: string, key: string, signature: string) {
 return /^[a-f0-9-]{36}$/i.test(key) && /^[a-f0-9]{64}$/.test(signature) && timingSafeEqual(Buffer.from(signature), Buffer.from(managementKey(session, scope, key)));
}
export type ManagementRecovery = { message: string; back: string; retry: boolean; fields: Record<string, string> };
export function packManagementRecovery(session: string, state: ManagementRecovery) {
 const body = Buffer.from(JSON.stringify(state)).toString('base64url'); return `${body}.${managementKey(session, 'recovery', body)}`;
}
export function readManagementRecovery(session: string, value: string): ManagementRecovery | null {
 const [body, signature = ''] = value.split('.');
 if (!body || !/^[a-f0-9]{64}$/.test(signature) || !timingSafeEqual(Buffer.from(signature), Buffer.from(managementKey(session, 'recovery', body)))) return null;
 try {
  const state: unknown = JSON.parse(Buffer.from(body, 'base64url').toString());
  if (!state || typeof state !== 'object' || !('message' in state) || !('back' in state) || !('retry' in state) || !('fields' in state)) return null;
  if (typeof state.message !== 'string' || typeof state.retry !== 'boolean' || typeof state.back !== 'string' || !/^\/(?:vendors|customers)\/[a-f0-9-]{36}$/i.test(state.back) ||
   !state.fields || typeof state.fields !== 'object' || Array.isArray(state.fields) || !Object.values(state.fields).every(v => typeof v === 'string')) return null;
  return state as ManagementRecovery;
 } catch { return null; }
}
