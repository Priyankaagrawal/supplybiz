import {
  Body, CanActivate, Controller, ExecutionContext, Get, HttpCode, Injectable, Post, Put,
  Query, Req, SetMetadata, UseGuards, BadRequestException, Header,
} from "@nestjs/common";
import { ApiBearerAuth, ApiHeader, ApiProperty, ApiPropertyOptional, ApiQuery, ApiResponse, ApiTags } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { IsIn, IsOptional, IsString, Length, Matches, ValidateNested, IsDefined } from "class-validator";
import { Request } from "express";
import { SessionsService } from "./sessions.service";
import { SessionTokensService, unauthenticated } from "./session-tokens.service";
import { NO_IDEMPOTENCY_CACHE } from "../../common/idempotency.constants";

class ConsentDto {
  @ApiProperty() @IsString() @Length(1, 50) termsVersion!: string;
  @ApiProperty() @IsString() @Length(1, 50) privacyVersion!: string;
}
class DeviceDto {
  @ApiProperty({ enum: ["ANDROID", "IOS", "WEB"] }) @IsIn(["ANDROID", "IOS", "WEB"])
  platform!: "ANDROID" | "IOS" | "WEB";
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(1, 64) appVersion?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(1, 64) osVersion?: string;
}
class VerifyOtpDto {
  @ApiProperty({ pattern: "^(?:\\+91)?[6-9]\\d{9}$" }) @Matches(/^(?:\+91)?[6-9]\d{9}$/) mobile!: string;
  @ApiProperty({ pattern: "^\\d{6}$" }) @Matches(/^\d{6}$/) code!: string;
  @ApiProperty({ type: DeviceDto }) @IsDefined() @ValidateNested() @Type(() => DeviceDto) device!: DeviceDto;
  @ApiPropertyOptional({ type: ConsentDto }) @IsOptional() @ValidateNested() @Type(() => ConsentDto) consent?: ConsentDto;
}
class RefreshDto {
  @ApiProperty({ pattern: "^[A-Za-z0-9_-]{43}$" }) @Matches(/^[A-Za-z0-9_-]{43}$/) refreshToken!: string;
}
class RoleDto {
  @ApiProperty({ enum: ["CUSTOMER", "VENDOR"] }) @IsIn(["CUSTOMER", "VENDOR"]) role!: "CUSTOMER" | "VENDOR";
}
class MeResponse {
  @ApiProperty({ format: "uuid" }) id!: string;
  @ApiProperty() mobile!: string;
  @ApiProperty({ type: String, nullable: true }) name!: string | null;
  @ApiProperty({ enum: ["EN", "HI"] }) language!: string;
  @ApiProperty({ type: [String], enum: ["CUSTOMER", "VENDOR"] }) roles!: string[];
  @ApiProperty({ type: String, enum: ["CUSTOMER", "VENDOR"], nullable: true }) activeRole!: string | null;
}
class TokensResponse {
  @ApiProperty() accessToken!: string;
  @ApiProperty() refreshToken!: string;
  @ApiProperty({ type: "integer", example: 900 }) expiresInSec!: number;
  @ApiProperty({ type: MeResponse }) user!: MeResponse;
}
type AuthRequest = Request & { session: { userId: string; sessionId: string } };

@Injectable()
export class SessionGuard implements CanActivate {
  constructor(private readonly sessions: SessionsService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthRequest>();
    const authorization = request.header("Authorization");
    if (!authorization?.startsWith("Bearer ")) throw unauthenticated();
    request.session = await this.sessions.authenticate(authorization.slice(7));
    return true;
  }
}

@ApiTags("auth")
@SetMetadata(NO_IDEMPOTENCY_CACHE, true)
@Controller("auth")
export class SessionsController {
  constructor(private readonly sessions: SessionsService, private readonly tokens: SessionTokensService) {}

  @Post("otp/verify") @HttpCode(200) @Header("Cache-Control", "no-store")
  @ApiHeader({ name: "Idempotency-Key", required: true })
  @ApiResponse({ status: 200, type: TokensResponse })
  @ApiResponse({ status: 400, description: "VALIDATION_FAILED, including missing consent for first login." })
  @ApiResponse({ status: 422, description: "OTP_INVALID or OTP_ATTEMPTS_EXCEEDED." })
  verify(@Body() input: VerifyOtpDto, @Req() request: Request) {
    return this.sessions.login(input.mobile, input.code, input.device, input.consent, request.ip);
  }

  @Post("refresh") @HttpCode(200) @Header("Cache-Control", "no-store")
  @ApiHeader({ name: "Idempotency-Key", required: true })
  @ApiResponse({ status: 200, type: TokensResponse })
  @ApiResponse({ status: 401, description: "UNAUTHENTICATED or REFRESH_REUSED (family revoked)." })
  refresh(@Body() input: RefreshDto) { return this.sessions.refresh(input.refreshToken); }

  @Post("logout") @HttpCode(204) @UseGuards(SessionGuard) @ApiBearerAuth()
  @ApiHeader({ name: "Idempotency-Key", required: true })
  @ApiQuery({ name: "all", required: false, type: String, enum: ["true", "false"],
    description: "Defaults to false (current session family); true revokes all account sessions." })
  @ApiResponse({ status: 204, description: "Revoked current family, or all sessions with ?all=true." })
  async logout(@Req() request: AuthRequest, @Query("all") all?: string) {
    if (all !== undefined && all !== "true" && all !== "false") throw new BadRequestException();
    await this.sessions.logout(request.session.userId, request.session.sessionId, all === "true");
  }

  @Get(".well-known/jwks.json")
  jwks() { return this.tokens.jwks(); }
}

@ApiTags("me") @ApiBearerAuth() @UseGuards(SessionGuard)
@ApiResponse({ status: 401, description: "UNAUTHENTICATED: missing, invalid, expired or revoked session." })
@SetMetadata(NO_IDEMPOTENCY_CACHE, true)
@Controller("me")
export class MeController {
  constructor(private readonly sessions: SessionsService) {}
  @Get() @Header("Cache-Control", "no-store") @ApiResponse({ status: 200, type: MeResponse })
  me(@Req() request: AuthRequest) { return this.sessions.me(request.session.userId); }

  @Post("roles") @HttpCode(200) @ApiHeader({ name: "Idempotency-Key", required: true })
  @ApiResponse({ status: 200, type: MeResponse })
  @ApiResponse({ status: 400, description: "VALIDATION_FAILED: invalid role or missing Idempotency-Key." })
  addRole(@Body() input: RoleDto, @Req() request: AuthRequest) {
    return this.sessions.role(request.session.userId, input.role, false);
  }
  @Put("active-role") @ApiHeader({ name: "Idempotency-Key", required: true })
  @ApiResponse({ status: 200, type: MeResponse })
  @ApiResponse({ status: 400, description: "VALIDATION_FAILED: invalid role or missing Idempotency-Key." })
  @ApiResponse({ status: 403, description: "ROLE_NOT_HELD." })
  activeRole(@Body() input: RoleDto, @Req() request: AuthRequest) {
    return this.sessions.role(request.session.userId, input.role, true);
  }
}
