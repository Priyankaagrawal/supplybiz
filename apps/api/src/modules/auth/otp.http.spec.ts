import { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import { randomBytes } from "node:crypto";
import request from "supertest";
import { configureHttpApp } from "../../bootstrap";
import { PinoLogger } from "../../common/logging/pino.logger";
import { IdempotencyInterceptor } from "../idempotency/idempotency.interceptor";
import { IdempotencyService } from "../idempotency/idempotency.service";
import { OtpController } from "./otp.controller";
import { OtpService } from "./otp.service";
import { ConsoleOtpProvider } from "./otp.providers";
import { OtpStore } from "./otp.types";

describe("T-014 OTP send HTTP boundary", () => {
  let app: INestApplication;
  const reserve = jest.fn<ReturnType<OtpStore["reserve"]>, Parameters<OtpStore["reserve"]>>();
  beforeAll(async () => {
    const store: OtpStore = {
      reserve,
      read: async () => null,
      consume: async () => ({ result: "OTP_EXPIRED" }),
      activate: async () => {},
      discard: async () => {},
    };
    const provider = new ConsoleOtpProvider("test");
    const otp = new OtpService(
      store,
      { SMS: provider, WHATSAPP: provider },
      {
        pepper: randomBytes(32).toString("hex"),
        deviceSendsPerHour: 5,
        lockoutBaseSeconds: 30,
        lockoutMaxSeconds: 3600,
      }
    );
    const module = await Test.createTestingModule({
      controllers: [OtpController],
      providers: [
        { provide: OtpService, useValue: otp },
        { provide: PinoLogger, useValue: { log: jest.fn(), error: jest.fn(), warn: jest.fn() } },
        IdempotencyInterceptor,
        {
          provide: IdempotencyService,
          useValue: {
            hashRequestBody: () => "fake-hash",
            getReplayResponse: async () => null,
            storeResponse: async () => {},
          },
        },
      ],
    }).compile();
    app = module.createNestApplication();
    configureHttpApp(app);
    // Exercise the real required-header interceptor without requiring Postgres.
    app.useGlobalInterceptors(module.get(IdempotencyInterceptor));
    await app.init();
  });
  beforeEach(() => reserve.mockReset().mockResolvedValue({ result: "OK" }));
  afterAll(async () => {
    await app?.close();
  });
  const send = () =>
    request(app.getHttpServer())
      .post("/api/v1/auth/otp/send")
      .set("Idempotency-Key", "fake-request-key")
      .set("X-Device-Id", "fake-installation");

  it("TC-001/TC-007 returns the same public response for either channel without exposing secrets", async () => {
    for (const channel of ["SMS", "WHATSAPP"]) {
      const response = await send().send({ mobile: "9000000000", channel }).expect(200);
      expect(response.body).toEqual({ resendAfterSec: 30, expiresInSec: 300 });
    }
  });
  it("TC-002 rejects invalid input, unknown fields, missing device/key and invalid app hash", async () => {
    for (const payload of [
      { mobile: "5000000000" },
      { mobile: "9000000000", channel: "EMAIL" },
      { mobile: "9000000000", channel: null },
      { mobile: "9000000000", appHash: "bad" },
      { mobile: "9000000000", role: "VENDOR" },
    ]) {
      const response = await send().send(payload).expect(400);
      expect(response.body.code).toBe("VALIDATION_FAILED");
    }
    await request(app.getHttpServer())
      .post("/api/v1/auth/otp/send")
      .set("Idempotency-Key", "fake-key")
      .send({ mobile: "9000000000" })
      .expect(400);
    await request(app.getHttpServer())
      .post("/api/v1/auth/otp/send")
      .set("X-Device-Id", "fake-installation")
      .send({ mobile: "9000000000" })
      .expect(400);
    expect(reserve).not.toHaveBeenCalled();
  });
  it("TC-006 returns Problem Details and Retry-After on Redis rate rejection", async () => {
    reserve.mockResolvedValue({ result: "RATE_LIMITED", retryAfterSec: 37 });
    const response = await send().send({ mobile: "9000000000" }).expect(429);
    expect(response.body).toMatchObject({ code: "RATE_LIMITED", status: 429 });
    expect(response.headers["retry-after"]).toBe("37");
  });
  it("Redis failure returns safe 503 without internal command/provider data", async () => {
    reserve.mockRejectedValue(new Error("fake-private-detail"));
    const response = await send().send({ mobile: "9000000000" }).expect(503);
    expect(response.body.code).toBe("OTP_UNAVAILABLE");
    expect(JSON.stringify(response.body)).not.toContain("fake-private-detail");
  });
});
