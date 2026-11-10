import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { ArrayUnique, IsArray, IsInt, Max, Min, IsNumber, IsLatitude, IsLongitude, IsOptional, IsString, IsUUID, Length, Matches, ValidateIf } from 'class-validator';

const trimmed = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
export class ServiceAreaDto {
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 20, nullable: true, description: 'Null disables radius coverage.' })
  @ValidateIf((_object, value: unknown) => value !== null) @IsInt() @Min(1) @Max(20)
  serviceRadiusKm!: number | null;
  @ApiProperty({ type: [String], description: 'Additional coverage; six-digit Indian pincodes.' })
  @IsArray() @ArrayUnique() @Matches(/^[1-9]\d{5}$/, { each: true }) pincodes!: string[];
}
export class VendorCategoryDto {
  @ApiProperty({ format: 'uuid' }) @IsUUID() categoryId!: string;
}
export class VendorBusinessDto {
  @ApiProperty() @Transform(trimmed) @IsString() @Length(2, 80) businessName!: string;
  @ApiPropertyOptional({ type: String, nullable: true }) @IsOptional() @Transform(trimmed)
  @Matches(/^(?:\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z])?$/) gstin?: string | null;
  @ApiProperty() @Transform(trimmed) @IsString() @Length(5, 200) addressLine!: string;
  @ApiProperty() @Transform(trimmed) @IsString() @Length(1, 120) city!: string;
  @ApiProperty() @Transform(trimmed) @IsString() @Length(1, 120) state!: string;
  @ApiProperty({ pattern: '^[1-9]\\d{5}$' }) @Matches(/^[1-9]\d{5}$/) pincode!: string;
  @ApiProperty({ type: Number, minimum: -90, maximum: 90 }) @IsNumber() @IsLatitude() latitude!: number;
  @ApiProperty({ type: Number, minimum: -180, maximum: 180 }) @IsNumber() @IsLongitude() longitude!: number;
  @ApiPropertyOptional({ type: String, format: 'uuid', nullable: true })
  @ValidateIf((_object, value: unknown) => value !== undefined && value !== null) @IsUUID() shopPhotoMediaId?: string | null;
}
export class VendorCategoryResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() code!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ type: String, nullable: true }) icon!: string | null;
}
export class VendorSettingsResponse {
  @ApiPropertyOptional({ type: [String], description: 'Present on fresh reads/writes; older onboarding replay snapshots may omit it.' }) pincodes?: string[];
  @ApiProperty({ type: 'integer', nullable: true }) serviceRadiusKm!: number | null;
  @ApiProperty({ type: 'integer' }) deliveryChargePaise!: number;
  @ApiProperty({ type: 'integer' }) minOrderPaise!: number;
  @ApiProperty({ type: [String] }) timeSlots!: string[];
  @ApiProperty() autoAcceptSubscriptions!: boolean;
  @ApiProperty() acceptingToday!: boolean;
  @ApiProperty() deliveryPaused!: boolean;
  @ApiProperty() allowKhataOrders!: boolean;
  @ApiProperty({ type: 'integer' }) version!: number;
}
export class VendorProfileResponse {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ format: 'uuid' }) categoryId!: string;
  @ApiProperty({ type: 'integer', description: 'Next onboarding screen: 2 business, 3 KYC, 4 status. Never regresses.' }) onboardingStep!: number;
  @ApiProperty() kycStatus!: string;
  @ApiProperty({ type: String, nullable: true }) businessName!: string | null;
  @ApiProperty({ type: String, nullable: true }) gstin!: string | null;
  @ApiProperty({ type: String, nullable: true }) addressLine!: string | null;
  @ApiProperty({ type: String, nullable: true }) city!: string | null;
  @ApiProperty({ type: String, nullable: true }) state!: string | null;
  @ApiProperty({ type: String, nullable: true }) pincode!: string | null;
  @ApiProperty({ type: Number, nullable: true }) latitude!: number | null;
  @ApiProperty({ type: Number, nullable: true }) longitude!: number | null;
  @ApiProperty({ type: String, format: 'uuid', nullable: true }) shopPhotoMediaId!: string | null;
  @ApiProperty({ type: VendorSettingsResponse }) settings!: VendorSettingsResponse;
}
