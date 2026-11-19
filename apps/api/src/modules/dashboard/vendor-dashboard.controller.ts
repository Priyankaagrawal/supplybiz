import { Controller, Get, Header, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { VendorDashboard, VendorDashboardQuery } from './vendor-dashboard.dto';
import { VendorDashboardService } from './vendor-dashboard.service';
@ApiTags('vendor-dashboard') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('vendor/dashboard')
export class VendorDashboardController {
  constructor(private readonly dashboard: VendorDashboardService) {}
  @Get() @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: VendorDashboard })
  @ApiResponse({ status: 400, description: 'Invalid IST date or unknown query fields.' })
  @ApiResponse({ status: 401, description: 'Missing/expired/revoked session.' })
  @ApiResponse({ status: 403, description: 'Active/held vendor role required; suspended vendors denied.' })
  @ApiResponse({ status: 404, description: 'Vendor onboarding not started.' })
  @ApiResponse({ status: 503, description: 'DASHBOARD_UNAVAILABLE; no cached/fabricated metrics.' })
  get(@Req() r: Request & { session: { userId: string } }, @Query() q: VendorDashboardQuery) {
    return this.dashboard.get(r.session.userId, q);
  }
}
