import { test } from 'node:test';
import assert from 'node:assert/strict';
import { decisionSignature, documentKind, validDecisionKey } from '../src/lib/kyc';
void test('TC-402 decision retry keys cannot cross cases or sessions or be forged', () => {
 const key = '00000000-0000-4000-8000-000000000001';
 const signature = decisionSignature('synthetic-session', 'case-one', key);
 assert.equal(validDecisionKey('synthetic-session', 'case-one', key, signature), true);
 assert.equal(validDecisionKey('other-session', 'case-one', key, signature), false);
 assert.equal(validDecisionKey('synthetic-session', 'case-two', key, signature), false);
 assert.equal(validDecisionKey('synthetic-session', 'case-one', `${key}1`, signature), false);
 assert.equal(validDecisionKey('synthetic-session', 'case-one', key, 'x'.repeat(64)), false);
});
void test('TC-403 document selectors reject arbitrary media fields and prototype keys', () => {
 for (const kind of ['front', 'back', 'pan']) assert.equal(documentKind(kind), true);
 for (const kind of ['__proto__', 'constructor', 'accountNumber', '../front', '']) assert.equal(documentKind(kind), false);
});
