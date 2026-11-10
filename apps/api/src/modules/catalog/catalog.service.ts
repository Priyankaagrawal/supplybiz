import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, products } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { ProductInput, ProductPatch, ProductQuery, StockAdjustment } from './catalog.dto';

export const LOW_STOCK_THRESHOLD = 10;
type Tx = Prisma.TransactionClient;
type StockChange = { vendorId: string; productId: string; actorId: string; delta: number;
  reason: 'ADJUST' | 'ORDER' | 'SALE' | 'REVERSAL'; note: string; refId?: string };
@Injectable()
export class CatalogService {
  constructor(private readonly db: PrismaService, private readonly idempotency: IdempotencyService) {}
  async list(userId: string, query: ProductQuery) {
    return this.db.$transaction(async tx => {
      const vendor = await this.authorize(tx, userId);
      const where = { vendor_id: vendor.id, deleted_at: null,
        ...(query.search ? { name: { contains: query.search, mode: 'insensitive' as const } } : {}),
        ...(query.productType && query.productType !== 'ALL' ? { product_type: query.productType } : {}) };
      const [rows, total] = await Promise.all([
        tx.products.findMany({ where, orderBy: [{ created_at: 'desc' }, { id: 'asc' }], take: query.limit ?? 50, skip: query.offset ?? 0 }),
        tx.products.count({ where }),
      ]);
      return { items: rows.map(row => this.present(row)), total };
    }, { isolationLevel: 'RepeatableRead' });
  }
  async get(userId: string, id: string) {
    const vendor = await this.authorize(this.db, userId);
    return this.present(await this.owned(this.db, vendor.id, id));
  }
  create(userId: string, key: string, input: ProductInput) {
    return this.mutate(userId, key, 'POST', 'create', input, async (tx, vendor) => {
      await this.validate(tx, vendor, userId, input);
      const row = await tx.products.create({ data: { vendor_id: vendor.id, ...this.fields(input),
        name: input.name, product_type: input.productType, unit_type: input.unitType,
        unit_value: input.unitValue, selling_price_paise: input.sellingPricePaise, stock_qty: input.stockQty ?? 0 } });
      if (row.stock_qty) await tx.stock_movements.create({ data: { product_id: row.id, delta: row.stock_qty,
        reason: 'OPENING', note: 'Initial stock', created_by: userId } });
      return this.present(row);
    });
  }
  patch(userId: string, key: string, id: string, input: ProductPatch) {
    return this.mutate(userId, key, 'PATCH', id, input, async (tx, vendor) => {
      const row = await this.lock(tx, vendor.id, id);
      await this.validate(tx, vendor, userId, { ...this.present(row), ...input });
      const delta = (input.stockQty ?? row.stock_qty) - row.stock_qty;
      if (delta && !input.stockReason?.trim()) throw new BadRequestException({ code: 'STOCK_REASON_REQUIRED' });
      if (delta) await this.changeStock(tx, { vendorId: vendor.id, productId: id, actorId: userId,
        delta, reason: 'ADJUST', note: input.stockReason! });
      return this.present(await tx.products.update({ where: { id }, data: { ...this.fields(input), version: { increment: 1 } } }));
    });
  }
  remove(userId: string, key: string, id: string) {
    return this.mutate(userId, key, 'DELETE', id, {}, async (tx, vendor) => {
      await this.lock(tx, vendor.id, id);
      if (await tx.product_subscription_links.count({ where: { product_id: id, status: { in: ['ACTIVE', 'PAUSED'] } } })) {
        throw new ConflictException({ code: 'PRODUCT_IN_USE' });
      }
      await tx.products.update({ where: { id }, data: { deleted_at: new Date(), is_active: false, version: { increment: 1 } } });
      return { id, deleted: true };
    });
  }
  adjust(userId: string, key: string, id: string, input: StockAdjustment) {
    return this.mutate(userId, key, 'POST', `${id}/stock-adjustments`, input, async (tx, vendor) =>
      this.present(await this.changeStock(tx, { vendorId: vendor.id, productId: id, actorId: userId,
        delta: input.delta, reason: 'ADJUST', note: input.reason })));
  }
  /** T-049/T-079/T-071 call inside their authorized financial transaction, never after commit. */
  async changeStock(tx: Tx, change: StockChange): Promise<products> {
    if (!Number.isInteger(change.delta) || !change.delta || Math.abs(change.delta) > 2147483647 ||
      !change.note.trim() || change.note.length > 200) throw new BadRequestException({ code: 'INVALID_STOCK_ADJUSTMENT' });
    const row = await this.lock(tx, change.vendorId, change.productId);
    const quantity = row.stock_qty + change.delta;
    if (quantity < 0) throw new ConflictException({ code: 'INSUFFICIENT_STOCK' });
    if (quantity > 2147483647) throw new BadRequestException({ code: 'STOCK_OVERFLOW' });
    const updated = await tx.products.update({ where: { id: row.id }, data: { stock_qty: quantity, version: { increment: 1 } } });
    await tx.stock_movements.create({ data: { product_id: row.id, delta: change.delta, reason: change.reason,
      note: change.note.trim(), ref_id: change.refId, created_by: change.actorId } });
    if (row.stock_qty > LOW_STOCK_THRESHOLD && quantity <= LOW_STOCK_THRESHOLD) {
      // Domain event only. T-032 must check real BUSINESS+ entitlements before delivery.
      await tx.outbox_events.create({ data: { aggregate_type: 'PRODUCT', aggregate_id: row.id,
        event_type: 'STOCK_LOW', payload: { vendorId: row.vendor_id, productId: row.id,
          stockQty: quantity, threshold: LOW_STOCK_THRESHOLD, requiredFeature: 'STOCK_ALERTS',
          minimumPlan: 'BUSINESS', productVersion: updated.version } } });
    }
    return updated;
  }
  /** T-072 maintains this reference with every subscription state change in its transaction. */
  async setSubscriptionReference(tx: Tx, subscriptionId: string, productId: string,
    status: 'PENDING' | 'ACTIVE' | 'PAUSED' | 'ENDED' | 'CANCELLED' | 'REJECTED') {
    return tx.product_subscription_links.upsert({ where: { subscription_id: subscriptionId },
      create: { subscription_id: subscriptionId, product_id: productId, status }, update: { product_id: productId, status } });
  }
  /** Discovery must also enforce vendor visibility/plan/coverage. */
  async requireSelectable(tx: Tx, vendorId: string, productId: string) {
    const row = await this.owned(tx, vendorId, productId);
    if (!row.is_active) throw new ConflictException({ code: 'PRODUCT_UNAVAILABLE' });
    return row;
  }
  private async authorize(tx: Tx, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true, vendor: { include: { category: true } } } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR')) {
      throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    }
    if (!user.vendor) throw new ConflictException({ code: 'CATEGORY_REQUIRED' });
    if (user.vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
    return user.vendor;
  }
  private async owned(tx: Tx, vendorId: string, id: string) {
    const row = await tx.products.findFirst({ where: { id, vendor_id: vendorId, deleted_at: null } });
    if (!row) throw new NotFoundException({ code: 'PRODUCT_NOT_FOUND' });
    return row;
  }
  private async lock(tx: Tx, vendorId: string, id: string) {
    const rows = await tx.$queryRaw<{ id: string }[]>`SELECT id FROM products
      WHERE id = ${id}::uuid AND vendor_id = ${vendorId}::uuid AND deleted_at IS NULL FOR UPDATE`;
    if (!rows.length) throw new NotFoundException({ code: 'PRODUCT_NOT_FOUND' });
    return this.owned(tx, vendorId, id);
  }
  private async validate(tx: Tx, vendor: { category: { product_types: Prisma.JsonValue } }, userId: string, input: ProductInput) {
    const types = vendor.category.product_types;
    if (!Array.isArray(types) || !types.includes(input.productType)) throw new BadRequestException({ code: 'PRODUCT_TYPE_UNAVAILABLE' });
    if (input.productType === 'MILK' ? !input.milkType : input.milkType != null) throw new BadRequestException({ code: 'INVALID_MILK_TYPE' });
    if (input.subscriptionPricePaise != null && input.subscriptionPricePaise > input.sellingPricePaise) {
      throw new BadRequestException({ code: 'SUBSCRIPTION_PRICE_TOO_HIGH' });
    }
    if (input.imageMediaId && !await tx.media_files.findFirst({ where: { id: input.imageMediaId,
      owner_user_id: userId, purpose: 'PRODUCT_IMAGE', status: 'READY' } })) throw new NotFoundException({ code: 'MEDIA_NOT_FOUND' });
  }
  private fields(input: ProductPatch) {
    return { name: input.name, product_type: input.productType, milk_type: input.milkType,
      unit_value: input.unitValue, unit_type: input.unitType, selling_price_paise: input.sellingPricePaise,
      subscription_price_paise: input.subscriptionPricePaise, moq: input.moq, description: input.description,
      image_media_id: input.imageMediaId, is_active: input.isActive };
  }
  private present(row: products) {
    return { id: row.id, name: row.name, productType: row.product_type, milkType: row.milk_type,
      unitValue: row.unit_value.toNumber(), unitType: row.unit_type, sellingPricePaise: row.selling_price_paise,
      subscriptionPricePaise: row.subscription_price_paise, stockQty: row.stock_qty, moq: row.moq,
      description: row.description, imageMediaId: row.image_media_id, isActive: row.is_active, version: row.version };
  }
  private mutate(userId: string, key: string, method: string, path: string, input: object,
    write: (tx: Tx, vendor: Awaited<ReturnType<CatalogService['authorize']>>) => Promise<Prisma.InputJsonObject>) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `catalog:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
    const requestHash = this.idempotency.hashRequestBody(input);
    return this.db.$transaction(async tx => {
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
      const vendor = await this.authorize(tx, userId);
      const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
      if (cached && cached.expires_at > new Date()) {
        if (cached.method !== method || cached.path !== path || cached.request_hash !== requestHash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
      const response = await write(tx, vendor);
      await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, user_id: userId, method, path,
        request_hash: requestHash, response_status: method === 'POST' ? 201 : 200, response_body: response,
        expires_at: new Date(Date.now() + 86400000) } });
      return response;
    }, { timeout: 15000 }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'CATALOG_WRITE_UNAVAILABLE' });
    });
  }
}
