// T-082 / FR-250–253. Exact paise and calendar strings; no provider verification.
import { ApiProperty,ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean,IsIn,IsInt,IsString,IsUUID,Length,Matches,Max,Min,ValidateIf } from 'class-validator';
const defined=(_:unknown,v:unknown)=>v!==undefined;
const nullable=(_:unknown,v:unknown)=>v!==undefined&&v!==null;
export class KhataPage {
  @ApiPropertyOptional({type:'integer',minimum:1,maximum:50,default:20}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit?:number;
  @ApiPropertyOptional({type:'integer',minimum:0,default:0}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(0) offset?:number;
}
export class KhataSummaryQuery extends KhataPage {
  @ApiPropertyOptional({enum:['ALL','CUSTOMERS','VENDORS']}) @ValidateIf(defined) @IsIn(['ALL','CUSTOMERS','VENDORS']) tab?:string;
  @ApiPropertyOptional({maxLength:120}) @ValidateIf(defined) @IsString() @Length(1,120) q?:string;
}
export class KhataMonthQuery extends KhataPage {
  @ApiPropertyOptional({pattern:'^\\d{4}-(0[1-9]|1[0-2])$',description:'Calendar month YYYY-MM; defaults to server IST current month.'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-(0[1-9]|1[0-2])$/) month?:string;
}
export class KhataVersion { @ApiProperty({type:'integer',minimum:1,maximum:2147483647}) @IsInt() @Min(1) @Max(2147483647) version!:number; }
export class PersonalContactInput {
  @ApiProperty({maxLength:120}) @IsString() @Length(1,120) name!:string;
  @ApiPropertyOptional({type:String,nullable:true,maxLength:20}) @ValidateIf(nullable) @IsString() @Matches(/^\+?\d{7,15}$/) mobile?:string|null;
}
export class PersonalContactPatch extends KhataVersion {
  @ApiPropertyOptional({maxLength:120}) @ValidateIf(defined) @IsString() @Length(1,120) name?:string;
  @ApiPropertyOptional({type:String,nullable:true,maxLength:20}) @ValidateIf(nullable) @IsString() @Matches(/^\+?\d{7,15}$/) mobile?:string|null;
  @ApiPropertyOptional({description:'True clears mobile for typed clients; cannot accompany a non-null value.'}) @ValidateIf(defined) @IsBoolean() clearMobile?:boolean;
}
export class PersonalEntryInput {
  @ApiProperty({format:'uuid'}) @IsUUID() contactId!:string;
  @ApiProperty({enum:['GAVE','GOT']}) @IsIn(['GAVE','GOT']) direction!:string;
  @ApiProperty({type:String,pattern:'^[1-9][0-9]{0,18}$'}) @IsString() @Matches(/^[1-9]\d{0,18}$/) amountPaise!:string;
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date!:string;
  @ApiPropertyOptional({maxLength:500}) @ValidateIf(defined) @IsString() @Length(0,500) note?:string;
}
export class PersonalEntryPatch extends KhataVersion {
  @ApiPropertyOptional({format:'uuid'}) @ValidateIf(defined) @IsUUID() contactId?:string;
  @ApiPropertyOptional({enum:['GAVE','GOT']}) @ValidateIf(defined) @IsIn(['GAVE','GOT']) direction?:string;
  @ApiPropertyOptional({type:String,pattern:'^[1-9][0-9]{0,18}$'}) @ValidateIf(defined) @IsString() @Matches(/^[1-9]\d{0,18}$/) amountPaise?:string;
  @ApiPropertyOptional({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date?:string;
  @ApiPropertyOptional({maxLength:500}) @ValidateIf(defined) @IsString() @Length(0,500) note?:string;
}
export class PersonalEntryQuery extends KhataPage {
  @ApiPropertyOptional({format:'uuid'}) @ValidateIf(defined) @IsUUID() contactId?:string;
  @ApiPropertyOptional({pattern:'^\\d{4}-(0[1-9]|1[0-2])$'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-(0[1-9]|1[0-2])$/) month?:string;
}
export class PaymentClaimInput {
  @ApiProperty({format:'uuid',description:'Select an accepted owned billing account returned by vendor entries; no mobile matching or silent allocation.'}) @IsUUID() vendorCustomerId!:string;
  @ApiProperty({type:String,pattern:'^[1-9][0-9]{0,18}$'}) @IsString() @Matches(/^[1-9]\d{0,18}$/) amountPaise!:string;
  @ApiProperty({enum:['UPI','CASH'],description:'Customer statement of external payment, not provider verification.'}) @IsIn(['UPI','CASH']) method!:string;
  @ApiPropertyOptional({maxLength:120,description:'Unverified customer-supplied transaction reference.'}) @ValidateIf(defined) @IsString() @Length(1,120) upiTxnRef?:string;
}
export class ClaimQuery extends KhataPage { @ApiPropertyOptional({enum:['PENDING','CONFIRMED','REJECTED']}) @ValidateIf(defined) @IsIn(['PENDING','CONFIRMED','REJECTED']) status?:string; }
export class ClaimRejection extends KhataVersion { @ApiProperty({maxLength:200}) @IsString() @Length(1,200) reason!:string; }
export class PersonalMutation {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() deleted!:boolean;
}
export class PersonalContactRecord {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() name!:string;
  @ApiProperty({type:String,nullable:true}) mobile!:string|null;
  @ApiProperty() balancePaise!:string;
}
export class PersonalContactList { @ApiProperty({type:[PersonalContactRecord]}) items!:PersonalContactRecord[]; @ApiProperty({type:'integer'}) total!:number; }
export class PersonalEntryRecord {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty({format:'uuid'}) contactId!:string;
  @ApiProperty({enum:['GAVE','GOT']}) direction!:string;
  @ApiProperty() amountPaise!:string;
  @ApiProperty({type:String,format:'date'}) date!:string;
  @ApiProperty() note!:string;
}
export class PersonalEntryList { @ApiProperty({type:[PersonalEntryRecord]}) items!:PersonalEntryRecord[]; @ApiProperty({type:'integer'}) total!:number; }
export class KhataAccount {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({enum:['VENDOR','PERSONAL']}) kind!:string;
  @ApiProperty() name!:string;
  @ApiProperty({description:'Customer perspective: positive receivable, negative payable.'}) balancePaise!:string;
  @ApiProperty({enum:['RECEIVABLE','PAYABLE','SETTLED']}) status!:string;
}
export class KhataSummary {
  @ApiProperty() totalReceivablePaise!:string;
  @ApiProperty() totalPayablePaise!:string;
  @ApiProperty() netBalancePaise!:string;
  @ApiProperty({type:[KhataAccount]}) items!:KhataAccount[];
  @ApiProperty({type:'integer'}) total!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
export class KhataLedgerEntry {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({format:'uuid'}) vendorCustomerId!:string;
  @ApiProperty({enum:['DEBIT','CREDIT']}) type!:string;
  @ApiProperty() amountPaise!:string;
  @ApiProperty({type:String,format:'date'}) entryDate!:string;
  @ApiProperty() refType!:string;
  @ApiProperty({format:'uuid'}) refId!:string;
  @ApiProperty({type:String,nullable:true,format:'uuid'}) reversesEntryId!:string|null;
  @ApiProperty() note!:string;
  @ApiProperty({type:String,nullable:true}) productSummary!:string|null;
  @ApiProperty({type:String,nullable:true,description:'Persisted source state only, no invented allocation of standalone payments/claims.'}) paymentStatus!:string|null;
}
export class KhataBillingAccount { @ApiProperty({format:'uuid'}) vendorCustomerId!:string; @ApiProperty() duePaise!:string; @ApiProperty() maxClaimPaise!:string; @ApiProperty() canClaim!:boolean; }
export class KhataVendorEntries {
  @ApiProperty({format:'uuid'}) vendorId!:string;
  @ApiProperty() vendorName!:string;
  @ApiProperty() month!:string;
  @ApiProperty() duePaise!:string;
  @ApiProperty() openingDuePaise!:string;
  @ApiProperty() closingDuePaise!:string;
  @ApiProperty() monthDebitPaise!:string;
  @ApiProperty() monthCreditPaise!:string;
  @ApiProperty() monthPaidPaise!:string;
  @ApiProperty({type:[KhataBillingAccount]}) accounts!:KhataBillingAccount[];
  @ApiProperty({type:[KhataLedgerEntry]}) items!:KhataLedgerEntry[];
  @ApiProperty({type:'integer'}) total!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
export class PaymentClaimRecord {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({format:'uuid'}) vendorId!:string;
  @ApiProperty({format:'uuid'}) vendorCustomerId!:string;
  @ApiProperty() amountPaise!:string;
  @ApiProperty({enum:['UPI','CASH']}) method!:string;
  @ApiProperty({type:String,nullable:true}) upiTxnRef!:string|null;
  @ApiProperty({enum:['PENDING','CONFIRMED','REJECTED']}) status!:string;
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() createdAt!:string;
  @ApiProperty({type:String,nullable:true}) decidedAt!:string|null;
  @ApiProperty({type:String,nullable:true}) rejectReason!:string|null;
}
export class ClaimMutation { @ApiProperty({format:'uuid'}) id!:string; @ApiProperty() status!:string; @ApiProperty({type:'integer'}) version!:number; }
export class PaymentClaimList { @ApiProperty({type:[PaymentClaimRecord]}) items!:PaymentClaimRecord[]; @ApiProperty({type:'integer'}) total!:number; }
export class PaymentPublicationInput extends KhataVersion {
  @ApiProperty({description:'Explicitly publish the supplied payment address only to linked customers, or unpublish. KYC data is never copied.'}) @IsBoolean() publish!:boolean;
  @ApiPropertyOptional({type:String,maxLength:321,pattern:'^[\\w.-]{2,256}@[a-zA-Z]{2,64}$'}) @ValidateIf(defined) @IsString() @Matches(/^[\w.-]{2,256}@[a-zA-Z]{2,64}$/) upiId?:string;
}
export class PaymentPublicationAck { @ApiProperty({type:'integer'}) version!:number; @ApiProperty() published!:boolean; }
export class VendorPaymentDetails {
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() published!:boolean;
  @ApiProperty({type:String,nullable:true}) upiId!:string|null;
  @ApiProperty() payeeName!:string;
}
export class CustomerSettlementOptions {
  @ApiProperty({format:'uuid'}) vendorId!:string;
  @ApiProperty() payeeName!:string;
  @ApiProperty({type:String,nullable:true,description:'Only an explicitly published payment setting; never verification-only KYC.'}) upiId!:string|null;
  @ApiProperty() upiAvailable!:boolean;
  @ApiProperty() cashAvailable!:boolean;
  @ApiProperty() duePaise!:string;
  @ApiProperty({type:[KhataBillingAccount]}) accounts!:KhataBillingAccount[];
}
