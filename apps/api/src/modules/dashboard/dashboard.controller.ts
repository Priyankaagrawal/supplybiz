import { Controller, Get, Header, SetMetadata } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminPermission } from '../admin-auth/admin-auth.controller';
import { AdminDashboard } from './dashboard.dto';
import { DashboardService } from './dashboard.service';
@ApiTags('admin-dashboard') @ApiBearerAuth() @SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('admin/dashboard')
export class DashboardController {
 constructor(private readonly dashboard: DashboardService) {}
 @Get() @AdminPermission('dashboard.read') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: AdminDashboard })
 get() { return this.dashboard.get(); }
}
