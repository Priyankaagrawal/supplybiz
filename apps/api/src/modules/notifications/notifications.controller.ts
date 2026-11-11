import { Body, Controller, Delete, Get, Header, Headers, HttpCode, Post, Put, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { DevicePushInput, DevicePushResponse, InboxQuery, InboxResponse, NotificationMutationResponse, NotificationPreferences, NotificationScope, ReadNotifications } from './notifications.dto';
import { NotificationsService } from './notifications.service';
type ActorRequest = Request & { session: { userId: string; sessionId: string } };
@ApiTags('notifications') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller()
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}
  @Get('notifications') @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: InboxResponse })
  list(@Req() req: ActorRequest, @Query() query: InboxQuery) { return this.service.list(req.session.userId, query); }
  @Post('notifications/read') @HttpCode(200) @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: NotificationMutationResponse })
  read(@Req() req: ActorRequest, @Headers('Idempotency-Key') key: string, @Body() input: ReadNotifications) { return this.service.read(req.session.userId, key, input); }
  @Delete('notifications') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: NotificationMutationResponse })
  clear(@Req() req: ActorRequest, @Headers('Idempotency-Key') key: string, @Query() scope: NotificationScope) { return this.service.clear(req.session.userId, key, scope.role); }
  @Get('me/notification-prefs') @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: NotificationPreferences })
  preferences(@Req() req: ActorRequest) { return this.service.preferences(req.session.userId); }
  @Put('me/notification-prefs') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: NotificationPreferences })
  savePreferences(@Req() req: ActorRequest, @Headers('Idempotency-Key') key: string, @Body() input: NotificationPreferences) { return this.service.savePreferences(req.session.userId, key, input); }
  @Put('me/devices/current') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: DevicePushResponse })
  device(@Req() req: ActorRequest, @Headers('Idempotency-Key') key: string, @Body() input: DevicePushInput) { return this.service.registerDevice(req.session.userId, req.session.sessionId, key, input); }
}
