import { Body, CanActivate, Controller, ExecutionContext, Get, Header, HttpCode, Injectable, Post, Req, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsString, Length, Matches } from 'class-validator';
import { Request } from 'express';
import { AdminAuthService } from './admin-auth.service';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
const ACCESS = 'admin.permission';
export const AdminPermission = (permission: string) => SetMetadata(ACCESS, permission);
const PUBLIC = 'admin.public';
class LoginDto {
  @ApiProperty() @IsEmail() @Length(1, 254) email!: string;
  @ApiProperty({ minLength: 12, maxLength: 128 }) @IsString() @Length(12, 128) password!: string;
}
class TotpDto {
  @ApiProperty() @Matches(/^[A-Za-z0-9_-]{43}$/) challengeToken!: string;
  @ApiProperty() @Matches(/^\d{6}$/) code!: string;
}
export class AdminChallengeResponse { @ApiProperty() challengeToken!: string; }
export class AdminEnrollmentResponse { @ApiProperty({ type: String, nullable: true }) enrollmentSecret!: string | null; }
export class AdminSessionResponse {
  @ApiProperty() sessionToken!: string;
  @ApiProperty() csrfToken!: string;
}
export class AdminMeResponse {
  @ApiProperty() id!: string;
  @ApiProperty() role!: string;
  @ApiProperty({ type: [String] }) permissions!: string[];
}
export function bearer(request: Request): string {
  const value = request.header('Authorization');
  return value?.startsWith('Bearer ') ? value.slice(7) : '';
}
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly auth: AdminAuthService, private readonly reflector: Reflector) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    if (!/^\/api\/v1\/admin(?:\/|$)/i.test(request.path)) return true;
    if (this.reflector.getAllAndOverride<boolean>(PUBLIC, [context.getHandler(), context.getClass()])) return true;
    const permission = this.reflector.getAllAndOverride<string>(ACCESS, [context.getHandler(), context.getClass()]);
    // Every future admin endpoint must explicitly declare its permission; self applies to auth/me/logout only.
    await this.auth.authenticate(bearer(request), permission === 'self' ? undefined : permission ?? '__unlisted__',
      request.method === 'GET' || request.method === 'HEAD' ? undefined : request.header('X-CSRF-Token') ?? '');
    return true;
  }
}
@ApiTags('admin-auth') @SetMetadata(NO_IDEMPOTENCY_CACHE, true)
@Controller('admin/auth')
export class AdminAuthController {
  constructor(private readonly auth: AdminAuthService) {}
  @Header('Cache-Control', 'no-store') @Post('login') @HttpCode(200) @SetMetadata(PUBLIC, true)
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiOkResponse({ type: AdminChallengeResponse })
  login(@Body() input: LoginDto, @Req() req: Request) { return this.auth.login(input.email, input.password, req.ip); }
  @Header('Cache-Control', 'no-store') @Get('challenge') @SetMetadata(PUBLIC, true) @ApiBearerAuth() @ApiOkResponse({ type: AdminEnrollmentResponse })
  challenge(@Req() req: Request) { return this.auth.challenge(bearer(req)); }
  @Header('Cache-Control', 'no-store') @Post('totp/verify') @HttpCode(200) @SetMetadata(PUBLIC, true)
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiOkResponse({ type: AdminSessionResponse })
  verify(@Body() input: TotpDto, @Req() req: Request) { return this.auth.verify(input.challengeToken, input.code, req.ip); }
  @Header('Cache-Control', 'no-store') @Get('me') @AdminPermission('self') @ApiBearerAuth() @ApiOkResponse({ type: AdminMeResponse })
  me(@Req() req: Request) { return this.auth.authenticate(bearer(req)); }
  @Header('Cache-Control', 'no-store') @Post('logout') @HttpCode(204) @AdminPermission('self') @ApiBearerAuth()
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
  logout(@Req() req: Request) { return this.auth.logout(bearer(req), req.header('X-CSRF-Token') ?? '', req.ip); }
}
