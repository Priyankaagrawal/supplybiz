// FR-405 / S-A-08 / T-153
import { BadRequestException, Body, ConflictException, Controller, Get, Header, Headers, HttpException, NotFoundException, Param, ParseUUIDPipe, Post, Put, Req, ServiceUnavailableException, SetMetadata, UnprocessableEntityException } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiProperty, ApiTags, ApiCreatedResponse } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayUnique, IsArray, IsEnum, IsInt, IsString, Length, Matches, Max, Min } from 'class-validator';
import { category_status, category_type } from '@prisma/client';
import { createHash } from 'node:crypto';
import { Request } from 'express';
import { PrismaService } from '../../prisma/prisma.service';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { IdempotencyService } from '../idempotency/idempotency.service';

export class CategoryInput {
 @ApiProperty() @Matches(/^[A-Z][A-Z0-9_]{0,63}$/) code!: string;
 @ApiProperty() @IsString() @Length(1, 120) @Matches(/\S/) name!: string;
 @ApiProperty({ description: 'Icon identifier, not a URL or HTML. Empty clears the icon.' }) @Matches(/^[a-zA-Z0-9_-]{0,120}$/) icon!: string;
 @ApiProperty({ enum: category_type }) @IsEnum(category_type) type!: category_type;
 @ApiProperty({ enum: category_status }) @IsEnum(category_status) status!: category_status;
 @ApiProperty() @IsInt() @Min(0) @Max(2147483647) sortOrder!: number;
 @ApiProperty({ type: [String] }) @IsArray() @ArrayMaxSize(50) @ArrayUnique() @IsString({ each: true }) @Length(1, 80, { each: true }) @Matches(/\S/, { each: true }) productTypes!: string[];
}
export class CategoryRow extends CategoryInput { @ApiProperty({ format: 'uuid' }) id!: string; }
export class CategoryList { @ApiProperty({ type: [CategoryRow] }) items!: CategoryRow[]; }

@ApiTags('categories') @ApiBearerAuth() @AdminPermission('categories.manage')
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('admin/categories')
export class CategoriesController {
 constructor(private readonly db: PrismaService, private readonly auth: AdminAuthService, private readonly idempotency: IdempotencyService) {}
 @Get() @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: CategoryList })
 async list(): Promise<CategoryList> {
  const rows = await this.db.categories.findMany({ orderBy: [{ sort_order: 'asc' }, { code: 'asc' }] });
  return { items: rows.map(row => ({ id: row.id, code: row.code, name: row.name_en, icon: row.icon ?? '', type: row.type,
   status: row.status, sortOrder: row.sort_order, productTypes: Array.isArray(row.product_types) ? row.product_types.filter((v): v is string => typeof v === 'string') : [] })) };
 }
 @Post() @Header('Cache-Control', 'no-store') @ApiCreatedResponse({ type: CategoryRow })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 create(@Body() input: CategoryInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.save(input, key, req); }
 @Put(':id') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: CategoryRow })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 update(@Param('id', ParseUUIDPipe) id: string, @Body() input: CategoryInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.save(input, key, req, id); }
 private async save(input: CategoryInput, key: string, req: Request, id?: string) {
  if (!key?.trim() || key.length > 120) throw new BadRequestException({ code: 'VALIDATION_FAILED' });
  const actor = await this.auth.authenticate(bearer(req), 'categories.manage', req.header('X-CSRF-Token') ?? '');
  const requestKey = `category:${createHash('sha256').update(`${actor.id}:${key}`).digest('hex')}`;
  const hash = this.idempotency.hashRequestBody(input), path = id ?? 'create';
  return this.db.$transaction(async tx => {
   // Serializes taxonomy edits, duplicate-code checks and concurrent retry attempts.
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended('admin-categories', 0))::text`;
   const cached = await tx.idempotency_keys.findUnique({ where: { idempotency_key: requestKey } });
   if (cached && cached.expires_at > new Date()) {
    if (cached.path !== path || cached.request_hash !== hash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
    return cached.response_body;
   }
   if (cached) await tx.idempotency_keys.delete({ where: { idempotency_key: requestKey } });
   const before = id ? await tx.categories.findUnique({ where: { id } }) : null;
   if (id && !before) throw new NotFoundException({ code: 'CATEGORY_NOT_FOUND' });
   const duplicate = await tx.categories.findUnique({ where: { code: input.code } });
   if (duplicate && duplicate.id !== id) throw new ConflictException({ code: 'CATEGORY_CODE_EXISTS' });
   if (id && before?.type !== input.type && await tx.vendors.count({ where: { category_id: id } })) throw new ConflictException({ code: 'CATEGORY_IN_USE' });
   const data = { code: input.code, name_en: input.name.trim(), icon: input.icon || null,
    type: input.type, status: input.status, sort_order: input.sortOrder, product_types: input.productTypes };
   const row = id ? await tx.categories.update({ where: { id }, data }) : await tx.categories.create({ data: { ...data, name_hi: '' } });
   const response = { ...input, name: row.name_en, id: row.id };
   await tx.audit_logs.create({ data: { actor_type: 'ADMIN', actor_id: actor.id, action: id ? 'CATEGORY_UPDATE' : 'CATEGORY_CREATE',
    entity: 'categories', entity_id: row.id, ip: req.ip,
    before: before ? { code: before.code, name: before.name_en, icon: before.icon, type: before.type, status: before.status, sortOrder: before.sort_order, productTypes: before.product_types } : undefined,
    after: response } });
   await tx.idempotency_keys.create({ data: { idempotency_key: requestKey, method: id ? 'PUT' : 'POST', path, request_hash: hash,
    response_status: id ? 200 : 201, response_body: response, expires_at: new Date(Date.now() + 86400000) } });
   return response;
  }).catch((error: unknown) => {
   if (error instanceof HttpException) throw error;
   throw new ServiceUnavailableException({ code: 'CATEGORY_WRITE_UNAVAILABLE' });
  });
 }
}
