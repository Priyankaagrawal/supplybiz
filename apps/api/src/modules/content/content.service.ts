import { BadRequestException, ConflictException, HttpException, Injectable, NotFoundException, ServiceUnavailableException, UnprocessableEntityException } from '@nestjs/common';
import { Prisma, app_config } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { appConfigPolicy } from './app-config';
import { AdminConfigResponse, ConfigInput, ContentQuery, FaqInput, FaqList, FaqRow, LegalInput, LegalList, LegalRow, LegalType } from './content.dto';

@Injectable()
export class ContentService {
 constructor(private readonly db: PrismaService, private readonly auth: AdminAuthService, private readonly idem: IdempotencyService) {}
 private faq(row: app_config): FaqRow { return { ...(row.value as unknown as Omit<FaqRow, 'id'|'updatedAt'>), id: row.key.slice('cms:faq:'.length), updatedAt: row.updated_at.toISOString() }; }
 async faqs(query: ContentQuery, admin = false): Promise<FaqList> {
  const where: Prisma.app_configWhereInput = { key: { startsWith: 'cms:faq:' }, AND: [
   ...(!admin ? [{ value: { path: ['published'], equals: true } }] : []),
   ...(query.topic ? [{ value: { path: ['topic'], equals: query.topic } }] : []),
  ] };
  const [rows, total] = await this.db.$transaction([
   this.db.app_config.findMany({ where, orderBy: { key: 'asc' }, skip: query.offset, take: 20 }),
   this.db.app_config.count({ where }),
  ], { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
  return { items: rows.map(r => this.faq(r)), total };
 }
 async legal(type: LegalType, version?: string): Promise<LegalRow> {
  if (version !== undefined && !/^[A-Za-z0-9][A-Za-z0-9._-]{0,49}$/.test(version)) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
  const pointer = version ? null : await this.db.app_config.findUnique({ where: { key: `cms:current:${type}` } });
  const selected = version ?? (pointer?.value as { version?: string } | undefined)?.version;
  const row = selected ? await this.db.app_config.findUnique({ where: { key: `cms:legal:${type}:${selected}` } }) : null;
  if (!row) throw new NotFoundException({ code: 'LEGAL_NOT_PUBLISHED' });
  return row.value as unknown as LegalRow;
 }
 async legalHistory(): Promise<LegalList> {
  const rows = await this.db.app_config.findMany({ where: { key: { startsWith: 'cms:legal:' } }, orderBy: [{ updated_at: 'desc' }, { key: 'asc' }], take: 20 });
  return { items: rows.map(r => r.value as unknown as LegalRow) };
 }
 async config(): Promise<AdminConfigResponse> {
  const row = await this.db.app_config.findUnique({ where: { key: 'mobile' } });
  if (!row) return { minVersionAndroid: '0.1.0', flags: {}, updatedAt: null };
  const value = appConfigPolicy.safeParse(row.value);
  if (!value.success) throw new ServiceUnavailableException({ code: 'CONFIG_UNAVAILABLE' });
  return { ...value.data, updatedAt: row.updated_at.toISOString() };
 }
 saveFaq(token: string, csrf: string, key: string, id: string, input: FaqInput) {
  return this.write(token, csrf, key, 'cms.manage', `faq:${id}`, input, async tx => {
   const name = `cms:faq:${id}`, before = await tx.app_config.findUnique({ where: { key: name } });
   if ((before?.updated_at.toISOString() ?? null) !== input.expectedUpdatedAt) throw new ConflictException({ code: 'VERSION_CONFLICT' });
   const value = { topic: input.topic, question: input.question.trim(), answer: input.answer.trim(), published: input.published };
   const row = await tx.app_config.upsert({ where: { key: name }, create: { key: name, value }, update: { value, updated_at: new Date(Math.max(Date.now(), (before?.updated_at.getTime() ?? 0) + 1)) } });
   return { response: this.faq(row), audit: { key: name, published: input.published, sha256: this.hash(value) } };
  });
 }
 publish(token: string, csrf: string, key: string, type: LegalType, input: LegalInput) {
  return this.write(token, csrf, key, 'cms.manage', `legal:${type}`, input, async tx => {
   const name = `cms:current:${type}`, current = await tx.app_config.findUnique({ where: { key: name } });
   if (((current?.value as { version?: string } | undefined)?.version ?? null) !== input.expectedVersion) throw new ConflictException({ code: 'VERSION_CONFLICT' });
   const versionKey = `cms:legal:${type}:${input.version}`;
   if (await tx.app_config.findUnique({ where: { key: versionKey } })) throw new ConflictException({ code: 'LEGAL_VERSION_EXISTS' });
   const value = { type, version: input.version, title: input.title.trim(), text: input.text.trim(), sha256: createHash('sha256').update(input.text.trim(), 'utf8').digest('hex'), publishedAt: new Date().toISOString() };
   await tx.app_config.create({ data: { key: versionKey, value } });
   await tx.app_config.upsert({ where: { key: name }, create: { key: name, value: { version: input.version } }, update: { value: { version: input.version } } });
   return { response: value, audit: { key: name, version: input.version, previousVersion: input.expectedVersion, sha256: value.sha256 } };
  });
 }
 saveConfig(token: string, csrf: string, key: string, input: ConfigInput) {
  const value = appConfigPolicy.safeParse({ minVersionAndroid: input.minVersionAndroid, flags: input.flags });
  const names = Object.keys(input.flags);
  if (!value.success || names.length > 50 || names.some(n => !/^[a-z][a-zA-Z0-9_]{0,63}$/.test(n) || ['constructor', 'prototype', '__proto__'].includes(n))) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
  return this.write(token, csrf, key, 'config.manage', 'config:mobile', input, async tx => {
   const before = await tx.app_config.findUnique({ where: { key: 'mobile' } });
   if ((before?.updated_at.toISOString() ?? null) !== input.expectedUpdatedAt) throw new ConflictException({ code: 'VERSION_CONFLICT' });
   const row = await tx.app_config.upsert({ where: { key: 'mobile' }, create: { key: 'mobile', value: value.data }, update: { value: value.data, updated_at: new Date(Math.max(Date.now(), (before?.updated_at.getTime() ?? 0) + 1)) } });
   return { response: { ...value.data, updatedAt: row.updated_at.toISOString() }, audit: { key: 'mobile', before: before?.value ?? null, after: value.data } };
  });
 }
 private hash(value: object) { return this.idem.hashRequestBody(value); }
 private async write<T extends object>(token: string, csrf: string, key: string, permission: string, path: string, input: object,
  action: (tx: Prisma.TransactionClient) => Promise<{ response: T; audit: object }>): Promise<T> {
  if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
  const hash = this.hash(input);
  return this.db.$transaction(async tx => {
   // Live admin/session lock is held through side effects and replay authorization.
   const actor = await this.auth.authenticateInTransaction(tx, token, permission, csrf);
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended('admin-content', 0))::text`;
   const requestKey = `content:${createHash('sha256').update(`${actor.id}:${key}`).digest('hex')}`;
   const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
   if (cached && cached.expires_at > new Date()) {
    if (cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
    return cached.response_body as unknown as T;
   }
   if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
   const { response, audit } = await action(tx);
   await tx.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: actor.id, action: 'CONTENT_UPDATE', entity: permission === 'config.manage' ? 'app_config' : 'cms', after: audit as Prisma.InputJsonObject } });
   await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, method: 'PUT', path, request_hash: hash, response_status: 200, response_body: response as Prisma.InputJsonObject, expires_at: new Date(Date.now() + 86400000) } });
   return response;
  }).catch((e: unknown) => { if (e instanceof HttpException) throw e; throw new ServiceUnavailableException({ code: 'CONTENT_WRITE_UNAVAILABLE' }); });
 }
}
