import { Body, Controller, Get, Header, Headers, Param, ParseUUIDPipe, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { CompleteSaleInput,SaleList,SaleQuery,SaleResponse } from './sales.dto';
import { SalesService } from './sales.service';
type Auth=Request & {session:{userId:string}};
@ApiTags('vendor-sales') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor/sales')
@ApiResponse({status:403,description:'Active vendor role, suspension or server plan/expiry denial.'})
@ApiResponse({status:409,description:'INSUFFICIENT_STOCK.'})
@ApiResponse({status:422,description:'WALKIN_MUST_BE_PAID, PAID_EXCEEDS_TOTAL or IDEMPOTENCY_MISMATCH.'})
export class SalesController {
  constructor(private readonly service:SalesService){}
  @Post() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:SaleResponse})
  complete(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Body() body:CompleteSaleInput){return this.service.complete(r.session.userId,key,body);}
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SaleList})
  list(@Req() r:Auth,@Query() q:SaleQuery){return this.service.list(r.session.userId,q);}
  @Get(':id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:SaleResponse})
  get(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string){return this.service.get(r.session.userId,id);}
}
