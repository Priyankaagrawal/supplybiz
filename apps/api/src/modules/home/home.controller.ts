import { Controller, Get, Header, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { SessionGuard } from '../auth/sessions.controller';
import { CustomerHome, HomeQuery } from './home.dto';
import { HomeService } from './home.service';

@ApiTags('customer-home') @ApiBearerAuth() @UseGuards(SessionGuard) @Controller('customer/home')
export class HomeController {
  constructor(private readonly home: HomeService) {}
  @Get() @Header('Cache-Control', 'no-store')
  @ApiResponse({ status: 200, type: CustomerHome })
  @ApiResponse({ status: 400, description: 'Invalid query or cursor not owned by this customer/current IST day.' })
  @ApiResponse({ status: 401, description: 'Missing, revoked or expired session.' })
  @ApiResponse({ status: 403, description: 'CUSTOMER_ROLE_REQUIRED.' })
  get(@Req() request: Request & { session: { userId: string } }, @Query() query: HomeQuery) {
    return this.home.get(request.session.userId, query);
  }
}
