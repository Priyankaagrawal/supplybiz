import { ApiProperty,ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsIn,IsString,Length,Matches,ValidateIf } from 'class-validator';
import { KhataPage } from './khata.dto';
const trim=({value}:{value:unknown})=>typeof value==='string'?value.trim():value;
export class VendorKhataQuery extends KhataPage {
  @ApiPropertyOptional({enum:['ALL','RECEIVABLE','PAID']}) @ValidateIf((_,v)=>v!==undefined) @IsIn(['ALL','RECEIVABLE','PAID']) tab?:string;
  @ApiPropertyOptional({maxLength:120}) @ValidateIf((_,v)=>v!==undefined) @IsString() @Length(1,120) q?:string;
}
export class VendorKhataAccount {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty() name!:string;
  @ApiProperty() mobile!:string;
  @ApiProperty() status!:string;
  @ApiProperty() archived!:boolean;
  @ApiProperty() totalDebitPaise!:string;
  @ApiProperty() totalCreditPaise!:string;
  @ApiProperty() totalPaidPaise!:string;
  @ApiProperty() duePaise!:string;
}
export class VendorKhataList {
  @ApiProperty({type:[VendorKhataAccount]}) items!:VendorKhataAccount[];
  @ApiProperty({type:'integer'}) total!:number;
  @ApiProperty() totalReceivablePaise!:string;
  @ApiProperty() thisMonthReceivedPaise!:string;
  @ApiProperty() canAdjust!:boolean;
  @ApiProperty() canRecordPayment!:boolean;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) businessDate!:string;
}
export class LedgerOpeningInput {
  @ApiProperty({enum:['DEBIT','CREDIT']}) @IsIn(['DEBIT','CREDIT']) type!:'DEBIT'|'CREDIT';
  @ApiProperty({pattern:'^[1-9][0-9]{0,18}$'}) @IsString() @Matches(/^[1-9]\d{0,18}$/) amountPaise!:string;
  @ApiProperty({maxLength:500}) @Transform(trim) @IsString() @Length(1,500) note!:string;
}
export class LedgerReversalInput { @ApiProperty({maxLength:500}) @Transform(trim) @IsString() @Length(1,500) reason!:string; }
export class LedgerAdjustmentAck { @ApiProperty({format:'uuid'}) id!:string; }
export class VendorCollection {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({format:'uuid'}) vendorCustomerId!:string;
  @ApiProperty() customerName!:string;
  @ApiProperty({description:'Signed net receipt/correction, exact integer paise.'}) amountPaise!:string;
  @ApiProperty() method!:string;
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) entryDate!:string;
  @ApiProperty() createdAt!:string;
  @ApiProperty() reversal!:boolean;
  @ApiProperty() source!:string;
}
export class VendorCollectionList { @ApiProperty({type:[VendorCollection]}) items!:VendorCollection[]; @ApiProperty({type:'integer'}) total!:number; @ApiProperty() month!:string; }
