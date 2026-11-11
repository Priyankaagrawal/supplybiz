import { ConfigService } from '@nestjs/config';
import { generateKeyPairSync, verify } from 'node:crypto';
import { validateEnv } from '../../config/env.schema';
import { FcmService, PushMessage } from './fcm.service';

const pair = generateKeyPairSync('rsa', { modulusLength: 2048 });
const account = { type: 'service_account', project_id: 'synthetic-project', client_email: 'synthetic@synthetic-project.iam.gserviceaccount.com',
  private_key: pair.privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() };
const item: PushMessage = { id: 'synthetic-notification', role: 'VENDOR', type: 'KYC_STATUS', path: '/vendor/onboarding/status',
  title: 'KYC status updated', body: 'Open Supply Biz to view your verification decision.' };
const response = (body: object, status = 200) => new Response(JSON.stringify(body), { status });
const oauth = () => response({ access_token: 'synthetic-oauth', token_type: 'Bearer', expires_in: 3600 });
const service = () => new FcmService(new ConfigService({ FCM_ENABLED: true, FCM_SERVICE_ACCOUNT_JSON: JSON.stringify(account) }));
describe('T-032 FCM HTTP adapter (simulated Google responses, never live delivery)', () => {
  afterEach(() => jest.restoreAllMocks());
  it('disabled/missing/invalid credentials fail closed without outbound requests or secret errors', async () => {
    const fetcher = jest.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Unexpected outbound request'));
    for (const config of [{}, { FCM_ENABLED: false }, { FCM_ENABLED: true, FCM_SERVICE_ACCOUNT_JSON: 'synthetic-invalid-secret' }]) {
      await expect(new FcmService(new ConfigService(config)).send('synthetic-device', item)).rejects.toThrow('FCM_DELIVERY_UNAVAILABLE');
    }
    expect(fetcher).not.toHaveBeenCalled();
    expect(() => validateEnv({ FCM_ENABLED: 'true' })).toThrow('Required when FCM is enabled');
  });
  it('signs/verifies scoped RS256 assertion and coalesces OAuth refresh across concurrent sends', async () => {
    const fetcher = jest.spyOn(globalThis, 'fetch').mockImplementation(async (url, init) => {
      expect(init?.redirect).toBe('error'); expect(init?.signal).toBeDefined();
      if (String(url) === 'https://oauth2.googleapis.com/token') {
        const assertion = new URLSearchParams(String(init?.body)).get('assertion')!;
        const [header, body, signature] = assertion.split('.');
        expect(JSON.parse(Buffer.from(header, 'base64url').toString())).toEqual({ alg: 'RS256', typ: 'JWT' });
        const claims = JSON.parse(Buffer.from(body, 'base64url').toString()) as Record<string, unknown>;
        expect(claims).toMatchObject({ iss: account.client_email, aud: 'https://oauth2.googleapis.com/token', scope: 'https://www.googleapis.com/auth/firebase.messaging' });
        expect((claims.exp as number) - (claims.iat as number)).toBe(3600);
        expect(verify('RSA-SHA256', Buffer.from(`${header}.${body}`), pair.publicKey, Buffer.from(signature, 'base64url'))).toBe(true);
        return oauth();
      }
      expect(String(url)).toBe('https://fcm.googleapis.com/v1/projects/synthetic-project/messages:send');
      expect(init?.headers).toMatchObject({ Authorization: 'Bearer synthetic-oauth' });
      expect(JSON.parse(String(init?.body))).toMatchObject({ message: { token: 'synthetic-device', data: { notificationId: item.id, path: item.path }, android: { notification: { tag: item.id } } } });
      return response({ name: 'projects/synthetic-project/messages/synthetic-message' });
    });
    const adapter = service();
    expect(await Promise.all([adapter.send('synthetic-device', item), adapter.send('synthetic-device', item)])).toEqual(['SENT','SENT']);
    expect(fetcher.mock.calls.filter(call => String(call[0]).includes('oauth2'))).toHaveLength(1);
    expect(fetcher).toHaveBeenCalledTimes(3);
  });
  it('only exact FCM UNREGISTERED makes a token permanently invalid', async () => {
    jest.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Unexpected outbound request')).mockResolvedValueOnce(oauth()).mockResolvedValueOnce(response({ error: { details: [
      { '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError', errorCode: 'UNREGISTERED' } ] } }, 404));
    await expect(service().send('synthetic-device', item)).resolves.toBe('UNREGISTERED');
  });
  it('generic 404/transient errors preserve tokens and redact provider responses', async () => {
    const fetcher = jest.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Unexpected outbound request'));
    for (const status of [404, 429, 500, 503]) {
      fetcher.mockResolvedValueOnce(oauth()).mockResolvedValueOnce(response({ error: { message: 'synthetic-private-provider-response' } }, status));
      await expect(service().send('synthetic-device', item)).rejects.toThrow('FCM_DELIVERY_UNAVAILABLE');
    }
  });
  it('401 invalidates cached OAuth credentials for the durable retry', async () => {
    const fetcher = jest.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Unexpected outbound request')).mockResolvedValueOnce(oauth()).mockResolvedValueOnce(response({ error: {} }, 401))
      .mockResolvedValueOnce(oauth()).mockResolvedValueOnce(response({ name: 'projects/synthetic-project/messages/retry' }));
    const adapter = service(); await expect(adapter.send('synthetic-device', item)).rejects.toThrow('FCM_DELIVERY_UNAVAILABLE');
    await expect(adapter.send('synthetic-device', item)).resolves.toBe('SENT');
    expect(fetcher.mock.calls.filter(call => String(call[0]).includes('oauth2'))).toHaveLength(2);
  });
});
