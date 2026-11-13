// T-045 / FR-040–046, FR-220–225 / ADR-032.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf, ValidateNested } from 'class-validator';
import { AddressResponse } from '../addresses/addresses.dto';
const defined = (_: unknown, value: unknown) => value !== undefined;
const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
export class OrderLineInput {
  @ApiProperty({ format: 'uuid' }) @IsUUID() productId!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 2147483647 }) @IsInt() @Min(1) @Max(2147483647) qty!: number;
}
export class CheckoutOptionsQuery {
  @ApiProperty({format:'uuid'}) @IsUUID() vendorId!: string;
  @ApiProperty({format:'uuid'}) @IsUUID() addressId!: string;
}
export class CheckoutOptions {
  @ApiProperty() serverTime!: string;
  @ApiProperty() businessDate!: string;
  @ApiProperty({type:[String]}) availableDates!: string[];
  @ApiProperty({type:[String]}) timeSlots!: string[];
  @ApiProperty({type:String,nullable:true}) sameDayCutoff!: string|null;
}
export class OrderQuoteInput {
  @ApiProperty({ format: 'uuid' }) @IsUUID() vendorId!: string;
  @ApiProperty({ format: 'uuid' }) @IsUUID() addressId!: string;
  @ApiProperty({ format: 'date' }) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) deliveryDate!: string;
  @ApiProperty() @IsString() @Length(1,80) timeSlot!: string;
  @ApiProperty({ enum: ['POD_CASH','POD_UPI'] }) @IsIn(['POD_CASH','POD_UPI']) paymentMode!: string;
  @ApiProperty({ type: [OrderLineInput], maxItems: 100 }) @IsArray() @ArrayMinSize(1) @ArrayMaxSize(100)
  @ArrayUnique((line: OrderLineInput) => line.productId) @ValidateNested({ each: true }) @Type(() => OrderLineInput) items!: OrderLineInput[];
}
export class OrderPlaceInput extends OrderQuoteInput {
  @ApiProperty({ description: 'Reviewed quote total, exact integer paise as decimal string.' })
  @IsString() @Matches(/^(0|[1-9]\d{0,18})$/) expectedTotalPaise!: string;
}
export class OrderTransitionInput {
  @ApiProperty({ enum: ['ACCEPTED','REJECTED','PREPARING','OUT_FOR_DELIVERY'] })
  @IsIn(['ACCEPTED','REJECTED','PREPARING','OUT_FOR_DELIVERY']) to!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 2147483647 }) @IsInt() @Min(1) @Max(2147483647) version!: number;
  @ApiPropertyOptional({ enum: ['CUSTOMER_UNAVAILABLE','OUT_OF_STOCK','NOT_SERVICEABLE','CUSTOMER_REQUEST','OTHER'] })
  @ValidateIf(defined) @IsIn(['CUSTOMER_UNAVAILABLE','OUT_OF_STOCK','NOT_SERVICEABLE','CUSTOMER_REQUEST','OTHER']) reason?: string;
  @ApiPropertyOptional({ description: 'Required for OTHER; 5–200 characters.' })
  @ValidateIf(defined) @Transform(trim) @IsString() @Length(5,200) reasonText?: string;
}
export class OrderCancelInput {
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 2147483647 }) @IsInt() @Min(1) @Max(2147483647) version!: number;
}
export class OrderQuery {
  @ApiPropertyOptional({ enum: ['ALL','NEW','ACCEPTED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','CANCELLED','FAILED'] })
  @ValidateIf(defined) @IsIn(['ALL','NEW','ACCEPTED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','CANCELLED','FAILED']) status?: string;
  @ApiPropertyOptional({ enum: ['ALL','ONGOING','DELIVERED','CANCELLED'] }) @ValidateIf(defined) @IsIn(['ALL','ONGOING','DELIVERED','CANCELLED']) tab?: string;
  @ApiPropertyOptional() @ValidateIf(defined) @Transform(trim) @IsString() @Length(0,120) q?: string;
  @ApiPropertyOptional({ format: 'date' }) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date?: string;
  @ApiPropertyOptional({ type: 'integer', default: 20, maximum: 50 }) @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(1) @Max(50) limit?: number;
  @ApiPropertyOptional({ type: 'integer', default: 0 }) @ValidateIf(defined) @Type(() => Number) @IsInt() @Min(0) @Max(2147483647) offset?: number;
}
export class OrderPricedLine {
  @ApiProperty({ format: 'uuid' }) productId!: string;
  @ApiProperty() name!: string;
  @ApiProperty() unitValue!: string;
  @ApiProperty() unitType!: string;
  @ApiProperty({ type: 'integer' }) qty!: number;
  @ApiProperty() unitPricePaise!: string;
  @ApiProperty() lineTotalPaise!: string;
}
export class OrderQuote {
  @ApiProperty() serverTime!: string;
  @ApiProperty({ format: 'date' }) businessDate!: string;
  @ApiProperty({ type: String, nullable: true, description: 'Vendor-configured IST cutoff, HH:mm:ss; null disables today.' }) sameDayCutoff!: string | null;
  @ApiProperty({ type: [OrderPricedLine] }) items!: OrderPricedLine[];
  @ApiProperty() subtotalPaise!: string;
  @ApiProperty() deliveryChargePaise!: string;
  @ApiProperty() discountPaise!: string;
  @ApiProperty() totalPaise!: string;
}
export class OrderResult {
  @ApiProperty({ format: 'uuid' }) id!: string;
  @ApiProperty() orderNo!: string;
  @ApiProperty({ format: 'uuid' }) vendorId!: string;
  @ApiProperty() status!: string;
  @ApiProperty({ type: 'integer' }) version!: number;
  @ApiProperty({ format: 'date' }) deliveryDate!: string;
  @ApiProperty() timeSlot!: string;
  @ApiProperty() totalPaise!: string;
  @ApiProperty() paymentMode!: string;
  @ApiProperty() paymentStatus!: string;
  @ApiProperty() source!: string;
  @ApiProperty() createdAt!: string;
}
export class OrderStatusEvent {
  @ApiProperty() status!: string;
  @ApiProperty({ type: String, nullable: true }) reason!: string | null;
  @ApiProperty() at!: string;
}
export class OrderDetail extends OrderResult {
  @ApiProperty({ type: String, nullable: true }) vendorName!: string | null;
  @ApiProperty() customerName!: string;
  @ApiProperty() customerMobile!: string;
  @ApiProperty({ type: AddressResponse }) address!: AddressResponse;
  @ApiProperty({ type: [OrderPricedLine] }) items!: OrderPricedLine[];
  @ApiProperty({ type: [OrderStatusEvent] }) timeline!: OrderStatusEvent[];
  @ApiProperty() subtotalPaise!: string;
  @ApiProperty() deliveryChargePaise!: string;
  @ApiProperty() discountPaise!: string;
  @ApiProperty({ type: String, nullable: true }) rejectReason!: string | null;
  @ApiProperty({ type: String, nullable: true }) cancelReason!: string | null;
  @ApiProperty({ type: String, nullable: true }) failReason!: string | null;
}
export class OrderList {
  @ApiProperty({ type: [OrderResult] }) items!: OrderResult[];
  @ApiProperty({ type: 'integer' }) total!: number;
}
export class OrderProblem {
  @ApiProperty() type!: string;
  @ApiProperty() title!: string;
  @ApiProperty({ type:'integer' }) status!: number;
  @ApiProperty() code!: string;
  @ApiProperty() detail!: string;
  @ApiProperty() requestId!: string;
  @ApiPropertyOptional({ type:OrderQuote }) quote?: OrderQuote;
  @ApiPropertyOptional({ format:'uuid' }) productId?: string;
}
