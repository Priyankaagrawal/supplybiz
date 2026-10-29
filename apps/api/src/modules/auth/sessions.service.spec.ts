import { ConfigService } from "@nestjs/config";
import { createHash, generateKeyPairSync, randomUUID } from "node:crypto";
import { PrismaService } from "../../prisma/prisma.service";
import { OtpService } from "./otp.service";
import { SessionTokensService } from "./session-tokens.service";
import { SessionsService } from "./sessions.service";

describe("T-015 session security (TC-008–TC-010, FR-009)", () => {
  const userId = randomUUID();
  const sessionId = randomUUID();
  const familyId = randomUUID();
  const user = { id: userId, mobile: "+919000000000", name: null, language: "EN",
    active_role: "CUSTOMER", status: "ACTIVE", roles: [{ role: "CUSTOMER" }] };
  const session = { id: sessionId, user_id: userId, family_id: familyId, device_id: null,
    status: "ACTIVE", last_used_at: null, expires_at: new Date(Date.now() + 86400000) };
  const db = {
    $queryRaw: jest.fn().mockResolvedValue([]),
    users: { findUnique: jest.fn(), findUniqueOrThrow: jest.fn(), create: jest.fn(), update: jest.fn() },
    devices: { create: jest.fn() },
    user_roles: { upsert: jest.fn() },
    sessions: { findFirst: jest.fn(), findUnique: jest.fn(), findUniqueOrThrow: jest.fn(),
      create: jest.fn(), update: jest.fn(), updateMany: jest.fn() },
    $transaction: jest.fn(),
  };
  const verifyOtp = jest.fn();
  let service: SessionsService;
  let tokens: SessionTokensService;
  beforeEach(() => {
    jest.clearAllMocks();
    db.$transaction.mockImplementation(async (callback: (tx: typeof db) => Promise<unknown>) => callback(db));
    db.users.findUnique.mockResolvedValue(user);
    db.users.findUniqueOrThrow.mockResolvedValue(user);
    db.users.create.mockResolvedValue(user);
    db.devices.create.mockResolvedValue({ id: randomUUID() });
    db.sessions.findFirst.mockResolvedValue(session);
    db.sessions.findUniqueOrThrow.mockResolvedValue(session);
    db.sessions.findUnique.mockResolvedValue({ ...session, user });
    db.sessions.create.mockImplementation(async ({ data }: { data: object }) => ({ ...data, id: randomUUID() }));
    verifyOtp.mockResolvedValue(undefined);
    tokens = new SessionTokensService(new ConfigService({ NODE_ENV: "test" }));
    service = new SessionsService(db as unknown as PrismaService,
      { verify: verifyOtp } as unknown as OtpService, tokens);
  });

  it("TC-013/FR-009 consumes a verified OTP before creating a user; signup requires consent", async () => {
    db.users.findUnique.mockResolvedValue(null);
    await expect(service.login("9000000000", "123456", { platform: "ANDROID" })).rejects.toMatchObject({
      status: 400, response: { code: "VALIDATION_FAILED" },
    });
    expect(db.users.create).not.toHaveBeenCalled();
    await service.login("9000000000", "123456", { platform: "ANDROID" },
      { termsVersion: "test-terms-v1", privacyVersion: "test-privacy-v1" }, "127.0.0.1");
    expect(verifyOtp).toHaveBeenCalledWith("9000000000", "123456");
    expect(db.users.create).toHaveBeenCalledWith(expect.objectContaining({ data: {
      mobile: "+919000000000", consents: { create: [
        { doc_type: "TERMS", doc_version: "test-terms-v1", ip: "127.0.0.1" },
        { doc_type: "PRIVACY", doc_version: "test-privacy-v1", ip: "127.0.0.1" },
      ] },
    } }));
  });
  it("failed OTP never accesses account/session storage", async () => {
    verifyOtp.mockRejectedValueOnce(new Error("fake-otp-failure"));
    await expect(service.login("9000000000", "123456", { platform: "ANDROID" })).rejects.toThrow();
    expect(db.$transaction).not.toHaveBeenCalled();
  });
  it("stores only refresh SHA-256, issues 15m access and sliding 30d refresh in same family", async () => {
    const result = await service.refresh("fake-refresh-input");
    const data = db.sessions.create.mock.calls[0][0].data;
    expect(data.family_id).toBe(familyId);
    expect(data.refresh_token_hash).toBe(createHash("sha256").update(result.refreshToken).digest("hex"));
    expect(JSON.stringify(data)).not.toContain(result.refreshToken);
    expect(result.refreshToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(data.expires_at.getTime() - Date.now()).toBeGreaterThan(30 * 86400000 - 5000);
    const claims = tokens.read(result.accessToken);
    expect(claims.exp - claims.iat).toBe(900);
    expect(claims).toMatchObject({ sub: userId, aud: "mobile", roles: ["CUSTOMER"] });
    expect(db.sessions.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: "REVOKED", last_used_at: expect.any(Date) }),
    }));
  });
  it("TC-009 reuse commits family revocation before REFRESH_REUSED; never issues tokens", async () => {
    db.sessions.findUniqueOrThrow.mockResolvedValue({ ...session, last_used_at: new Date(), status: "REVOKED" });
    await expect(service.refresh("fake-consumed-refresh")).rejects.toMatchObject({ response: { code: "REFRESH_REUSED" } });
    expect(db.sessions.updateMany).toHaveBeenCalledWith({ where: { family_id: familyId },
      data: { status: "REVOKED", revoked_at: expect.any(Date) } });
    expect(db.sessions.create).not.toHaveBeenCalled();
    await expect(db.$transaction.mock.results[0].value).resolves.toBeNull();
  });
  it("rejects unknown, expired, revoked refresh and blocked users", async () => {
    db.sessions.findFirst.mockResolvedValueOnce(null);
    await expect(service.refresh("fake-unknown")).rejects.toMatchObject({ status: 401 });
    for (const state of [{ status: "REVOKED" }, { expires_at: new Date(0) }]) {
      db.sessions.findUniqueOrThrow.mockResolvedValueOnce({ ...session, ...state });
      await expect(service.refresh("fake-invalid")).rejects.toMatchObject({ status: 401 });
    }
    db.users.findUniqueOrThrow.mockResolvedValueOnce({ ...user, status: "BLOCKED" });
    await expect(service.refresh("fake-blocked")).rejects.toMatchObject({ response: { code: "ACCOUNT_BLOCKED" } });
    expect(db.sessions.create).not.toHaveBeenCalled();
  });
  it("TC-010 revokes every device on logout-all; current logout revokes only its family", async () => {
    await service.logout(userId, sessionId, true);
    expect(db.sessions.updateMany).toHaveBeenLastCalledWith(expect.objectContaining({ where: { user_id: userId } }));
    await service.logout(userId, sessionId, false);
    expect(db.sessions.updateMany).toHaveBeenLastCalledWith(expect.objectContaining({
      where: { user_id: userId, family_id: familyId },
    }));
    db.sessions.findUnique.mockResolvedValueOnce({ ...session, status: "REVOKED", user });
    await expect(service.authenticate(tokens.issue(userId, sessionId, ["CUSTOMER"]))).rejects.toMatchObject({ status: 401 });
  });
  it("guards reject forged session ownership and blocked users even with valid signature", async () => {
    db.sessions.findUnique.mockResolvedValueOnce({ ...session, user_id: randomUUID(), user });
    await expect(service.authenticate(tokens.issue(userId, sessionId, []))).rejects.toMatchObject({ status: 401 });
    db.sessions.findUnique.mockResolvedValueOnce({ ...session, user: { ...user, status: "BLOCKED" } });
    await expect(service.authenticate(tokens.issue(userId, sessionId, []))).rejects.toMatchObject({ status: 403 });
  });
  it("TC-008 first role is selected; unheld role switch is rejected; roles are self scoped", async () => {
    await expect(service.role(userId, "VENDOR", true)).rejects.toMatchObject({ response: { code: "ROLE_NOT_HELD" } });
    expect(db.users.update).not.toHaveBeenCalled();
    db.users.findUniqueOrThrow.mockResolvedValueOnce({ ...user, roles: [] });
    await service.role(userId, "VENDOR", false);
    expect(db.user_roles.upsert).toHaveBeenCalledWith({ where: { user_id_role: { user_id: userId, role: "VENDOR" } },
      create: { user_id: userId, role: "VENDOR" }, update: {} });
    expect(db.users.update).toHaveBeenCalledWith({ where: { id: userId }, data: { active_role: "VENDOR" } });
    db.users.findUniqueOrThrow.mockResolvedValueOnce({ ...user, roles: [{ role: "CUSTOMER" }, { role: "VENDOR" }] });
    await service.role(userId, "VENDOR", true);
    expect(db.users.update).toHaveBeenLastCalledWith({ where: { id: userId }, data: { active_role: "VENDOR" } });
  });
  it("first login exposes no active role until selection; /me never returns session secrets", async () => {
    db.users.findUniqueOrThrow.mockResolvedValueOnce({ ...user, roles: [] });
    const result = await service.me(userId);
    expect(result).toMatchObject({ activeRole: null, roles: [] });
    expect(Object.keys(result).sort()).toEqual(["activeRole", "id", "language", "mobile", "name", "roles"]);
  });

  it("verifies signatures, algorithm, expiry and retained public key after rotation", () => {
    const jwt = tokens.issue(userId, sessionId, []);
    expect(() => tokens.read(`${jwt.slice(0, -10)}AAAAAAAAAA`)).toThrow();
    expect(() => tokens.read(`eyJhbGciOiJub25lIn0.${jwt.split(".")[1]}.`)).toThrow();
    jest.useFakeTimers();
    jest.setSystemTime(Date.now() + 901000);
    expect(() => tokens.read(jwt)).toThrow();
    jest.useRealTimers();
    const old = generateKeyPairSync("ed25519");
    const first = new SessionTokensService(new ConfigService({ NODE_ENV: "test", AUTH_SIGNING_KEY_ID: "first",
      AUTH_SIGNING_PRIVATE_KEY: old.privateKey.export({ type: "pkcs8", format: "pem" }).toString() }));
    const rotated = new SessionTokensService(new ConfigService({ NODE_ENV: "test", AUTH_SIGNING_KEY_ID: "second",
      AUTH_PREVIOUS_PUBLIC_KEYS: { first: old.publicKey.export({ type: "spki", format: "pem" }).toString() } }));
    expect(rotated.read(first.issue(userId, sessionId, [])).sub).toBe(userId);
    expect(JSON.stringify(rotated.jwks())).not.toContain('"d":');
    const production = new ConfigService({ NODE_ENV: "production" });
    jest.spyOn(production, "get").mockReturnValueOnce(undefined).mockReturnValueOnce("production");
    expect(() => new SessionTokensService(production)).toThrow();
  });
});
