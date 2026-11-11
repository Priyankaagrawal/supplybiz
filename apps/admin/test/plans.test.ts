import { test } from 'node:test';
import assert from 'node:assert/strict';
import { istInput, istTimestamp, packPlanRetry, paise, planSignature, readPlanRetry, validPlanKey } from '../src/lib/plans';
const key = '12345678-1234-4234-8234-123456789012';
void test('plan form keys are bound to the session, operation and target', () => {
 const signature = planSignature('synthetic-session', 'assign:vendor-a', key);
 assert.ok(validPlanKey('synthetic-session', 'assign:vendor-a', key, signature));
 for (const [session, scope] of [['other', 'assign:vendor-a'], ['synthetic-session', 'assign:vendor-b'], ['synthetic-session', 'extend:vendor-a']]) assert.equal(validPlanKey(session, scope, key, signature), false);
 assert.equal(validPlanKey('synthetic-session', 'assign:vendor-a', 'bad', signature), false);
});
void test('reference prices parse to exact integer paise without rounding', () => {
 assert.equal(paise('99.09'), 9909); assert.equal(paise('0.1'), 10); assert.equal(paise('0'), 0);
 for (const value of ['-1', '1.001', '1e3', '', 'Infinity', '999999999999999']) assert.equal(paise(value), null);
});
void test('IST form conversion is independent of host timezone', () => {
 assert.equal(istInput('2026-11-11T18:45:00Z'), '2026-11-12T00:15');
 assert.equal(istTimestamp('2026-11-12T00:15'), '2026-11-12T00:15:00+05:30');
 assert.equal(istTimestamp('2026-11-12'), null);
});
void test('recovery preserves the original request and rejects another session or tampering', () => {
 const state = { message: 'Synthetic recovery', back: '/plans', retry: true, fields: { key, reason: 'Synthetic reason' } };
 const packed = packPlanRetry('synthetic-session', state);
 assert.deepEqual(readPlanRetry('synthetic-session', packed), state);
 assert.equal(readPlanRetry('other-session', packed), null);
 assert.equal(readPlanRetry('synthetic-session', `x${packed}`), null);
});
