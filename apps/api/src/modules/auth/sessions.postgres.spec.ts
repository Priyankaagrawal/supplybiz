import { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import { createHash, createHmac, generateKeyPairSync, randomBytes, randomInt, randomUUID } from "node:crypto";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import request from "supertest";
import { configureHttpApp } from "../../bootstrap";
import { PinoLogger } from "../../common/logging/pino.logger";
import { PrismaService } from "../../prisma/prisma.service";
import { ConsoleOtpProvider } from "./otp.providers";
import { OTP_PROVIDERS } from "./otp.types";
import { SessionTokensService } from "./session-tokens.service";
import { SessionsService } from "./sessions.service";
import { windowsPrivateDirectory } from '../../storage/windows-private-directory';

interface UserView { id: string; roles: string[]; activeRole: string | null }
interface Tokens { accessToken: string; refreshToken: string; expiresInSec: number; user: UserView }
const nativeTests = process.env.SESSIONS_TEST_DATABASE_URL ? describe : describe.skip;
nativeTests("T-015 native HTTP sessions with development/test OTP only", () => {
  let app: INestApplication;
  let peer: INestApplication | undefined;
  let uploadRoot: string;
  const prisma = new PrismaService({ datasources: { db: { url: process.env.SESSIONS_TEST_DATABASE_URL } } });
  const runId = randomUUID();
  const pepper = randomBytes(32).toString("hex");
  const codes = new Map<string, string>();
  const mobiles = new Set<string>();
  const devices = new Set<string>();
  const envBefore = { ...process.env };
  const provider = new ConsoleOtpProvider("test", async delivery => { codes.set(delivery.mobile, delivery.code); });
  async function boot() {
    const { AppModule } = await import("../../app.module");
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(OTP_PROVIDERS).useValue({ SMS: provider, WHATSAPP: provider })
      .overrideProvider(PinoLogger).useValue({ log: jest.fn(), error: jest.fn(), warn: jest.fn() })
      .compile();
    const instance = module.createNestApplication();
    configureHttpApp(instance);
    try { await instance.init(); }
    catch (error) { await instance.close(); throw error; }
    return instance;
  }
  beforeAll(async () => {
    const url = new URL(process.env.SESSIONS_TEST_DATABASE_URL!);
    if (!url.pathname.endsWith("_test")) throw new Error("Use a dedicated database ending in _test");
    // The real storage module rejects source/temp roots; use a private disposable
    // subdirectory on the native persistent-storage path and remove only that directory.
    const storageBase = join(homedir(), ".local", "share", "supplybiz", "test-uploads");
    await mkdir(storageBase, { recursive: true, mode: 0o700 });
    uploadRoot = await mkdtemp(join(storageBase, "sessions-"));
    if (process.platform === 'win32') await windowsPrivateDirectory(uploadRoot, true);
    Object.assign(process.env, {
      NODE_ENV: "test", DATABASE_URL: url.toString(), UPLOAD_ROOT: uploadRoot,
      OTP_DELIVERY_MODE: "console", OTP_HMAC_PEPPER: pepper, RATE_LIMIT_MAX_REQUESTS: "1000",
      AUTH_SIGNING_KEY_ID: "synthetic-sessions", AUTH_PREVIOUS_PUBLIC_KEYS: "{}",
      AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync("ed25519").privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
    });
    await prisma.$connect();
    app = await boot();
    peer = await boot(); // Independent API instances, same DB and signing key.
  });
  afterAll(async () => {
    await peer?.close(); await app?.close();
    if (uploadRoot) {
      const users = await prisma.users.findMany({ where: { mobile: { in: [...mobiles] } }, select: { id: true } });
      const userIds = users.map(user => user.id);
      await prisma.sessions.deleteMany({ where: { user_id: { in: userIds } } });
      await prisma.users.deleteMany({ where: { id: { in: userIds } } });
      await prisma.idempotency_keys.deleteMany({ where: { idempotency_key: { startsWith: runId } } });
      const keys: string[] = [];
      for (const mobile of mobiles) for (const kind of ["challenge", "mobile", "lockout"]) {
        keys.push(`otp:${kind}:${digest("mobile", mobile)}`);
      }
      for (const device of devices) keys.push(`otp:device:${digest("device", device)}`);
      for (const ip of ["127.0.0.1", "::ffff:127.0.0.1", "::1"]) keys.push(`otp:ip:${digest("ip", ip)}`);
      for (const key of keys) await prisma.$executeRaw`DELETE FROM auth_abuse_state WHERE key = ${key}`;
      await rm(uploadRoot, { recursive: true, force: true });
    }
    codes.clear();
    await prisma.$disconnect();
    for (const key of Object.keys(process.env)) if (!(key in envBefore)) delete process.env[key];
    Object.assign(process.env, envBefore);
  });
  function digest(kind: string, value: string) {
    return createHmac("sha256", pepper).update(`${kind}:${value}`).digest("hex");
  }
  function mobile() {
    const value = `+919${randomInt(0, 1000000000).toString().padStart(9, "0")}`;
    mobiles.add(value);
    return value;
  }
  function mutation(instance: INestApplication, path: string, access?: string, method: "post" | "put" = "post") {
    const call = request(instance.getHttpServer())[method](`/api/v1/${path}`)
      .set("Idempotency-Key", `${runId}-${randomUUID()}`);
    return access ? call.set("Authorization", `Bearer ${access}`) : call;
  }
  function me(instance: INestApplication, access: string) {
    return request(instance.getHttpServer()).get("/api/v1/me").set("Authorization", `Bearer ${access}`);
  }
  async function send(value: string) {
    const device = randomUUID(); devices.add(device);
    const response = await mutation(app, "auth/otp/send").set("X-Device-Id", device)
      .send({ mobile: value }).expect(200);
    expect(response.body).toEqual({ resendAfterSec: 30, expiresInSec: 300 });
    const code = codes.get(value);
    if (!code) throw new Error("Test delivery capture missing");
    return { mobile: value, code, device: { platform: "ANDROID", appVersion: "synthetic-test" } };
  }
  async function signup(value = mobile()): Promise<Tokens> {
    const input = await send(value);
    const response = await mutation(app, "auth/otp/verify").send({ ...input,
      consent: { termsVersion: "test-terms-v1", privacyVersion: "test-privacy-v1" },
    }).expect(200).expect("Cache-Control", "no-store");
    return response.body as Tokens;
  }
  async function refresh(instance: INestApplication, token: string, status = 200) {
    return mutation(instance, "auth/refresh").send({ refreshToken: token }).expect(status);
  }

  it("TC-013 requires consent and atomically stores versions/timestamps; OTP is single-use", async () => {
    const rejected = mobile();
    const input = await send(rejected);
    await mutation(app, "auth/otp/verify").send(input).expect(400);
    expect(await prisma.users.count({ where: { mobile: rejected } })).toBe(0);
    const tokens = await signup();
    expect(tokens.user).toMatchObject({ roles: [], activeRole: null });
    expect(tokens.expiresInSec).toBe(900);
    const consents = await prisma.consents.findMany({ where: { user_id: tokens.user.id } });
    expect(consents.map(row => [row.doc_type, row.doc_version]).sort()).toEqual([
      ["PRIVACY", "test-privacy-v1"], ["TERMS", "test-terms-v1"],
    ]);
    expect(consents.every(row => row.accepted_at instanceof Date)).toBe(true);
    const [stored] = await prisma.sessions.findMany({ where: { user_id: tokens.user.id } });
    expect(stored?.refresh_token_hash === createHash("sha256").update(tokens.refreshToken).digest("hex")).toBe(true);
    expect(stored!.expires_at.getTime() - Date.now()).toBeGreaterThan(30 * 86400000 - 5000);
    const claims = app.get(SessionTokensService).read(tokens.accessToken);
    expect(claims.exp - claims.iat).toBe(900);
    const value = (await prisma.users.findUniqueOrThrow({ where: { id: tokens.user.id } })).mobile;
    await mutation(app, "auth/otp/verify").send({ mobile: value, code: codes.get(value),
      device: { platform: "ANDROID" } }).expect(410);
    expect(await prisma.sessions.count({ where: { user_id: tokens.user.id } })).toBe(1);
    expect(await prisma.idempotency_keys.count({ where: { idempotency_key: { startsWith: runId },
      path: { in: ["/api/v1/auth/otp/verify", "/api/v1/auth/refresh"] } } })).toBe(0);
  });

  it("TC-008 persists held and active roles across instances/reconnect without re-login", async () => {
    const tokens = await signup();
    await mutation(app, "me/active-role", tokens.accessToken, "put").send({ role: "VENDOR" }).expect(403);
    const selected = await mutation(app, "me/roles", tokens.accessToken).send({ role: "CUSTOMER" }).expect(200);
    expect(selected.body.activeRole).toBe("CUSTOMER");
    await mutation(app, "me/roles", tokens.accessToken).send({ role: "VENDOR" }).expect(200);
    await mutation(app, "me/active-role", tokens.accessToken, "put").send({ role: "VENDOR" }).expect(200);
    const response = await me(peer!, tokens.accessToken).expect(200);
    expect(response.body.activeRole).toBe("VENDOR");
    expect(response.body.roles.sort()).toEqual(["CUSTOMER", "VENDOR"]);
    expect(Object.keys(response.body).sort()).toEqual(["activeRole", "id", "language", "mobile", "name", "roles"]);
    await peer!.close(); peer = await boot();
    expect((await me(peer, tokens.accessToken).expect(200)).body.activeRole).toBe("VENDOR");
    const rotated = (await refresh(peer, tokens.refreshToken)).body as Tokens;
    expect(rotated.user.activeRole).toBe("VENDOR");
    expect(app.get(SessionTokensService).read(rotated.accessToken).roles.sort()).toEqual(["CUSTOMER", "VENDOR"]);
  });

  it("TC-009 rotates once, rejects reuse and commits family revocation across instances", async () => {
    const tokens = await signup();
    const rotated = (await refresh(peer!, tokens.refreshToken)).body as Tokens;
    expect(rotated.refreshToken === tokens.refreshToken).toBe(false);
    await me(app, tokens.accessToken).expect(401);
    await me(app, rotated.accessToken).expect(200);
    expect((await refresh(app, tokens.refreshToken, 401)).body.code).toBe("REFRESH_REUSED");
    await me(peer!, rotated.accessToken).expect(401);
    await refresh(app, rotated.refreshToken, 401);
    expect(await prisma.sessions.count({ where: { user_id: tokens.user.id, status: "ACTIVE" } })).toBe(0);
  });

  it("TC-009 concurrent refresh across instances produces one successor then revokes the family", async () => {
    const tokens = await signup();
    const responses = await Promise.all([app, peer!].map(instance =>
      mutation(instance, "auth/refresh").send({ refreshToken: tokens.refreshToken })));
    expect(responses.map(response => response.status).sort()).toEqual([200, 401]);
    expect(responses.find(response => response.status === 401)?.body.code).toBe("REFRESH_REUSED");
    expect(await prisma.sessions.count({ where: { user_id: tokens.user.id } })).toBe(2);
    expect(await prisma.sessions.count({ where: { user_id: tokens.user.id, status: "ACTIVE" } })).toBe(0);
  });

  it("TC-010 current logout preserves the other device; logout-all revokes both devices and refresh tokens", async () => {
    const value = mobile();
    const first = await signup(value);
    // Advance only this fixture's resend cooldown; production policy stays unchanged.
    await prisma.$executeRaw`UPDATE auth_abuse_state SET value = '[]'::jsonb
      WHERE key = ${`otp:mobile:${digest("mobile", value)}`}`;
    const input = await send(value);
    const second = (await mutation(app, "auth/otp/verify").send(input).expect(200)).body as Tokens;
    await mutation(app, "auth/logout", first.accessToken).expect(204);
    await me(peer!, first.accessToken).expect(401);
    await refresh(app, first.refreshToken, 401);
    await me(peer!, second.accessToken).expect(200);
    const rotated = (await refresh(app, second.refreshToken)).body as Tokens;
    await mutation(peer!, "auth/logout?all=true", rotated.accessToken).expect(204);
    await me(app, rotated.accessToken).expect(401);
    await refresh(app, rotated.refreshToken, 401);
    expect(await prisma.sessions.count({ where: { user_id: first.user.id, status: "ACTIVE" } })).toBe(0);
  });

  it("TC-010 logout-all invalidates another still-active device on its next API call", async () => {
    const value = mobile(), first = await signup(value);
    await prisma.$executeRaw`UPDATE auth_abuse_state SET value = '[]'::jsonb
      WHERE key = ${`otp:mobile:${digest("mobile", value)}`}`;
    const input = await send(value);
    const second = (await mutation(app, "auth/otp/verify").send(input).expect(200)).body as Tokens;
    await mutation(app, "auth/logout?all=true", first.accessToken).expect(204);
    await me(peer!, second.accessToken).expect(401);
    await refresh(peer!, second.refreshToken, 401);
  });

  it("TC-010 an already authenticated logout revokes a concurrent refresh successor", async () => {
    const tokens = await signup();
    const claims = app.get(SessionTokensService).read(tokens.accessToken);
    const results = await Promise.allSettled([
      peer!.get(SessionsService).refresh(tokens.refreshToken),
      app.get(SessionsService).logout(tokens.user.id, claims.sid, false),
    ]);
    expect(results[1]?.status).toBe("fulfilled");
    expect(await prisma.sessions.count({ where: { user_id: tokens.user.id, status: "ACTIVE" } })).toBe(0);
  });

  it("rejects expired/revoked sessions, blocked accounts and forged ownership", async () => {
    const tokens = await signup(), victim = await signup();
    await mutation(app, "me/roles", tokens.accessToken).send({ role: "VENDOR", userId: victim.user.id }).expect(400);
    await mutation(app, "me/roles", tokens.accessToken).send({ role: "ADMIN" }).expect(400);
    expect(await prisma.user_roles.count({ where: { user_id: victim.user.id } })).toBe(0);
    const claims = app.get(SessionTokensService).read(tokens.accessToken);
    const forged = app.get(SessionTokensService).issue(victim.user.id, claims.sid, []);
    await me(app, forged).expect(401);
    await prisma.users.update({ where: { id: tokens.user.id }, data: { status: "BLOCKED" } });
    await me(app, tokens.accessToken).expect(403);
    await refresh(app, tokens.refreshToken, 403);
    await prisma.users.update({ where: { id: tokens.user.id }, data: { status: "ACTIVE" } });
    await prisma.sessions.update({ where: { id: claims.sid }, data: { expires_at: new Date(0) } });
    await me(app, tokens.accessToken).expect(401);
    await refresh(app, tokens.refreshToken, 401);
    await refresh(app, randomBytes(32).toString("base64url"), 401);
  });
});
