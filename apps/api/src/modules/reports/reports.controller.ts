import { Controller, Get, Header, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { ReportDailySales,ReportProducts,ReportProductsQuery,ReportQuery,ReportSummary } from './reports.dto';
import { ReportsService } from './reports.service';
type Actor=Request & {session:{userId:string}};
@ApiTags('vendor-reports') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true)
@Controller('vendor/reports')
@ApiResponse({status:400,description:'Invalid inclusive IST range (max 366 days), unknown query field or pagination.'})
@ApiResponse({status:403,description:'Active/held vendor role, suspension or PLAN_FEATURE_LOCKED. Advanced tables require active BUSINESS/PREMIUM.'})
@ApiResponse({status:503,description:'REPORTS_UNAVAILABLE; no fabricated/cached totals.'})
export class ReportsController {
  constructor(private readonly reports:ReportsService){}
  @Get('summary') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:ReportSummary})
  summary(@Req() r:Actor,@Query() q:ReportQuery){return this.reports.summary(r.session.userId,q);}
  @Get('sales-daily') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:ReportDailySales})
  daily(@Req() r:Actor,@Query() q:ReportQuery){return this.reports.daily(r.session.userId,q);}
  @Get('products') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:ReportProducts})
  products(@Req() r:Actor,@Query() q:ReportProductsQuery){return this.reports.products(r.session.userId,q);}
}
