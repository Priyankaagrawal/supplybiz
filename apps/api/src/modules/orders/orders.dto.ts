// T-045 / FR-040–046, FR-220–225 / ADR-032.
import { ApiProperty, ApiPropertyOptional, PickType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsBoolean, IsDateString, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf, ValidateNested } from 'class-validator';
import { AddressResponse } from '../addresses/addresses.dto';
import { ProductResponse } from '../catalog/catalog.dto';
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
export class DeliveryPaymentInput {
  @ApiProperty() @IsBoolean() collected!: boolean;
  @ApiPropertyOptional({enum:['CASH','UPI','BANK','WALLET'],description:'Off-platform record only; no platform wallet or money movement.'})
  @ValidateIf(defined) @IsIn(['CASH','UPI','BANK','WALLET']) method?: string;
  @ApiPropertyOptional({description:'Exact positive integer paise, decimal string. Required when collected=true.'})
  @ValidateIf(defined) @IsString() @Matches(/^[1-9]\d{0,18}$/) amountPaise?: string;
}
export class OrderTransitionInput {
  @ApiPropertyOptional({format:'date-time',description:'Untrusted device creation time for offline-action audit only. Server event/completion time remains authoritative.'})
  @ValidateIf(defined) @IsString() @Length(20,35) @Matches(/T.*(?:Z|[+-]\d{2}:\d{2})$/) @IsDateString({strict:true}) clientCreatedAt?: string;
  @ApiProperty({ enum: ['ACCEPTED','REJECTED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','FAILED'] })
  @IsIn(['ACCEPTED','REJECTED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','FAILED']) to!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 2147483647 }) @IsInt() @Min(1) @Max(2147483647) version!: number;
  @ApiPropertyOptional({description:'REJECTED: CUSTOMER_UNAVAILABLE/OUT_OF_STOCK/NOT_SERVICEABLE/CUSTOMER_REQUEST/OTHER. FAILED: required nonempty free text, up to 200 characters.'})
  @ValidateIf(defined) @Transform(trim) @IsString() @Length(1,200) reason?: string;
  @ApiPropertyOptional({ description: 'Required for OTHER; 5–200 characters.' })
  @ValidateIf(defined) @Transform(trim) @IsString() @Length(5,200) reasonText?: string;
  @ApiPropertyOptional({type:DeliveryPaymentInput,description:'Required for DELIVERED; collected=false forbids method/amount.'})
  @ValidateIf(defined) @ValidateNested() @Type(()=>DeliveryPaymentInput) payment?: DeliveryPaymentInput;
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
  @ApiPropertyOptional({type:[String]}) itemSummary?: string[];
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
  @ApiPropertyOptional({type:String,nullable:true,description:'Owned order vendor contact for dialer handoff.'}) vendorMobile?: string|null;
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
export class ReorderLine {
  @ApiProperty({type:ProductResponse}) product!:ProductResponse;
  @ApiProperty({type:'integer'}) qty!:number;
}
export class ReorderUnavailable {
  @ApiProperty({format:'uuid'}) productId!:string;
  @ApiProperty() name!:string;
  @ApiProperty({enum:['PRODUCT_UNAVAILABLE','BELOW_MOQ','INSUFFICIENT_STOCK']}) reason!:string;
}
export class OrderReorder {
  @ApiProperty({format:'uuid'}) vendorId!:string;
  @ApiProperty() vendorName!:string;
  @ApiProperty({type:[ReorderLine]}) items!:ReorderLine[];
  @ApiProperty({type:[ReorderUnavailable]}) unavailable!:ReorderUnavailable[];
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
export class DeliveryQuery extends PickType(OrderQuery,['date','limit','offset'] as const) {
  @ApiPropertyOptional({enum:['ALL','PENDING','PREPARING','OUT_FOR_DELIVERY','DELIVERED','FAILED']})
  @ValidateIf(defined) @IsIn(['ALL','PENDING','PREPARING','OUT_FOR_DELIVERY','DELIVERED','FAILED']) status?: string;
}
export class DeliveryCounts {
  @ApiProperty({type:'integer'}) ALL!: number;
  @ApiProperty({type:'integer'}) PENDING!: number;
  @ApiProperty({type:'integer'}) PREPARING!: number;
  @ApiProperty({type:'integer'}) OUT_FOR_DELIVERY!: number;
  @ApiProperty({type:'integer'}) DELIVERED!: number;
  @ApiProperty({type:'integer'}) FAILED!: number;
}
export class DeliveryList {
  @ApiProperty() serverTime!: string;
  @ApiProperty() businessDate!: string;
  @ApiProperty() deliveryDate!: string;
  @ApiProperty({type:DeliveryCounts}) counts!: DeliveryCounts;
  @ApiProperty({type:[OrderDetail]}) items!: OrderDetail[];
  @ApiProperty({type:'integer'}) total!: number;
}
