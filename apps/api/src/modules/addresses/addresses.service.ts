import { BadRequestException, ConflictException, ForbiddenException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { addresses, Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { AddressInput, AddressPatch } from './addresses.dto';

type Tx = Prisma.TransactionClient;
@Injectable()
export class AddressesService {
  constructor(private readonly db: PrismaService, private readonly idempotency: IdempotencyService) {}
  async list(userId: string) {
    await this.customer(this.db, userId);
    const rows = await this.db.addresses.findMany({ where: { user_id: userId, deleted_at: null },
      orderBy: [{ is_default: 'desc' }, { created_at: 'asc' }, { id: 'asc' }] });
    return { items: rows.map(row => this.present(row)) };
  }
  async get(userId: string, id: string) {
    await this.customer(this.db, userId);
    return this.present(await this.owned(this.db, userId, id));
  }
  create(userId: string, key: string, input: AddressInput) {
    return this.mutate(userId, key, 'POST', '', input, async tx => {
      const first = !await tx.addresses.count({ where: { user_id: userId, deleted_at: null } });
      const isDefault = first || input.isDefault === true;
      if (isDefault) await this.clearDefault(tx, userId);
      const fields = { ...input }; delete fields.isDefault;
      return this.present(await tx.addresses.create({ data: { user_id: userId, ...fields, is_default: isDefault } }));
    });
  }
  patch(userId: string, key: string, id: string, input: AddressPatch) {
    return this.mutate(userId, key, 'PATCH', id, input, async tx => {
      const row = await this.owned(tx, userId, id);
      if (row.is_default && input.isDefault === false) throw new ConflictException({ code: 'DEFAULT_ADDRESS_REQUIRED',
        detail: 'Choose another default address before clearing this default.' });
      if (input.isDefault === true) await this.clearDefault(tx, userId);
      const { isDefault, ...fields } = input;
      return this.present(await tx.addresses.update({ where: { id }, data: { ...fields, is_default: isDefault } }));
    });
  }
  remove(userId: string, key: string, id: string) {
    return this.mutate(userId, key, 'DELETE', id, {}, async tx => {
      const row = await this.owned(tx, userId, id);
      await tx.addresses.update({ where: { id }, data: { deleted_at: new Date(), is_default: false } });
      if (row.is_default) {
        const next = await tx.addresses.findFirst({ where: { user_id: userId, deleted_at: null }, orderBy: [{ created_at: 'asc' }, { id: 'asc' }] });
        if (next) await tx.addresses.update({ where: { id: next.id }, data: { is_default: true } });
      }
      return { id, deleted: true };
    });
  }
  /** Discovery/checkout combine this owned address with VendorsService.covers in their transaction. */
  async requireOwned(tx: Tx, userId: string, id: string) {
    await this.customer(tx, userId);
    return this.owned(tx, userId, id);
  }
  private clearDefault(tx: Tx, userId: string) {
    return tx.addresses.updateMany({ where: { user_id: userId, is_default: true, deleted_at: null }, data: { is_default: false } });
  }
  private async customer(tx: Tx, userId: string) {
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'CUSTOMER' || !user.roles.some(r => r.role === 'CUSTOMER')) {
      throw new ForbiddenException({ code: 'CUSTOMER_ROLE_REQUIRED' });
    }
  }
  private async owned(tx: Tx, userId: string, id: string) {
    const row = await tx.addresses.findFirst({ where: { id, user_id: userId, deleted_at: null } });
    if (!row) throw new NotFoundException({ code: 'ADDRESS_NOT_FOUND' });
    return row;
  }
  private present(row: addresses) {
    return { id: row.id, label: row.label, line1: row.line1, line2: row.line2, landmark: row.landmark,
      city: row.city, state: row.state, pincode: row.pincode, latitude: row.latitude, longitude: row.longitude, isDefault: row.is_default };
  }
  private mutate(userId: string, key: string, method: string, path: string, input: object,
    write: (tx: Tx) => Promise<Prisma.InputJsonObject>) {
    if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
    const requestKey = `addresses:${createHash('sha256').update(`${userId}:${key}`).digest('hex')}`;
    const requestHash = this.idempotency.hashRequestBody(input);
    return this.db.$transaction(async tx => {
      // Shared with session/role writes; serializes default selection and replay across processes.
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))::text`;
      await this.customer(tx, userId);
      const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
      if (cached && cached.expires_at > new Date()) {
        if (cached.method !== method || cached.path !== path || cached.request_hash !== requestHash) {
          throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        }
        return cached.response_body;
      }
      if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
      const response = await write(tx);
      await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, user_id: userId, method, path,
        request_hash: requestHash, response_status: method === 'POST' ? 201 : 200, response_body: response,
        expires_at: new Date(Date.now() + 86400000) } });
      return response;
    }, { timeout: 15000 }).catch((error: unknown) => {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException({ code: 'ADDRESS_WRITE_UNAVAILABLE' });
    });
  }
}
