import { ConfigService } from "@nestjs/config";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import { PrismaService } from "../../prisma/prisma.service";
import { PostgresAbuseState } from "../../common/abuse/postgres-abuse-state";
import { PostgresThrottlerStorage } from "../../common/abuse/postgres-throttler.storage";
import { PostgresOtpStore } from "./postgres-otp.store";
import { OtpChallenge } from "./otp.types";

// Opt-in to a dedicated, already migrated native PostgreSQL test database.
// Only keys created by this suite are removed; never resets identity/session data.
const databaseTests = process.env.ABUSE_TEST_DATABASE_URL ? describe : describe.skip;
databaseTests("T-180 PostgreSQL atomic OTP/shared abuse policy", () => {
  const url = process.env.ABUSE_TEST_DATABASE_URL ?? "postgresql://localhost:5432/supplybiz_abuse_test";
  const prisma = new PrismaService({ datasources: { db: { url } } });
  const replica = new PrismaService({ datasources: { db: { url } } });
  const state = new PostgresAbuseState(prisma);
  const config = new ConfigService({ OTP_DELIVERY_MODE: "console" });
  const store = new PostgresOtpStore(state, config);
  const secondStore = new PostgresOtpStore(new PostgresAbuseState(replica), config);
  const policy = { deviceSendsPerHour: 5, lockoutBaseSeconds: 30, lockoutMaxSeconds: 3600 };
  const owned = new Set<string>();
  const digest = () => randomBytes(32).toString("hex");
  const key = (kind: string, value: string) => `otp:${kind}:${value}`;
  const challenge = (): OtpChallenge => ({
    revision: randomUUID(),
    salt: randomBytes(16).toString("hex"),
    digest: randomBytes(32).toString("hex"),
  });
  const keys = () => {
    const values = { mobile: digest(), ip: digest(), device: digest() };
    track(values);
    return values;
  };
  function track(values: { mobile: string; ip: string; device: string }) {
    for (const kind of ["challenge", "mobile", "lockout"]) owned.add(key(kind, values.mobile));
    owned.add(key("ip", values.ip));
    owned.add(key("device", values.device));
  }
  beforeAll(async () => { await Promise.all([prisma.$connect(), replica.$connect()]); });
  afterAll(async () => {
    for (const value of owned) await prisma.$executeRaw`DELETE FROM auth_abuse_state WHERE key = ${value}`;
    await Promise.all([prisma.$disconnect(), replica.$disconnect()]);
  });
  async function clearCooldown(mobile: string): Promise<void> {
    await state.atomic([key("mobile", mobile)], async tx => {
      const values = await tx.read<number[]>(key("mobile", mobile));
      await tx.write(key("mobile", mobile), values?.map((_, index) => tx.now - 60000 - index) ?? [], tx.now + 3600000);
    });
  }
  it("TC-006 reserves exactly one concurrent send and enforces 30-second resend cooldown", async () => {
    const subject = keys();
    const decisions = await Promise.all(
      Array.from({ length: 10 }, (_, index) => (index % 2 ? store : secondStore).reserve(subject, challenge(), policy))
    );
    expect(decisions.filter((value) => value.result === "OK")).toHaveLength(1);
    expect(decisions.filter((value) => value.result === "RATE_LIMITED")).toHaveLength(9);
    const [row] = await prisma.$queryRaw<{ ttl: number }[]>`
      SELECT extract(epoch FROM (expires_at - clock_timestamp()))::double precision AS ttl
      FROM auth_abuse_state WHERE key = ${key("challenge", subject.mobile)}`;
    expect(row?.ttl).toBeGreaterThan(290);
    expect(row?.ttl).toBeLessThanOrEqual(300);
  });
  it("TC-003/TC-005 pending delivery cannot verify; active OTP is consumed exactly once and expires", async () => {
    const subject = keys();
    const value = challenge();
    await store.reserve(subject, value, policy);
    expect(await store.consume(subject.mobile, value.revision, true, policy)).toEqual({
      result: "OTP_INVALID",
    });
    await store.activate(subject.mobile, value.revision);
    const results = await Promise.all(
      Array.from({ length: 5 }, (_, index) => (index % 2 ? store : secondStore).consume(subject.mobile, value.revision, true, policy))
    );
    expect(results.filter((result) => result.result === "OK")).toHaveLength(1);
    expect(results.filter((result) => result.result === "OTP_EXPIRED")).toHaveLength(4);
    await clearCooldown(subject.mobile);
    const next = challenge();
    await store.reserve(subject, next, policy);
    await store.activate(subject.mobile, next.revision);
    await prisma.$executeRaw`UPDATE auth_abuse_state SET expires_at = clock_timestamp() - interval '1 second'
      WHERE key = ${key("challenge", subject.mobile)}`;
    expect(await store.consume(subject.mobile, next.revision, true, policy)).toEqual({
      result: "OTP_EXPIRED",
    });
  });
  it("TC-004 invalidates on the fifth wrong attempt and applies escalating lockout", async () => {
    const subject = keys();
    for (let round = 0; round < 2; round++) {
      const value = challenge();
      expect(await store.reserve(subject, value, policy)).toEqual({ result: "OK" });
      await store.activate(subject.mobile, value.revision);
      for (let attempt = 1; attempt <= 5; attempt++) {
        expect(await store.consume(subject.mobile, value.revision, false, policy)).toEqual({
          result: attempt === 5 ? "OTP_ATTEMPTS_EXCEEDED" : "OTP_INVALID",
        });
      }
      expect(await store.consume(subject.mobile, value.revision, true, policy)).toEqual({
        result: "OTP_ATTEMPTS_EXCEEDED",
      });
      await clearCooldown(subject.mobile);
      const rejected = await store.reserve(subject, challenge(), policy);
      expect(rejected.result).toBe("RATE_LIMITED");
      if (rejected.result === "RATE_LIMITED") {
        expect(rejected.retryAfterSec).toBeGreaterThanOrEqual(round === 0 ? 29 : 59);
      }
      await state.atomic([key("lockout", subject.mobile)], async tx => {
        const value = await tx.read<{ streak: number }>(key("lockout", subject.mobile));
        await tx.write(key("lockout", subject.mobile), { ...value, until: 0 }, tx.now + 3600000);
      });
    }
    const value = await state.atomic([key("lockout", subject.mobile)], tx =>
      tx.read<{ streak: number }>(key("lockout", subject.mobile)));
    expect(value?.streak).toBe(2);
  });
  it("TC-006 enforces the mobile, IP and device budgets atomically", async () => {
    const subject = keys();
    for (let i = 0; i < 5; i++) {
      expect(await store.reserve(subject, challenge(), policy)).toEqual({ result: "OK" });
      await clearCooldown(subject.mobile);
    }
    expect((await store.reserve(subject, challenge(), policy)).result).toBe("RATE_LIMITED");
    for (const dimension of ["ip", "device"] as const) {
      const common = digest();
      const limit = dimension === "ip" ? 20 : 5;
      const results = await Promise.all(
        Array.from({ length: limit + 4 }, () =>
          { const subject = { ...keys(), [dimension]: common }; track(subject);
            return store.reserve(subject, challenge(), policy); }
        )
      );
      expect(results.filter((result) => result.result === "OK")).toHaveLength(limit);
    }
  });
  it("resend and failed-delivery cleanup cannot consume/delete a newer challenge", async () => {
    const subject = keys();
    const first = challenge();
    await store.reserve(subject, first, policy);
    await store.activate(subject.mobile, first.revision);
    await clearCooldown(subject.mobile);
    const second = challenge();
    await store.reserve(subject, second, policy);
    await store.activate(subject.mobile, second.revision);
    await store.discard(subject.mobile, first.revision);
    expect(await store.consume(subject.mobile, first.revision, true, policy)).toEqual({
      result: "OTP_INVALID",
    });
    expect(await store.consume(subject.mobile, second.revision, true, policy)).toEqual({
      result: "OK",
    });
  });
  it("persists a pending OTP and cooldown across a client disconnect/reconnect", async () => {
    const subject = keys(), value = challenge();
    await secondStore.reserve(subject, value, policy);
    await secondStore.activate(subject.mobile, value.revision);
    await replica.$disconnect();
    await replica.$connect();
    expect(await secondStore.read(subject.mobile)).toEqual(value);
    expect((await secondStore.reserve(subject, challenge(), policy)).result).toBe("RATE_LIMITED");
    expect((await store.consume(subject.mobile, value.revision, true, policy)).result).toBe("OK");
  });
  it("shares bounded HTTP/session counters across replicas", async () => {
    const input = randomUUID();
    owned.add(`http:${createHash("sha256").update(`http-rate:${input}`).digest("hex")}`);
    const first = new PostgresThrottlerStorage(state, 5);
    const second = new PostgresThrottlerStorage(new PostgresAbuseState(replica), 5);
    const results = await Promise.all(Array.from({ length: 10 }, (_, i) =>
      (i % 2 ? first : second).increment(input, 60000)));
    expect(results.filter(r => r.totalHits <= 5)).toHaveLength(5);
    expect(results.filter(r => r.totalHits > 5)).toHaveLength(5);
  });
  it("cleanup removes expired state while preserving live challenges", async () => {
    const expired = keys(), active = keys();
    await store.reserve(expired, challenge(), policy);
    const value = challenge();
    await store.reserve(active, value, policy);
    await prisma.$executeRaw`UPDATE auth_abuse_state SET expires_at = clock_timestamp() - interval '1 second'
      WHERE key = ${key("challenge", expired.mobile)}`;
    await state.cleanup();
    const rows = await prisma.$queryRaw<unknown[]>`SELECT key FROM auth_abuse_state
      WHERE key = ${key("challenge", expired.mobile)}`;
    expect(rows).toHaveLength(0);
    expect(await store.read(active.mobile)).toEqual(value);
  });
});
