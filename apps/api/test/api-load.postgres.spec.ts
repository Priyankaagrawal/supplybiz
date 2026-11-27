import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { generateKeyPairSync, randomBytes, randomInt, randomUUID } from 'node:crypto';
import { cpus, freemem, totalmem, homedir } from 'node:os';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { AddressInfo } from 'node:net';
import { configureHttpApp } from '../src/bootstrap';
import { PrismaService } from '../src/prisma/prisma.service';
import { PinoLogger } from '../src/common/logging/pino.logger';
import { SessionTokensService } from '../src/modules/auth/session-tokens.service';
import { assignPlanFixture } from './fixtures/plans';
import { loadDatabase, LoadSample, summarize, storageCleanupPath } from './api-load.utils';

const native = process.env.NATIVE_TEST_DATABASE_URL ? describe : describe.skip;
native('T-171 / TC-602 bounded local HTTP/PostgreSQL load', () => {
  it('measures authenticated reads/writes and verifies stock, replay, isolation and rate limits', async () => {
    const output = resolve('build/t171-load.json');
    await mkdir(dirname(output), { recursive: true });
    await rm(output, { force: true }); // A failed run must not leave a stale PASS report.
    const url = loadDatabase(process.env.NATIVE_TEST_DATABASE_URL!);
    const original = { ...process.env };
    // Let the real storage service create private ACLs, outside source/OS temp.
    const rootBase = resolve(homedir(), 'SupplyBizT171');
    const root = join(rootBase, randomUUID());
    const db = new PrismaService({ datasources: { db: { url } } });
    let app: INestApplication | undefined;
    let categoryId: string | undefined;
    let internalErrors = 0;
    const deadline = new AbortController();
    let deadlineTimer: ReturnType<typeof setTimeout> | undefined;
    try {
      Object.assign(process.env, { NODE_ENV: 'test', DATABASE_URL: url, UPLOAD_ROOT: root,
        OTP_DELIVERY_MODE: 'disabled', FCM_ENABLED: 'false', HEALTHCHECK_STRICT: 'true',
        FIELD_ENCRYPTION_KEY: randomBytes(32).toString('hex'), ADMIN_TOTP_KEY: randomBytes(32).toString('hex'),
        AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync('ed25519').privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() });
      await db.$connect();
      const { AppModule } = await import('../src/app.module');
      const module = await Test.createTestingModule({ imports: [AppModule] })
        .overrideProvider(PinoLogger).useValue({ log() {}, warn() {}, error() { internalErrors++; } }).compile();
      app = module.createNestApplication(); configureHttpApp(app); await app.listen(0, '127.0.0.1');
      const base = `http://127.0.0.1:${(app.getHttpServer().address() as AddressInfo).port}/api/v1`;
      const limit = app.get(ConfigService).getOrThrow<number>('RATE_LIMIT_MAX_REQUESTS');
      const ttl = app.get(ConfigService).getOrThrow<number>('RATE_LIMIT_TTL_SECONDS');
      const tokens = app.get(SessionTokensService);
      const [database] = await db.$queryRaw<{ version: string }[]>`SELECT current_setting('server_version') AS version`;
      const category = await db.categories.create({ data: { code: `T171-${randomUUID()}`, name_en: 'Synthetic load',
        name_hi: '', type: 'SUPPLY', product_types: ['MILK'] } });
      categoryId = category.id;
      const actors: { token: string; product: string; vendor: string }[] = [];
      for (let actor = 0; actor < 3; actor++) {
        const user = await db.users.create({ data: { mobile: `+919000${String(randomInt(1000000)).padStart(6, '0')}`,
          name: 'Synthetic load vendor', active_role: 'VENDOR', roles: { create: { role: 'VENDOR' } } } });
        const session = await db.sessions.create({ data: { user_id: user.id, family_id: randomUUID(),
          refresh_token_hash: 'synthetic-unused', expires_at: new Date(Date.now() + 3600000) } });
        const vendor = await db.vendors.create({ data: { user_id: user.id, category_id: category.id,
          business_name: 'Synthetic load shop', kyc_status: 'VERIFIED', settings: { create: {} } } });
        await db.$transaction(tx => assignPlanFixture(tx, vendor.id, 'BUSINESS'));
        const product = randomUUID();
        await db.products.createMany({ data: Array.from({ length: 200 }, (_, i) => ({
          id: i === 0 ? product : randomUUID(), vendor_id: vendor.id, name: `Synthetic milk ${i}`,
          product_type: 'MILK', milk_type: 'COW', unit_value: 1, unit_type: 'L', selling_price_paise: 5000, stock_qty: 100,
        })) });
        await db.vendor_customers.createMany({ data: Array.from({ length: 100 }, (_, i) => ({
          vendor_id: vendor.id, name: `Synthetic customer ${i}`, mobile: `+919100${String(i).padStart(6, '0')}`,
        })) });
        actors.push({ token: tokens.issue(user.id, session.id, []), product, vendor: vendor.id });
      }
      deadlineTimer = setTimeout(() => deadline.abort(), 60000);
      deadlineTimer.unref();
      const call = async (actor: typeof actors[number], path: string, key?: string) => {
        const start = performance.now();
        const response = await fetch(`${base}/${path}`, { method: key ? 'POST' : 'GET',
          headers: { Authorization: `Bearer ${actor.token}`, ...(key ? { 'Idempotency-Key': key, 'Content-Type': 'application/json' } : {}) },
          ...(key ? { body: JSON.stringify({ delta: 1, reason: 'Synthetic T-171 adjustment' }) } : {}),
          signal: AbortSignal.any([AbortSignal.timeout(10000), deadline.signal]) });
        const body: unknown = await response.json();
        return { status: response.status, ms: performance.now() - start, body };
      };
      // Warm-up is outside the measured burst; no limiter or auth bypass.
      for (const actor of actors) {
        for (const [path, total, size] of [['vendor/products?limit=50', 200, 50],
          ['vendor/customers?limit=20', 100, 20]] as const) {
          const result = await call(actor, path);
          expect(result.status).toBe(200);
          const page = result.body as { total: number; items: unknown[] };
          expect(page.total).toBe(total); expect(page.items).toHaveLength(size);
        }
      }
      const samples: LoadSample[] = [], keys = actors.map(() => randomUUID());
      const started = performance.now();
      const freeAtStart = freemem();
      await Promise.all(actors.map(async (actor, actorIndex) => {
        for (let i = 0; i < 30; i++) {
          const write = i % 3 === 2;
          const route = write ? 'stock-adjustment' : i % 3 === 0 ? 'product-page' : 'customer-page';
          const key = write ? (i === 29 ? keys[actorIndex] : randomUUID()) : undefined;
          const path = write ? `vendor/products/${actor.product}/stock-adjustments`
            : route === 'product-page' ? 'vendor/products?limit=50&offset=50' : 'vendor/customers?limit=20&offset=20';
          const result = await call(actor, path, key);
          samples.push({ kind: write ? 'write' : 'read', route, status: result.status, ms: result.ms });
        }
      }));
      const elapsedMs = performance.now() - started;
      // A repeated concurrent key must not increment stock or add movements.
      const replay = await Promise.all([0, 1].map(() => call(actors[0],
        `vendor/products/${actors[0].product}/stock-adjustments`, keys[0])));
      expect(replay.map(row => row.status)).toEqual([201, 201]);
      expect((await call(actors[0], `vendor/products/${actors[1].product}`)).status).toBe(404);
      for (const actor of actors) {
        expect((await db.products.findUniqueOrThrow({ where: { id: actor.product } })).stock_qty).toBe(110);
        expect(await db.stock_movements.count({ where: { product_id: actor.product } })).toBe(10);
      }
      // Exhaustion check is distinct from latency measurements and bounded at 121.
      let policyRequests = 0, rateLimited = false;
      if (limit <= 120) {
        while (policyRequests < Math.min(limit + 1, 121)) {
          policyRequests++;
          const result = await call(actors[0], 'vendor/products?limit=50');
          if (result.status === 429) { rateLimited = true; break; }
          expect(result.status).toBe(200);
        }
        expect(rateLimited).toBe(true);
      }
      const summary = summarize(samples);
      const report = { task: 'T-171', generatedAt: new Date().toISOString(), scope: 'local diagnostic burst, not approved production capacity',
        productionAcceptance: 'NOT_RUN', targetScale: 'DEFERRED SR-06', workers: 3,
        localLatencyStatus: Object.values(summary).every(row => row.errors === 0 && row.p95Ms <= row.budgetMs) && internalErrors === 0 ? 'PASS' : 'FAIL',
        dataset: { vendors: 3, productsPerVendor: 200, customersPerVendor: 100 },
        measuredRequests: samples.length, elapsedMs, throughputPerSecond: samples.length * 1000 / elapsedMs,
        latency: summary, samples, policy: { limit, ttlSeconds: ttl, bypassed: false, probeRequests: policyRequests,
          exhaustion: rateLimited ? 'PASS' : 'NOT_RUN: configured limit exceeds bounded probe' },
        integrity: 'PASS: exact stock/movement counts, concurrent replay and tenant denial', internalErrors,
        host: { platform: process.platform, arch: process.arch, node: process.version, postgres: database.version, logicalCpus: cpus().length,
          cpuModel: cpus()[0]?.model, totalRamBytes: totalmem(), freeRamBytes: freeAtStart,
          sameProcessGenerator: true, apiAndGeneratorRssBytes: process.memoryUsage().rss } };
      await writeFile(output, JSON.stringify(report, null, 2));
      expect(summary.read.count).toBe(60); expect(summary.write.count).toBe(30);
      expect(summary.read.errors + summary.write.errors + internalErrors).toBe(0);
      expect(summary.read.p95Ms).toBeLessThanOrEqual(500);
      expect(summary.write.p95Ms).toBeLessThanOrEqual(800);
    } finally {
      if (deadlineTimer) clearTimeout(deadlineTimer);
      deadline.abort();
      try { await app?.close(); }
      finally {
        try { if (categoryId) await db.categories.update({ where: { id: categoryId }, data: { status: 'HIDDEN' } }); }
        finally {
          await db.$disconnect();
          for (const key of Object.keys(process.env)) if (!(key in original)) delete process.env[key];
          Object.assign(process.env, original);
          await rm(storageCleanupPath(rootBase, root), { recursive: true, force: true });
        }
      }
    }
  });
});
