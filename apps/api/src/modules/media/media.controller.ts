import { Controller, Get, Header, Param, ParseUUIDPipe, Post, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiHeader, ApiProperty, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { MediaService } from './media.service';
import { PURPOSES } from './media-validation';
class MediaResponse {
  @ApiProperty({ format: 'uuid' }) mediaId!: string;
  @ApiProperty({ enum: ['READY'] }) status!: string;
}
@ApiTags('media') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE, true)
@Controller('media')
export class MediaController {
  constructor(private readonly media: MediaService) {}
  @Post() @ApiConsumes('multipart/form-data')
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiBody({ schema: { type: 'object', required: ['file', 'purpose'], properties: {
    file: { type: 'string', format: 'binary' }, purpose: { type: 'string', enum: [...PURPOSES] } } } })
  @ApiResponse({ status: 201, type: MediaResponse })
  @ApiResponse({ status: 400, description: 'Invalid media or multipart fields.' })
  @ApiResponse({ status: 413, description: 'File exceeds configured limit.' })
  @ApiResponse({ status: 422, description: 'IDEMPOTENCY_MISMATCH' })
  upload(@Req() req: Request & { session: { userId: string } }) { return this.media.upload(req.session.userId, req); }
  @Get(':id/content') @Header('Cache-Control', 'no-store') @Header('X-Content-Type-Options', 'nosniff')
  @ApiResponse({ status: 200, schema: { type: 'string', format: 'binary' } })
  @ApiResponse({ status: 404, description: 'Missing media or not owned by caller.' })
  content(@Param('id', ParseUUIDPipe) id: string, @Req() req: Request & { session: { userId: string } }) {
    return this.media.content(id, { owner: req.session.userId });
  }
}
@ApiTags('media') @ApiBearerAuth() @Controller('admin/media')
export class AdminMediaController {
  constructor(private readonly media: MediaService) {}
  @Get(':id/content') @AdminPermission('kyc.documents')
  @Header('Cache-Control', 'no-store') @Header('X-Content-Type-Options', 'nosniff')
  @ApiResponse({ status: 200, schema: { type: 'string', format: 'binary' } })
  content(@Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.media.content(id, { adminToken: bearer(req), ip: req.ip });
  }
}
