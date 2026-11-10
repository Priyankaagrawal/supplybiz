// FR-030–FR-036 / US-030–US-032 / T-026
import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsNumber, IsString, IsUUID, Length, Max, Min, ValidateIf } from 'class-validator';

const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
const defined = (_object: unknown, value: unknown) => value !== undefined;
const nullable = (_object: unknown, value: unknown) => value !== undefined && value !== null;
const INT_MAX = 2147483647;
export class ProductInput {
  @ApiProperty() @Transform(trim) @IsString() @Length(1, 120) name!: string;
  @ApiProperty({ description: 'One of the vendor category productTypes (admin-managed).' })
  @Transform(trim) @IsString() @Length(1, 80) productType!: string;
  @ApiPropertyOptional({ type: String, nullable: true, enum: ['COW','BUFFALO','TONED','DOUBLE_TONED','FULL_CREAM','OTHER'] })
  @ValidateIf(nullable) @IsIn(['COW','BUFFALO','TONED','DOUBLE_TONED','FULL_CREAM','OTHER']) milkType?: string | null;
  @ApiProperty({ minimum: 0.001, maximum: 999999999.999 })
  @IsNumber({ maxDecimalPlaces: 3 }) @Min(0.001) @Max(999999999.999) unitValue!: number;
  @ApiProperty({ enum: ['ML','L','G','KG','PCS'] }) @IsIn(['ML','L','G','KG','PCS']) unitType!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: INT_MAX }) @IsInt() @Min(1) @Max(INT_MAX) sellingPricePaise!: number;
  @ApiPropertyOptional({ type: 'integer', nullable: true, minimum: 0, maximum: INT_MAX })
  @ValidateIf(nullable) @IsInt() @Min(0) @Max(INT_MAX) subscriptionPricePaise?: number | null;
  @ApiPropertyOptional({ type: 'integer', minimum: 0, maximum: INT_MAX, default: 0 })
  @ValidateIf(defined) @IsInt() @Min(0) @Max(INT_MAX) stockQty?: number;
  @ApiPropertyOptional({ type: 'integer', minimum: 1, maximum: INT_MAX, default: 1 })
  @ValidateIf(defined) @IsInt() @Min(1) @Max(INT_MAX) moq?: number;
  @ApiPropertyOptional({ default: '' }) @ValidateIf(defined) @Transform(trim) @IsString() @Length(0, 500) description?: string;
  @ApiPropertyOptional({ type: String, format: 'uuid', nullable: true }) @ValidateIf(nullable) @IsUUID() imageMediaId?: string | null;
  @ApiPropertyOptional({ default: true }) @ValidateIf(defined) @IsBoolean() isActive?: boolean;
}
// Null only clears the explicitly nullable fields. Required fields cannot be cleared.
export class ProductPatch extends PartialType(ProductInput, { skipNullProperties: false }) {
  @ApiPropertyOptional({ description: 'Required when changing stockQty.' })
  @ValidateIf(defined) @Transform(trim) @IsString() @Length(1, 200) stockReason?: string;
}
export class StockAdjustment {
  @ApiProperty({ type: 'integer', description: 'Nonzero pack delta.' }) @IsInt() @Min(-INT_MAX) @Max(INT_MAX) delta!: number;
  @ApiProperty() @Transform(trim) @IsString() @Length(1, 200) reason!: string;
}
export class ProductQuery {
  @ApiPropertyOptional() @ValidateIf(defined) @Transform(trim) @IsString() @Length(0, 120) search?: string;
  @ApiPropertyOptional() @ValidateIf(defined) @IsString() @Length(1, 80) productType?: string;
  @ApiPropertyOptional({ type: 'integer', default: 50, maximum: 100 })
  @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number;
  @ApiPropertyOptional({ type: 'integer', default: 0 })
  @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(0) @Max(INT_MAX) offset?: number;
}
export class ProductResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() productType!: string;
  @ApiProperty({ type: String, nullable: true }) milkType!: string | null;
  @ApiProperty() unitValue!: number;
  @ApiProperty({ enum: ['ML','L','G','KG','PCS'] }) unitType!: string;
  @ApiProperty({ type: 'integer' }) sellingPricePaise!: number;
  @ApiProperty({ type: 'integer', nullable: true }) subscriptionPricePaise!: number | null;
  @ApiProperty({ type: 'integer' }) stockQty!: number;
  @ApiProperty({ type: 'integer' }) moq!: number;
  @ApiProperty() description!: string;
  @ApiProperty({ type: String, format: 'uuid', nullable: true }) imageMediaId!: string | null;
  @ApiProperty() isActive!: boolean;
  @ApiProperty({ type: 'integer' }) version!: number;
}
export class ProductList {
  @ApiProperty({ type: [ProductResponse] }) items!: ProductResponse[];
  @ApiProperty({ type: 'integer' }) total!: number;
}
export class ProductDeleted { @ApiProperty({ format: 'uuid' }) id!: string; @ApiProperty() deleted!: boolean; }
