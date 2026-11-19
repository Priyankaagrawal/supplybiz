import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsIn, IsISO8601, IsString, Length, Matches } from 'class-validator';
export const ROLES = ['SUPER_ADMIN','OPS','SUPPORT','FINANCE'] as const;
export class CreateAdminInput {
 @ApiProperty() @IsEmail() @Length(3,254) email!: string;
 @ApiProperty({minLength:12,maxLength:128}) @IsString() @Length(12,128) password!: string;
 @ApiProperty({enum:ROLES}) @IsIn(ROLES) role!: string;
 @ApiProperty() @IsString() @Length(3,500) @Matches(/\S/) reason!: string;
}
export class ChangeAdminInput {
 @ApiProperty({enum:ROLES}) @IsIn(ROLES) role!: string;
 @ApiProperty({enum:['ACTIVE','DISABLED']}) @IsIn(['ACTIVE','DISABLED']) status!: 'ACTIVE'|'DISABLED';
 @ApiProperty() @IsISO8601({strict:true}) expectedUpdatedAt!: string;
 @ApiProperty() @IsString() @Length(3,500) @Matches(/\S/) reason!: string;
}
export class AdminAccountResponse {
 @ApiProperty() id!: string;
 @ApiProperty() email!: string;
 @ApiProperty() role!: string;
 @ApiProperty() status!: string;
 @ApiProperty() totpEnrolled!: boolean;
 @ApiProperty() updatedAt!: string;
}
export class AdminAccountsResponse {
 @ApiProperty({type:[AdminAccountResponse]}) items!: AdminAccountResponse[];
 @ApiProperty() total!: number;
}
export class PlatformExportInput {
 @ApiProperty({enum:['PLATFORM_SUMMARY']}) @IsIn(['PLATFORM_SUMMARY']) kind!: 'PLATFORM_SUMMARY';
}
export class PlatformExportResponse {
 @ApiProperty() filename!: string;
 @ApiProperty() csv!: string;
 @ApiProperty() snapshotAt!: string;
}
