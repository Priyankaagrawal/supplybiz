import { HttpException, ServiceUnavailableException, BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { VendorBusinessDto, VendorCategoryDto } from './vendors.dto';

const include = { settings: true } satisfies Prisma.vendorsInclude;
type Profile = Prisma.vendorsGetPayload<{ include: typeof include }>;
@Injectable()
export class VendorsService {
  constructor(private readonly prisma: PrismaService, private readonly idempotency: IdempotencyService) {}

  async categories(userId: string) {
    await this.authorize(this.prisma, userId);
    const rows = await this.prisma.categories.findMany({ where: { type: 'SUPPLY', status: 'ENABLED' },
      orderBy: [{ sort_order: 'asc' }, { code: 'asc' }] });
    rows.sort((a, b) => Number(b.code === 'MILK') - Number(a.code === 'MILK'));
    return rows.map(row => ({ id: row.id, code: row.code, name: row.name_en, icon: row.icon }));
  }
  async profile(userId: string) {
    await this.authorize(this.prisma, userId);
    const row = await this.prisma.vendors.findUnique({ where: { user_id: userId }, include });
    if (!row) throw new NotFoundException({ code: 'ONBOARDING_NOT_STARTED' });
    return this.present(row);
  }
  category(userId: string, key: string, input: VendorCategoryDto) {
    return this.mutate(userId, key, 'category', input, async tx => {
      const category = await tx.categories.findFirst({ where: { id: input.categoryId, type: 'SUPPLY', status: 'ENABLED' } });
      if (!category) throw new BadRequestException({ code: 'CATEGORY_UNAVAILABLE' });
      const existing = await tx.vendors.findUnique({ where: { user_id: userId } });
      if (existing && existing.category_id !== input.categoryId && existing.kyc_status !== 'NOT_VERIFIED') {
        throw new ConflictException({ code: 'REVERIFICATION_REQUIRED' });
      }
      return tx.vendors.upsert({ where: { user_id: userId },
        create: { user_id: userId, category_id: input.categoryId, settings: { create: {} } },
        update: { category_id: input.categoryId }, include });
    });
  }
  business(userId: string, key: string, input: VendorBusinessDto) {
    return this.mutate(userId, key, 'business', input, async tx => {
      const vendor = await tx.vendors.findUnique({ where: { user_id: userId } });
      if (!vendor) throw new ConflictException({ code: 'CATEGORY_REQUIRED' });
      // KYC-aware changes are owned by T-106; onboarding cannot bypass re-verification.
      if (vendor.kyc_status !== 'NOT_VERIFIED') throw new ConflictException({ code: 'REVERIFICATION_REQUIRED' });
      if (input.shopPhotoMediaId) {
        const media = await tx.media_files.findFirst({ where: { id: input.shopPhotoMediaId,
          owner_user_id: userId, purpose: 'SHOP_PHOTO', status: 'READY' } });
        if (!media) throw new NotFoundException({ code: 'MEDIA_NOT_FOUND' });
      }
      return tx.vendors.update({ where: { id: vendor.id }, data: {
        business_name: input.businessName, gstin: input.gstin || null, address_line: input.addressLine,
        city: input.city, state: input.state, pincode: input.pincode, latitude: input.latitude, longitude: input.longitude,
        shop_photo_media_id: input.shopPhotoMediaId, onboarding_step: Math.max(3, vendor.onboarding_step),
      }, include });
    });
  }
  private async authorize(tx: Prisma.TransactionClient, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR')) {
      throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    }
  }
  private mutate(userId: string, key: string, step: string, input: VendorCategoryDto | VendorBusinessDto,
    write: (tx: Prisma.TransactionClient) => Promise<Profile>) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `vendor:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
    const requestHash = this.idempotency.hashRequestBody(input);
    return this.prisma.$transaction(async tx => {
      // Same lock as session/role changes; profile and replay commit together.
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
      await this.authorize(tx, userId);
      const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
      if (cached && cached.expires_at > new Date()) {
        if (cached.path !== step || cached.request_hash !== requestHash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
      const response = this.present(await write(tx));
      await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, user_id: userId,
        method: step === 'category' ? 'POST' : 'PUT', path: step, request_hash: requestHash,
        response_status: step === 'category' ? 201 : 200, response_body: response,
        expires_at: new Date(Date.now() + 86400000) } });
      return response;
    }).catch((error: unknown) => {
      // Prisma errors can embed business/contact fields; expose only a redacted failure.
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'VENDOR_WRITE_UNAVAILABLE' });
    });
  }
  private present(row: Profile) {
    const s = row.settings;
    if (!s) throw new ConflictException({ code: 'SETTINGS_MISSING' });
    return { id: row.id, categoryId: row.category_id, onboardingStep: row.onboarding_step, kycStatus: row.kyc_status,
      businessName: row.business_name, gstin: row.gstin, addressLine: row.address_line, city: row.city, state: row.state,
      pincode: row.pincode, latitude: row.latitude, longitude: row.longitude, shopPhotoMediaId: row.shop_photo_media_id,
      settings: { serviceRadiusKm: s.service_radius_km, deliveryChargePaise: s.delivery_charge_paise,
        minOrderPaise: s.min_order_paise, timeSlots: s.time_slots, autoAcceptSubscriptions: s.auto_accept_subscriptions,
        acceptingToday: s.accepting_today, deliveryPaused: s.delivery_paused, allowKhataOrders: s.allow_khata_orders, version: s.version } };
  }
}
