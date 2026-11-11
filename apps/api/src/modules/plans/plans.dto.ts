import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsBoolean, IsEnum, IsISO8601, IsInt, IsOptional, IsString, IsUUID, Length, Matches, Max, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { plan_price_duration, plan_status } from '@prisma/client';
export class ExtendPlanInput {
  @ApiProperty({ format: 'date-time' }) @IsISO8601({ strict: true }) @Matches(/(?:Z|[+-]\d{2}:\d{2})$/) endsAt!: string;
  @ApiProperty() @IsString() @Length(1, 500) @Matches(/\S/) reason!: string;
}
export class AssignPlanInput extends ExtendPlanInput {
  @ApiProperty({ format: 'uuid' }) @IsUUID() planId!: string;
  @ApiProperty({ format: 'date-time' }) @IsISO8601({ strict: true }) @Matches(/(?:Z|[+-]\d{2}:\d{2})$/) startsAt!: string;
}
export class PlanPriceResponse {
  @ApiProperty({ enum: ['MONTHLY', 'HALF_YEARLY', 'YEARLY'] }) duration!: string;
  @ApiProperty({ type: 'integer', minimum: 0 }) pricePaise!: number;
}
export class PlanCatalogRow {
  @ApiProperty({ format: 'date-time' }) updatedAt!: string;
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: ['BASIC', 'STANDARD', 'BUSINESS', 'PREMIUM'] }) code!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ type: 'integer' }) customerLimit!: number;
  @ApiProperty({ type: [String] }) features!: string[];
  @ApiProperty() isPopular!: boolean;
  @ApiProperty({ enum: ['ACTIVE', 'INACTIVE'] }) status!: string;
  @ApiProperty({ type: [PlanPriceResponse] }) prices!: PlanPriceResponse[];
}
export class CatalogPriceInput {
  @ApiProperty({ enum: plan_price_duration }) @IsEnum(plan_price_duration) duration!: plan_price_duration;
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER }) @IsInt() @Min(0) @Max(Number.MAX_SAFE_INTEGER) pricePaise!: number;
}
export class CatalogPlanInput {
  @ApiProperty() @IsString() @Length(1, 120) @Matches(/\S/) name!: string;
  @ApiProperty({ enum: plan_status }) @IsEnum(plan_status) status!: plan_status;
  @ApiProperty() @IsBoolean() isPopular!: boolean;
  @ApiProperty({ format: 'date-time' }) @IsISO8601({ strict: true }) expectedUpdatedAt!: string;
  @ApiProperty() @IsString() @Length(1, 500) @Matches(/\S/) reason!: string;
  @ApiProperty({ type: [CatalogPriceInput] }) @IsArray() @ArrayMinSize(3) @ArrayMaxSize(3)
  @ArrayUnique((price: CatalogPriceInput | null) => price?.duration) @ValidateNested({ each: true }) @Type(() => CatalogPriceInput) prices!: CatalogPriceInput[];
}
export class PlanAdminQuery {
  @ApiProperty({ required: false }) @IsOptional() @IsString() @Length(0, 80) search?: string;
  @ApiProperty({ required: false, type: 'integer', minimum: 0 }) @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(1000000) offset?: number;
}
export class PlanVendorRow {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ nullable: true, type: String }) businessName!: string | null;
}
export class PlanVendorList {
  @ApiProperty({ type: [PlanVendorRow] }) items!: PlanVendorRow[];
  @ApiProperty({ type: 'integer' }) total!: number;
}
export class PlanCatalogResponse { @ApiProperty({ type: [PlanCatalogRow] }) items!: PlanCatalogRow[]; }
export class AssignmentResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ format: 'uuid' }) vendorId!: string;
  @ApiProperty({ format: 'uuid' }) planId!: string;
  @ApiProperty() code!: string;
  @ApiProperty({ format: 'date-time' }) startsAt!: string;
  @ApiProperty({ format: 'date-time' }) endsAt!: string;
  @ApiProperty() reason!: string;
  @ApiProperty({ format: 'uuid' }) grantedByAdmin!: string;
  @ApiProperty({ format: 'uuid' }) auditId!: string;
}
export class PlanHistoryRow extends AssignmentResponse {
  @ApiProperty({ nullable: true, type: String, format: 'date-time' }) supersededAt!: string | null;
}
export class PlanHistoryResponse {
  @ApiProperty({ type: [PlanHistoryRow] }) items!: PlanHistoryRow[];
  @ApiProperty({ type: 'integer' }) total!: number;
}
export class VendorAssignmentResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ format: 'uuid' }) planId!: string;
  @ApiProperty() code!: string;
  @ApiProperty({ format: 'date-time' }) startsAt!: string;
  @ApiProperty({ format: 'date-time' }) endsAt!: string;
}
export class CurrentPlanResponse {
  @ApiProperty({ type: VendorAssignmentResponse, nullable: true }) assignment!: VendorAssignmentResponse | null;
  @ApiProperty({ enum: ['UNASSIGNED', 'SCHEDULED', 'ACTIVE', 'EXPIRED', 'UNAVAILABLE'] }) status!: string;
  @ApiProperty({ type: 'integer' }) customerLimit!: number;
  @ApiProperty({ type: 'integer' }) activeCustomers!: number;
  @ApiProperty() canAddCustomer!: boolean;
  @ApiProperty({ type: [String] }) features!: string[];
}
