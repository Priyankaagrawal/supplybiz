// T-100 / FR-090-095. Exact paise and volume strings; tables, no chart payloads.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsString, Matches, Max, Min, ValidateIf } from 'class-validator';
const defined=(_:unknown,v:unknown)=>v!==undefined;
export class ReportQuery {
  @ApiPropertyOptional({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$',description:'Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days.'})
  @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) from?:string;
  @ApiPropertyOptional({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) to?:string;
}
export class ReportProductsQuery extends ReportQuery {
  @ApiPropertyOptional({type:'integer',minimum:1,maximum:50,default:20}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit?:number;
  @ApiPropertyOptional({type:'integer',minimum:0,maximum:2147483647,default:0}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(0) @Max(2147483647) offset?:number;
}
export class ReportRange {
  @ApiProperty({type:String,format:'date'}) from!:string;
  @ApiProperty({type:String,format:'date'}) to!:string;
  @ApiProperty({format:'date-time'}) serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
export class ReportSummary extends ReportRange {
  @ApiProperty({type:String,pattern:'^[0-9]+$',description:'Gross delivered-order totals plus POS totals on actual completion/sale dates. Includes charges; not receipts.'}) totalSalesPaise!:string;
  @ApiProperty({type:'integer',minimum:0,description:'Retained orders scheduled in range; POS is not an order.'}) totalOrders!:number;
  @ApiProperty({type:'integer',minimum:0,description:'Scheduled-in-range orders now DELIVERED.'}) deliveredOrders!:number;
  @ApiProperty({type:'integer',minimum:0,description:'Scheduled-in-range orders now CANCELLED; excludes REJECTED/FAILED.'}) cancelledOrders!:number;
  @ApiProperty({type:String,pattern:'^[0-9]+(\\.[0-9]+)?$',description:'Known milk litres from immutable delivered/POS line snapshots in actual completion/sale range.'}) milkSoldLitres!:string;
  @ApiProperty({type:'integer',minimum:0,description:'Legacy zero-volume/unknown-classification or non-volume milk lines. Milk total is incomplete when nonzero; never infer history from current catalog.'}) milkSoldUnmeasuredLines!:number;
  @ApiProperty({type:String,pattern:'^-?[0-9]+$',description:'Net external receipts by ledger value date: payment/POS/confirmed-claim credit roots and reversal chains, plus paid walk-ins once. Opening credits excluded. May be negative for corrections.'}) totalEarningsPaise!:string;
  @ApiProperty({type:String,pattern:'^[0-9]+$',description:'Current positive Khata due summed per customer, including archived/inactive links, as of serverTime; independent of date range.'}) pendingPaymentsPaise!:string;
  @ApiProperty({type:'integer',minimum:0,description:'Current ACTIVE non-deleted customer links; independent of range.'}) activeCustomers!:number;
  @ApiProperty({type:String,pattern:'^[0-9]+$',description:'Range item sales excluding delivery charges; matches complete product table total.'}) productSalesPaise!:string;
  @ApiProperty({type:String,pattern:'^[0-9]+$'}) deliveryChargesPaise!:string;
  @ApiProperty({type:String,pattern:'^[0-9]+$',description:'Stored order discounts; zero under current scope.'}) discountPaise!:string;
  @ApiProperty({type:String,pattern:'^-?[0-9]+$',description:'Legacy missing/inconsistent item subtotal gap. Sales = products + charges - discounts + this gap.'}) unitemizedSalesPaise!:string;
}
export class ReportSalesBucket {
  @ApiProperty({type:String,format:'date'}) from!:string;
  @ApiProperty({type:String,format:'date'}) to!:string;
  @ApiProperty({type:String,pattern:'^[0-9]+$'}) salesPaise!:string;
}
export class ReportDailySales extends ReportRange {
  @ApiProperty({enum:['DAY','WEEK'],description:'DAY through 62 inclusive days; otherwise Monday-based weeks clipped to requested range. Zero periods included.'}) bucket!:string;
  @ApiProperty({type:[ReportSalesBucket]}) items!:ReportSalesBucket[];
}
export class ReportProduct {
  @ApiProperty({format:'uuid'}) productId!:string;
  @ApiProperty({description:'Immutable sold name; renamed/repacked products produce distinct snapshot groups.'}) name!:string;
  @ApiProperty() unitValue!:string;
  @ApiProperty() unitType!:string;
  @ApiProperty({type:String,pattern:'^[0-9]+$',description:'Integer packs, not litres. Exact aggregate string.'}) quantityPacks!:string;
  @ApiProperty({type:String,pattern:'^[0-9]+$'}) salesPaise!:string;
}
export class ReportProducts extends ReportRange {
  @ApiProperty({type:[ReportProduct]}) items!:ReportProduct[];
  @ApiProperty({type:'integer',minimum:0}) total!:number;
  @ApiProperty({type:String,pattern:'^[0-9]+$',description:'All product snapshot groups across the range, not just the current page.'}) totalProductSalesPaise!:string;
}
