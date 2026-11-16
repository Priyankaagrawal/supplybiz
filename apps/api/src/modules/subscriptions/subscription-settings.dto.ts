// T-075 / FR-075. Millilitre storage is exact; API capacity uses decimal-string litres.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsString, Matches, Max, Min, ValidateIf } from 'class-validator';
const defined=(_:unknown,v:unknown)=>v!==undefined;
const nonnull=(_:unknown,v:unknown)=>v!==undefined && v!==null;
export class SubscriptionSettingsPatch {
  @ApiProperty({type:'integer',minimum:1,maximum:2147483647}) @IsInt() @Min(1) @Max(2147483647) version!:number;
  @ApiPropertyOptional({description:'Enabling requires active BUSINESS+.'}) @ValidateIf(defined) @IsBoolean() autoAcceptSubscriptions?:boolean;
  @ApiPropertyOptional() @ValidateIf(defined) @IsBoolean() deliveryAvailable?:boolean;
  @ApiPropertyOptional({type:String,nullable:true,pattern:'^([01][0-9]|2[0-3]):[0-5][0-9]$',description:'IST daily delivery window. Both ends may be cleared with null; overnight windows are allowed.'})
  @ValidateIf(nonnull) @IsString() @Matches(/^([01]\d|2[0-3]):[0-5]\d$/) deliveryStartTime?:string|null;
  @ApiPropertyOptional({type:String,nullable:true,pattern:'^([01][0-9]|2[0-3]):[0-5][0-9]$'})
  @ValidateIf(nonnull) @IsString() @Matches(/^([01]\d|2[0-3]):[0-5]\d$/) deliveryEndTime?:string|null;
  @ApiPropertyOptional({type:'integer',nullable:true,minimum:1,maximum:2147483647,description:'Positive order limit; null is unlimited. Typed clients may use clearMaxDailyOrders.'})
  @ValidateIf(nonnull) @IsInt() @Min(1) @Max(2147483647) maxDailyOrders?:number|null;
  @ApiPropertyOptional({type:String,nullable:true,description:'Positive exact litres, up to three fractional digits (1 ml), max 2147483.647. Null is unlimited. Typed clients may use clearDailyMilkCapacity.'})
  @ValidateIf(nonnull) @IsString() @Matches(/^(0|[1-9]\d{0,6})(\.\d{1,3})?$/) dailyMilkCapacityLitres?:string|null;
  @ApiPropertyOptional() @ValidateIf(defined) @IsBoolean() pauseAllSubscriptions?:boolean;
  @ApiPropertyOptional({description:'Set true to clear both delivery times. Cannot accompany non-null times.'}) @ValidateIf(defined) @IsBoolean() clearDeliveryWindow?:boolean;
  @ApiPropertyOptional({description:'Set true to remove the order limit. Cannot accompany a non-null limit.'}) @ValidateIf(defined) @IsBoolean() clearMaxDailyOrders?:boolean;
  @ApiPropertyOptional({description:'Set true to remove the milk limit. Cannot accompany a non-null limit.'}) @ValidateIf(defined) @IsBoolean() clearDailyMilkCapacity?:boolean;
}
export class SubscriptionSettingsSummary {
  @ApiProperty({type:'integer'}) totalSubscriptions!:number;
  @ApiProperty({type:'integer'}) active!:number;
  @ApiProperty({type:'integer'}) paused!:number;
  @ApiProperty({type:'integer'}) pendingApproval!:number;
  @ApiProperty({type:'integer'}) cancelled!:number;
  @ApiProperty({type:'integer'}) rejected!:number;
  @ApiProperty({type:'integer'}) completed!:number;
  @ApiProperty({type:'integer',description:'Distinct undeleted vendor customers with ACTIVE/PAUSED subscriptions.'}) subscriptionCustomers!:number;
}
export class SubscriptionSettingsResponse {
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({format:'date'}) businessDate!:string;
  @ApiProperty() autoAcceptSubscriptions!:boolean;
  @ApiProperty() effectiveAutoAcceptSubscriptions!:boolean;
  @ApiProperty() canAutoAccept!:boolean;
  @ApiProperty() canEditSubscriptions!:boolean;
  @ApiProperty({description:'Owned reducing controls remain available with history access after expiry/downgrade.'}) canReduceActivity!:boolean;
  @ApiProperty() deliveryAvailable!:boolean;
  @ApiProperty({type:String,nullable:true}) deliveryStartTime!:string|null;
  @ApiProperty({type:String,nullable:true}) deliveryEndTime!:string|null;
  @ApiProperty({type:'integer',nullable:true}) maxDailyOrders!:number|null;
  @ApiProperty({type:String,nullable:true}) dailyMilkCapacityLitres!:string|null;
  @ApiProperty() pauseAllSubscriptions!:boolean;
  @ApiProperty({type:SubscriptionSettingsSummary}) summary!:SubscriptionSettingsSummary;
}
export class SubscriptionCustomer {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty() name!:string;
  @ApiProperty() mobile!:string;
  @ApiProperty() status!:string;
  @ApiProperty({type:'integer'}) activeSubscriptions!:number;
  @ApiProperty({type:'integer'}) pausedSubscriptions!:number;
}
export class SubscriptionCustomerList {
  @ApiProperty({type:[SubscriptionCustomer]}) items!:SubscriptionCustomer[];
  @ApiProperty({type:'integer'}) total!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({format:'date'}) businessDate!:string;
}
