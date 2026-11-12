import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsNumber, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf } from 'class-validator';
const defined = (_: unknown, v: unknown) => v !== undefined;
const coordinate = ({value}:{value:unknown}) => typeof value === 'string' && value.trim() !== '' ? Number(value) : value;
export class DiscoveryQuery {
  @ApiProperty({ minimum: -90, maximum: 90 }) @Transform(coordinate) @IsNumber() @Min(-90) @Max(90) lat!: number;
  @ApiProperty({ minimum: -180, maximum: 180 }) @Transform(coordinate) @IsNumber() @Min(-180) @Max(180) lng!: number;
  @ApiProperty({ pattern: '^[1-9][0-9]{5}$' }) @Matches(/^[1-9]\d{5}$/) pincode!: string;
  @ApiPropertyOptional({ format: 'uuid' }) @ValidateIf(defined) @IsUUID() category?: string;
  @ApiPropertyOptional({ enum: ['NEARBY','POPULAR'] }) @ValidateIf(defined) @IsIn(['NEARBY','POPULAR']) sort?: string;
  @ApiPropertyOptional() @ValidateIf(defined) @Transform(({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value) @IsString() @Length(0,120) q?: string;
  @ApiPropertyOptional({ maximum: 50, default: 20 }) @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(1) @Max(50) limit?: number;
  @ApiPropertyOptional() @ValidateIf(defined) @IsString() @Length(1,2048) cursor?: string;
}
export class DiscoveredVendor {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() businessName!: string;
  @ApiProperty({ format: 'uuid' }) categoryId!: string;
  @ApiProperty({ type: String, nullable: true, format: 'uuid' }) shopPhotoMediaId!: string | null;
  @ApiProperty({ type: [String] }) badges!: string[];
  @ApiProperty() distanceMeters!: number;
  @ApiProperty({ type: 'integer' }) completedOrders30Days!: number;
  @ApiProperty() favorite!: boolean;
}
export class DiscoveryPage {
  @ApiProperty({ type: [DiscoveredVendor] }) items!: DiscoveredVendor[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class FavoriteResult {
  @ApiProperty({ format: 'uuid' }) vendorId!: string;
  @ApiProperty() favorite!: boolean;
}
export class VendorAbout extends DiscoveredVendor {
  @ApiProperty({ type: String, nullable: true }) address!: string | null;
  @ApiProperty({ type: String, nullable: true }) city!: string | null;
  @ApiProperty({ type: String, nullable: true }) state!: string | null;
  @ApiProperty({ type: String, nullable: true }) pincode!: string | null;
  @ApiProperty({ type: 'integer' }) deliveryChargePaise!: number;
  @ApiProperty({ type: 'integer' }) minOrderPaise!: number;
  @ApiProperty({ type: 'object', additionalProperties: true, nullable: true, description: 'Unconfigured until business-hours settings exist.' }) openingHours!: object | null;
  @ApiProperty({ type: 'array', items: { type: 'object', properties: { date: {type:'string',format:'date'}, reason: {type:'string'} } } }) holidays!: {date:string;reason:string}[];
}
