// T-158 / FR-408: English plaintext content, immutable published legal versions.
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsInt, IsObject, IsOptional, IsString, Length, Matches, Max, Min, ValidateIf } from 'class-validator';
import { Type } from 'class-transformer';
import { AppConfigResponse } from './app-config';

export enum LegalType { TERMS = 'TERMS', PRIVACY = 'PRIVACY' }
export class ContentQuery {
 @ApiPropertyOptional({ type: 'integer', default: 0, minimum: 0, maximum: 100000 }) @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(100000) offset: number = 0;
 @ApiPropertyOptional() @IsOptional() @Matches(/^[a-z][a-z0-9-]{0,39}$/) topic?: string;
}
export class FaqInput {
 @ApiProperty({ description: 'Null when creating; otherwise exact server updatedAt.' , type: String, nullable: true })
 @ValidateIf((_o, v: unknown) => v !== null) @IsString() @Length(1, 40) expectedUpdatedAt!: string | null;
 @ApiProperty() @Matches(/^[a-z][a-z0-9-]{0,39}$/) topic!: string;
 @ApiProperty() @IsString() @Length(1, 200) @Matches(/\S/) question!: string;
 @ApiProperty({ description: 'Plaintext only; clients must render as text, never HTML.' }) @IsString() @Length(1, 5000) @Matches(/\S/) answer!: string;
 @ApiProperty() @IsBoolean() published!: boolean;
}
export class FaqRow {
 @ApiProperty({ format: 'uuid' }) id!: string;
 @ApiProperty() topic!: string;
 @ApiProperty() question!: string;
 @ApiProperty() answer!: string;
 @ApiProperty() published!: boolean;
 @ApiProperty({ format: 'date-time' }) updatedAt!: string;
}
export class FaqList {
 @ApiProperty({ type: [FaqRow] }) items!: FaqRow[];
 @ApiProperty({ type: 'integer' }) total!: number;
}
export class LegalInput {
 @ApiProperty({ type: String, nullable: true, description: 'Current published version, or null for the first version.' })
 @ValidateIf((_o, v: unknown) => v !== null) @Matches(/^[A-Za-z0-9][A-Za-z0-9._-]{0,49}$/) expectedVersion!: string | null;
 @ApiProperty() @Matches(/^[A-Za-z0-9][A-Za-z0-9._-]{0,49}$/) version!: string;
 @ApiProperty() @IsString() @Length(1, 120) @Matches(/\S/) title!: string;
 @ApiProperty({ description: 'English plaintext; published versions cannot be overwritten.' }) @IsString() @Length(1, 50000) @Matches(/\S/) text!: string;
}
export class LegalRow {
 @ApiProperty({ enum: LegalType }) @IsEnum(LegalType) type!: LegalType;
 @ApiProperty() version!: string;
 @ApiProperty() title!: string;
 @ApiProperty() text!: string;
 @ApiProperty() sha256!: string;
 @ApiProperty({ format: 'date-time' }) publishedAt!: string;
}
export class LegalList { @ApiProperty({ type: [LegalRow] }) items!: LegalRow[]; }
export class ConfigInput {
 @ApiProperty({ type: String, nullable: true }) @ValidateIf((_o, v: unknown) => v !== null) @IsString() @Length(1, 40) expectedUpdatedAt!: string | null;
 @ApiProperty() @Matches(/^(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})$/) minVersionAndroid!: string;
 @ApiProperty({ type: 'object', additionalProperties: { type: 'boolean' }, description: 'Up to 50 simple presentation flags. Never grants permissions or entitlements.' }) @IsObject() flags!: Record<string, boolean>;
}
export class AdminConfigResponse extends AppConfigResponse {
 @ApiProperty({ type: String, format: 'date-time', nullable: true }) updatedAt!: string | null;
}
