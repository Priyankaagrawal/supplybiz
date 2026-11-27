import { resolve } from 'node:path';
import { loadDatabase, p95, summarize, storageCleanupPath } from './api-load.utils';

describe('T-171 measurement safety and accounting', () => {
  it('permits cleanup only for a UUID child directly within the intended fixture root', () => {
    const base = resolve('synthetic-t171'), id = '11111111-1111-4111-8111-111111111111';
    expect(storageCleanupPath(base, resolve(base, id))).toBe(resolve(base, id));
    for (const path of [base, resolve(base, '../other', id), resolve(base, 'nested', id), resolve(base, 'not-a-fixture')]) {
      expect(() => storageCleanupPath(base, path)).toThrow('Unsafe');
    }
  });
  it('accepts only the approved isolated local DB, never a general or remote DB', () => {
    expect(loadDatabase('postgresql://localhost/supplybiz_service_area_test')).toContain('supplybiz_service_area_test');
    for (const url of ['postgresql://localhost/supplybiz', 'postgresql://localhost/another_test',
      'postgresql://remote.invalid/supplybiz_service_area_test', 'https://localhost/supplybiz_service_area_test']) {
      expect(() => loadDatabase(url)).toThrow('isolated local test database');
    }
  });
  it('uses nearest rank and rejects absent/nonfinite measurements', () => {
    expect(p95(Array.from({ length: 100 }, (_, i) => i + 1))).toBe(95);
    for (const values of [[], [NaN], [Infinity], [-1]]) expect(() => p95(values)).toThrow();
  });
  it('counts errors including throttling and includes their latency instead of filtering failures', () => {
    const summary = summarize([
      { kind: 'read', route: 'product-page', ms: 900, status: 429 },
      { kind: 'read', route: 'customer-page', ms: 10, status: 200 },
      { kind: 'write', route: 'stock-adjustment', ms: 1200, status: 503 },
    ]);
    expect(summary.read).toMatchObject({ count: 2, errors: 1, p95Ms: 900, budgetMs: 500 });
    expect(summary.write).toMatchObject({ count: 1, errors: 1, p95Ms: 1200, budgetMs: 800 });
  });
});
