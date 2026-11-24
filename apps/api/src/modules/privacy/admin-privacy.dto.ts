import { ApiProperty } from '@nestjs/swagger';
import { Equals, IsIn, IsInt, IsString, IsUUID, Length, Matches, Min } from 'class-validator';
import { Transform } from 'class-transformer';
const trim=({value}:{value:unknown})=>typeof value==='string'?value.trim():value;
export class PrivacyExportInput {
 @ApiProperty() @IsUUID() userId!:string;
 @ApiProperty() @Equals(true) identityVerified!:boolean;
 @ApiProperty() @Transform(trim) @IsString() @Length(3,500) @Matches(/\S/) reason!:string;
}
export class PrivacyHoldInput {
 @ApiProperty({enum:['HOLD','RELEASE']}) @IsIn(['HOLD','RELEASE']) action!: 'HOLD'|'RELEASE';
 @ApiProperty() @IsInt() @Min(1) expectedVersion!:number;
 @ApiProperty() @Transform(trim) @IsString() @Length(3,500) @Matches(/\S/) reason!:string;
}
export class PrivacyRequestRow {
 @ApiProperty() id!:string;
 @ApiProperty() userId!:string;
 @ApiProperty() kind!:string;
 @ApiProperty() status!:string;
 @ApiProperty() createdAt!:string;
 @ApiProperty() deadline!:string;
 @ApiProperty({type:String,nullable:true}) reason!:string|null;
 @ApiProperty() version!:number;
}
export class PrivacyRequestsPage {
 @ApiProperty({type:[PrivacyRequestRow]}) items!:PrivacyRequestRow[];
 @ApiProperty() total!:number;
}
export class SubjectExportResponse {
 @ApiProperty() filename!:string;
 @ApiProperty() json!:string;
}
