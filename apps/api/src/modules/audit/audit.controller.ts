import { Controller, Get, Header, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsOptional, IsUUID, Matches } from 'class-validator';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminPermission } from '../admin-auth/admin-auth.controller';
export class AuditQuery {
  @ApiPropertyOptional({ format: 'uuid' }) @IsOptional() @IsUUID() beforeId?: string;
  @ApiPropertyOptional() @IsOptional() @Matches(/^[A-Z_]{1,64}$/) action?: string;
  @ApiPropertyOptional({ format: 'uuid' }) @IsOptional() @IsUUID() actorId?: string;
}
class AuditSnapshot {
  @ApiPropertyOptional() role?: string;
  @ApiPropertyOptional() status?: string;
  @ApiPropertyOptional({ type: Number }) failed_attempts?: number;
  @ApiPropertyOptional({ type: String, nullable: true, format: 'date-time' }) locked_until?: string | null;
  @ApiPropertyOptional({ type: String, nullable: true, format: 'date-time' }) last_login_at?: string | null;
  @ApiPropertyOptional() totp_enrolled?: boolean;
  @ApiPropertyOptional() verificationMethod?: string;
  @ApiPropertyOptional() providerChecks?: string;
  @ApiPropertyOptional({ type: String, nullable: true, format: 'uuid' }) reviewerId?: string | null;
}

class AuditRow {
  @ApiProperty() id!: string;
  @ApiProperty() actor_type!: string;
  @ApiProperty({ type: String, nullable: true }) actor_id!: string | null;
  @ApiProperty() action!: string;
  @ApiProperty() entity!: string;
  @ApiProperty({ type: String, nullable: true }) entity_id!: string | null;
  @ApiProperty({ type: AuditSnapshot, nullable: true }) before!: Prisma.JsonValue;
  @ApiProperty({ type: AuditSnapshot, nullable: true }) after!: Prisma.JsonValue;
  @ApiProperty({ type: String, nullable: true }) ip!: string | null;
  @ApiProperty({ type: String, format: 'date-time' }) at!: Date;
}
export class AuditPage {
  @ApiProperty({ type: [AuditRow] }) items!: AuditRow[];
  @ApiProperty() hasMore!: boolean;
}
@ApiTags('audit') @ApiBearerAuth() @Controller('admin/audit-logs')
export class AuditController {
  constructor(private readonly db: PrismaService) {}
  @Get() @AdminPermission('audit.read') @Header('Cache-Control', 'no-store')
  @ApiOkResponse({ type: AuditPage })
  async list(@Query() query: AuditQuery): Promise<AuditPage> {
    const rows = await this.db.audit_logs.findMany({
      where: { action: query.action, actor_id: query.actorId },
      ...(query.beforeId ? { cursor: { id: query.beforeId }, skip: 1 } : {}),
      orderBy: [{ at: 'desc' }, { id: 'desc' }], take: 51,
    });
    return { items: rows.slice(0, 50), hasMore: rows.length > 50 };
  }
}
