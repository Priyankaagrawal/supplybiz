import { ConfigService } from "@nestjs/config";
import { randomBytes, randomUUID } from "node:crypto";
import { AbuseTransaction, PostgresAbuseState } from "../../common/abuse/postgres-abuse-state";
import { PostgresThrottlerStorage } from "../../common/abuse/postgres-throttler.storage";
import { PrismaService } from "../../prisma/prisma.service";
import { PostgresOtpStore } from "./postgres-otp.store";

// Policy tests use a deterministic database clock; real SQL/locking is tested
// separately in otp.postgres.spec.ts against a dedicated native test database.
const prisma = new PrismaService();
class MemoryTransaction extends AbuseTransaction {
  constructor(readonly rows: Map<string, { value: unknown; expires: number }>, now: number) {
    super(prisma, now);
  }
  override async read<T>(key: string): Promise<T | null> {
    const row = this.rows.get(key);
    return row && row.expires > this.now ? structuredClone(row.value) as T : null;
  }
  override async write(key: string, value: unknown, expires: number) {
    this.rows.set(key, { value: structuredClone(value), expires });
  }
  override async remove(key: string) { this.rows.delete(key); }
}
class MemoryState extends PostgresAbuseState {
  now = 10000000;
  rows = new Map<string, { value: unknown; expires: number }>();
  constructor() { super(prisma); }
  override async atomic<T>(_keys: string[], operation: (tx: AbuseTransaction) => Promise<T>) {
    return operation(new MemoryTransaction(this.rows, this.now));
  }
}

