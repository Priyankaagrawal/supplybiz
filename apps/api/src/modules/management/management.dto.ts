import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayUnique, IsArray, IsISO8601, IsInt, IsOptional, IsString, Length, Matches, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';
export class ManagementQuery {
 @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 80) search?: string;
 @ApiPropertyOptional({ type: 'integer', minimum: 0 }) @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(1000000) offset?: number;
}
export class ManagementInput {
 @ApiProperty() @IsString() @Length(1, 500) @Matches(/\S/) reason!: string;
 @ApiProperty({ format: 'date-time' }) @IsISO8601({ strict: true }) expectedUpdatedAt!: string;
}
export class BadgeInput extends ManagementInput {
 @ApiProperty({ type: [String] }) @IsArray() @ArrayMaxSize(10) @ArrayUnique((value: unknown) => typeof value === 'string' ? value.trim().toLowerCase() : value)
 @IsString({ each: true }) @Length(1, 40, { each: true }) @Matches(/\S/, { each: true }) badges!: string[];
}
export class ManagedCustomer {
 @ApiProperty({ format: 'uuid' }) id!: string;
 @ApiProperty({ nullable: true, type: String }) name!: string | null;
 @ApiProperty() mobile!: string;
 @ApiProperty({ enum: ['ACTIVE', 'BLOCKED', 'DELETED'] }) status!: string;
 @ApiProperty({ format: 'date-time' }) updatedAt!: string;
}
export class ManagedVendor {
 @ApiProperty({ format: 'uuid' }) id!: string;
 @ApiProperty({ nullable: true, type: String }) businessName!: string | null;
 @ApiProperty({ type: ManagedCustomer }) account!: ManagedCustomer;
 @ApiProperty() category!: string;
 @ApiProperty({ nullable: true, type: String }) city!: string | null;
 @ApiProperty() kycStatus!: string;
 @ApiProperty() isSuspended!: boolean;
 @ApiProperty({ type: [String] }) badges!: string[];
 @ApiProperty({ format: 'date-time' }) updatedAt!: string;
}
export class ManagedVendorDetail extends ManagedVendor {
 @ApiProperty({ nullable: true, type: String }) planCode!: string | null;
 @ApiProperty({ enum: ['UNASSIGNED', 'ACTIVE', 'EXPIRED', 'SCHEDULED', 'UNAVAILABLE'] }) planStatus!: string;
 @ApiProperty({ nullable: true, type: String, format: 'date-time' }) planStartsAt!: string | null;
 @ApiProperty({ nullable: true, type: String, format: 'date-time' }) planEndsAt!: string | null;
 @ApiProperty({ type: 'integer' }) customerLimit!: number;
}
export class ManagedVendorList { @ApiProperty({ type: [ManagedVendor] }) items!: ManagedVendor[]; @ApiProperty({ type: 'integer' }) total!: number; }
export class ManagedCustomerList { @ApiProperty({ type: [ManagedCustomer] }) items!: ManagedCustomer[]; @ApiProperty({ type: 'integer' }) total!: number; }
export class ManagementResponse {
 @ApiProperty({ format: 'uuid' }) id!: string;
 @ApiProperty({ format: 'date-time' }) updatedAt!: string;
 @ApiPropertyOptional() status?: string;
 @ApiPropertyOptional() isSuspended?: boolean;
 @ApiPropertyOptional({ type: [String] }) badges?: string[];
}
