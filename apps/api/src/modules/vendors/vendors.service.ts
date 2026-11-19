import { HttpException, ServiceUnavailableException, BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { ServiceAreaDto, VendorBusinessDto, VendorCategoryDto, VendorBusinessEditDto, VendorDeliveryDto } from './vendors.dto';
import { KycService } from '../kyc/kyc.service';

const include = { settings: true, service_pincodes: { orderBy: { pincode: 'asc' as const } } } satisfies Prisma.vendorsInclude;
type Profile = Prisma.vendorsGetPayload<{ include: typeof include }>;
@Injectable()
export class VendorsService {
  constructor(private readonly prisma: PrismaService, private readonly idempotency: IdempotencyService, private readonly kyc: KycService) {}

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
  serviceArea(userId: string, key: string, input: ServiceAreaDto) {
    return this.mutate(userId, key, 'service-area', input, async tx => {
      const vendor = await tx.vendors.findUnique({ where: { user_id: userId } });
      if (!vendor) throw new ConflictException({ code: 'CATEGORY_REQUIRED' });
      if (input.serviceRadiusKm === null && !input.pincodes.length) {
        throw new BadRequestException({ code: 'SERVICE_AREA_REQUIRED' });
      }
      if (input.serviceRadiusKm !== null && (vendor.latitude === null || vendor.longitude === null)) {
        throw new ConflictException({ code: 'SHOP_LOCATION_REQUIRED' });
      }
      await tx.vendor_settings.update({ where: { vendor_id: vendor.id }, data: {
        service_radius_km: input.serviceRadiusKm, version: { increment: 1 },
      } });
      await tx.vendor_service_pincodes.deleteMany({ where: { vendor_id: vendor.id } });
      if (input.pincodes.length) await tx.vendor_service_pincodes.createMany({
        data: input.pincodes.map(pincode => ({ vendor_id: vendor.id, pincode })),
      });
      return tx.vendors.findUniqueOrThrow({ where: { id: vendor.id }, include });
    });
  }
  businessSettings(userId: string, key: string, input: VendorBusinessEditDto) {
    return this.mutate(userId, key, 'settings-business', input, async tx => {
      const vendor = await tx.vendors.findUniqueOrThrow({ where: { user_id: userId }, include });
      if (vendor.settings?.version !== input.version) throw new ConflictException({ code: 'VERSION_CONFLICT' });
      if (vendor.kyc_status === 'MANUAL_REVIEW') throw new ConflictException({ code: 'KYC_STATE_CONFLICT' });
      if (input.shopPhotoMediaId && !await tx.media_files.findFirst({ where: { id: input.shopPhotoMediaId, owner_user_id: userId, purpose: 'SHOP_PHOTO', status: 'READY' } })) throw new NotFoundException({ code: 'MEDIA_NOT_FOUND' });
      if (vendor.business_name !== input.businessName) await this.kyc.businessRevision(tx, userId, input.businessName);
      const row = await tx.vendors.update({ where: { id: vendor.id }, data: { business_name: input.businessName, gstin: input.gstin || null,
        address_line: input.addressLine, city: input.city, state: input.state, pincode: input.pincode,
        latitude: input.latitude, longitude: input.longitude, shop_photo_media_id: input.shopPhotoMediaId } });
      await tx.vendor_settings.update({ where: { vendor_id: vendor.id }, data: { version: { increment: 1 } } });
      await tx.audit_logs.create({ data: { actor_type: 'USER', actor_id: userId, action: 'VENDOR_BUSINESS_UPDATED', entity: 'VENDOR', entity_id: vendor.id,
        before: { version: input.version, kycStatus: vendor.kyc_status }, after: { version: input.version + 1, kycStatus: row.kyc_status } } });
      return tx.vendors.findUniqueOrThrow({ where: { id: vendor.id }, include });
    });
  }
  deliverySettings(userId: string, key: string, input: VendorDeliveryDto) {
    const slots = [...input.timeSlots].sort();
    if (input.acceptingToday && !input.sameDayCutoff || slots.some((s, i) => s.slice(0, 5) >= s.slice(6) || i > 0 && slots[i-1].slice(6) > s.slice(0, 5))) throw new BadRequestException({ code: 'DELIVERY_SETTINGS_INVALID' });
    return this.mutate(userId, key, 'settings-delivery', input, async tx => {
      const vendor = await tx.vendors.findUniqueOrThrow({ where: { user_id: userId }, include });
      if (vendor.settings?.version !== input.version) throw new ConflictException({ code: 'VERSION_CONFLICT' });
      await tx.vendor_settings.update({ where: { vendor_id: vendor.id }, data: { delivery_charge_paise: input.deliveryChargePaise,
        min_order_paise: input.minOrderPaise, time_slots: slots, accepting_today: input.acceptingToday,
        same_day_cutoff: input.sameDayCutoff ? new Date(`1970-01-01T${input.sameDayCutoff}:00Z`) : null, version: { increment: 1 } } });
      await tx.audit_logs.create({ data: { actor_type: 'USER', actor_id: userId, action: 'VENDOR_DELIVERY_SETTINGS_UPDATED', entity: 'VENDOR', entity_id: vendor.id,
        before: { version: input.version }, after: { version: input.version + 1, deliveryChargePaise: input.deliveryChargePaise, minOrderPaise: input.minOrderPaise, timeSlots: slots, acceptingToday: input.acceptingToday, sameDayCutoff: input.sameDayCutoff } } });
      return tx.vendors.findUniqueOrThrow({ where: { id: vendor.id }, include });
    });
  }
  /** Shared by discovery/order tasks: radius OR an explicitly listed pincode (TC-028). */
  async covers(vendorId: string, latitude: number, longitude: number, pincode: string,
    tx: Prisma.TransactionClient = this.prisma): Promise<boolean> {
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
      !Number.isFinite(longitude) || longitude < -180 || longitude > 180 || !/^[1-9]\d{5}$/.test(pincode)) {
      throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    }
    const rows = await tx.$queryRaw<{ covered: boolean }[]>`
      SELECT (EXISTS (SELECT 1 FROM vendor_service_pincodes p WHERE p.vendor_id = v.id AND p.pincode = ${pincode})
        OR COALESCE(ST_DWithin(v.location, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography,
          s.service_radius_km * 1000), false)) AS covered
      FROM vendors v JOIN vendor_settings s ON s.vendor_id = v.id WHERE v.id = ${vendorId}::uuid`;
    return rows[0]?.covered ?? false;
  }
  private async authorize(tx: Prisma.TransactionClient, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR')) {
      throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    }
  }
  private mutate(userId: string, key: string, step: string, input: VendorCategoryDto | VendorBusinessDto | ServiceAreaDto | VendorBusinessEditDto | VendorDeliveryDto,
    write: (tx: Prisma.TransactionClient) => Promise<Profile>) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `vendor:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
    const requestHash = this.idempotency.hashRequestBody(input);
    return this.prisma.$transaction(async tx => {
      // Same lock as session/role changes; profile and replay commit together.
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
      await this.authorize(tx, userId);
      if (step.startsWith('settings-')) {
        const vendor = await tx.vendors.findUnique({ where: { user_id: userId } });
        if (!vendor) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
        await tx.$queryRaw`SELECT id FROM vendors WHERE id=${vendor.id}::uuid FOR UPDATE`;
        if ((await tx.vendors.findUniqueOrThrow({ where: { id: vendor.id } })).is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
      }
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
      settings: { serviceRadiusKm: s.service_radius_km, pincodes: row.service_pincodes.map(p => p.pincode), deliveryChargePaise: s.delivery_charge_paise,
        minOrderPaise: s.min_order_paise, timeSlots: s.time_slots, autoAcceptSubscriptions: s.auto_accept_subscriptions,
        sameDayCutoff: s.same_day_cutoff?.toISOString().slice(11,16) ?? null,
        acceptingToday: s.accepting_today, deliveryPaused: s.delivery_paused, allowKhataOrders: s.allow_khata_orders, version: s.version } };
  }
}
