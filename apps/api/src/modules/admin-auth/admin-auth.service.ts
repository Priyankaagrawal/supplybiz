import { ForbiddenException, Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma, admin_users } from '@prisma/client';
import { auditContext } from '../audit/audit-context';
import { randomBytes } from 'node:crypto';
import * as argon2 from 'argon2';
import { PrismaService } from '../../prisma/prisma.service';
import { base32, decryptSecret, digest, encryptSecret, opaque, totpStep } from './admin-crypto';
import { permissions } from './admin-policy';

const denied = () => new UnauthorizedException('Sign in failed or session expired.');
@Injectable()
export class AdminAuthService {
  private readonly dummy = argon2.hash(opaque(), { type: argon2.argon2id });
  constructor(private readonly db: PrismaService, private readonly config: ConfigService) {}
  private key(): Buffer {
    const key = this.config.get<string>('ADMIN_TOTP_KEY');
    if (!key || !/^[a-f0-9]{64}$/i.test(key)) throw new ServiceUnavailableException('Admin authentication is not configured.');
    return Buffer.from(key, 'hex');
  }
  private async lock(tx: Prisma.TransactionClient, id: string, ip?: string): Promise<admin_users> {
    await auditContext(tx, id, ip);
    await tx.$queryRaw`SELECT id FROM admin_users WHERE id = ${id}::uuid FOR UPDATE`;
    return tx.admin_users.findUniqueOrThrow({ where: { id } });
  }
  private async event(tx: Prisma.TransactionClient, action: string, admin_id?: string): Promise<void> {
    await tx.admin_auth_events.create({ data: { action, admin_id } });
  }
  private async failure(tx: Prisma.TransactionClient, user: admin_users, now: Date): Promise<void> {
    const failed = user.failed_attempts + 1;
    await tx.admin_users.update({ where: { id: user.id }, data: { failed_attempts: failed,
      ...(failed >= 5 ? { locked_until: new Date(now.getTime() + 30 * 60000) } : {}) } });
    await this.event(tx, 'LOGIN_FAILED', user.id);
  }
  private async clock(tx: Prisma.TransactionClient): Promise<Date> {
    const [row] = await tx.$queryRaw<{ now: Date }[]>`SELECT clock_timestamp() AS now`;
    return row.now;
  }
  private async available(tx: Prisma.TransactionClient, user: admin_users, now: Date): Promise<admin_users | null> {
    if (user.status !== 'ACTIVE' || !permissions(user.role).length || (user.locked_until && user.locked_until > now)) {
      await this.event(tx, 'LOGIN_DENIED', user.id); return null;
    }
    if (user.locked_until) return tx.admin_users.update({ where: { id: user.id }, data: { locked_until: null, failed_attempts: 0 } });
    return user;
  }
  async login(email: string, password: string, ip?: string): Promise<{ challengeToken: string }> {
    const key = this.key();
    const candidate = await this.db.admin_users.findUnique({ where: { email: email.trim().toLowerCase() } });
    // Equal expensive work for unknown accounts; lockout counters are shared across instances.
    const valid = await argon2.verify(candidate?.password_hash ?? await this.dummy, password);
    const result = await this.db.$transaction(async tx => {
      await auditContext(tx, undefined, ip);
      if (!candidate) { await this.event(tx, 'LOGIN_FAILED'); return null; }
      const locked = await this.lock(tx, candidate.id, ip), now = await this.clock(tx);
      const user = await this.available(tx, locked, now);
      if (!user) return null;
      if (!valid || user.password_hash !== candidate.password_hash) { await this.failure(tx, user, now); return null; }
      await tx.admin_auth_challenges.deleteMany({ where: { admin_id: user.id, expires_at: { lte: now } } });
      await tx.admin_sessions.deleteMany({ where: { admin_id: user.id, expires_at: { lte: now } } });
      const token = opaque();
      await tx.admin_auth_challenges.create({ data: { token_hash: digest(token), admin_id: user.id,
        secret_enc: user.totp_secret_enc ?? encryptSecret(base32(randomBytes(20)), key),
        enrolling: !user.totp_secret_enc, expires_at: new Date(now.getTime() + 5 * 60000) } });
      await this.event(tx, 'PASSWORD_VERIFIED', user.id);
      return { challengeToken: token };
    });
    if (!result) throw denied();
    return result;
  }
  async challenge(token: string): Promise<{ enrollmentSecret: string | null }> {
    const row = await this.db.admin_auth_challenges.findUnique({ where: { token_hash: digest(token) } });
    const user = row ? await this.db.admin_users.findUnique({ where: { id: row.admin_id } }) : null;
    if (!row || !user || user.status !== 'ACTIVE' || !permissions(user.role).length ||
        (user.locked_until && user.locked_until.getTime() > Date.now()) || row.expires_at.getTime() <= Date.now()) throw denied();
    return { enrollmentSecret: row.enrolling ? decryptSecret(row.secret_enc, this.key()) : null };
  }
  async verify(token: string, code: string, ip?: string): Promise<{ sessionToken: string; csrfToken: string }> {
    const key = this.key();
    const result = await this.db.$transaction(async tx => {
      const challenge = await tx.admin_auth_challenges.findUnique({ where: { token_hash: digest(token) } });
      if (!challenge) return null;
      const locked = await this.lock(tx, challenge.admin_id, ip), now = await this.clock(tx);
      const user = await this.available(tx, locked, now);
      const current = await tx.admin_auth_challenges.findUnique({ where: { token_hash: digest(token) } });
      if (!user || !current || current.expires_at <= now) return null;
      if (challenge.enrolling && user.totp_secret_enc) return null;
      const step = totpStep(decryptSecret(challenge.secret_enc, key), code, now.getTime(), user.last_totp_step);
      if (step === undefined) { await this.failure(tx, user, now); return null; }
      await tx.admin_users.update({ where: { id: user.id }, data: { totp_secret_enc: challenge.secret_enc,
        last_totp_step: step, failed_attempts: 0, locked_until: null, last_login_at: now } });
      await tx.admin_auth_challenges.deleteMany({ where: { admin_id: user.id } });
      const sessionToken = opaque(), csrfToken = opaque();
      await tx.admin_sessions.create({ data: { token_hash: digest(sessionToken), admin_id: user.id,
        csrf_hash: digest(csrfToken), created_at: now, last_used_at: now, expires_at: new Date(now.getTime() + 8 * 3600000) } });
      await this.event(tx, challenge.enrolling ? 'TOTP_ENROLLED_LOGIN' : 'LOGIN_SUCCEEDED', user.id);
      return { sessionToken, csrfToken };
    });
    if (!result) throw denied();
    return result;
  }
  async authenticate(token: string, permission?: string, csrf?: string): Promise<{ id: string; role: string; permissions: string[] }> {
    return this.db.$transaction(tx => this.authenticateInTransaction(tx, token, permission, csrf));
  }
  /** Domain mutations keep the admin/session lock through their atomic write and replay. */
  async authenticateInTransaction(tx: Prisma.TransactionClient, token: string, permission?: string, csrf?: string): Promise<{ id: string; role: string; permissions: string[] }> {
      const session = await tx.admin_sessions.findUnique({ where: { token_hash: digest(token) } });
      if (!session) throw denied();
      const user = await this.lock(tx, session.admin_id), now = await this.clock(tx);
      const current = await tx.admin_sessions.findUnique({ where: { token_hash: digest(token) } });
      if (!current || user.status !== 'ACTIVE' || current.expires_at <= now ||
          current.last_used_at.getTime() + 30 * 60000 <= now.getTime() || !permissions(user.role).length) throw denied();
      if (csrf !== undefined && digest(csrf) !== current.csrf_hash) throw new ForbiddenException('Invalid CSRF token.');
      const grants = permissions(user.role);
      if (permission && !grants.includes(permission)) throw new ForbiddenException();
      await tx.admin_sessions.update({ where: { token_hash: current.token_hash }, data: { last_used_at: now } });
      return { id: user.id, role: user.role, permissions: grants };
  }
  async logout(token: string, csrf: string, ip?: string): Promise<void> {
    // Check + deletion under the same user lock used by authenticate.
    await this.db.$transaction(async tx => {
      const session = await tx.admin_sessions.findUnique({ where: { token_hash: digest(token) } });
      if (!session || digest(csrf) !== session.csrf_hash) throw new ForbiddenException();
      await this.lock(tx, session.admin_id, ip);
      await tx.admin_sessions.deleteMany({ where: { token_hash: session.token_hash } });
      await this.event(tx, 'LOGOUT', session.admin_id);
    });
  }
}
