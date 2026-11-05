import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, Length, Matches } from 'class-validator';

export class KycSubmissionDto {
  @ApiProperty({ format: 'uuid' }) @IsUUID() aadhaarFrontMediaId!: string;
  @ApiProperty({ format: 'uuid' }) @IsUUID() aadhaarBackMediaId!: string;
  @ApiProperty({ format: 'uuid' }) @IsUUID() panMediaId!: string;
  @ApiProperty() @Matches(/^[A-Z]{5}\d{4}[A-Z]$/) pan!: string;
  @ApiProperty() @IsString() @Length(2, 120) @Matches(/\S/) holderName!: string;
  @ApiProperty() @IsString() @Length(2, 120) @Matches(/\S/) bankName!: string;
  @ApiProperty() @Matches(/^\d{9,18}$/) accountNumber!: string;
  @ApiProperty() @Matches(/^\d{9,18}$/) accountNumberConfirmation!: string;
  @ApiProperty() @Matches(/^[A-Z]{4}0[A-Z0-9]{6}$/) ifsc!: string;
  @ApiPropertyOptional() @IsOptional() @Matches(/^[\w.-]{2,256}@[a-zA-Z]{2,64}$/) upiId?: string;
}
export class KycDecisionDto {
  @ApiProperty({ enum: ['VERIFIED', 'REJECTED'] }) @IsIn(['VERIFIED', 'REJECTED']) decision!: 'VERIFIED' | 'REJECTED';
  @ApiProperty() @IsString() @Length(3, 500) @Matches(/^\s*\S(?:[\s\S]*\S)?\s*$/) reason!: string;
}
export class KycResponse {
  @ApiProperty() id!: string;
  @ApiProperty() vendorId!: string;
  @ApiProperty() status!: string;
  @ApiProperty() verificationMethod!: string;
  @ApiProperty({ enum: ['NOT_RUN'] }) providerChecks!: string;
  @ApiProperty({ format: 'date-time' }) submittedAt!: string;
  @ApiProperty({ type: String, nullable: true, format: 'date-time' }) reviewedAt!: string | null;
  @ApiProperty({ type: String, nullable: true }) reviewerId!: string | null;
  @ApiProperty({ type: String, nullable: true }) reason!: string | null;
  @ApiProperty() aadhaarFrontMediaId!: string;
  @ApiProperty() aadhaarBackMediaId!: string;
  @ApiProperty() panMediaId!: string;
  @ApiProperty() panLast4!: string;
  @ApiProperty() accountLast4!: string;
  @ApiProperty() holderName!: string;
  @ApiProperty() bankName!: string;
  @ApiProperty() ifsc!: string;
  @ApiProperty({ type: String, nullable: true }) upiId!: string | null;
}
export class KycPage {
  @ApiProperty({ type: [KycResponse] }) items!: KycResponse[];
  @ApiProperty() hasMore!: boolean;
}
export class KycQueueQuery {
  @ApiPropertyOptional({ format: 'uuid' }) @IsOptional() @IsUUID() beforeId?: string;
}
export class KycNotice {
  @ApiProperty() id!: string;
  @ApiProperty() status!: string;
  @ApiProperty({ type: String, nullable: true }) reason!: string | null;
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
}
