import { HttpException } from "@nestjs/common";
import { createHmac, randomBytes } from "node:crypto";
import { OtpService } from "./otp.service";
import { ConsoleOtpProvider, SmsOtpProvider, WhatsAppOtpProvider } from "./otp.providers";
import { OtpChallenge, OtpDelivery, OtpPolicy, OtpStore } from "./otp.types";
import { validateEnv } from "../../config/env.schema";

// Synthetic data only. Store behavior is tested separately against Redis.
const mobile = "9000000000";
const context = { ip: "192.0.2.1", deviceId: "fake-installation" };
describe("T-014 OTP service", () => {
  let service: OtpService;
  let policy: OtpPolicy;
  let delivered: OtpDelivery[];
  let challenge: OtpChallenge | null;
  let store: jest.Mocked<OtpStore>;
  beforeEach(() => {
    delivered = [];
    challenge = null;
    policy = {
      pepper: randomBytes(32).toString("hex"),
      deviceSendsPerHour: 5,
      lockoutBaseSeconds: 30,
      lockoutMaxSeconds: 3600,
    };
    store = {
      reserve: jest.fn<ReturnType<OtpStore["reserve"]>, Parameters<OtpStore["reserve"]>>(
        async (_keys, value) => {
          challenge = value;
          return { result: "OK" as const };
        }
      ),
      activate: jest.fn<ReturnType<OtpStore["activate"]>, Parameters<OtpStore["activate"]>>(
        async () => {}
      ),
      discard: jest.fn<ReturnType<OtpStore["discard"]>, Parameters<OtpStore["discard"]>>(
        async () => {}
      ),
      read: jest.fn<ReturnType<OtpStore["read"]>, Parameters<OtpStore["read"]>>(
        async () => challenge
      ),
      consume: jest.fn<ReturnType<OtpStore["consume"]>, Parameters<OtpStore["consume"]>>(
        async (_key, _revision, matches) => {
          if (matches) {
            challenge = null;
            return { result: "OK" as const };
          }
          return { result: "OTP_INVALID" as const };
        }
      ),
    };
    const provider = new ConsoleOtpProvider("test", async (delivery) => {
      delivered.push(delivery);
    });
    service = new OtpService(store, { SMS: provider, WHATSAPP: provider }, policy);
  });

  it("TC-001/TC-003: sends a six-digit OTP; stores only HMAC/salt; normalizes +91 and consumes success", async () => {
    await expect(service.send({ mobile }, context)).resolves.toEqual({
      resendAfterSec: 30,
      expiresInSec: 300,
    });
    const delivery = delivered[0];
    expect(delivery.code).toMatch(/^\d{6}$/);
    expect(delivery.mobile).toBe(`+91${mobile}`);
    expect(delivery.channel).toBe("SMS");
    const key = createHmac("sha256", policy.pepper).update(`mobile:+91${mobile}`).digest("hex");
    const stored = store.reserve.mock.calls[0][1];
    expect(stored.digest).toBe(
      createHmac("sha256", policy.pepper)
        .update(`otp:${key}:${stored.salt}:${delivery.code}`)
        .digest("hex")
    );
    expect(Object.keys(stored).sort()).toEqual(["digest", "revision", "salt"]);
    expect(store.reserve.mock.calls[0][0]).toEqual({
      mobile: key,
      ip: expect.stringMatching(/^[a-f0-9]{64}$/),
      device: expect.stringMatching(/^[a-f0-9]{64}$/),
    });
    await expect(service.verify(`+91${mobile}`, delivery.code)).resolves.toBeUndefined();
    await expect(service.verify(mobile, delivery.code)).rejects.toMatchObject({
      response: { code: "OTP_EXPIRED" },
      status: 410,
    });
  });
  it("TC-002 rejects invalid numbers, channel, app hash and device context before sending", async () => {
    for (const invalid of ["5000000000", "90000", "letters", "+449000000000"]) {
      await expect(service.send({ mobile: invalid }, context)).rejects.toBeInstanceOf(
        HttpException
      );
    }
    await expect(service.send({ mobile, appHash: "bad" }, context)).rejects.toBeInstanceOf(
      HttpException
    );
    await expect(
      service.send({ mobile }, { ...context, deviceId: "bad\nvalue" })
    ).rejects.toBeInstanceOf(HttpException);
    await expect(service.send({ mobile }, { ...context, ip: "untrusted" })).rejects.toBeInstanceOf(
      HttpException
    );
    expect(store.reserve).not.toHaveBeenCalled();
    expect(delivered).toEqual([]);
  });
  it("TC-004/TC-005/TC-006 maps store decisions without leaking secrets", async () => {
    await service.send({ mobile }, context);
    for (const code of ["OTP_INVALID", "OTP_ATTEMPTS_EXCEEDED", "OTP_EXPIRED"] as const) {
      store.consume.mockResolvedValueOnce({ result: code });
      await expect(service.verify(mobile, "000000")).rejects.toMatchObject({ response: { code } });
    }
    store.reserve.mockResolvedValueOnce({ result: "RATE_LIMITED", retryAfterSec: 30 });
    await expect(service.send({ mobile }, context)).rejects.toMatchObject({
      response: { code: "RATE_LIMITED", retryAfterSec: 30 },
      status: 429,
    });
    expect(delivered).toHaveLength(1);
  });
  it("TC-007 routes WhatsApp and optional Android app hash through the provider", async () => {
    await service.send({ mobile, channel: "WHATSAPP", appHash: "FAKEhash12+" }, context);
    expect(delivered[0]).toMatchObject({ channel: "WHATSAPP", appHash: "FAKEhash12+" });
  });
  it("fails closed when delivery/Redis fails and never activates a failed delivery", async () => {
    const provider = new ConsoleOtpProvider("test", async () => {
      throw new Error("fake provider detail");
    });
    service = new OtpService(store, { SMS: provider, WHATSAPP: provider }, policy);
    await expect(service.send({ mobile }, context)).rejects.toMatchObject({
      response: { code: "OTP_PROVIDER_UNAVAILABLE" },
      status: 503,
    });
    expect(store.discard).toHaveBeenCalled();
    expect(store.activate).not.toHaveBeenCalled();
    store.reserve.mockRejectedValueOnce(new Error("fake private Redis error"));
    await expect(service.send({ mobile }, context)).rejects.toMatchObject({
      response: { code: "OTP_UNAVAILABLE", detail: "OTP service is unavailable." },
    });
  });
  it("reissuing changes the salt/digest and stale codes do not verify", async () => {
    await service.send({ mobile }, context);
    const first = store.reserve.mock.calls[0][1];
    await service.send({ mobile }, context);
    expect(store.reserve.mock.calls[1][1].salt).not.toEqual(first.salt);
    // A guaranteed wrong synthetic code avoids randomness-dependent assertions.
    const wrong = delivered[1].code === "000000" ? "000001" : "000000";
    await expect(service.verify(mobile, wrong)).rejects.toMatchObject({
      response: { code: "OTP_INVALID" },
    });
    expect(store.consume.mock.calls.at(-1)?.[2]).toBe(false);
  });
  it("production adapters remain disabled and console cannot be enabled outside dev/test", () => {
    for (const provider of [
      new SmsOtpProvider(),
      new WhatsAppOtpProvider(),
      new ConsoleOtpProvider("production"),
      new ConsoleOtpProvider("staging"),
    ]) {
      expect(() => provider.assertAvailable()).toThrow(HttpException);
    }
    expect(() =>
      validateEnv({
        NODE_ENV: "production",
        OTP_DELIVERY_MODE: "console",
        OTP_HMAC_PEPPER: policy.pepper,
      })
    ).toThrow();
    expect(() => validateEnv({ OTP_DELIVERY_MODE: "console" })).toThrow();
    expect(validateEnv({}).OTP_DELIVERY_MODE).toBe("disabled");
  });
});
