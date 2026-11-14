import { Body, Controller, Get, Header, Headers, Param, ParseUUIDPipe, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { OrderCancelInput, OrderDetail, OrderList, OrderPlaceInput, OrderProblem, OrderQuery, OrderQuote, OrderQuoteInput, OrderResult, OrderTransitionInput } from './orders.dto';
import { OrdersService } from './orders.service';
import { CheckoutOptions, CheckoutOptionsQuery } from './orders.dto';
import { DeliveryList, DeliveryQuery } from './orders.dto';
import { OrderReorder } from './orders.dto';
type AuthRequest = Request & {session:{userId:string}};
@ApiTags('customer-orders') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('customer/orders')
@ApiResponse({status:400,description:'Invalid input, forbidden checkout payment mode or missing mutation key.'})
@ApiResponse({status:401,description:'Missing/revoked session.'})
@ApiResponse({status:403,description:'CUSTOMER_ROLE_REQUIRED, CUSTOMER_INACTIVE or PLAN_FEATURE_LOCKED.'})
@ApiResponse({status:404,description:'ORDER_NOT_FOUND, ADDRESS_NOT_FOUND or VENDOR_UNAVAILABLE; foreign IDs hidden.'})
@ApiResponse({status:409,type:OrderProblem,description:'PRICE_CHANGED (includes fresh quote), CUSTOMER_LINK_REQUIRED, VERSION_CONFLICT or INVALID_STATE_TRANSITION.'})
@ApiResponse({status:422,type:OrderProblem,description:'BELOW_MOQ, OUT_OF_STOCK, NOT_SERVICEABLE, PAST_CUTOFF, VENDOR_HOLIDAY, DELIVERY_PAUSED, INVALID_TIME_SLOT, MIN_ORDER_NOT_MET, CAPACITY_REACHED, PLAN_CUSTOMER_LIMIT or IDEMPOTENCY_MISMATCH.'})
export class CustomerOrdersController {
  constructor(private readonly orders: OrdersService) {}
  @Get('options') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:CheckoutOptions,description:'Owned-address eligibility and server IST dates/vendor slots; quote rechecks capacity and prices.'})
  options(@Req() r:AuthRequest,@Query() q:CheckoutOptionsQuery) { return this.orders.options(r.session.userId,q.vendorId,q.addressId); }
  @Post('quote') @Header('Cache-Control','no-store') @ApiResponse({status:201,type:OrderQuote,description:'Read-only validation and server pricing; no reservation.'})
  quote(@Req() r:AuthRequest,@Body() input:OrderQuoteInput) { return this.orders.quote(r.session.userId,input); }
  @Post() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:OrderResult})
  place(@Req() r:AuthRequest,@Headers('Idempotency-Key') key:string,@Body() input:OrderPlaceInput) { return this.orders.place(r.session.userId,key,input); }
  @Post(':id/reorder') @Header('Cache-Control','no-store') @ApiResponse({status:201,type:OrderReorder,description:'Read-only owned past-order cart preview at current product prices; no reservation or new order.'})
  reorder(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string) { return this.orders.reorder(r.session.userId,id); }
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:OrderList})
  list(@Req() r:AuthRequest,@Query() q:OrderQuery) { return this.orders.list(r.session.userId,'CUSTOMER',q); }
  @Get(':id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:OrderDetail})
  detail(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string) { return this.orders.detail(r.session.userId,'CUSTOMER',id); }
  @Post(':id/cancel') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:OrderResult})
  cancel(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:OrderCancelInput) { return this.orders.cancel(r.session.userId,key,id,input); }
}
@ApiTags('vendor-orders') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor/orders')
@ApiResponse({status:400,description:'Invalid input/key/rejection/failure reason or delivery payment. DELIVERED requires explicit collected=true/false.'})
@ApiResponse({status:401,description:'Missing/revoked session.'})
@ApiResponse({status:403,description:'VENDOR_ROLE_REQUIRED, VENDOR_SUSPENDED or PLAN_FEATURE_LOCKED.'})
@ApiResponse({status:404,description:'ORDER_NOT_FOUND; foreign vendor IDs hidden.'})
@ApiResponse({status:409,type:OrderProblem,description:'INVALID_STATE_TRANSITION, VERSION_CONFLICT, INSUFFICIENT_STOCK or invalid/missing order source snapshots.'})
@ApiResponse({status:422,type:OrderProblem,description:'IDEMPOTENCY_MISMATCH.'})
export class VendorOrdersController {
  constructor(private readonly orders: OrdersService) {}
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:OrderList})
  list(@Req() r:AuthRequest,@Query() q:OrderQuery) { return this.orders.list(r.session.userId,'VENDOR',q); }
  @Get(':id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:OrderDetail})
  detail(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string) { return this.orders.detail(r.session.userId,'VENDOR',id); }
  @Post(':id/transitions') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:OrderResult})
  transition(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() input:OrderTransitionInput) { return this.orders.transition(r.session.userId,key,id,input); }
}
@ApiTags('vendor-deliveries') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor/deliveries')
@ApiResponse({status:400,description:'Invalid status/date/pagination.'})
@ApiResponse({status:401,description:'Missing/revoked session.'})
@ApiResponse({status:403,description:'VENDOR_ROLE_REQUIRED or VENDOR_SUSPENDED.'})
export class VendorDeliveriesController {
  constructor(private readonly orders:OrdersService) {}
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:DeliveryList})
  list(@Req() r:AuthRequest,@Query() q:DeliveryQuery) { return this.orders.deliveries(r.session.userId,q); }
}
