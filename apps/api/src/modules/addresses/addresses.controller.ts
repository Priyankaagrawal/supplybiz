import { Body, Controller, Delete, Get, Header, Headers, Param, ParseUUIDPipe, Patch, Post, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { AddressDeleted, AddressInput, AddressList, AddressPatch, AddressResponse } from './addresses.dto';
import { AddressesService } from './addresses.service';

type AuthRequest = Request & { session: { userId: string } };
@ApiTags('customer-addresses') @ApiBearerAuth() @UseGuards(SessionGuard)
@ApiResponse({ status: 400, description: 'Invalid input, UUID or missing Idempotency-Key.' })
@ApiResponse({ status: 401, description: 'Missing, expired or revoked session.' })
@ApiResponse({ status: 403, description: 'CUSTOMER_ROLE_REQUIRED.' })
@ApiResponse({ status: 404, description: 'ADDRESS_NOT_FOUND: missing, deleted or owned by another customer.' })
@ApiResponse({ status: 409, description: 'DEFAULT_ADDRESS_REQUIRED: select another default first.' })
@ApiResponse({ status: 422, description: 'IDEMPOTENCY_MISMATCH.' })
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('customer/addresses')
export class AddressesController {
  constructor(private readonly addresses: AddressesService) {}
  @Get() @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: AddressList })
  list(@Req() req: AuthRequest) { return this.addresses.list(req.session.userId); }
  @Get(':id') @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: AddressResponse })
  get(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) { return this.addresses.get(req.session.userId, id); }
  @Post() @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: AddressResponse })
  create(@Req() req: AuthRequest, @Headers('Idempotency-Key') key: string, @Body() input: AddressInput) {
    return this.addresses.create(req.session.userId, key, input);
  }
  @Patch(':id') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: AddressResponse })
  patch(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string, @Body() input: AddressPatch) {
    return this.addresses.patch(req.session.userId, key, id, input);
  }
  @Delete(':id') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: AddressDeleted })
  remove(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string) {
    return this.addresses.remove(req.session.userId, key, id);
  }
}
