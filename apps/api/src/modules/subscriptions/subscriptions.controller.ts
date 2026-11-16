import { Body, Controller, Get, Header, Headers, Param, ParseUUIDPipe, Patch, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { user_role_type } from '@prisma/client';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { CustomerSubscriptionInput, SubscriptionList, SubscriptionMutation, SubscriptionPatch, SubscriptionPause, SubscriptionPlans, SubscriptionPlansQuery, SubscriptionQuery, SubscriptionRecord, SubscriptionReject, SubscriptionSkip, SubscriptionVersion, VendorSubscriptionInput } from './subscriptions.dto';
import { SubscriptionsService } from './subscriptions.service';
type AuthRequest=Request & {session:{userId:string}};
abstract class SubscriptionRoutes {
  protected abstract role:user_role_type;
  constructor(protected readonly service:SubscriptionsService) {}
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SubscriptionList})
  list(@Req() r:AuthRequest,@Query() q:SubscriptionQuery){return this.service.list(r.session.userId,this.role,q);}
  @Get(':id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SubscriptionRecord})
  get(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string){return this.service.get(r.session.userId,this.role,id);}
  @Patch(':id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:SubscriptionMutation})
  edit(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionPatch){return this.service.change(r.session.userId,this.role,key,id,'EDIT',input);}
  @Post(':id/pause') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  pause(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionPause){return this.service.change(r.session.userId,this.role,key,id,'PAUSE',input);}
  @Post(':id/resume') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  resume(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionVersion){return this.service.change(r.session.userId,this.role,key,id,'RESUME',input);}
  @Post(':id/cancel') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  cancel(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionVersion){return this.service.change(r.session.userId,this.role,key,id,'CANCEL',input);}
  @Post(':id/skip') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  skip(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionSkip){return this.service.change(r.session.userId,this.role,key,id,'SKIP',input);}
}
@ApiTags('vendor-subscriptions') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor/subscriptions')
@ApiResponse({status:403,description:'Vendor scope/suspension/plan denial.'})
@ApiResponse({status:409,description:'VERSION_CONFLICT or invalid state.'})
@ApiResponse({status:422,description:'Date/cutoff/slot or immutable retry mismatch.'})
export class VendorSubscriptionsController extends SubscriptionRoutes {
  protected role:user_role_type='VENDOR';
  constructor(service:SubscriptionsService){super(service);}
  @Post() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  create(@Req() r:AuthRequest,@Headers('Idempotency-Key') key:string,@Body() input:VendorSubscriptionInput){return this.service.create(r.session.userId,this.role,key,input);}
  @Post(':id/approve') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  approve(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionVersion){return this.service.change(r.session.userId,this.role,key,id,'APPROVE',input);}
  @Post(':id/reject') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  reject(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:SubscriptionReject){return this.service.change(r.session.userId,this.role,key,id,'REJECT',input);}
}
@ApiTags('customer-subscriptions') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('customer/subscriptions')
@ApiResponse({status:404,description:'Only accepted-link-owned subscriptions are readable/mutable; mobile matching grants no access.'})
@ApiResponse({status:409,description:'VERSION_CONFLICT, CUSTOMER_LINK_REQUIRED or invalid state.'})
@ApiResponse({status:422,description:'PAST_CUTOFF or invalid date/slot/coverage; no partial effects.'})
export class CustomerSubscriptionsController extends SubscriptionRoutes {
  protected role:user_role_type='CUSTOMER';
  constructor(service:SubscriptionsService){super(service);}
  @Post() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SubscriptionMutation})
  create(@Req() r:AuthRequest,@Headers('Idempotency-Key') key:string,@Body() input:CustomerSubscriptionInput){return this.service.create(r.session.userId,this.role,key,input);}
}
@ApiTags('customer-subscriptions') @ApiBearerAuth() @UseGuards(SessionGuard)
@Controller('customer/vendors')
export class SubscriptionPlansController {
  constructor(private readonly service:SubscriptionsService){}
  @Get(':id/subscription-plans') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SubscriptionPlans})
  plans(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Query() q:SubscriptionPlansQuery){return this.service.plansFor(r.session.userId,id,q.addressId);}
}
