import { Body, Controller, Get, Header, Headers, Param, ParseEnumPipe, ParseUUIDPipe, Put, Query, Req, SetMetadata } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiQuery, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { ContentService } from './content.service';
import { AdminConfigResponse, ConfigInput, ContentQuery, FaqInput, FaqList, FaqRow, LegalInput, LegalList, LegalRow, LegalType } from './content.dto';

@ApiTags('content') @Controller('content')
export class ContentController {
 constructor(private readonly content: ContentService) {}
 @Get('faqs') @Header('Cache-Control', 'public, max-age=60') @ApiOkResponse({ type: FaqList })
 faqs(@Query() query: ContentQuery) { return this.content.faqs(query); }
 @Get('legal/:type') @Header('Cache-Control', 'public, max-age=60') @ApiOkResponse({ type: LegalRow })
 @ApiQuery({ name: 'version', required: false, type: String })
 legal(@Param('type', new ParseEnumPipe(LegalType)) type: LegalType, @Query('version') version?: string) { return this.content.legal(type, version); }
}
@ApiTags('admin-content') @ApiBearerAuth() @Controller('admin')
@SetMetadata(NO_IDEMPOTENCY_CACHE, true)
export class AdminContentController {
 constructor(private readonly content: ContentService) {}
 @Get('faqs') @AdminPermission('cms.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: FaqList })
 faqs(@Query() query: ContentQuery) { return this.content.faqs(query, true); }
 @Get('legal') @AdminPermission('cms.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: LegalList })
 history() { return this.content.legalHistory(); }
 @Get('legal/:type') @AdminPermission('cms.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: LegalRow })
 @ApiQuery({ name: 'version', required: false, type: String })
 legal(@Param('type', new ParseEnumPipe(LegalType)) type: LegalType, @Query('version') version?: string) { return this.content.legal(type, version); }
 @Get('config') @AdminPermission('config.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: AdminConfigResponse })
 config() { return this.content.config(); }
 @Put('faqs/:id') @AdminPermission('cms.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: FaqRow })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 faq(@Param('id', ParseUUIDPipe) id: string, @Body() input: FaqInput, @Req() req: Request, @Headers('Idempotency-Key') key: string) { return this.content.saveFaq(bearer(req), req.header('X-CSRF-Token') ?? '', key, id, input); }
 @Put('legal/:type') @AdminPermission('cms.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: LegalRow })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 publish(@Param('type', new ParseEnumPipe(LegalType)) type: LegalType, @Body() input: LegalInput, @Req() req: Request, @Headers('Idempotency-Key') key: string) { return this.content.publish(bearer(req), req.header('X-CSRF-Token') ?? '', key, type, input); }
 @Put('config') @AdminPermission('config.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: AdminConfigResponse })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 saveConfig(@Body() input: ConfigInput, @Req() req: Request, @Headers('Idempotency-Key') key: string) { return this.content.saveConfig(bearer(req), req.header('X-CSRF-Token') ?? '', key, input); }
}
