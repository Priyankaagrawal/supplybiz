import { Body, Controller, Get, Header, Headers, Param, ParseUUIDPipe, Patch, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { CustomerInput, CustomerList, CustomerPatch, CustomerQuery, CustomerResponse, LinkDecisionResponse, LinkRequestList, LinkRequestQuery } from './customers.dto';
import { CustomersService } from './customers.service';

type AuthRequest = Request & { session: { userId: string } };
@ApiTags('vendor-customers') @ApiBearerAuth() @UseGuards(SessionGuard)
@ApiResponse({ status: 400, description: 'Invalid input or missing Idempotency-Key.' })
@ApiResponse({ status: 401, description: 'Missing, expired or revoked session.' })
@ApiResponse({ status: 403, description: 'VENDOR_ROLE_REQUIRED or VENDOR_SUSPENDED.' })
@ApiResponse({ status: 404, description: 'CUSTOMER_NOT_FOUND, including other vendors.' })
@ApiResponse({ status: 409, description: 'DUPLICATE, LINKED_MOBILE_IMMUTABLE or CATEGORY_REQUIRED.' })
@ApiResponse({ status: 422, description: 'PLAN_CUSTOMER_LIMIT or IDEMPOTENCY_MISMATCH.' })
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('vendor/customers')
export class CustomersController {
  constructor(private readonly customers: CustomersService) {}
  @Get() @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: CustomerList })
  list(@Req() req: AuthRequest, @Query() query: CustomerQuery) { return this.customers.list(req.session.userId, query); }
  @Get(':id') @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: CustomerResponse })
  get(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) { return this.customers.get(req.session.userId, id); }
  @Post() @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: CustomerResponse })
  create(@Req() req: AuthRequest, @Headers('Idempotency-Key') key: string, @Body() input: CustomerInput) {
    return this.customers.create(req.session.userId, key, input);
  }
  @Patch(':id') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: CustomerResponse })
  patch(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string, @Body() input: CustomerPatch) {
    return this.customers.patch(req.session.userId, key, id, input);
  }
}
@ApiTags('customer-links') @ApiBearerAuth() @UseGuards(SessionGuard)
@ApiResponse({ status: 400, description: 'Invalid UUID or missing Idempotency-Key.' })
@ApiResponse({ status: 401, description: 'Missing, expired or revoked session.' })
@ApiResponse({ status: 403, description: 'CUSTOMER_ROLE_REQUIRED.' })
@ApiResponse({ status: 404, description: 'LINK_REQUEST_NOT_FOUND: not matched to authenticated mobile, deleted or suspended.' })
@ApiResponse({ status: 409, description: 'LINK_ALREADY_DECIDED or DUPLICATE.' })
@ApiResponse({ status: 422, description: 'IDEMPOTENCY_MISMATCH.' })
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('customer/link-requests')
export class CustomerLinksController {
  constructor(private readonly customers: CustomersService) {}
  @Get() @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: LinkRequestList })
  list(@Req() req: AuthRequest, @Query() query: LinkRequestQuery) { return this.customers.linkRequests(req.session.userId, query); }
  @Post(':id/accept') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: LinkDecisionResponse })
  accept(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string) {
    return this.customers.decide(req.session.userId, key, id, 'ACCEPTED');
  }
  @Post(':id/decline') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: LinkDecisionResponse })
  decline(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string) {
    return this.customers.decide(req.session.userId, key, id, 'DECLINED');
  }
}
