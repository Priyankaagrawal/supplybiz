import { Body, Controller, Get, Header, Headers, Post, Put, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { VendorBusinessDto, VendorCategoryDto, VendorCategoryResponse, VendorProfileResponse } from './vendors.dto';
import { VendorsService } from './vendors.service';

type VendorRequest = Request & { session: { userId: string } };
@ApiTags('vendor-onboarding') @ApiBearerAuth() @UseGuards(SessionGuard)
@ApiResponse({ status: 401, description: 'Missing, expired or revoked session.' })
@ApiResponse({ status: 403, description: 'VENDOR_ROLE_REQUIRED: requires held and active vendor role.' })
@SetMetadata(NO_IDEMPOTENCY_CACHE, true)
@Controller('vendor')
export class VendorsController {
  constructor(private readonly vendors: VendorsService) {}
  @Header('Cache-Control', 'no-store')
  @Get('onboarding/categories') @ApiResponse({ status: 200, type: [VendorCategoryResponse] })
  categories(@Req() req: VendorRequest) { return this.vendors.categories(req.session.userId); }

  @Header('Cache-Control', 'no-store')
  @Get('onboarding') @ApiResponse({ status: 200, type: VendorProfileResponse })
  @ApiResponse({ status: 404, description: 'ONBOARDING_NOT_STARTED: show category screen.' })
  profile(@Req() req: VendorRequest) { return this.vendors.profile(req.session.userId); }

  @Header('Cache-Control', 'no-store')
  @Post('onboarding/category') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 201, type: VendorProfileResponse })
  @ApiResponse({ status: 400, description: 'Invalid category or key.' })
  @ApiResponse({ status: 409, description: 'REVERIFICATION_REQUIRED' })
  @ApiResponse({ status: 422, description: 'IDEMPOTENCY_MISMATCH' })
  category(@Body() input: VendorCategoryDto, @Headers('Idempotency-Key') key: string, @Req() req: VendorRequest) {
    return this.vendors.category(req.session.userId, key, input);
  }
  @Header('Cache-Control', 'no-store')
  @Put('onboarding/business') @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiResponse({ status: 200, type: VendorProfileResponse })
  @ApiResponse({ status: 400, description: 'Invalid business fields or key.' })
  @ApiResponse({ status: 404, description: 'MEDIA_NOT_FOUND: wrong owner/purpose or not READY.' })
  @ApiResponse({ status: 409, description: 'CATEGORY_REQUIRED or REVERIFICATION_REQUIRED' })
  @ApiResponse({ status: 422, description: 'IDEMPOTENCY_MISMATCH' })
  business(@Body() input: VendorBusinessDto, @Headers('Idempotency-Key') key: string, @Req() req: VendorRequest) {
    return this.vendors.business(req.session.userId, key, input);
  }
}
