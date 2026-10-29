import { BadRequestException, ForbiddenException, Injectable } from "@nestjs/common";
import { Prisma, user_role_type } from "@prisma/client";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import { PrismaService } from "../../prisma/prisma.service";
import { OtpService } from "./otp.service";
import { SessionTokensService, unauthenticated } from "./session-tokens.service";

const userInclude = { roles: true } satisfies Prisma.usersInclude;
type User = Prisma.usersGetPayload<{ include: typeof userInclude }>;
export interface ConsentInput { termsVersion: string; privacyVersion: string }
export interface DeviceInput { platform: "ANDROID" | "IOS" | "WEB"; appVersion?: string; osVersion?: string }

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService, private readonly otp: OtpService,
    private readonly tokens: SessionTokensService) {}

  async login(mobileInput: string, code: string, device: DeviceInput, consent?: ConsentInput, ip?: string) {
    await this.otp.verify(mobileInput, code);
    const mobile = mobileInput.startsWith("+91") ? mobileInput : `+91${mobileInput}`;
    return this.prisma.$transaction(async tx => {
      // Serialize creation for the same verified mobile across API instances.
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${mobile}, 0))::text`;
      let user = await tx.users.findUnique({ where: { mobile }, include: userInclude });
      if (!user) {
        if (!consent) throw new BadRequestException({ code: "VALIDATION_FAILED", detail: "Terms and privacy consent are required." });
        user = await tx.users.create({ data: { mobile, consents: { create: [
          { doc_type: "TERMS", doc_version: consent.termsVersion, ip },
          { doc_type: "PRIVACY", doc_version: consent.privacyVersion, ip },
        ] } }, include: userInclude });
      }
      this.assertActive(user);
      await this.lockUser(tx, user.id);
      const registered = await tx.devices.create({ data: {
        user_id: user.id, platform: device.platform, app_version: device.appVersion,
        os_version: device.osVersion, last_seen_at: new Date(),
      } });
      return this.issue(tx, user, randomUUID(), registered.id);
    });
  }

  async refresh(token: string) {
    const hash = createHash("sha256").update(token).digest("hex");
    const known = await this.prisma.sessions.findFirst({ where: { refresh_token_hash: hash } });
    if (!known) throw unauthenticated();
    const result = await this.prisma.$transaction(async tx => {
      await this.lockUser(tx, known.user_id);
      const session = await tx.sessions.findUniqueOrThrow({ where: { id: known.id } });
      if (session.last_used_at) {
        // Return an error value: throwing here would roll back family revocation.
        await tx.sessions.updateMany({ where: { family_id: session.family_id },
          data: { status: "REVOKED", revoked_at: new Date() } });
        return null;
      }
      if (session.status !== "ACTIVE" || session.expires_at <= new Date()) throw unauthenticated();
      const user = await tx.users.findUniqueOrThrow({ where: { id: session.user_id }, include: userInclude });
      this.assertActive(user);
      await tx.sessions.update({ where: { id: session.id },
        data: { status: "REVOKED", revoked_at: new Date(), last_used_at: new Date() } });
      return this.issue(tx, user, session.family_id, session.device_id);
    });
    if (!result) throw unauthenticated("REFRESH_REUSED");
    return result;
  }

  async authenticate(token: string) {
    const claims = this.tokens.read(token);
    const session = await this.prisma.sessions.findUnique({ where: { id: claims.sid },
      include: { user: { include: userInclude } } });
    if (!session || session.user_id !== claims.sub || session.status !== "ACTIVE" || session.expires_at <= new Date()) throw unauthenticated();
    this.assertActive(session.user);
    return { userId: session.user_id, sessionId: session.id,
      roles: session.user.roles.map(item => item.role), activeRole: session.user.active_role };
  }

  async logout(userId: string, sessionId: string, all: boolean): Promise<void> {
    await this.prisma.$transaction(async tx => {
      await this.lockUser(tx, userId);
      const session = await tx.sessions.findFirst({ where: { id: sessionId, user_id: userId } });
      if (!session) throw unauthenticated();
      // Revoke the whole current family, including a concurrent rotated successor.
      await tx.sessions.updateMany({ where: all ? { user_id: userId } : { user_id: userId, family_id: session.family_id },
        data: { status: "REVOKED", revoked_at: new Date() } });
    });
  }

  async me(userId: string) {
    const user = await this.prisma.users.findUniqueOrThrow({ where: { id: userId }, include: userInclude });
    this.assertActive(user);
    return this.publicUser(user);
  }

  async role(userId: string, role: user_role_type, select: boolean) {
    return this.prisma.$transaction(async tx => {
      await this.lockUser(tx, userId);
      const user = await tx.users.findUniqueOrThrow({ where: { id: userId }, include: userInclude });
      this.assertActive(user);
      if (select && !user.roles.some(item => item.role === role)) {
        throw new ForbiddenException({ code: "ROLE_NOT_HELD", detail: "Select a role held by this account." });
      }
      if (!select) await tx.user_roles.upsert({ where: { user_id_role: { user_id: userId, role } },
        create: { user_id: userId, role }, update: {} });
      if (select || user.roles.length === 0) await tx.users.update({ where: { id: userId }, data: { active_role: role } });
      return this.publicUser(await tx.users.findUniqueOrThrow({ where: { id: userId }, include: userInclude }));
    });
  }

  private lockUser(tx: Prisma.TransactionClient, userId: string) {
    return tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
  }
  private assertActive(user: User) {
    if (user.status !== "ACTIVE") throw new ForbiddenException({ code: "ACCOUNT_BLOCKED", detail: "Account is unavailable." });
  }
  private publicUser(user: User) {
    return { id: user.id, mobile: user.mobile, name: user.name, language: user.language,
      roles: user.roles.map(item => item.role), activeRole: user.roles.length ? user.active_role : null };
  }
  private async issue(tx: Prisma.TransactionClient, user: User, familyId: string, deviceId: string | null) {
    const refreshToken = randomBytes(32).toString("base64url");
    const session = await tx.sessions.create({ data: { user_id: user.id, family_id: familyId,
      device_id: deviceId, refresh_token_hash: createHash("sha256").update(refreshToken).digest("hex"),
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } });
    return { accessToken: this.tokens.issue(user.id, session.id, user.roles.map(item => item.role)),
      refreshToken, expiresInSec: 900, user: this.publicUser(user) };
  }
}
