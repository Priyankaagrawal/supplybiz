import { Body, Controller, Get, Header, Headers, Patch, Param, ParseIntPipe, ParseUUIDPipe, Post, Query, Req, SetMetadata, DefaultValuePipe, BadRequestException, HttpCode } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiQuery, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { AdminAccountsService } from './admin-accounts.service';
import { AdminAccountResponse, AdminAccountsResponse, ChangeAdminInput, CreateAdminInput, PlatformExportInput, PlatformExportResponse } from './admin-accounts.dto';
@Controller('admin') @ApiTags('admin-accounts-reports') @ApiBearerAuth() @SetMetadata(NO_IDEMPOTENCY_CACHE,true)
export class AdminAccountsController {
 constructor(private readonly service:AdminAccountsService) {}
 @Header('Cache-Control','no-store') @Get('admins') @AdminPermission('admins.manage') @ApiQuery({name:'offset',required:false,type:Number}) @ApiOkResponse({type:AdminAccountsResponse})
 list(@Query('offset',new DefaultValuePipe(0),ParseIntPipe) offset:number) { if(offset<0||offset>100000)throw new BadRequestException();return this.service.list(offset); }
 @Header('Cache-Control','no-store') @Post('admins') @HttpCode(200) @AdminPermission('admins.manage') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiHeader({name:'X-CSRF-Token',required:true}) @ApiOkResponse({type:AdminAccountResponse})
 create(@Req() r:Request,@Headers('Idempotency-Key') key:string,@Body() input:CreateAdminInput) {return this.service.create(bearer(r),r.header('X-CSRF-Token')??'',key,input,r.ip);}
 @Header('Cache-Control','no-store') @Patch('admins/:id') @AdminPermission('admins.manage') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiHeader({name:'X-CSRF-Token',required:true}) @ApiOkResponse({type:AdminAccountResponse})
 change(@Req() r:Request,@Headers('Idempotency-Key') key:string,@Param('id',ParseUUIDPipe) id:string,@Body() input:ChangeAdminInput) {return this.service.change(bearer(r),r.header('X-CSRF-Token')??'',key,id,input,r.ip);}
 @Header('Cache-Control','no-store') @Post('reports/exports') @HttpCode(200) @AdminPermission('reports.export') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiHeader({name:'X-CSRF-Token',required:true}) @ApiOkResponse({type:PlatformExportResponse})
 export(@Req() r:Request,@Headers('Idempotency-Key') key:string,@Body() input:PlatformExportInput) {return this.service.export(bearer(r),r.header('X-CSRF-Token')??'',key,input,r.ip);}
}
