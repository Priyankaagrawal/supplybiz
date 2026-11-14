import { Body, Controller, Get, Header, Headers, Post, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { PaymentList, PaymentQuery, PaymentRecord, PaymentSummary, RecordPaymentInput } from './payments.dto';
import { PaymentsService } from './payments.service';
type AuthRequest=Request & {session:{userId:string}};
@ApiTags('vendor-payments') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor/payments')
@ApiResponse({status:400,description:'Invalid exact positive amount, received date, pagination or idempotency key.'})
@ApiResponse({status:401,description:'Missing/revoked session.'})
@ApiResponse({status:403,description:'Vendor role/suspension or plan permission denial.'})
@ApiResponse({status:404,description:'Owned customer not found.'})
@ApiResponse({status:422,description:'IDEMPOTENCY_MISMATCH.'})
@ApiResponse({status:503,description:'Ledger grants unavailable or redacted transactional failure; no partial receipt/credit.'})
export class PaymentsController {
  constructor(private readonly payments:PaymentsService) {}
  @Post() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:PaymentRecord})
  record(@Req() r:AuthRequest,@Headers('Idempotency-Key') key:string,@Body() input:RecordPaymentInput) {return this.payments.record(r.session.userId,key,input);}
  @Get('summary') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PaymentSummary})
  summary(@Req() r:AuthRequest) {return this.payments.summary(r.session.userId);}
  @Get() @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PaymentList})
  list(@Req() r:AuthRequest,@Query() q:PaymentQuery) {return this.payments.list(r.session.userId,q);}
}