describe("T-180 OTP and shared abuse policy", () => {
  let state: MemoryState;
  let store: PostgresOtpStore;
  const policy = { deviceSendsPerHour: 5, lockoutBaseSeconds: 30, lockoutMaxSeconds: 3600 };
  const keys = () => ({ mobile: randomBytes(32).toString("hex"), ip: randomBytes(32).toString("hex"), device: randomBytes(32).toString("hex") });
  const challenge = () => ({ revision: randomUUID(), salt: randomBytes(16).toString("hex"), digest: randomBytes(32).toString("hex") });
  beforeEach(() => {
    state = new MemoryState();
    store = new PostgresOtpStore(state, new ConfigService({ OTP_DELIVERY_MODE: "console" }));
  });

  it("TC-003/005 pending codes cannot verify, activation keeps TTL, and success is single-use", async () => {
    const subject = keys(), value = challenge();
    await store.reserve(subject, value, policy);
    expect(await store.consume(subject.mobile, value.revision, true, policy)).toEqual({ result: "OTP_INVALID" });
    state.now += 20000;
    await store.activate(subject.mobile, value.revision);
    expect(state.rows.get(`otp:challenge:${subject.mobile}`)?.expires).toBe(10300000);
    expect(await store.consume(subject.mobile, value.revision, true, policy)).toEqual({ result: "OK" });
    expect(await store.consume(subject.mobile, value.revision, true, policy)).toEqual({ result: "OTP_EXPIRED" });
  });

  it("TC-005 expired codes cannot activate or verify even before physical cleanup", async () => {
    const subject = keys(), value = challenge();
    await store.reserve(subject, value, policy);
    state.now += 300000;
    expect(await store.read(subject.mobile)).toBeNull();
    await expect(store.activate(subject.mobile, value.revision)).rejects.toThrow();
    expect(await store.consume(subject.mobile, value.revision, true, policy)).toEqual({ result: "OTP_EXPIRED" });
  });

  it("TC-006 resend cooldown and hourly budgets expire using the store clock", async () => {
    const subject = keys();
    for (let i = 0; i < 5; i++) {
      expect(await store.reserve(subject, challenge(), policy)).toEqual({ result: "OK" });
      expect(await store.reserve(subject, challenge(), policy)).toEqual({
        result: "RATE_LIMITED", retryAfterSec: i === 4 ? 3480 : 30,
      });
      state.now += 30000;
    }
    expect((await store.reserve(subject, challenge(), policy)).result).toBe("RATE_LIMITED");
    state.now += 3600000;
    expect(await store.reserve(subject, challenge(), policy)).toEqual({ result: "OK" });
  });

  it.each(["ip", "device"] as const)("TC-006 shares the %s budget across different mobiles", async dimension => {
    const common = keys()[dimension], limit = dimension === "ip" ? 20 : 5;
    for (let i = 0; i < limit; i++) {
      expect(await store.reserve({ ...keys(), [dimension]: common }, challenge(), policy)).toEqual({ result: "OK" });
    }
    expect((await store.reserve({ ...keys(), [dimension]: common }, challenge(), policy)).result).toBe("RATE_LIMITED");
    expect((await store.reserve(keys(), challenge(), policy)).result).toBe("OK");
  });

  it("TC-004 locks on the fifth failure, doubles up to cap and resets after one hour", async () => {
    const subject = keys();
    const custom = { ...policy, lockoutMaxSeconds: 60 };
    for (let round = 0; round < 4; round++) {
      const value = challenge();
      await store.reserve(subject, value, custom);
      await store.activate(subject.mobile, value.revision);
      for (let i = 0; i < 5; i++) {
        expect((await store.consume(subject.mobile, value.revision, false, custom)).result)
          .toBe(i === 4 ? "OTP_ATTEMPTS_EXCEEDED" : "OTP_INVALID");
      }
      expect((await store.consume(subject.mobile, value.revision, true, custom)).result).toBe("OTP_ATTEMPTS_EXCEEDED");
      const delay = round === 0 || round === 3 ? 30 : 60;
      expect(await store.reserve(subject, challenge(), custom)).toEqual({ result: "RATE_LIMITED", retryAfterSec: delay });
      state.now += round === 2 ? 3600000 : delay * 1000;
    }
  });

  it("stale delivery callbacks and comparisons cannot change the replacement challenge", async () => {
    const subject = keys(), first = challenge(), second = challenge();
    await store.reserve(subject, first, policy);
    state.now += 30000;
    await store.reserve(subject, second, policy);
    await store.discard(subject.mobile, first.revision);
    await expect(store.activate(subject.mobile, first.revision)).rejects.toThrow();
    expect((await store.consume(subject.mobile, first.revision, true, policy)).result).toBe("OTP_INVALID");
    await store.activate(subject.mobile, second.revision);
    expect((await store.consume(subject.mobile, second.revision, true, policy)).result).toBe("OK");
  });

  it("shared HTTP/session budgets survive storage object recreation and recover at expiry", async () => {
    const first = new PostgresThrottlerStorage(state, 2);
    const second = new PostgresThrottlerStorage(state, 2);
    expect((await first.increment("synthetic-ip-and-route", 60000)).totalHits).toBe(1);
    state.now += 10000;
    expect((await second.increment("synthetic-ip-and-route", 60000)).totalHits).toBe(2);
    expect(await first.increment("synthetic-ip-and-route", 60000)).toEqual({ totalHits: 3, timeToExpire: 50 });
    expect(JSON.stringify([...state.rows])).not.toContain("synthetic-ip-and-route");
    state.now += 50000;
    expect((await second.increment("synthetic-ip-and-route", 60000)).totalHits).toBe(2);
    state.now += 60000;
    expect((await first.increment("synthetic-ip-and-route", 60000)).totalHits).toBe(1);
  });

  it("fails closed without exposing storage errors or falling back to local counters", async () => {
    jest.spyOn(state, "atomic").mockRejectedValue(new Error("synthetic-private-sql"));
    await expect(new PostgresThrottlerStorage(state, 2).increment("fake", 1000))
      .rejects.toMatchObject({ status: 503, response: { code: "DEPENDENCY_UNAVAILABLE", detail: "Please try again later." } });
  });
});
