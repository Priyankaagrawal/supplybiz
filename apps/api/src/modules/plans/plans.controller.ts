import { Body, Controller, Get, Header, Headers, Param, ParseUUIDPipe, Post, Put, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiCreatedResponse, ApiHeader, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { SessionGuard } from '../auth/sessions.controller';
import { AssignPlanInput, AssignmentResponse, CatalogPlanInput, CurrentPlanResponse, ExtendPlanInput, PlanAdminQuery, PlanCatalogResponse, PlanCatalogRow, PlanHistoryResponse, PlanVendorList } from './plans.dto';
import { PlansService } from './plans.service';

@ApiTags('vendor-plans') @ApiBearerAuth() @UseGuards(SessionGuard) @Controller('vendor')
export class VendorPlansController {
  constructor(private readonly plans: PlansService) {}
  @Get('plans') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: PlanCatalogResponse })
  catalog(@Req() req: Request & { session: { userId: string } }) { return this.plans.catalog(req.session.userId); }
  @Get('plan') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: CurrentPlanResponse })
  current(@Req() req: Request & { session: { userId: string } }) { return this.plans.current(req.session.userId); }
}
@ApiTags('admin-plans') @ApiBearerAuth() @AdminPermission('plans.manage')
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('admin')
export class AdminPlansController {
  constructor(private readonly plans: PlansService) {}
  @Get('plans') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: PlanCatalogResponse })
  catalog() { return this.plans.catalog(); }
  @Put('plans/:id') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: PlanCatalogRow })
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
  save(@Param('id', ParseUUIDPipe) id: string, @Body() input: CatalogPlanInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) {
    return this.plans.saveCatalog(bearer(req), req.header('X-CSRF-Token') ?? '', key, id, input, req.ip);
  }
  @Get('plan-vendors') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: PlanVendorList })
  vendors(@Query() query: PlanAdminQuery) { return this.plans.vendors(query); }
  @Get('vendors/:id/plan-history') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: PlanHistoryResponse })
  history(@Param('id', ParseUUIDPipe) id: string, @Query() query: PlanAdminQuery) { return this.plans.history(id, query); }
  @Get('vendors/:id/plan') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: CurrentPlanResponse })
  current(@Param('id', ParseUUIDPipe) id: string) { return this.plans.adminCurrent(id); }
  @Post('vendors/:id/plan-assignments') @Header('Cache-Control', 'no-store') @ApiCreatedResponse({ type: AssignmentResponse })
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
  assign(@Param('id', ParseUUIDPipe) id: string, @Body() input: AssignPlanInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) {
    return this.plans.assign(bearer(req), req.header('X-CSRF-Token') ?? '', key, id, input, undefined, req.ip);
  }
  @Post('vendors/:id/plan-assignments/:assignmentId/extend') @Header('Cache-Control', 'no-store') @ApiCreatedResponse({ type: AssignmentResponse })
  @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
  extend(@Param('id', ParseUUIDPipe) id: string, @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Body() input: ExtendPlanInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) {
    return this.plans.assign(bearer(req), req.header('X-CSRF-Token') ?? '', key, id, input, assignmentId, req.ip);
  }
}
