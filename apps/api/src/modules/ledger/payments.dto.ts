import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf } from 'class-validator';
const defined=(_:unknown,value:unknown)=>value!==undefined;
export class RecordPaymentInput {
  @ApiProperty({format:'uuid'}) @IsUUID() vendorCustomerId!:string;
  @ApiProperty({description:'Positive exact integer paise as decimal string, signed BIGINT maximum.'})
  @IsString() @Matches(/^[1-9]\d{0,18}$/) amountPaise!:string;
  @ApiProperty({enum:['CASH','UPI','BANK','WALLET'],description:'External payment record only; no platform money movement.'})
  @IsIn(['CASH','UPI','BANK','WALLET']) method!:string;
  @ApiProperty({format:'date',description:'Received business date, YYYY-MM-DD.'})
  @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) receivedOn!:string;
  @ApiPropertyOptional({maxLength:200}) @ValidateIf(defined)
  @Transform(({value}:{value:unknown})=>typeof value==='string'?value.trim():value) @IsString() @Length(0,200) note?:string;
}
export class PaymentQuery {
  @ApiPropertyOptional({format:'uuid'}) @ValidateIf(defined) @IsUUID() vendorCustomerId?:string;
  @ApiPropertyOptional({type:'integer',default:20,maximum:50}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit?:number;
  @ApiPropertyOptional({type:'integer',default:0}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(0) @Max(2147483647) offset?:number;
}
export class PaymentRecord {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({format:'uuid'}) vendorCustomerId!:string;
  @ApiProperty({type:String,nullable:true,format:'uuid'}) orderId!:string|null;
  @ApiProperty() amountPaise!:string;
  @ApiProperty() method!:string;
  @ApiProperty({format:'date'}) receivedOn!:string;
  @ApiProperty() note!:string;
  @ApiProperty() createdAt!:string;
}
export class PaymentList {
  @ApiProperty({type:[PaymentRecord]}) items!:PaymentRecord[];
  @ApiProperty({type:'integer'}) total!:number;
}
export class PaymentSummary {
  @ApiProperty() serverTime!:string;
  @ApiProperty({format:'date'}) businessDate!:string;
  @ApiProperty({description:'Sum of positive customer dues; advances do not offset other customers.'}) totalReceivablePaise!:string;
  @ApiProperty({description:'All owned receipts with receivedOn in the current server IST month.'}) thisMonthReceivedPaise!:string;
}
