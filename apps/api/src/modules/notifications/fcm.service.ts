// T-032: fixed-origin FCM HTTP v1 + OAuth service-account assertion; no new SDK.
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createPrivateKey, sign } from 'node:crypto';
import { z } from 'zod';

const OAUTH = 'https://oauth2.googleapis.com/token';
const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const credentials = z.object({ type: z.literal('service_account'), project_id: z.string().regex(/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/),
  client_email: z.string().email().regex(/@[^@]+\.gserviceaccount\.com$/), private_key: z.string().min(100),
  private_key_id: z.string().regex(/^[a-zA-Z0-9_-]{1,120}$/).optional() });
export type PushMessage = { id: string; role: string; type: string; path: string; title: string; body: string };
@Injectable()
export class FcmService {
  private cached?: { token: string; until: number };
  private refreshing?: Promise<string>;
  constructor(private readonly config: ConfigService) {}
  private account() {
    try {
      if (!this.config.get<boolean>('FCM_ENABLED', false)) throw new Error();
      const row = credentials.parse(JSON.parse(this.config.getOrThrow<string>('FCM_SERVICE_ACCOUNT_JSON')));
      const key = createPrivateKey(row.private_key);
      if (key.asymmetricKeyType !== 'rsa' || (key.asymmetricKeyDetails?.modulusLength ?? 0) < 2048) throw new Error();
      return { ...row, key };
    } catch { throw new Error('FCM_PROVIDER_UNAVAILABLE'); }
  }
  private async accessToken(account: ReturnType<FcmService['account']>): Promise<string> {
    if (this.cached && this.cached.until > Date.now()) return this.cached.token;
    if (this.refreshing) return this.refreshing;
    this.refreshing = (async () => {
      const now = Math.floor(Date.now() / 1000);
      const encode = (value: object) => Buffer.from(JSON.stringify(value)).toString('base64url');
      const unsigned = `${encode({ alg: 'RS256', typ: 'JWT', ...(account.private_key_id ? { kid: account.private_key_id } : {}) })}.${encode({
        iss: account.client_email, scope: SCOPE, aud: OAUTH, iat: now, exp: now + 3600 })}`;
      const assertion = `${unsigned}.${sign('RSA-SHA256', Buffer.from(unsigned), account.key).toString('base64url')}`;
      const response = await fetch(OAUTH, { method: 'POST', redirect: 'error', signal: AbortSignal.timeout(10000),
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }).toString() });
      if (!response.ok) throw new Error();
      const body = z.object({ access_token: z.string().min(1).max(10000), token_type: z.literal('Bearer'),
        expires_in: z.number().int().positive().max(3600) }).parse(await response.json());
      this.cached = { token: body.access_token, until: Date.now() + Math.max(0, body.expires_in - 60) * 1000 };
      return body.access_token;
    })();
    try { return await this.refreshing; } finally { this.refreshing = undefined; }
  }
  async send(token: string, item: PushMessage): Promise<'SENT' | 'UNREGISTERED'> {
    try {
      const account = this.account();
      const access = await this.accessToken(account);
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
        method: 'POST', redirect: 'error', signal: AbortSignal.timeout(10000),
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${access}` },
        body: JSON.stringify({ message: { token, notification: { title: item.title, body: item.body },
          data: { notificationId: item.id, role: item.role, type: item.type, path: item.path },
          android: { notification: { tag: item.id } } } }),
      });
      const body: unknown = await response.json();
      if (response.ok && z.object({ name: z.string().startsWith(`projects/${account.project_id}/messages/`) }).safeParse(body).success) return 'SENT';
      const error = z.object({ error: z.object({ details: z.array(z.object({ '@type': z.string(), errorCode: z.string().optional() }).passthrough()).optional() }).passthrough() }).safeParse(body);
      if (response.status === 404 && error.success && error.data.error.details?.some(d =>
        d['@type'] === 'type.googleapis.com/google.firebase.fcm.v1.FcmError' && d.errorCode === 'UNREGISTERED')) return 'UNREGISTERED';
      if (response.status === 401) this.cached = undefined;
      throw new Error();
    } catch {
      // Neither OAuth assertions, tokens, service keys nor provider bodies escape.
      throw new Error('FCM_DELIVERY_UNAVAILABLE');
    }
  }
}
