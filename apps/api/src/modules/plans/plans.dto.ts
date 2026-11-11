import { ApiProperty } from '@nestjs/swagger';
import { IsISO8601, IsString, IsUUID, Length, Matches } from 'class-validator';
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
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: ['BASIC', 'STANDARD', 'BUSINESS', 'PREMIUM'] }) code!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ type: 'integer' }) customerLimit!: number;
  @ApiProperty({ type: [String] }) features!: string[];
  @ApiProperty() isPopular!: boolean;
  @ApiProperty({ enum: ['ACTIVE', 'INACTIVE'] }) status!: string;
  @ApiProperty({ type: [PlanPriceResponse] }) prices!: PlanPriceResponse[];
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
