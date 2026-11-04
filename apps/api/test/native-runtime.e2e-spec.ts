import { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { configureHttpApp } from "../src/bootstrap";

const nativeTests = process.env.NATIVE_TEST_DATABASE_URL ? describe : describe.skip;
nativeTests("T-182/T-184 real native runtime smoke", () => {
  let app: INestApplication;
  beforeAll(async () => {
    const url = new URL(process.env.NATIVE_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith("_test")) throw new Error("Use a dedicated database ending in _test");
    process.env.NODE_ENV = "test";
    process.env.DATABASE_URL = url.toString();
    process.env.HEALTHCHECK_STRICT = "true";
    process.env.OTP_DELIVERY_MODE = "disabled";
    const { AppModule } = await import("../src/app.module");
    const module = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = module.createNestApplication();
    configureHttpApp(app);
    await app.init();
  });
  afterAll(async () => { await app?.close(); });

  it("readiness queries real PostgreSQL and probes persistent private storage", async () => {
    const response = await request(app.getHttpServer()).get("/api/v1/health/ready").expect(200);
    expect(response.body).toMatchObject({ status: "UP", strict: true,
      checks: { database: { status: "up" }, storage: { status: "up" } } });
    expect(JSON.stringify(response.body)).not.toMatch(/postgresql:|UPLOAD_ROOT|password/);
  });
  it("disabled providers fail closed through the real global DB limiter", async () => {
    const response = await request(app.getHttpServer()).post("/api/v1/auth/otp/send")
      .set("Idempotency-Key", "synthetic-native-smoke").set("X-Device-Id", "synthetic-native-device")
      .send({ mobile: "9000000000" }).expect(503);
    expect(response.body.code).toBe("OTP_PROVIDER_UNAVAILABLE");
    expect(JSON.stringify(response.body)).not.toMatch(/postgresql:|password/);
  });
});
