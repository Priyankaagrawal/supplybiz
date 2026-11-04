import { createHash } from 'node:crypto';
import { assertUnbreached } from './admin-password';
describe('TC-400 admin provisioning breached-password check', () => {
 const password = 'synthetic-provisioning-test-only';
 const sha = createHash('sha1').update(password).digest('hex').toUpperCase();
 it('sends only five hash characters and rejects an actual breach match', async () => {
   const fake = jest.fn<Promise<Response>, Parameters<typeof fetch>>().mockResolvedValue(new Response(`${sha.slice(5)}:42\r\n${'0'.repeat(35)}:0`));
   await expect(assertUnbreached(password, fake)).rejects.toThrow('Password appears in a breach');
   expect(fake.mock.calls[0][0]).toBe(`https://api.pwnedpasswords.com/range/${sha.slice(0, 5)}`);
   expect(JSON.stringify(fake.mock.calls)).not.toContain(password);
 });
 it('accepts padding with zero count and non-matching hashes', async () => {
   const fake: typeof fetch = () => Promise.resolve(new Response(`${sha.slice(5)}:0\r\n${'0'.repeat(35)}:5`));
   await expect(assertUnbreached(password, fake)).resolves.toBeUndefined();
 });
 it('fails closed on HTTP errors, malformed/empty responses and network errors', async () => {
   for (const response of [new Response('', { status: 503 }), new Response(''), new Response('invalid'), new Response(`${'0'.repeat(35)}:0\ninvalid`)]) {
     await expect(assertUnbreached(password, () => Promise.resolve(response))).rejects.toThrow();
   }
   await expect(assertUnbreached(password, () => Promise.reject(new Error('synthetic network failure')))).rejects.toThrow();
 });
});
