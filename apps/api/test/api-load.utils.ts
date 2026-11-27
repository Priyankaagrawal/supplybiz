// T-171: local diagnostic workload, never a production/target-scale claim.
import { basename, dirname, resolve } from 'node:path';

export function storageCleanupPath(base: string, candidate: string): string {
  const target = resolve(candidate);
  if (dirname(target) !== resolve(base) ||
      !/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(basename(target))) {
    throw new Error('Unsafe load-storage cleanup path');
  }
  return target;
}
export function loadDatabase(raw: string): string {
  const url = new URL(raw);
  if (!['postgres:', 'postgresql:'].includes(url.protocol) ||
      !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname) ||
      url.pathname !== '/supplybiz_service_area_test') {
    throw new Error('T-171 requires the approved isolated local test database');
  }
  return url.toString();
}

export function p95(samples: number[]): number {
  if (!samples.length || samples.some(n => !Number.isFinite(n) || n < 0)) {
    throw new Error('Missing or invalid latency samples');
  }
  return [...samples].sort((a, b) => a - b)[Math.ceil(samples.length * .95) - 1];
}

export type LoadSample = { kind: 'read' | 'write'; route: 'product-page' | 'customer-page' | 'stock-adjustment'; ms: number; status: number };
export function summarize(samples: LoadSample[]) {
  return Object.fromEntries((['read', 'write'] as const).map(kind => {
    const rows = samples.filter(row => row.kind === kind);
    return [kind, { count: rows.length, p95Ms: p95(rows.map(row => row.ms)),
      errors: rows.filter(row => row.status !== (kind === 'read' ? 200 : 201)).length,
      budgetMs: kind === 'read' ? 500 : 800 }];
  })) as Record<'read' | 'write', { count: number; p95Ms: number; errors: number; budgetMs: number }>;
}
