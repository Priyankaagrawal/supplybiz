import { Body,Controller,Get,Header,Headers,Param,ParseUUIDPipe,Post,Req,SetMetadata,UseGuards } from '@nestjs/common';
import { ApiBearerAuth,ApiHeader,ApiProduces,ApiResponse,ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { ReportExportCreated,ReportExportInput,ReportExportStatus } from './report-exports.dto';
import { ReportExportsService } from './report-exports.service';
type Actor=Request & {session:{userId:string}};
@ApiTags('vendor-report-exports') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true)
@Controller('vendor/reports/exports')
@ApiResponse({status:403,description:'Live vendor role/suspension/active BUSINESS+ entitlement required, including replay/status/download.'})
@ApiResponse({status:404,description:'REPORT_EXPORT_NOT_FOUND; includes exports owned by another actor/vendor.'})
@ApiResponse({status:410,description:'REPORT_EXPORT_EXPIRED; use a new key for a fresh snapshot.'})
@ApiResponse({status:413,description:'REPORT_EXPORT_TOO_LARGE; narrow date range. No truncated file created.'})
export class ReportExportsController {
  constructor(private readonly exports:ReportExportsService){}
  @Post() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:ReportExportCreated})
  create(@Req() r:Actor,@Headers('Idempotency-Key') key:string,@Body() input:ReportExportInput){return this.exports.create(r.session.userId,key,input);}
  @Get(':id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:ReportExportStatus})
  status(@Req() r:Actor,@Param('id',ParseUUIDPipe) id:string){return this.exports.status(r.session.userId,id);}
  @Get(':id/download') @Header('Cache-Control','no-store') @Header('X-Content-Type-Options','nosniff') @ApiProduces('text/csv')
  @ApiResponse({status:200,schema:{type:'string',format:'binary'}})
  download(@Req() r:Actor,@Param('id',ParseUUIDPipe) id:string){return this.exports.download(r.session.userId,id);}
}
