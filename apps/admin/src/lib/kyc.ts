import { createHmac, timingSafeEqual } from 'node:crypto';

// Bind a stable retry key to this session and case, so browser retries remain safe.
export function decisionSignature(session: string, id: string, key: string): string {
 return createHmac('sha256', session).update(`kyc:${id}:${key}`).digest('hex');
}
export function validDecisionKey(session: string, id: string, key: string, signature: string): boolean {
 if (!/^[a-f0-9-]{36}$/.test(key) || !/^[a-f0-9]{64}$/.test(signature)) return false;
 return timingSafeEqual(Buffer.from(signature), Buffer.from(decisionSignature(session, id, key)));
}
export const documentFields = {
 front: 'aadhaarFrontMediaId', back: 'aadhaarBackMediaId', pan: 'panMediaId',
} as const;
export function documentKind(value: string): value is keyof typeof documentFields {
 return Object.hasOwn(documentFields, value);
}
