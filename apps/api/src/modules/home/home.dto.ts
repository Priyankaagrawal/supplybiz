// T-042 / FR-201 / S-C-01
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsInt, IsNumber, IsUUID, Matches, Max, Min, ValidateIf } from 'class-validator';

const defined = (_: unknown, value: unknown) => value !== undefined;
const coordinate = ({ value }: { value: unknown }) =>
  typeof value === 'string' && value.trim() !== '' ? Number(value) : value;
const locationProvided = (query: HomeQuery) => query.lat !== undefined || query.lng !== undefined;
export class HomeQuery {
  @ApiPropertyOptional({ minimum: -90, maximum: 90, description: 'Optional location pair; does not filter owned deliveries.' })
  @Transform(coordinate) @ValidateIf(locationProvided) @IsNumber() @Min(-90) @Max(90) lat?: number;
  @ApiPropertyOptional({ minimum: -180, maximum: 180 })
  @Transform(coordinate) @ValidateIf(locationProvided) @IsNumber() @Min(-180) @Max(180) lng?: number;
  @ApiPropertyOptional({ pattern: '^[1-9][0-9]{5}$' }) @ValidateIf(defined) @Matches(/^[1-9]\d{5}$/) pincode?: string;
  @ApiPropertyOptional({ default: 20, maximum: 50 }) @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(1) @Max(50) limit?: number;
  @ApiPropertyOptional({ format: 'uuid', description: 'Last order ID from this customer and current IST day.' })
  @ValidateIf(defined) @IsUUID() cursor?: string;
}
export class HomeCategory {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() code!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ type: String, nullable: true }) icon!: string | null;
  @ApiProperty({ enum: ['ENABLED', 'COMING_SOON'] }) status!: string;
  @ApiProperty() available!: boolean;
  @ApiProperty({ type: [String] }) productTypes!: string[];
}
export class HomeDeliveryItem {
  @ApiProperty({ format: 'uuid' }) productId!: string;
  @ApiProperty({ description: 'Persisted order-time name, including inactive/deleted products.' }) name!: string;
  @ApiProperty({ type: 'integer' }) qty!: number;
}
export class HomeDelivery {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() orderNo!: string;
  @ApiProperty({ format: 'uuid' }) vendorId!: string;
  @ApiProperty({ type: String, nullable: true }) vendorName!: string | null;
  @ApiProperty({ enum: ['APP', 'SUBSCRIPTION', 'VENDOR'] }) source!: string;
  @ApiProperty({ enum: ['NEW', 'ACCEPTED', 'REJECTED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'FAILED', 'CANCELLED'] }) status!: string;
  @ApiProperty({ format: 'date' }) deliveryDate!: string;
  @ApiProperty() timeSlot!: string;
  @ApiProperty({ type: [HomeDeliveryItem] }) items!: HomeDeliveryItem[];
}
export class CustomerHome {
  @ApiProperty({ format: 'date-time' }) serverTime!: string;
  @ApiProperty({ format: 'date', description: 'Database-derived Asia/Kolkata date.' }) businessDate!: string;
  @ApiProperty({ type: [HomeCategory] }) categories!: HomeCategory[];
  @ApiProperty({ type: [HomeDelivery] }) deliveries!: HomeDelivery[];
  @ApiProperty({ type: String, format: 'uuid', nullable: true }) nextCursor!: string | null;
}
