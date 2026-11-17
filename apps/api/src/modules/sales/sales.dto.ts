// T-079 / FR-050–054. Vendor-authorized rate edits; exact integer paise.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsIn, IsInt, IsISO8601, IsString, IsUUID, Matches, Max, MaxLength, Min, ValidateIf, ValidateNested } from 'class-validator';
const defined=(_:unknown,v:unknown)=>v!==undefined;
export class SaleLineInput {
  @ApiProperty({format:'uuid'}) @IsUUID() productId!:string;
  @ApiProperty({type:'integer',minimum:1,maximum:2147483647}) @IsInt() @Min(1) @Max(2147483647) qty!:number;
  @ApiPropertyOptional({type:String,pattern:'^(0|[1-9][0-9]{0,18})$',description:'Authorized vendor rate override in paise; omitted uses current selling price. Max signed BIGINT.'}) @ValidateIf(defined) @IsString() @Matches(/^(0|[1-9]\d{0,18})$/) ratePaise?:string;
}
export class CompleteSaleInput {
  @ApiPropertyOptional({format:'uuid',description:'Omitted for anonymous walk-in; no synthetic customer is created.'}) @ValidateIf(defined) @IsUUID() vendorCustomerId?:string;
  @ApiProperty({type:[SaleLineInput],minItems:1,maxItems:100}) @IsArray() @ArrayMinSize(1) @ArrayMaxSize(100) @ValidateNested({each:true}) @Type(()=>SaleLineInput) items!:SaleLineInput[];
  @ApiProperty({type:String,pattern:'^(0|[1-9][0-9]{0,18})$',description:'Recorded external payment, 0 through server total. Walk-in must equal total.'}) @IsString() @Matches(/^(0|[1-9]\d{0,18})$/) paidPaise!:string;
  @ApiProperty({enum:['CASH','UPI','OTHER']}) @IsIn(['CASH','UPI','OTHER']) paymentMethod!:string;
  @ApiPropertyOptional({type:String,format:'date-time',description:'Untrusted offline audit metadata only; never controls business date, authorization or posting.'}) @ValidateIf(defined) @IsString() @MaxLength(40) @IsISO8601({strict:true}) @Matches(/(Z|[+-]\d{2}:\d{2})$/) clientCreatedAt?:string;
}
export class SaleQuery {
  @ApiPropertyOptional({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$',description:'Server IST sale date YYYY-MM-DD.'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date?:string;
  @ApiPropertyOptional({format:'uuid'}) @ValidateIf(defined) @IsUUID() vendorCustomerId?:string;
  @ApiPropertyOptional({type:'integer',minimum:1,maximum:50,default:20}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit?:number;
  @ApiPropertyOptional({type:'integer',minimum:0,default:0}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(0) offset?:number;
}
export class SaleItemResponse {
  @ApiProperty({format:'uuid'}) productId!:string;
  @ApiProperty() name!:string;
  @ApiProperty() unitValue!:string;
  @ApiProperty() unitType!:string;
  @ApiProperty({type:'integer'}) qty!:number;
  @ApiProperty() ratePaise!:string;
  @ApiProperty() amountPaise!:string;
}
export class SaleResponse {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty() saleNo!:string;
  @ApiProperty({type:String,format:'uuid',nullable:true}) vendorCustomerId!:string|null;
  @ApiProperty() totalPaise!:string;
  @ApiProperty() paidPaise!:string;
  @ApiProperty() balancePaise!:string;
  @ApiProperty({enum:['PAID','UNPAID']}) paymentStatus!:string;
  @ApiProperty({enum:['CASH','UPI','OTHER']}) paymentMethod!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
  @ApiProperty({type:String,format:'date-time'}) createdAt!:string;
  @ApiProperty({type:String,format:'date-time',nullable:true}) clientCreatedAt!:string|null;
  @ApiProperty({type:[SaleItemResponse]}) items!:SaleItemResponse[];
}
export class SaleList {
  @ApiProperty({type:[SaleResponse]}) items!:SaleResponse[];
  @ApiProperty({type:'integer'}) total!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
