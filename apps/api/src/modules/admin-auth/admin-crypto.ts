import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
export const digest = (value: string): string => createHash('sha256').update(value).digest('hex');
export const opaque = (): string => randomBytes(32).toString('base64url');
const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
export function base32(bytes: Buffer): string {
  let bits = 0, value = 0, result = '';
  for (const byte of bytes) {
    value = (value << 8) | byte; bits += 8;
    while (bits >= 5) { result += alphabet[(value >>> (bits - 5)) & 31]; bits -= 5; }
  }
  if (bits) result += alphabet[(value << (5 - bits)) & 31];
  return result;
}
function decode(value: string): Buffer {
  let bits = 0, buffer = 0; const result: number[] = [];
  for (const char of value) {
    const digit = alphabet.indexOf(char); if (digit < 0) throw new Error('Invalid TOTP secret');
    buffer = (buffer << 5) | digit; bits += 5;
    if (bits >= 8) { result.push((buffer >>> (bits - 8)) & 255); bits -= 8; }
  }
  return Buffer.from(result);
}
export function totp(secret: string, step: number): string {
  const counter = Buffer.alloc(8); counter.writeBigUInt64BE(BigInt(step));
  const mac = createHmac('sha1', decode(secret)).update(counter).digest();
  const offset = mac[19] & 15;
  return ((mac.readUInt32BE(offset) & 0x7fffffff) % 1000000).toString().padStart(6, '0');
}
export function totpStep(secret: string, code: string, now: number, last: bigint): number | undefined {
  if (!/^\d{6}$/.test(code)) return;
  const current = Math.floor(now / 30000);
  for (const step of [current, current - 1, current + 1]) {
    if (BigInt(step) > last && timingSafeEqual(Buffer.from(totp(secret, step)), Buffer.from(code))) return step;
  }
}
export function encryptSecret(secret: string, key: Buffer): string {
  const iv = randomBytes(12), cipher = createCipheriv('aes-256-gcm', key, iv);
  cipher.setAAD(Buffer.from('supplybiz:admin-totp:v1'));
  const data = Buffer.concat([cipher.update(secret, 'utf8'), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), data]).toString('base64');
}
export function decryptSecret(value: string, key: Buffer): string {
  const bytes = Buffer.from(value, 'base64');
  const cipher = createDecipheriv('aes-256-gcm', key, bytes.subarray(0, 12));
  cipher.setAAD(Buffer.from('supplybiz:admin-totp:v1')); cipher.setAuthTag(bytes.subarray(12, 28));
  return Buffer.concat([cipher.update(bytes.subarray(28)), cipher.final()]).toString('utf8');
}
