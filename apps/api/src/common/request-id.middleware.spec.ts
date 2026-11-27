import { Request, Response } from 'express';
import { RequestIdMiddleware, REQUEST_ID_HEADER } from './request-id.middleware';

describe('T-173 request correlation input boundary', () => {
  const valid = '11111111-1111-4111-8111-111111111111';
  function run(value?: string) {
    const req = { header: () => value, headers: {} } as unknown as Request;
    const res = { setHeader: jest.fn() } as unknown as Response;
    const next = jest.fn();
    new RequestIdMiddleware().use(req, res, next);
    expect(next).toHaveBeenCalledTimes(1);
    expect(res.setHeader).toHaveBeenCalledWith(REQUEST_ID_HEADER, req.headers[REQUEST_ID_HEADER]);
    return req.headers[REQUEST_ID_HEADER];
  }
  it('preserves a client UUID for response/log correlation', () => {
    expect(run(valid)).toBe(valid);
    expect(run(valid.toUpperCase())).toBe(valid.toUpperCase());
  });
  it.each([undefined, '', ' ', 'synthetic-person@example.invalid', '9000000000',
    'x'.repeat(8192), `${valid}\n`, `${valid},${valid}`])('replaces unsafe/missing client input %#', input => {
    const id = run(input);
    expect(id).not.toBe(input);
    expect(id).toMatch(/^[a-f0-9-]{36}$/);
  });
});
