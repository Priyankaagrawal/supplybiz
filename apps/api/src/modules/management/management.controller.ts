import { Body, Controller, Get, Header, Headers, HttpCode, Param, ParseUUIDPipe, Patch, Post, Query, Req, SetMetadata } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { AdminPermission, bearer } from '../admin-auth/admin-auth.controller';
import { BadgeInput, ManagedCustomer, ManagedCustomerList, ManagedVendorDetail, ManagedVendorList, ManagementInput, ManagementQuery, ManagementResponse } from './management.dto';
import { ManagementService } from './management.service';
@ApiTags('admin-management') @ApiBearerAuth() @SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('admin')
export class ManagementController {
 constructor(private readonly management: ManagementService) {}
 @Get('vendors') @AdminPermission('vendors.read') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagedVendorList })
 vendors(@Query() query: ManagementQuery) { return this.management.vendors(query); }
 @Get('vendors/:id') @AdminPermission('vendors.read') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagedVendorDetail })
 vendor(@Param('id', ParseUUIDPipe) id: string) { return this.management.vendorDetail(id); }
 @Get('customers') @AdminPermission('customers.read') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagedCustomerList })
 customers(@Query() query: ManagementQuery) { return this.management.customers(query); }
 @Get('customers/:id') @AdminPermission('customers.read') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagedCustomer })
 customer(@Param('id', ParseUUIDPipe) id: string) { return this.management.customerDetail(id); }
 @Post('vendors/:id/suspend') @HttpCode(200) @AdminPermission('vendors.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagementResponse })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 suspend(@Param('id', ParseUUIDPipe) id: string, @Body() input: ManagementInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.write(req, key, id, 'SUSPEND', input); }
 @Post('vendors/:id/reinstate') @HttpCode(200) @AdminPermission('vendors.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagementResponse })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 reinstate(@Param('id', ParseUUIDPipe) id: string, @Body() input: ManagementInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.write(req, key, id, 'REINSTATE', input); }
 @Patch('vendors/:id') @AdminPermission('vendors.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagementResponse })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 badges(@Param('id', ParseUUIDPipe) id: string, @Body() input: BadgeInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.write(req, key, id, 'BADGES', input); }
 @Post('customers/:id/block') @HttpCode(200) @AdminPermission('customers.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagementResponse })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 block(@Param('id', ParseUUIDPipe) id: string, @Body() input: ManagementInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.write(req, key, id, 'BLOCK', input); }
 @Post('customers/:id/unblock') @HttpCode(200) @AdminPermission('customers.manage') @Header('Cache-Control', 'no-store') @ApiOkResponse({ type: ManagementResponse })
 @ApiHeader({ name: 'Idempotency-Key', required: true }) @ApiHeader({ name: 'X-CSRF-Token', required: true })
 unblock(@Param('id', ParseUUIDPipe) id: string, @Body() input: ManagementInput, @Headers('Idempotency-Key') key: string, @Req() req: Request) { return this.write(req, key, id, 'UNBLOCK', input); }
 private write(req: Request, key: string, id: string, action: 'SUSPEND' | 'REINSTATE' | 'BADGES' | 'BLOCK' | 'UNBLOCK', input: ManagementInput | BadgeInput) {
  return this.management.change(bearer(req), req.header('X-CSRF-Token') ?? '', key, id, action, input, req.ip);
 }
}
