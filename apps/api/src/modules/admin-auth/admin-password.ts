import { createHash } from 'node:crypto';
// HIBP Pwned Passwords range protocol; no password/full hash leaves the host.
export async function assertUnbreached(password: string, fetcher: typeof fetch = fetch): Promise<void> {
 const sha = createHash('sha1').update(password).digest('hex').toUpperCase();
 const response = await fetcher(`https://api.pwnedpasswords.com/range/${sha.slice(0, 5)}`, {
   headers: { 'Add-Padding': 'true', 'User-Agent': 'SupplyBiz-Admin-Provisioning' }, signal: AbortSignal.timeout(10000) });
 if (!response.ok) throw new Error('Breach check unavailable');
 const lines = (await response.text()).trim().split(/\r?\n/);
 if (!lines.length || !lines.every(line => /^[A-F0-9]{35}:\d+$/.test(line))) throw new Error('Invalid breach check response');
 if (lines.some(line => line.startsWith(`${sha.slice(5)}:`) && Number(line.split(':')[1]) > 0)) throw new Error('Password appears in a breach');
}
