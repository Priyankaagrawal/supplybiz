import { BadRequestException, Body, Controller, DefaultValuePipe, Get, Header, Headers, HttpCode, Param, ParseIntPipe, ParseUUIDPipe, Post, Query, Req, SetMetadata } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiQuery, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { PrivacyExportInput, PrivacyHoldInput, PrivacyRequestRow, PrivacyRequestsPage, SubjectExportResponse } from './admin-privacy.dto';
import { AdminPrivacyService } from './admin-privacy.service';
@Controller('admin/data-requests') @ApiTags('admin-privacy') @ApiBearerAuth() @AdminPermission('privacy.manage') @SetMetadata(NO_IDEMPOTENCY_CACHE,true)
export class AdminPrivacyController {
 constructor(private readonly service:AdminPrivacyService){}
 @Get() @Header('Cache-Control','no-store') @ApiQuery({name:'offset',required:false,type:Number}) @ApiOkResponse({type:PrivacyRequestsPage})
 list(@Query('offset',new DefaultValuePipe(0),ParseIntPipe) offset:number){if(offset<0||offset>100000)throw new BadRequestException();return this.service.list(offset);}
 @Post() @HttpCode(200) @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiHeader({name:'X-CSRF-Token',required:true}) @ApiOkResponse({type:PrivacyRequestRow})
 create(@Req() r:Request,@Headers('Idempotency-Key') key:string,@Body() input:PrivacyExportInput){return this.service.create(bearer(r),r.header('X-CSRF-Token')??'',key,input,r.ip);}
 @Post(':id/hold') @HttpCode(200) @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiHeader({name:'X-CSRF-Token',required:true}) @ApiOkResponse({type:PrivacyRequestRow})
 hold(@Req() r:Request,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:PrivacyHoldInput){return this.service.hold(bearer(r),r.header('X-CSRF-Token')??'',key,id,input,r.ip);}
 @Get(':id/export') @Header('Cache-Control','no-store') @ApiOkResponse({type:SubjectExportResponse})
 download(@Req() r:Request,@Param('id',ParseUUIDPipe) id:string){return this.service.download(bearer(r),id,r.ip);}
}
