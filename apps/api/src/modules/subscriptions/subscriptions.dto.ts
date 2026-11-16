// T-072 / FR-070–077, FR-230–232. Money is exact decimal-string paise.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf, ValidateNested } from 'class-validator';
import { CustomerInput } from '../customers/customers.dto';
const defined=(_:unknown,v:unknown)=>v!==undefined;
export class SubscriptionSetup {
  @ApiProperty({format:'uuid'}) @IsUUID() productId!:string;
  @ApiProperty({type:'integer',minimum:1,maximum:2147483647}) @IsInt() @Min(1) @Max(2147483647) qty!:number;
  @ApiProperty({type:[Number],description:'ISO weekdays 1=Monday through 7=Sunday, unique.'})
  @IsArray() @ArrayMinSize(1) @ArrayMaxSize(7) @ArrayUnique() @IsInt({each:true}) @Min(1,{each:true}) @Max(7,{each:true}) weekdays!:number[];
  @ApiProperty({format:'date'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) startDate!:string;
  @ApiPropertyOptional({format:'date'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) endDate?:string;
  @ApiProperty({maxLength:80}) @IsString() @Length(1,80) timeSlot!:string;
  @ApiProperty({enum:['CASH','UPI','WALLET'],description:'External payment preference; postpaid Khata, no funds held or prepaid charge.'}) @IsIn(['CASH','UPI','WALLET']) paymentMethod!:string;
}
export class VendorSubscriptionInput extends SubscriptionSetup {
  @ApiPropertyOptional({format:'uuid'}) @ValidateIf(defined) @IsUUID() vendorCustomerId?:string;
  @ApiPropertyOptional({type:CustomerInput,description:'Exactly one of vendorCustomerId or newCustomer.'})
  @ValidateIf(defined) @ValidateNested() @Type(()=>CustomerInput) newCustomer?:CustomerInput;
}
export class CustomerSubscriptionInput extends SubscriptionSetup {
  @ApiProperty({format:'uuid'}) @IsUUID() vendorId!:string;
  @ApiProperty({format:'uuid'}) @IsUUID() addressId!:string;
}
export class SubscriptionVersion {
  @ApiProperty({type:'integer',minimum:1,maximum:2147483647}) @IsInt() @Min(1) @Max(2147483647) version!:number;
}
export class SubscriptionPatch extends SubscriptionVersion {
  @ApiPropertyOptional({type:'integer',minimum:1,maximum:2147483647}) @ValidateIf(defined) @IsInt() @Min(1) @Max(2147483647) qty?:number;
  @ApiPropertyOptional({type:[Number]}) @ValidateIf(defined) @IsArray() @ArrayMinSize(1) @ArrayMaxSize(7) @ArrayUnique()
  @IsInt({each:true}) @Min(1,{each:true}) @Max(7,{each:true}) weekdays?:number[];
  @ApiPropertyOptional({maxLength:80}) @ValidateIf(defined) @IsString() @Length(1,80) timeSlot?:string;
}
export class SubscriptionPause extends SubscriptionVersion {
  @ApiPropertyOptional({format:'date',description:'Defaults to earliest modifiable date; inclusive.'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) fromDate?:string;
  @ApiPropertyOptional({format:'date',description:'Inclusive; absent means open-ended.'}) @ValidateIf(defined) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) toDate?:string;
}
export class SubscriptionSkip extends SubscriptionVersion {
  @ApiProperty({format:'date'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date!:string;
}
export class SubscriptionReject extends SubscriptionVersion {
  @ApiPropertyOptional({maxLength:200}) @ValidateIf(defined) @IsString() @Length(1,200) reason?:string;
}
export class SubscriptionQuery {
  @ApiPropertyOptional({type:'integer',default:20,maximum:50}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit?:number;
  @ApiPropertyOptional({type:'integer',default:0}) @ValidateIf(defined) @Type(()=>Number) @IsInt() @Min(0) @Max(2147483647) offset?:number;
}
export class SubscriptionPlansQuery {
  @ApiProperty({format:'uuid'}) @IsUUID() addressId!:string;
}
export class SubscriptionMutation {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() status!:string;
  @ApiProperty({format:'date'}) effectiveFrom!:string;
}
export class SubscriptionRevision {
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty({format:'date'}) effectiveFrom!:string;
  @ApiProperty({type:'integer'}) qty!:number;
  @ApiProperty({type:[Number]}) weekdays!:number[];
  @ApiProperty() timeSlot!:string;
  @ApiProperty() status!:string;
  @ApiProperty() action!:string;
  @ApiProperty({type:String,nullable:true}) reason!:string|null;
}
export class SubscriptionPauseRecord {
  @ApiProperty({format:'date'}) fromDate!:string;
  @ApiProperty({type:String,nullable:true,format:'date'}) toDate!:string|null;
  @ApiProperty({type:String,nullable:true,format:'date'}) resumedFrom!:string|null;
}
export class SubscriptionRecord extends SubscriptionMutation {
  @ApiProperty({format:'uuid'}) vendorId!:string;
  @ApiProperty({format:'uuid'}) vendorCustomerId!:string;
  @ApiProperty({format:'uuid'}) productId!:string;
  @ApiProperty() productName!:string;
  @ApiProperty({type:'integer'}) qty!:number;
  @ApiProperty({type:[Number]}) weekdays!:number[];
  @ApiProperty() timeSlot!:string;
  @ApiProperty({format:'date'}) startDate!:string;
  @ApiProperty({type:String,nullable:true,format:'date'}) endDate!:string|null;
  @ApiProperty({type:'object',additionalProperties:true}) addressSnapshot!:object;
  @ApiProperty() paymentMethod!:string;
  @ApiProperty() createdBy!:string;
  @ApiProperty() dailyAmountPaise!:string;
  @ApiProperty() monthlyEstimatePaise!:string;
  @ApiProperty({description:'Server IST month for the estimate; not an invoice.'}) estimateMonth!:string;
  @ApiProperty({type:[SubscriptionRevision]}) revisions!:SubscriptionRevision[];
  @ApiProperty({type:[SubscriptionPauseRecord]}) pauses!:SubscriptionPauseRecord[];
  @ApiProperty({type:[String]}) skips!:string[];
}
export class SubscriptionList {
  @ApiProperty() serverTime!:string;
  @ApiProperty({format:'date'}) businessDate!:string;
  @ApiProperty({type:[SubscriptionRecord]}) items!:SubscriptionRecord[];
  @ApiProperty({type:'integer'}) total!:number;
}
export class SubscriptionPlan {
  @ApiProperty({format:'uuid'}) productId!:string;
  @ApiProperty() productName!:string;
  @ApiProperty({description:'CUSTOM or an available 500/1000/2000 ml daily size.'}) kind!:string;
  @ApiProperty({type:'integer'}) qty!:number;
  @ApiProperty() dailyAmountPaise!:string;
  @ApiProperty() monthlyEstimatePaise!:string;
  @ApiProperty({type:Boolean,nullable:true,description:'Unavailable until vendor selection is configured; never guessed.'}) mostPopular!:boolean|null;
}
export class SubscriptionPlans {
  @ApiProperty({type:[SubscriptionPlan]}) items!:SubscriptionPlan[];
  @ApiProperty({type:[String]}) timeSlots!:string[];
  @ApiProperty() freeDelivery!:boolean;
  @ApiProperty({format:'date'}) earliestStartDate!:string;
  @ApiProperty() estimateMonth!:string;
}
