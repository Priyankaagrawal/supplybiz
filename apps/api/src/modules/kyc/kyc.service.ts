import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma, vendor_kyc } from '@prisma/client';
import { isIP } from 'node:net';
import { createCipheriv, createHash, createHmac, randomBytes } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { KycDecisionDto, KycResponse, KycSubmissionDto } from './kyc.dto';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class KycService {
  constructor(private readonly db: PrismaService, private readonly config: ConfigService,
    private readonly admins: AdminAuthService, private readonly notifications: NotificationsService) {}

  private key(): Buffer {
    const key = this.config.get<string>('FIELD_ENCRYPTION_KEY');
    if (!['development', 'test'].includes(this.config.getOrThrow<string>('NODE_ENV')) || !key) {
      throw new ServiceUnavailableException({ code: 'KYC_ENCRYPTION_UNAVAILABLE' });
    }
    return Buffer.from(key, 'hex');
  }
  private encrypt(value: string, key: Buffer, context: string): string {
    const iv = randomBytes(12), cipher = createCipheriv('aes-256-gcm', key, iv);
    cipher.setAAD(Buffer.from(`supplybiz:kyc:v1:${context}`));
    const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
    return `dev-v1:${Buffer.concat([iv, cipher.getAuthTag(), encrypted]).toString('base64')}`;
  }
  private async vendor(tx: Prisma.TransactionClient, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR')) {
      throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    }
    const vendor = await tx.vendors.findUnique({ where: { user_id: userId } });
    if (!vendor) throw new ConflictException({ code: 'BUSINESS_REQUIRED' });
    return vendor;
  }
  async status(userId: string) {
    const vendor = await this.vendor(this.db, userId);
    const row = await this.db.vendor_kyc.findFirst({ where: { vendor_id: vendor.id }, orderBy: [{ submitted_at: 'desc' }, { id: 'desc' }] });
    if (!row) throw new NotFoundException({ code: 'KYC_NOT_SUBMITTED' });
    return this.present(row);
  }
  async notices(userId: string) {
    await this.vendor(this.db, userId);
    const rows = await this.db.kyc_notices.findMany({ where: { user_id: userId }, orderBy: [{ created_at: 'desc' }, { id: 'desc' }], take: 50 });
    return rows.map(row => ({ id: row.id, status: row.status, reason: row.reason, createdAt: row.created_at.toISOString() }));
  }
  submit(userId: string, key: string, input: KycSubmissionDto, ip?: string) {
    const encryptionKey = this.key();
    if (input.accountNumber !== input.accountNumberConfirmation) throw new BadRequestException({ code: 'ACCOUNT_CONFIRMATION_MISMATCH' });
    return this.mutate(userId, key, 'submit', input, async tx => {
      const vendor = await this.vendor(tx, userId);
      if (!vendor.business_name || vendor.onboarding_step < 3 || vendor.is_suspended) throw new ConflictException({ code: 'BUSINESS_REQUIRED' });
      if (!['NOT_VERIFIED', 'REJECTED', 'PENDING'].includes(vendor.kyc_status)) throw new ConflictException({ code: 'KYC_STATE_CONFLICT' });
      const ids = [input.aadhaarFrontMediaId, input.aadhaarBackMediaId, input.panMediaId];
      if (new Set(ids).size !== 3) throw new BadRequestException({ code: 'DISTINCT_DOCUMENTS_REQUIRED' });
      const files = await tx.media_files.count({ where: { id: { in: ids }, owner_user_id: userId, purpose: 'KYC_DOC', status: 'READY' } });
      if (files !== 3) throw new NotFoundException({ code: 'MEDIA_NOT_FOUND' });
      const row = await tx.vendor_kyc.create({ data: { vendor_id: vendor.id,
        aadhaar_front_media_id: ids[0], aadhaar_back_media_id: ids[1], pan_media_id: ids[2],
        pan_enc: this.encrypt(input.pan, encryptionKey, `${vendor.id}:pan`), pan_last4: input.pan.slice(-4),
        account_number_enc: this.encrypt(input.accountNumber, encryptionKey, `${vendor.id}:account`), account_last4: input.accountNumber.slice(-4),
        holder_name: input.holderName.trim(), bank_name: input.bankName.trim(), ifsc: input.ifsc, upi_id: input.upiId,
      } });
      await tx.vendors.update({ where: { id: vendor.id }, data: { kyc_status: 'MANUAL_REVIEW', onboarding_step: 4 } });
      await this.audit(tx, 'USER', userId, row, 'KYC_SUBMITTED', ip);
      return this.present(row);
    }, async tx => { await this.vendor(tx, userId); });
  }
  async queue(token: string, beforeId?: string) {
    await this.admins.authenticate(token, 'kyc.review');
    const rows = await this.db.vendor_kyc.findMany({ where: { status: 'MANUAL_REVIEW' },
      ...(beforeId ? { cursor: { id: beforeId }, skip: 1 } : {}),
      orderBy: [{ submitted_at: 'asc' }, { id: 'asc' }], take: 51 });
    return { items: rows.slice(0, 50).map(row => this.present(row)), hasMore: rows.length > 50 };
  }
  async detail(token: string, id: string) {
    await this.admins.authenticate(token, 'kyc.review');
    const row = await this.db.vendor_kyc.findUnique({ where: { id } });
    if (!row) throw new NotFoundException({ code: 'KYC_NOT_FOUND' });
    return this.present(row);
  }
  async decide(token: string, csrf: string, key: string, id: string, input: KycDecisionDto, ip?: string) {
    if (input.reason.trim().length < 3) throw new BadRequestException({ code: 'REVIEW_REASON_REQUIRED' });
    const admin = await this.admins.authenticate(token, 'kyc.review', csrf);
    const candidate = await this.db.vendor_kyc.findUnique({ where: { id } });
    if (!candidate) throw new NotFoundException({ code: 'KYC_NOT_FOUND' });
    const vendor = await this.db.vendors.findUniqueOrThrow({ where: { id: candidate.vendor_id } });
    return this.mutate(admin.id, key, `decision:${id}`, input, async tx => {
      // Shared with onboarding, role changes and vendor resubmission.
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${vendor.user_id}, 0))::text`;
      const row = await tx.vendor_kyc.findUniqueOrThrow({ where: { id } });
      if (row.status !== 'MANUAL_REVIEW') throw new ConflictException({ code: 'KYC_STATE_CONFLICT' });
      const updated = await tx.vendor_kyc.update({ where: { id }, data: {
        status: input.decision, reason: input.reason.trim(), reviewer_id: admin.id, reviewed_at: new Date(),
      } });
      await tx.vendors.update({ where: { id: row.vendor_id }, data: { kyc_status: input.decision } });
      await this.audit(tx, 'ADMIN', admin.id, updated, `KYC_${input.decision}`, ip);
      // Actual durable in-app notice; no claim of push/SMS delivery before T-032.
      await tx.kyc_notices.create({ data: { user_id: vendor.user_id, submission_id: id, status: input.decision, reason: updated.reason } });
      await this.notifications.enqueue(tx, { recipientId: vendor.user_id, role: 'VENDOR', type: 'KYC_STATUS', sourceKey: `kyc:${id}` });
      return this.present(updated);
    }, async () => { await this.admins.authenticate(token, 'kyc.review', csrf); });
  }
  private async audit(tx: Prisma.TransactionClient, actor: string, actorId: string, row: vendor_kyc, action: string, ip?: string) {
    // Free-text reasons and banking PII stay outside the general audit viewer.
    await tx.audit_logs.create({ data: { actor_type: actor, actor_id: actorId, action, entity: 'vendor_kyc', entity_id: row.id, ip: ip && isIP(ip) ? ip : undefined,
      ...(action === 'KYC_SUBMITTED' ? {} : { before: { status: 'MANUAL_REVIEW', verificationMethod: 'MANUAL_REVIEW', providerChecks: 'NOT_RUN', reviewerId: null } }),
      after: { status: row.status, verificationMethod: row.verification_method, providerChecks: row.provider_checks, reviewerId: row.reviewer_id } } });
  }
  private mutate(actor: string, key: string, path: string, input: object,
    write: (tx: Prisma.TransactionClient) => Promise<KycResponse>, authorize: (tx: Prisma.TransactionClient) => Promise<void>) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `kyc:${createHash('sha256').update(`${actor}:${key}`).digest('hex')}`;
    // A keyed digest prevents guessing low-entropy banking input from the replay table.
    const hash = createHmac('sha256', this.key()).update(JSON.stringify(input, Object.keys(input).sort())).digest('hex');
    return this.db.$transaction(async tx => {
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${actor}, 0))::text`;
      await authorize(tx);
      const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
      if (cached && cached.expires_at > new Date()) {
        if (cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
      const response = await write(tx);
      await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, method: 'POST', path, request_hash: hash,
        response_status: 201, response_body: response as unknown as Prisma.InputJsonObject, expires_at: new Date(Date.now() + 86400000) } });
      return response;
    }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'KYC_WRITE_UNAVAILABLE' });
    });
  }
  private present(row: vendor_kyc): KycResponse {
    return { id: row.id, vendorId: row.vendor_id, status: row.status, verificationMethod: row.verification_method,
      providerChecks: row.provider_checks, submittedAt: row.submitted_at.toISOString(), reviewedAt: row.reviewed_at?.toISOString() ?? null,
      reviewerId: row.reviewer_id, reason: row.reason, aadhaarFrontMediaId: row.aadhaar_front_media_id,
      aadhaarBackMediaId: row.aadhaar_back_media_id, panMediaId: row.pan_media_id, panLast4: row.pan_last4,
      accountLast4: row.account_last4, holderName: row.holder_name, bankName: row.bank_name, ifsc: row.ifsc, upiId: row.upi_id };
  }
}
