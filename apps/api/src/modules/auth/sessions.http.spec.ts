import { INestApplication } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Test } from "@nestjs/testing";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import { randomUUID } from "node:crypto";
import request from "supertest";
import { configureHttpApp } from "../../bootstrap";
import { PinoLogger } from "../../common/logging/pino.logger";
import { IdempotencyInterceptor } from "../idempotency/idempotency.interceptor";
import { IdempotencyService } from "../idempotency/idempotency.service";
import { MeController, SessionGuard, SessionsController } from "./sessions.controller";
import { SessionTokensService, unauthenticated } from "./session-tokens.service";
import { SessionsService } from "./sessions.service";

describe("T-015 session HTTP boundary", () => {
  let app: INestApplication;
  const userId = randomUUID();
  const sessionId = randomUUID();
  const sessions = { login: jest.fn(), refresh: jest.fn(), authenticate: jest.fn(),
    me: jest.fn(), role: jest.fn(), logout: jest.fn() };
  const cache = { hashRequestBody: jest.fn(), getReplayResponse: jest.fn(), storeResponse: jest.fn() };
  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [SessionsController, MeController],
      providers: [SessionGuard, IdempotencyInterceptor,
        { provide: SessionsService, useValue: sessions },
        { provide: SessionTokensService, useValue: new SessionTokensService(new ConfigService({ NODE_ENV: "test" })) },
        { provide: IdempotencyService, useValue: cache },
        { provide: PinoLogger, useValue: { log: jest.fn(), error: jest.fn(), warn: jest.fn() } },
      ],
    }).compile();
    app = module.createNestApplication();
    configureHttpApp(app);
    app.useGlobalInterceptors(module.get(IdempotencyInterceptor));
    await app.init();
  });
  beforeEach(() => {
    jest.clearAllMocks();
    sessions.authenticate.mockImplementation(async (token: string) => {
      if (token !== "fake-access") throw unauthenticated();
      return { userId, sessionId };
    });
    sessions.login.mockResolvedValue({ accessToken: "fake-access", refreshToken: "fake-refresh" });
    sessions.refresh.mockResolvedValue({ accessToken: "fake-access-next", refreshToken: "fake-refresh-next" });
    sessions.me.mockResolvedValue({ id: userId, roles: [], activeRole: null });
    sessions.role.mockResolvedValue({ id: userId, roles: ["VENDOR"], activeRole: "VENDOR" });
  });
  afterAll(async () => { await app?.close(); });
  const verify = (payload: object) => request(app.getHttpServer()).post("/api/v1/auth/otp/verify")
    .set("Idempotency-Key", "fake-request-key").send(payload);
  const valid = { mobile: "9000000000", code: "123456", device: { platform: "ANDROID" },
    consent: { termsVersion: "test-v1", privacyVersion: "test-v1" } };

  it("Swagger keeps logout all optional and requires idempotency only on mutations", () => {
    const document = SwaggerModule.createDocument(app, new DocumentBuilder().addBearerAuth().build());
    expect(document.paths["/api/v1/auth/logout"].post?.parameters).toContainEqual(
      expect.objectContaining({ name: "all", in: "query", required: false })
    );
    for (const path of ["otp/verify", "refresh", "logout"]) {
      expect(document.paths[`/api/v1/auth/${path}`].post?.parameters).toContainEqual(
        expect.objectContaining({ name: "Idempotency-Key", in: "header", required: true })
      );
    }
    expect(document.paths["/api/v1/auth/.well-known/jwks.json"].get?.parameters ?? []).not.toContainEqual(
      expect.objectContaining({ name: "Idempotency-Key" })
    );
  });

  it("FR-009 validates nested consent/device and rejects injected roles, IDs and unknown fields", async () => {
    for (const payload of [
      { ...valid, mobile: "5000000000" }, { ...valid, code: "123" },
      { ...valid, device: undefined }, { ...valid, device: { platform: "UNKNOWN" } },
      { ...valid, consent: { termsVersion: "test-v1" } },
      { ...valid, consent: { ...valid.consent, accepted: false } },
      { ...valid, userId: randomUUID() }, { ...valid, role: "VENDOR" },
    ]) {
      const response = await verify(payload).expect(400);
      expect(response.body.code).toBe("VALIDATION_FAILED");
    }
    expect(sessions.login).not.toHaveBeenCalled();
  });
  it("never stores or replays plaintext tokens in global idempotency cache", async () => {
    await verify(valid).expect(200).expect("Cache-Control", "no-store");
    await request(app.getHttpServer()).post("/api/v1/auth/refresh")
      .set("Idempotency-Key", "fake-same-key").send({ refreshToken: "A".repeat(43) })
      .expect(200).expect("Cache-Control", "no-store");
    expect(cache.hashRequestBody).not.toHaveBeenCalled();
    expect(cache.getReplayResponse).not.toHaveBeenCalled();
    expect(cache.storeResponse).not.toHaveBeenCalled();
    await request(app.getHttpServer()).post("/api/v1/auth/refresh")
      .send({ refreshToken: "A".repeat(43) }).expect(400);
    await request(app.getHttpServer()).post("/api/v1/auth/refresh")
      .set("Idempotency-Key", "fake-key").send({ refreshToken: "bad" }).expect(400);
  });
  it("TC-008 /me and role changes derive ownership from the guarded session", async () => {
    await request(app.getHttpServer()).get("/api/v1/me").set("Authorization", "Bearer fake-access").expect(200);
    expect(sessions.me).toHaveBeenCalledWith(userId);
    await request(app.getHttpServer()).post("/api/v1/me/roles")
      .set("Authorization", "Bearer fake-access").set("Idempotency-Key", "fake-key")
      .send({ role: "VENDOR", userId: randomUUID() }).expect(400);
    await request(app.getHttpServer()).post("/api/v1/me/roles")
      .set("Authorization", "Bearer fake-access").set("Idempotency-Key", "fake-key")
      .send({ role: "ADMIN" }).expect(400);
    await request(app.getHttpServer()).post("/api/v1/me/roles")
      .set("Authorization", "Bearer fake-access").set("Idempotency-Key", "fake-key")
      .send({ role: "VENDOR" }).expect(200);
    expect(sessions.role).toHaveBeenLastCalledWith(userId, "VENDOR", false);
    await request(app.getHttpServer()).put("/api/v1/me/active-role")
      .set("Authorization", "Bearer fake-access").set("Idempotency-Key", "fake-key")
      .send({ role: "VENDOR" }).expect(200);
    expect(sessions.role).toHaveBeenLastCalledWith(userId, "VENDOR", true);
    expect(cache.getReplayResponse).not.toHaveBeenCalled();
  });
  it("TC-010 rejects unauthenticated calls; logout-all targets only the authenticated user", async () => {
    await request(app.getHttpServer()).get("/api/v1/me").expect(401);
    await request(app.getHttpServer()).get("/api/v1/me").set("Authorization", "Bearer fake-revoked").expect(401);
    await request(app.getHttpServer()).post("/api/v1/auth/logout?all=true")
      .set("Authorization", "Bearer fake-access").set("Idempotency-Key", "fake-key").expect(204);
    expect(sessions.logout).toHaveBeenCalledWith(userId, sessionId, true);
    await request(app.getHttpServer()).post("/api/v1/auth/logout?all=invalid")
      .set("Authorization", "Bearer fake-access").set("Idempotency-Key", "fake-key").expect(400);
  });
});
