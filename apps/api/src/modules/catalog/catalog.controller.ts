import { Body, Controller, Delete, Get, Header, Headers, Param, ParseUUIDPipe, Patch, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { CatalogService } from './catalog.service';
import { ProductDeleted, ProductInput, ProductList, ProductOptions, ProductPatch, ProductQuery, ProductResponse, StockAdjustment } from './catalog.dto';

type VendorRequest = Request & { session: { userId: string } };
@ApiTags('catalog') @ApiBearerAuth() @UseGuards(SessionGuard)
@ApiResponse({ status: 400, description: 'Invalid input or missing Idempotency-Key.' })
@ApiResponse({ status: 401, description: 'Missing, expired or revoked session.' })
@ApiResponse({ status: 403, description: 'VENDOR_ROLE_REQUIRED or VENDOR_SUSPENDED.' })
@ApiResponse({ status: 404, description: 'PRODUCT_NOT_FOUND (including another owner or soft-deleted).' })
@ApiResponse({ status: 409, description: 'PRODUCT_IN_USE, INSUFFICIENT_STOCK or CATEGORY_REQUIRED.' })
@ApiResponse({ status: 422, description: 'IDEMPOTENCY_MISMATCH.' })
@SetMetadata(NO_IDEMPOTENCY_CACHE, true) @Controller('vendor/products')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}
  @Get() @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: ProductList })
  list(@Req() req: VendorRequest, @Query() query: ProductQuery) { return this.catalog.list(req.session.userId, query); }
  @Get('options') @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: ProductOptions })
  options(@Req() req: VendorRequest) { return this.catalog.options(req.session.userId); }
  @Get(':id') @Header('Cache-Control', 'no-store') @ApiResponse({ status: 200, type: ProductResponse })
  get(@Req() req: VendorRequest, @Param('id', ParseUUIDPipe) id: string) { return this.catalog.get(req.session.userId, id); }
  @Post() @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: ProductResponse })
  create(@Req() req: VendorRequest, @Headers('Idempotency-Key') key: string, @Body() input: ProductInput) {
    return this.catalog.create(req.session.userId, key, input);
  }
  @Patch(':id') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: ProductResponse })
  patch(@Req() req: VendorRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string, @Body() input: ProductPatch) {
    return this.catalog.patch(req.session.userId, key, id, input);
  }
  @Delete(':id') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: ProductDeleted })
  remove(@Req() req: VendorRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string) {
    return this.catalog.remove(req.session.userId, key, id);
  }
  @Post(':id/stock-adjustments') @Header('Cache-Control', 'no-store') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: ProductResponse })
  adjust(@Req() req: VendorRequest, @Param('id', ParseUUIDPipe) id: string, @Headers('Idempotency-Key') key: string, @Body() input: StockAdjustment) {
    return this.catalog.adjust(req.session.userId, key, id, input);
  }
}
