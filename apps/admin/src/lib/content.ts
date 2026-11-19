import { createHmac, timingSafeEqual } from 'node:crypto';
export function contentSignature(token: string, scope: string, key: string): string {
 return createHmac('sha256', token).update(`content:${scope}:${key}`).digest('hex');
}
export function validContentKey(token: string, scope: string, key: string, signature: string): boolean {
 return /^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/.test(key) && /^[a-f0-9]{64}$/.test(signature)
  && timingSafeEqual(Buffer.from(signature), Buffer.from(contentSignature(token, scope, key)));
}
