import { Prisma } from "@prisma/client";
import { Controller, Get, INestApplication } from "@nestjs/common";
import { APP_GUARD } from "@nestjs/core";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { configureHttpApp } from "../../bootstrap";
import { PinoLogger } from "../../common/logging/pino.logger";
import { PrismaService } from "../../prisma/prisma.service";
import { AppConfigController, AppConfigService, AppVersionGuard, isOlderVersion } from "./app-config";

describe("T-017 version policy", () => {
  it("FR-408 compares numeric components and rejects malformed versions", () => {
    expect(isOlderVersion("0.9.9", "0.10.0")).toBe(true);
    expect(isOlderVersion("1.0.0", "0.99.0")).toBe(false);
    expect(isOlderVersion("0.1.0", "0.1.0")).toBe(false);
    for (const value of ["", "01.0.0", "1.0", "1.0.0-beta", "9999999.0.0"]) {
      expect(() => isOlderVersion(value, "0.1.0")).toThrow();
    }
  });
});
@Controller("protected")
class ProbeController {
  @Get() read() { return { ok: true }; }
}
const nativeTests = process.env.CONFIG_TEST_DATABASE_URL ? describe : describe.skip;
nativeTests("T-017 FR-408 native PostgreSQL HTTP config smoke", () => {
  let app: INestApplication;
  const prisma = new PrismaService({ datasources: { db: { url: process.env.CONFIG_TEST_DATABASE_URL } } });
  let previous: Awaited<ReturnType<typeof prisma.app_config.findUnique>>;
  async function boot() {
    const module = await Test.createTestingModule({
      controllers: [AppConfigController, ProbeController],
      providers: [AppConfigService, { provide: PrismaService, useValue: prisma },
        { provide: PinoLogger, useValue: { log: jest.fn(), error: jest.fn(), warn: jest.fn() } },
        { provide: APP_GUARD, useClass: AppVersionGuard }],
    }).compile();
    const instance = module.createNestApplication();
    configureHttpApp(instance); await instance.init(); return instance;
  }
  async function policy(minimum = "0.10.0") {
    await prisma.app_config.upsert({ where: { key: "mobile" },
      create: { key: "mobile", value: { minVersionAndroid: minimum, flags: { operationalNotice: true } } },
      update: { value: { minVersionAndroid: minimum, flags: { operationalNotice: true } } } });
  }
  beforeAll(async () => {
    if (!new URL(process.env.CONFIG_TEST_DATABASE_URL!).pathname.endsWith("_test")) throw new Error("Use a dedicated _test database");
    await prisma.$connect();
    previous = await prisma.app_config.findUnique({ where: { key: "mobile" } });
    await policy(); app = await boot();
  });
  afterAll(async () => {
    await app?.close();
    if (previous) {
      const restored = { ...previous, value: previous.value ?? Prisma.JsonNull };
      await prisma.app_config.upsert({ where: { key: "mobile" }, create: restored, update: restored });
    }
    else await prisma.app_config.deleteMany({ where: { key: "mobile" } });
    await prisma.$disconnect();
  });
  it("loads persisted public policy without auth, survives service restart, exposes no mutation", async () => {
    let response = await request(app.getHttpServer()).get("/api/v1/config").expect(200).expect("Cache-Control", "public, max-age=60");
    expect(response.body).toEqual({ minVersionAndroid: "0.10.0", flags: { operationalNotice: true } });
    await app.close(); app = await boot();
    response = await request(app.getHttpServer()).get("/api/v1/config").expect(200);
    expect(response.body.minVersionAndroid).toBe("0.10.0");
    await request(app.getHttpServer()).post("/api/v1/config").send({ flags: {} }).expect(404);
  });
  it("blocks old Android, admits equal/newer versions, keeps config available, validates metadata", async () => {
    const call = (version: string, path = "/protected") => request(app.getHttpServer()).get(`/api/v1${path}`)
      .set("X-Platform", "android").set("X-App-Version", version);
    expect((await call("0.9.9").expect(426)).body.code).toBe("UPGRADE_REQUIRED");
    await call("0.10.0").expect(200); await call("1.0.0").expect(200);
    await call("broken").expect(400); await call("0.0.1", "/config").expect(200);
    await request(app.getHttpServer()).get("/api/v1/protected").expect(200); // Non-mobile callers.
  });
  it("invalid persisted config fails closed with a safe error", async () => {
    await prisma.app_config.update({ where: { key: "mobile" }, data: { value: { minVersionAndroid: "bad", flags: { test: "secret" } } } });
    const response = await request(app.getHttpServer()).get("/api/v1/config").expect(503);
    expect(response.body.code).toBe("CONFIG_UNAVAILABLE");
    expect(JSON.stringify(response.body)).not.toMatch(/secret|postgresql:/);
    await policy();
  });
});
