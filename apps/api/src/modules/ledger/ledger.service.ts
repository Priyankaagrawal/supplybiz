// T-070 / RULE-09/10. Internal transaction boundary; no ungated HTTP mutations.
import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { ledger_entries, Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';

type Tx = Prisma.TransactionClient;
export type LedgerType = 'DEBIT' | 'CREDIT';
export interface LedgerPost {
  vendorId: string; customerId: string; actorId: string; type: LedgerType; amountPaise: bigint;
  refType: 'ORDER' | 'SALE' | 'PAYMENT' | 'CLAIM'; refId: string; note?: string; entryDate?: string;
}
type Append = Omit<LedgerPost, 'refType'> & { refType: LedgerPost['refType'] | 'OPENING' | 'REVERSAL';
  reversesId?: string; requestKey?: string; requestHash?: string };
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const maxPaise = 9223372036854775807n;
@Injectable()
export class LedgerService {
  constructor(private readonly db: PrismaService, private readonly idempotency: IdempotencyService) {}

  /** T-049/T-071/T-079 post within the same transaction as the authorized source transition. */
  post(tx: Tx, input: LedgerPost) {
    if (!['ORDER','SALE','PAYMENT','CLAIM'].includes(input.refType)) throw new BadRequestException({ code: 'INVALID_LEDGER_ENTRY' });
    return this.append(tx, input);
  }

  opening(userId: string, key: string, customerId: string,
    input: { type: LedgerType; amountPaise: bigint; note: string; entryDate?: string }) {
    const request = this.request(userId, key, { action: 'OPENING', customerId, ...input, amountPaise: String(input.amountPaise) });
    const hex = request.requestKey;
    const refId = `${hex.slice(0,8)}-${hex.slice(8,12)}-4${hex.slice(13,16)}-8${hex.slice(17,20)}-${hex.slice(20,32)}`;
    return this.db.$transaction(async tx => {
      const vendor = await this.vendor(tx, userId);
      return this.present(await this.append(tx, { ...input, ...request, refType: 'OPENING', refId,
        vendorId: vendor.id, customerId, actorId: userId }));
    }, { timeout: 15000 });
  }
  reverse(userId: string, key: string, entryId: string, note: string) {
    if (!uuid.test(entryId)) throw new BadRequestException({ code: 'INVALID_LEDGER_ENTRY' });
    const request = this.request(userId, key, { action: 'REVERSAL', entryId, note });
    return this.db.$transaction(async tx => {
      const vendor = await this.vendor(tx, userId);
      const original = await tx.ledger_entries.findFirst({ where: { id: entryId, vendor_id: vendor.id } });
      if (!original) throw new NotFoundException({ code: 'LEDGER_ENTRY_NOT_FOUND' });
      return this.present(await this.append(tx, { ...request, vendorId: vendor.id,
        customerId: original.vendor_customer_id, actorId: userId, refType: 'REVERSAL', refId: entryId,
        reversesId: entryId, type: original.type === 'DEBIT' ? 'CREDIT' : 'DEBIT', amountPaise: original.amount_paise, note }));
    }, { timeout: 15000 });
  }
  async balance(userId: string, customerId: string) {
    const vendor = await this.vendor(this.db, userId);
    await this.customer(this.db, vendor.id, customerId);
    const row = await this.db.ledger_balances.findUnique({ where: { vendor_customer_id: customerId } });
    return { customerId, totalDebitPaise: String(row?.total_debit_paise ?? 0n),
      totalCreditPaise: String(row?.total_credit_paise ?? 0n), duePaise: String(row?.due_paise ?? 0n) };
  }
  async entries(userId: string, customerId: string, limit = 50, beforeId?: string) {
    if (!Number.isInteger(limit) || limit < 1 || limit > 100) throw new BadRequestException({ code: 'INVALID_PAGE' });
    return this.db.$transaction(async tx => {
      const vendor = await this.vendor(tx, userId);
      await this.customer(tx, vendor.id, customerId);
      if (beforeId && (!uuid.test(beforeId) || !await tx.ledger_entries.findFirst({ where: { id: beforeId, vendor_customer_id: customerId } }))) {
        throw new NotFoundException({ code: 'LEDGER_ENTRY_NOT_FOUND' });
      }
      const rows = await tx.ledger_entries.findMany({ where: { vendor_customer_id: customerId },
        orderBy: [{ created_at: 'desc' }, { id: 'desc' }], take: limit + 1,
        ...(beforeId ? { cursor: { id: beforeId }, skip: 1 } : {}) });
      return { items: rows.slice(0,limit).map(row => this.present(row)), hasMore: rows.length > limit };
    }, { isolationLevel: 'RepeatableRead' });
  }

  /** Fail closed until the operator installs separate ownership/runtime grants. */
  async assertPrivileges(tx: Tx) {
    const [permissions] = await tx.$queryRaw<{ can_insert: boolean; unsafe: boolean }[]>`
      SELECT has_table_privilege(current_user,'public.ledger_entries','INSERT') AS can_insert,
        (has_table_privilege(current_user,'public.ledger_entries','UPDATE,DELETE,TRUNCATE,TRIGGER')
         OR has_any_column_privilege(current_user,'public.ledger_entries','UPDATE')
         OR has_table_privilege(current_user,'public.ledger_balances','INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
         OR has_any_column_privilege(current_user,'public.ledger_balances','INSERT,UPDATE')
         OR has_table_privilege(current_user,'public.ledger_reconciliation_findings','UPDATE,DELETE,TRUNCATE,TRIGGER')
         OR has_any_column_privilege(current_user,'public.ledger_reconciliation_findings','UPDATE')) AS unsafe`;
    if (!permissions?.can_insert || permissions.unsafe) throw new ServiceUnavailableException({ code: 'LEDGER_GRANTS_NOT_APPLIED' });
  }
  private request(userId: string, key: string, body: object) {
    if (!uuid.test(userId) || typeof key !== 'string' || !key.trim() || key.length > 120) throw new BadRequestException({ code: 'INVALID_IDEMPOTENCY_KEY' });
    return { requestKey: createHash('sha256').update(`${userId}:${key}`).digest('hex'), requestHash: this.idempotency.hashRequestBody(body) };
  }
  private async append(tx: Tx, input: Append): Promise<ledger_entries> {
    if (![input.vendorId,input.customerId,input.actorId,input.refId].every(id => typeof id === 'string' && uuid.test(id)) ||
      !['DEBIT','CREDIT'].includes(input.type) || !['ORDER','SALE','PAYMENT','CLAIM','OPENING','REVERSAL'].includes(input.refType) ||
      typeof input.amountPaise !== 'bigint' || input.amountPaise <= 0n || input.amountPaise > maxPaise ||
      (input.note !== undefined && typeof input.note !== 'string')) throw new BadRequestException({ code: 'INVALID_LEDGER_ENTRY' });
    const note = input.note?.trim() ?? '';
    if (note.length > 500 || (['OPENING','REVERSAL'].includes(input.refType) && !note)) throw new BadRequestException({ code: 'LEDGER_NOTE_REQUIRED' });
    if (input.entryDate !== undefined && (typeof input.entryDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(input.entryDate) ||
      !Number.isFinite(Date.parse(input.entryDate)) || new Date(input.entryDate).toISOString().slice(0,10) !== input.entryDate)) {
      throw new BadRequestException({ code: 'INVALID_LEDGER_DATE' });
    }
    const vendor = await this.vendor(tx, input.actorId, true);
    if (vendor.id !== input.vendorId) throw new ForbiddenException({ code: 'VENDOR_SCOPE_REQUIRED' });
    await this.assertPrivileges(tx);
    // Serialize source replay, reversal and aggregate updates using the same customer lock.
    await tx.$queryRaw`SELECT id FROM vendor_customers WHERE id = ${input.customerId}::uuid
      AND vendor_id = ${vendor.id}::uuid AND deleted_at IS NULL FOR UPDATE`;
    await this.customer(tx, vendor.id, input.customerId);
    if (input.requestKey) {
      const previous = await tx.ledger_entries.findUnique({ where: { request_key: input.requestKey } });
      if (previous) {
        if (previous.request_hash !== input.requestHash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
        return previous;
      }
    }
    if (input.reversesId && await tx.ledger_entries.findUnique({ where: { reverses_entry_id: input.reversesId } })) {
      throw new ConflictException({ code: 'ENTRY_ALREADY_REVERSED' });
    }
    const existing = await tx.ledger_entries.findUnique({ where: { ref_type_ref_id_type: { ref_type: input.refType, ref_id: input.refId, type: input.type } } });
    if (existing) {
      if (existing.vendor_id !== vendor.id || existing.vendor_customer_id !== input.customerId || existing.created_by !== input.actorId ||
        existing.amount_paise !== input.amountPaise || existing.note !== note ||
        (input.entryDate && existing.entry_date.toISOString().slice(0,10) !== input.entryDate)) {
        throw new ConflictException({ code: 'LEDGER_REFERENCE_MISMATCH' });
      }
      return existing;
    }
    return tx.ledger_entries.create({ data: { vendor_id: vendor.id, vendor_customer_id: input.customerId,
      created_by: input.actorId, type: input.type, amount_paise: input.amountPaise, ref_type: input.refType,
      ref_id: input.refId, reverses_entry_id: input.reversesId, request_key: input.requestKey, request_hash: input.requestHash,
      note, ...(input.entryDate ? { entry_date: new Date(input.entryDate) } : {}) } });
  }
  private async vendor(tx: Tx, userId: string, write = false) {
    if (!uuid.test(userId)) throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    if (write) await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
    const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true, vendor: true } });
    if (!user || user.status !== 'ACTIVE' || user.active_role !== 'VENDOR' || !user.roles.some(r => r.role === 'VENDOR')) {
      throw new ForbiddenException({ code: 'VENDOR_ROLE_REQUIRED' });
    }
    if (!user.vendor) throw new NotFoundException({ code: 'VENDOR_NOT_FOUND' });
    if (write) await tx.$queryRaw`SELECT id FROM vendors WHERE id = ${user.vendor.id}::uuid FOR UPDATE`;
    const vendor = write ? await tx.vendors.findUniqueOrThrow({ where: { id: user.vendor.id } }) : user.vendor;
    if (vendor.is_suspended) throw new ForbiddenException({ code: 'VENDOR_SUSPENDED' });
    return vendor;
  }
  private async customer(tx: Tx, vendorId: string, customerId: string) {
    if (!uuid.test(customerId) || !await tx.vendor_customers.findFirst({ where: { id: customerId, vendor_id: vendorId, deleted_at: null } })) {
      throw new NotFoundException({ code: 'CUSTOMER_NOT_FOUND' });
    }
  }
  private present(row: ledger_entries) {
    return { id: row.id, customerId: row.vendor_customer_id, type: row.type, amountPaise: String(row.amount_paise),
      refType: row.ref_type, refId: row.ref_id, reversesEntryId: row.reverses_entry_id, note: row.note,
      entryDate: row.entry_date.toISOString().slice(0,10), createdAt: row.created_at.toISOString() };
  }
}
