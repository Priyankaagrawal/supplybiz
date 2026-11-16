import { Body, Controller, Get, Header, Headers, Patch, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { SubscriptionQuery } from './subscriptions.dto';
import { SubscriptionCustomerList, SubscriptionSettingsPatch, SubscriptionSettingsResponse } from './subscription-settings.dto';
import { SubscriptionSettingsService } from './subscription-settings.service';
type AuthRequest=Request & {session:{userId:string}};
@ApiTags('vendor-subscription-settings') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor/settings')
@ApiResponse({status:400,description:'Invalid exact capacity, delivery window, patch or idempotency key.'})
@ApiResponse({status:403,description:'Vendor role/suspension or server plan feature denial; contact support to assign/renew.'})
@ApiResponse({status:409,description:'VERSION_CONFLICT on shared vendor settings.'})
@ApiResponse({status:422,description:'IDEMPOTENCY_MISMATCH.'})
export class SubscriptionSettingsController {
  constructor(private readonly service:SubscriptionSettingsService){}
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SubscriptionSettingsResponse})
  get(@Req() r:AuthRequest){return this.service.get(r.session.userId);}
  @Patch() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:SubscriptionSettingsResponse})
  patch(@Req() r:AuthRequest,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionSettingsPatch){return this.service.patch(r.session.userId,key,input);}
  @Get('subscription-customers') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SubscriptionCustomerList})
  customers(@Req() r:AuthRequest,@Query() q:SubscriptionQuery){return this.service.customers(r.session.userId,q);}
}
