import { createHmac, timingSafeEqual } from 'node:crypto';
export function adminOrigin(): string {
 const origin = process.env.ADMIN_ORIGIN ?? 'http://127.0.0.1:3100';
 const url = new URL(origin);
 if (url.origin !== origin || (url.protocol !== 'https:' && !['127.0.0.1', 'localhost'].includes(url.hostname))) throw new Error('Invalid admin origin');
 return origin;
}
function key(): string {
 const value = process.env.ADMIN_CSRF_KEY;
 if (!value || value.length < 32) throw new Error('Configure ADMIN_CSRF_KEY (at least 32 random characters)');
 return value;
}
export function csrf(credential: string, now = Date.now()): string {
 const expires = String(now + 30 * 60000);
 return `${expires}.${createHmac('sha256', key()).update(`${expires}:${credential}`).digest('hex')}`;
}
export function validCsrf(value: string, credential: string, now = Date.now()): boolean {
 if (!/^\d{13}\.[a-f0-9]{64}$/.test(value)) return false;
 const [expires, signature] = value.split('.');
 if (Number(expires) <= now || Number(expires) > now + 30 * 60000) return false;
 const expected = createHmac('sha256', key()).update(`${expires}:${credential}`).digest('hex');
 return timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}
export const cookieOptions = () => ({ httpOnly: true, secure: new URL(adminOrigin()).protocol === 'https:', sameSite: 'strict' as const, path: '/' });
