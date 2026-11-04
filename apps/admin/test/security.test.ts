import { test } from 'node:test';
import assert from 'node:assert/strict';
import { adminOrigin, cookieOptions, csrf, validCsrf } from '../src/lib/security';
process.env.ADMIN_CSRF_KEY = 'synthetic-test-key-with-at-least-32-characters';
void test('TC-400 CSRF expires, rejects cross-session use and tampering', () => {
 const now = 1700000000000;
 const token = csrf('synthetic-session', now);
 assert.equal(validCsrf(token, 'synthetic-session', now + 1), true);
 assert.equal(validCsrf(token, 'different-session', now + 1), false);
 assert.equal(validCsrf(token, 'synthetic-session', now + 1800000), false);
 assert.equal(validCsrf(`${token}x`, 'synthetic-session', now + 1), false);
});
void test('TC-400 cookies are httpOnly/strict, Secure on HTTPS, HTTP restricted to localhost', () => {
 process.env.ADMIN_ORIGIN = 'https://admin.example.invalid';
 assert.deepEqual(cookieOptions(), { httpOnly: true, secure: true, sameSite: 'strict', path: '/' });
 process.env.ADMIN_ORIGIN = 'http://admin.example.invalid'; assert.throws(adminOrigin);
 process.env.ADMIN_ORIGIN = 'http://127.0.0.1:3100'; assert.equal(cookieOptions().secure, false);
});
