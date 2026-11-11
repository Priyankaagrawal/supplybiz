// FR-060–FR-064 / T-028
import { ApiProperty, ApiPropertyOptional, PartialType, PickType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsEmail, IsIn, IsInt, IsString, Length, Matches, Max, Min, ValidateIf } from 'class-validator';

const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
const defined = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
export class CustomerInput {
  @ApiProperty() @Transform(trim) @IsString() @Length(1, 120) name!: string;
  @ApiProperty({ description: 'Indian mobile, ten digits or +91-prefixed. Stored in +91 form.' })
  @Transform(trim) @IsString() @Matches(/^(?:\+91)?[6-9]\d{9}$/) mobile!: string;
  @ApiPropertyOptional({ type: String, nullable: true })
  @ValidateIf(nullable) @Transform(trim) @IsEmail() @Length(1, 254) email?: string | null;
  @ApiPropertyOptional({ description: 'Defaults to empty on creation; omission preserves the address on PATCH.' })
  @ValidateIf(defined) @Transform(trim) @IsString() @Length(0, 500) address?: string;
  @ApiPropertyOptional({ enum: ['CASH','UPI','BANK','WALLET'], description: 'Defaults to CASH on creation; omission preserves the method on PATCH.' })
  @ValidateIf(defined) @IsIn(['CASH','UPI','BANK','WALLET']) preferredPayment?: string;
}
export class CustomerPatch extends PartialType(CustomerInput, { skipNullProperties: false }) {
  @ApiPropertyOptional({ enum: ['ACTIVE','INACTIVE'] }) @ValidateIf(defined) @IsIn(['ACTIVE','INACTIVE']) status?: string;
}
export class CustomerQuery {
  @ApiPropertyOptional() @ValidateIf(defined) @Transform(trim) @IsString() @Length(0, 120) search?: string;
  @ApiPropertyOptional({ enum: ['ALL','ACTIVE','INACTIVE','SUBSCRIPTION'], default: 'ALL' })
  @ValidateIf(defined) @IsIn(['ALL','ACTIVE','INACTIVE','SUBSCRIPTION']) filter?: string;
  @ApiPropertyOptional({ type: 'integer', default: 50, maximum: 100 })
  @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number;
  @ApiPropertyOptional({ type: 'integer', default: 0 })
  @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(0) @Max(2147483647) offset?: number;
}
export class CustomerResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() mobile!: string;
  @ApiProperty({ type: String, nullable: true }) email!: string | null;
  @ApiProperty() address!: string;
  @ApiProperty({ enum: ['CASH','UPI','BANK','WALLET'] }) preferredPayment!: string;
  @ApiProperty({ enum: ['ACTIVE','INACTIVE'] }) status!: string;
  @ApiProperty({ enum: ['UNLINKED','LINKED'] }) linkStatus!: string;
  @ApiProperty({ type: String, format: 'uuid', nullable: true }) userId!: string | null;
}
export class CustomerList {
  @ApiProperty({ type: [CustomerResponse] }) items!: CustomerResponse[];
  @ApiProperty({ type: 'integer' }) total!: number;
  @ApiProperty({ type: 'integer' }) activeCount!: number;
  @ApiProperty({ type: 'integer' }) customerLimit!: number;
}
export class LinkRequestResponse {
  @ApiProperty({ format: 'uuid', description: 'The matching vendor-customer record ID.' }) id!: string;
  @ApiProperty({ format: 'uuid' }) vendorId!: string;
  @ApiProperty({ type: String, nullable: true }) businessName!: string | null;
}
export class LinkRequestQuery extends PickType(CustomerQuery, ['limit','offset'] as const) {}
export class LinkRequestList {
  @ApiProperty({ type: [LinkRequestResponse] }) items!: LinkRequestResponse[];
  @ApiProperty({ type: 'integer' }) total!: number;
}
export class LinkDecisionResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ enum: ['ACCEPTED','DECLINED'] }) decision!: string;
}
