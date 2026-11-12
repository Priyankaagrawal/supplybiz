// FR-291 / US-290 / T-040
import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsNumber, IsString, Length, Matches, Max, Min, ValidateIf } from 'class-validator';

const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
const defined = (_: unknown, value: unknown) => value !== undefined;
export class AddressInput {
  @ApiProperty() @Transform(trim) @IsString() @Length(1, 50) label!: string;
  @ApiProperty({ description: 'House or flat.' }) @Transform(trim) @IsString() @Length(1, 200) line1!: string;
  @ApiProperty({ description: 'Street or area.' }) @Transform(trim) @IsString() @Length(1, 200) line2!: string;
  @ApiPropertyOptional() @ValidateIf(defined) @Transform(trim) @IsString() @Length(0, 200) landmark?: string;
  @ApiProperty() @Transform(trim) @IsString() @Length(1, 100) city!: string;
  @ApiProperty() @Transform(trim) @IsString() @Length(1, 100) state!: string;
  @ApiProperty({ pattern: '^[1-9][0-9]{5}$' }) @IsString() @Matches(/^[1-9]\d{5}$/) pincode!: string;
  @ApiProperty({ minimum: -90, maximum: 90 }) @IsNumber() @Min(-90) @Max(90) latitude!: number;
  @ApiProperty({ minimum: -180, maximum: 180 }) @IsNumber() @Min(-180) @Max(180) longitude!: number;
  @ApiPropertyOptional({ description: 'First address is always default. Use true to move the default.' })
  @ValidateIf(defined) @IsBoolean() isDefault?: boolean;
}
export class AddressPatch extends PartialType(AddressInput, { skipNullProperties: false }) {}
export class AddressResponse extends AddressInput {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty({ type: String, required: true }) declare landmark: string;
  @ApiProperty({ type: Boolean, required: true }) declare isDefault: boolean;
}
export class AddressList {
  @ApiProperty({ type: [AddressResponse] }) items!: AddressResponse[];
}
export class AddressDeleted {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() deleted!: boolean;
}
