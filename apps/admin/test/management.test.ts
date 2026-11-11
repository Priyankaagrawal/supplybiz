import { test } from 'node:test';
import assert from 'node:assert/strict';
import { managementKey, packManagementRecovery, readManagementRecovery, validManagementKey } from '../src/lib/management';
void test('management form keys cannot cross accounts, actions or sessions', () => {
 const key = '12345678-1234-4234-8234-123456789012', signature = managementKey('synthetic', 'vendors:a:suspend', key);
 assert.equal(validManagementKey('synthetic', 'vendors:a:suspend', key, signature), true);
 for (const scope of ['vendors:b:suspend', 'vendors:a:reinstate', 'customers:a:block']) assert.equal(validManagementKey('synthetic', scope, key, signature), false);
 assert.equal(validManagementKey('other', 'vendors:a:suspend', key, signature), false);
});
void test('management recovery preserves the request and rejects tampering/another session', () => {
 const state = { message: 'Synthetic recovery', back: '/vendors/12345678-1234-4234-8234-123456789012', retry: true, fields: { key: 'synthetic-key', reason: 'Synthetic reason' } };
 const packed = packManagementRecovery('synthetic', state);
 assert.deepEqual(readManagementRecovery('synthetic', packed), state);
 assert.equal(readManagementRecovery('other', packed), null); assert.equal(readManagementRecovery('synthetic', `x${packed}`), null);
});
