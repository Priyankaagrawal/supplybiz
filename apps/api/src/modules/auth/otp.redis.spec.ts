import { ConfigService } from "@nestjs/config";
import { randomBytes, randomUUID } from "node:crypto";
import { createClient } from "redis";
import { RedisOtpStore } from "./redis-otp.store";
import { OtpChallenge } from "./otp.types";

// Opt-in against an already-running test Redis; never starts a service or FLUSHes
// a database. Every key has a fresh, isolated namespace and is deleted afterwards.
const redisTests = process.env.OTP_TEST_REDIS_URL ? describe : describe.skip;
redisTests("T-014 atomic Redis OTP policy", () => {
  const prefix = `otp-test-${randomUUID()}`;
  const url = process.env.OTP_TEST_REDIS_URL ?? "redis://127.0.0.1:6379";
  const client = createClient({ url, socket: { reconnectStrategy: false, connectTimeout: 2000 } });
  const store = new RedisOtpStore(
    new ConfigService({ REDIS_URL: url, OTP_DELIVERY_MODE: "console", OTP_REDIS_PREFIX: prefix })
  );
  const policy = { deviceSendsPerHour: 5, lockoutBaseSeconds: 30, lockoutMaxSeconds: 3600 };
  const key = (kind: string, value: string) => `${prefix}:{${prefix}}:${kind}:${value}`;
  const challenge = (): OtpChallenge => ({
    revision: randomUUID(),
    salt: randomBytes(16).toString("hex"),
    digest: randomBytes(32).toString("hex"),
  });
  const keys = () => ({ mobile: randomUUID(), ip: randomUUID(), device: randomUUID() });
  beforeAll(async () => {
    client.on("error", jest.fn());
    await client.connect();
  });
  afterAll(async () => {
    await store.onModuleDestroy();
    if (client.isReady) {
      for await (const batch of client.scanIterator({ MATCH: `${prefix}:*`, COUNT: 100 })) {
        if (batch.length) await client.del(batch);
      }
    }
    if (client.isOpen) client.destroy();
  });
  async function clearCooldown(mobile: string): Promise<void> {
    const values = await client.zRangeWithScores(key("sends", mobile), 0, -1);
    await client.zAdd(
      key("sends", mobile),
      values.map((entry, index) => ({
        value: entry.value,
        score: Date.now() - 60000 - index,
      }))
    );
  }
  it("TC-006 reserves exactly one concurrent send and enforces 30-second resend cooldown", async () => {
    const subject = keys();
    const decisions = await Promise.all(
      Array.from({ length: 10 }, () => store.reserve(subject, challenge(), policy))
    );
    expect(decisions.filter((value) => value.result === "OK")).toHaveLength(1);
    expect(decisions.filter((value) => value.result === "RATE_LIMITED")).toHaveLength(9);
    expect(await client.pTTL(key("challenge", subject.mobile))).toBeGreaterThan(290000);
    expect(await client.pTTL(key("challenge", subject.mobile))).toBeLessThanOrEqual(300000);
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
      Array.from({ length: 5 }, () => store.consume(subject.mobile, value.revision, true, policy))
    );
    expect(results.filter((result) => result.result === "OK")).toHaveLength(1);
    expect(results.filter((result) => result.result === "OTP_EXPIRED")).toHaveLength(4);
    await clearCooldown(subject.mobile);
    const next = challenge();
    await store.reserve(subject, next, policy);
    await store.activate(subject.mobile, next.revision);
    await client.pExpire(key("challenge", subject.mobile), 1);
    await new Promise((resolve) => setTimeout(resolve, 10));
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
      await client.hSet(key("lockout", subject.mobile), "untilMs", "0");
    }
    expect(await client.hGet(key("lockout", subject.mobile), "streak")).toBe("2");
    expect(await client.ttl(key("lockout", subject.mobile))).toBeGreaterThanOrEqual(3590);
  });
  it("TC-006 enforces the mobile, IP and device budgets atomically", async () => {
    const subject = keys();
    for (let i = 0; i < 5; i++) {
      expect(await store.reserve(subject, challenge(), policy)).toEqual({ result: "OK" });
      await clearCooldown(subject.mobile);
    }
    expect((await store.reserve(subject, challenge(), policy)).result).toBe("RATE_LIMITED");
    for (const dimension of ["ip", "device"] as const) {
      const common = randomUUID();
      const limit = dimension === "ip" ? 20 : 5;
      const results = await Promise.all(
        Array.from({ length: limit + 4 }, () =>
          store.reserve({ ...keys(), [dimension]: common }, challenge(), policy)
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
});
