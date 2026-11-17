import { Body, Controller, Delete, Get, Header, Headers, Param, ParseUUIDPipe, Patch, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { AvailabilityMutation, AvailabilityPatch, AvailabilityResponse, DeliveryImpact, HolidayDeleted, HolidayImpactQuery, HolidayInput, HolidayList, HolidayMutation, HolidayQuery } from './availability.dto';
import { AvailabilityService } from './availability.service';
type Auth=Request & {session:{userId:string}};
@ApiTags('vendor-availability') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true)
@Controller('vendor')
@ApiResponse({status:403,description:'Active vendor role/suspension or plan denial; reducing operations and history survive expiry.'})
@ApiResponse({status:409,description:'VERSION_CONFLICT, HOLIDAY_EXISTS or HOLIDAY_NOT_FUTURE.'})
@ApiResponse({status:422,description:'HOLIDAY_IN_PAST or IDEMPOTENCY_MISMATCH.'})
export class AvailabilityController {
  constructor(private readonly service:AvailabilityService){}
  @Get('availability') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:AvailabilityResponse})
  get(@Req() r:Auth){return this.service.get(r.session.userId);}
  @Get('availability/impact') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:DeliveryImpact})
  pauseImpact(@Req() r:Auth){return this.service.impact(r.session.userId);}
  @Patch('availability') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:AvailabilityMutation})
  patch(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Body() input:AvailabilityPatch){return this.service.patch(r.session.userId,key,input);}
  @Get('holidays') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:HolidayList})
  list(@Req() r:Auth,@Query() q:HolidayQuery){return this.service.list(r.session.userId,q);}
  @Get('holidays/impact') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:DeliveryImpact})
  impact(@Req() r:Auth,@Query() q:HolidayImpactQuery){return this.service.impact(r.session.userId,q.date);}
  @Post('holidays') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:HolidayMutation})
  create(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Body() input:HolidayInput){return this.service.create(r.session.userId,key,input);}
  @Delete('holidays/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:HolidayDeleted})
  delete(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Param('id',ParseUUIDPipe) id:string){return this.service.delete(r.session.userId,key,id);}
}
