// T-032 / FR-100–FR-103. No public endpoint creates notifications.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayUnique, IsArray, IsBoolean, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf } from 'class-validator';
const defined = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
export class NotificationScope {
  @ApiPropertyOptional({ enum: ['VENDOR','CUSTOMER'] }) @ValidateIf(defined) @IsIn(['VENDOR','CUSTOMER']) role?: 'VENDOR' | 'CUSTOMER';
}
export class InboxQuery extends NotificationScope {
  @ApiPropertyOptional({ enum: ['ALL','ORDERS','PAYMENTS','DELIVERY','SYSTEM'] }) @ValidateIf(defined)
  @IsIn(['ALL','ORDERS','PAYMENTS','DELIVERY','SYSTEM']) category?: string;
  @ApiPropertyOptional({ type: 'integer', minimum: 1, maximum: 100, default: 50 }) @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number;
  @ApiPropertyOptional({ type: 'integer', minimum: 0, default: 0 }) @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(0) @Max(2147483647) offset?: number;
}
export class ReadNotifications extends NotificationScope {
  @ApiPropertyOptional({ type: [String], format: 'uuid', description: 'Provide IDs or all=true, exclusively.' })
  @ValidateIf(defined) @IsArray() @ArrayUnique() @ArrayMaxSize(100) @IsUUID(undefined, { each: true }) ids?: string[];
  @ApiPropertyOptional() @ValidateIf(defined) @IsBoolean() all?: boolean;
}
export class NotificationPreferences {
  @ApiProperty() @IsBoolean() orders!: boolean;
  @ApiProperty() @IsBoolean() payments!: boolean;
  @ApiProperty() @IsBoolean() delivery!: boolean;
  @ApiProperty({ description: 'Optional system pushes only; security/KYC always bypass this preference.' }) @IsBoolean() system!: boolean;
}
export class DevicePushInput {
  @ApiPropertyOptional({ type: String, nullable: true, description: 'Required when enabled. Null/omission with pushEnabled=false removes the current token. Never echoed.' })
  @ValidateIf(nullable) @IsString() @Length(16, 4096) @Matches(/^\S+$/) pushToken?: string | null;
  @ApiProperty() @IsBoolean() pushEnabled!: boolean;
  @ApiPropertyOptional() @ValidateIf(defined) @IsString() @Length(1, 64) appVersion?: string;
  @ApiPropertyOptional() @ValidateIf(defined) @IsString() @Length(1, 64) osVersion?: string;
}
export class DevicePushResponse {
  @ApiProperty({ format: 'uuid' }) deviceId!: string;
  @ApiProperty() pushEnabled!: boolean;
}
export class InboxItem {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: ['VENDOR','CUSTOMER'] }) role!: string;
  @ApiProperty({ enum: ['ORDERS','PAYMENTS','DELIVERY','SYSTEM'] }) category!: string;
  @ApiProperty() type!: string;
  @ApiProperty() title!: string;
  @ApiProperty() body!: string;
  @ApiProperty() path!: string;
  @ApiProperty({ type: String, format: 'date-time', nullable: true }) readAt!: string | null;
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
}
export class InboxResponse {
  @ApiProperty({ type: [InboxItem] }) items!: InboxItem[];
  @ApiProperty({ type: 'integer' }) total!: number;
  @ApiProperty({ type: 'integer' }) unreadCount!: number;
}
export class NotificationMutationResponse { @ApiProperty({ type: 'integer' }) changed!: number; }
