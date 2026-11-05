import { Body, Controller, Get, Header, Headers, Param, ParseUUIDPipe, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiHeader, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { KycDecisionDto, KycNotice, KycPage, KycQueueQuery, KycResponse, KycSubmissionDto } from './kyc.dto';
import { KycService } from './kyc.service';
type VendorRequest = Request & { session: { userId: string } };
@ApiTags('kyc') @ApiBearerAuth()
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @UseGuards(SessionGuard) @Controller('vendor/kyc')
export class KycController {
  constructor(private readonly kyc: KycService) {}
  @Header('Cache-Control', 'no-store') @Get() @ApiOkResponse({ type: KycResponse })
  status(@Req() req: VendorRequest) { return this.kyc.status(req.session.userId); }
  @Header('Cache-Control', 'no-store') @Get('notices') @ApiOkResponse({ type: [KycNotice] })
  notices(@Req() req: VendorRequest) { return this.kyc.notices(req.session.userId); }
  @Header('Cache-Control', 'no-store') @Post() @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiCreatedResponse({ type: KycResponse })
  submit(@Req() req: VendorRequest, @Headers('Idempotency-Key') key: string, @Body() input: KycSubmissionDto) {
    return this.kyc.submit(req.session.userId, key, input, req.ip);
  }
}
@ApiTags('kyc') @ApiBearerAuth()
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @AdminPermission('kyc.review') @Controller('admin/kyc')
export class AdminKycController {
  constructor(private readonly kyc: KycService) {}
  @Header('Cache-Control', 'no-store') @Get() @ApiOkResponse({ type: KycPage })
  queue(@Req() req: Request, @Query() query: KycQueueQuery) { return this.kyc.queue(bearer(req), query.beforeId); }
  @Header('Cache-Control', 'no-store') @Get(':id') @ApiOkResponse({ type: KycResponse })
  detail(@Req() req: Request, @Param('id', ParseUUIDPipe) id: string) { return this.kyc.detail(bearer(req), id); }
  @Header('Cache-Control', 'no-store') @Post(':id/decision') @ApiCreatedResponse({ type: KycResponse })
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
  decide(@Req() req: Request, @Param('id', ParseUUIDPipe) id: string, @Body() input: KycDecisionDto,
    @Headers('Idempotency-Key') key: string) {
    return this.kyc.decide(bearer(req), req.header('X-CSRF-Token') ?? '', key, id, input, req.ip);
  }
}
