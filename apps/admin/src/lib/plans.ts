import { createHmac, timingSafeEqual } from 'node:crypto';
export const uuid = (value: string) => /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(value);
export function planSignature(session: string, scope: string, key: string) {
 return createHmac('sha256', session).update(`plans:${scope}:${key}`).digest('hex');
}
export function validPlanKey(session: string, scope: string, key: string, signature: string) {
 return uuid(key) && /^[a-f0-9]{64}$/.test(signature) && timingSafeEqual(Buffer.from(signature), Buffer.from(planSignature(session, scope, key)));
}
export function paise(value: string): number | null {
 if (!/^\d{1,13}(?:\.\d{1,2})?$/.test(value)) return null;
 const [whole, fraction = ''] = value.split('.');
 const amount = BigInt(whole) * 100n + BigInt(fraction.padEnd(2, '0'));
 return amount <= BigInt(Number.MAX_SAFE_INTEGER) ? Number(amount) : null;
}
export function rupees(value: number) { const amount = BigInt(value); return `${amount / 100n}.${String(amount % 100n).padStart(2, '0')}`; }
export function istInput(value: string) { return new Date(new Date(value).getTime() + 19800000).toISOString().slice(0, 16); }
export function istTimestamp(value: string): string | null {
 return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value) ? `${value}:00+05:30` : null;
}
export function pageOffset(value?: string) { return value && /^\d+$/.test(value) && Number(value) <= 1000000 ? Number(value) : 0; }
export type PlanRetry = { message: string; fields: Record<string, string>; back: string; retry: boolean };
export function packPlanRetry(session: string, value: PlanRetry) {
 const body = Buffer.from(JSON.stringify(value)).toString('base64url');
 return `${body}.${planSignature(session, 'retry', body)}`;
}
export function readPlanRetry(session: string, value: string): PlanRetry | null {
 const [body, signature = ''] = value.split('.');
 if (!body || !/^[a-f0-9]{64}$/.test(signature) || !timingSafeEqual(Buffer.from(signature), Buffer.from(planSignature(session, 'retry', body)))) return null;
 try {
  const result: unknown = JSON.parse(Buffer.from(body, 'base64url').toString());
  if (!result || typeof result !== 'object' || !('message' in result) || !('fields' in result) || !('back' in result) || !('retry' in result)) return null;
  if (typeof result.message !== 'string' || typeof result.back !== 'string' || !/^\/plans(?:\/vendors\/[a-f0-9-]{36})?$/.test(result.back) || typeof result.retry !== 'boolean' ||
   !result.fields || typeof result.fields !== 'object' || Array.isArray(result.fields) || !Object.values(result.fields).every(v => typeof v === 'string')) return null;
  return result as PlanRetry;
 } catch { return null; }
}
