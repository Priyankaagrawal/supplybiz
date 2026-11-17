// T-074 / FR-082–085. Calendar dates and server-owned versions.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsInt, IsString, Length, Matches, Max, Min, ValidateIf } from 'class-validator';
export class AvailabilityPatch {
  @ApiProperty({type:'integer',minimum:1,maximum:2147483647}) @IsInt() @Min(1) @Max(2147483647) version!:number;
  @ApiPropertyOptional({description:'False rejects new one-time orders for today; existing orders remain.'}) @ValidateIf((_,v)=>v!==undefined) @IsBoolean() acceptingToday?:boolean;
  @ApiPropertyOptional({description:'Open-ended delivery pause. True cancels NEW/ACCEPTED/PREPARING orders today onward; progressed orders remain.'}) @ValidateIf((_,v)=>v!==undefined) @IsBoolean() deliveryPaused?:boolean;
}
export class HolidayInput {
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$',description:'IST calendar date YYYY-MM-DD; deliberately string-valued for exact client serialization.'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date!:string;
  @ApiProperty({maxLength:100,minLength:1}) @IsString() @Length(1,100) reason!:string;
}
export class HolidayImpactQuery {
  @ApiProperty({type:String,pattern:'^\\d{4}-\\d{2}-\\d{2}$',description:'IST calendar date YYYY-MM-DD.'}) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}$/) date!:string;
}
export class HolidayQuery {
  @ApiPropertyOptional({type:'integer',minimum:1,maximum:50,default:20}) @ValidateIf((_,v)=>v!==undefined) @Type(()=>Number) @IsInt() @Min(1) @Max(50) limit?:number;
  @ApiPropertyOptional({type:'integer',minimum:0,default:0}) @ValidateIf((_,v)=>v!==undefined) @Type(()=>Number) @IsInt() @Min(0) offset?:number;
}
export class AvailabilityResponse {
  @ApiProperty({type:'integer'}) version!:number;
  @ApiProperty() acceptingToday!:boolean;
  @ApiProperty() deliveryPaused!:boolean;
  @ApiProperty({type:String,nullable:true,format:'date-time',description:'Legacy finite pause end; PATCH deliveryPaused always clears it to implement open-ended pause/resume.'}) deliveryPausedUntil!:string|null;
  @ApiProperty() canResume!:boolean;
  @ApiProperty() canReduceActivity!:boolean;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
export class HolidayRecord {
  @ApiProperty({format:'uuid'}) id!:string;
  @ApiProperty({type:String,format:'date'}) date!:string;
  @ApiProperty() reason!:string;
}
export class HolidayList {
  @ApiProperty({type:[HolidayRecord]}) items!:HolidayRecord[];
  @ApiProperty({type:'integer'}) total!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
export class DeliveryImpact {
  @ApiProperty({type:'integer',description:'Only NEW/ACCEPTED/PREPARING; preview is rechecked atomically on write.'}) affectedOrders!:number;
  @ApiProperty() serverTime!:string;
  @ApiProperty({type:String,format:'date'}) businessDate!:string;
}
export class AvailabilityMutation {
  @ApiProperty({type:'integer'}) cancelledOrders!:number;
  @ApiProperty({type:AvailabilityResponse}) availability!:AvailabilityResponse;
}
export class HolidayMutation {
  @ApiProperty({type:HolidayRecord}) holiday!:HolidayRecord;
  @ApiProperty({type:'integer'}) cancelledOrders!:number;
}
export class HolidayDeleted { @ApiProperty({format:'uuid'}) id!:string; @ApiProperty() deleted!:boolean; }
