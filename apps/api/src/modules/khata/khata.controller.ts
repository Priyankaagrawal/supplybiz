import { Body,Controller,Delete,Get,Header,Headers,Param,ParseUUIDPipe,Patch,Post,Query,Req,SetMetadata,UseGuards } from '@nestjs/common';
import { ApiBearerAuth,ApiHeader,ApiResponse,ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { KhataReadService } from './khata-read.service';
import { PersonalKhataService } from './personal-khata.service';
import { PaymentClaimsService } from './payment-claims.service';
import { PaymentDetailsService } from './payment-details.service';
import { CustomerSettlementOptions,PaymentPublicationAck,PaymentPublicationInput,VendorPaymentDetails,PersonalContactRecord,PersonalEntryRecord } from './khata.dto';
import { ClaimMutation,ClaimQuery,ClaimRejection,KhataMonthQuery,KhataPage,KhataSummary,KhataSummaryQuery,KhataVendorEntries,KhataVersion,PaymentClaimInput,PaymentClaimList,PersonalContactInput,PersonalContactList,PersonalContactPatch,PersonalEntryInput,PersonalEntryList,PersonalEntryPatch,PersonalEntryQuery,PersonalMutation } from './khata.dto';
type Auth=Request & {session:{userId:string}};
@ApiTags('customer-khata') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('customer')
export class CustomerKhataController {
  constructor(private readonly reads:KhataReadService,private readonly personal:PersonalKhataService,private readonly claims:PaymentClaimsService,private readonly details:PaymentDetailsService){}
  @Get('khata/vendors/:id/settlement-options') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:CustomerSettlementOptions})
  options(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string){return this.details.customer(r.session.userId,id);}
  @Get('khata/summary') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:KhataSummary})
  summary(@Req() r:Auth,@Query() q:KhataSummaryQuery){return this.reads.summary(r.session.userId,q);}
  @Get('khata/vendors/:id/entries') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:KhataVendorEntries})
  entries(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Query() q:KhataMonthQuery){return this.reads.customerEntries(r.session.userId,id,q);}
  @Get('khata/vendors/:id/claims') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PaymentClaimList})
  claimList(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Query() q:ClaimQuery){return this.claims.customerList(r.session.userId,id,q);}
  @Post('khata/vendors/:id/claims') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:ClaimMutation})
  claim(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:PaymentClaimInput){return this.claims.create(r.session.userId,id,key,body);}
  @Get('personal-contacts') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PersonalContactList})
  contacts(@Req() r:Auth,@Query() q:KhataPage){return this.personal.contacts(r.session.userId,q);}
  @Get('personal-contacts/:id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PersonalContactRecord})
  contactGet(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string){return this.personal.getContact(r.session.userId,id);}
  @Post('personal-contacts') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:PersonalMutation})
  contactCreate(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Body() body:PersonalContactInput){return this.personal.createContact(r.session.userId,key,body);}
  @Patch('personal-contacts/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:PersonalMutation})
  contactPatch(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:PersonalContactPatch){return this.personal.patchContact(r.session.userId,key,id,body);}
  @Delete('personal-contacts/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:PersonalMutation})
  contactDelete(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:KhataVersion){return this.personal.deleteContact(r.session.userId,key,id,body);}
  @Get('personal-entries') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PersonalEntryList})
  personalEntries(@Req() r:Auth,@Query() q:PersonalEntryQuery){return this.personal.entries(r.session.userId,q);}
  @Get('personal-entries/:id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PersonalEntryRecord})
  entryGet(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string){return this.personal.getEntry(r.session.userId,id);}
  @Post('personal-entries') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:PersonalMutation})
  entryCreate(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Body() body:PersonalEntryInput){return this.personal.createEntry(r.session.userId,key,body);}
  @Patch('personal-entries/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:PersonalMutation})
  entryPatch(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:PersonalEntryPatch){return this.personal.patchEntry(r.session.userId,key,id,body);}
  @Delete('personal-entries/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:PersonalMutation})
  entryDelete(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:KhataVersion){return this.personal.deleteEntry(r.session.userId,key,id,body);}
}
@ApiTags('vendor-khata') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('vendor')
export class VendorKhataController {
  constructor(private readonly reads:KhataReadService,private readonly claims:PaymentClaimsService,private readonly details:PaymentDetailsService){}
  @Get('khata/payment-details') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:VendorPaymentDetails})
  detailsGet(@Req() r:Auth){return this.details.vendor(r.session.userId);}
  @Patch('khata/payment-details') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:PaymentPublicationAck})
  detailsPublish(@Req() r:Auth,@Headers('Idempotency-Key') key:string,@Body() body:PaymentPublicationInput){return this.details.publish(r.session.userId,key,body);}
  @Get('khata/:id/entries') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:KhataVendorEntries})
  entries(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Query() q:KhataMonthQuery){return this.reads.vendorEntries(r.session.userId,id,q);}
  @Get('payment-claims') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:PaymentClaimList})
  list(@Req() r:Auth,@Query() q:ClaimQuery){return this.claims.vendorList(r.session.userId,q);}
  @Post('payment-claims/:id/confirm') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:ClaimMutation})
  confirm(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:KhataVersion){return this.claims.decide(r.session.userId,id,key,body,true);}
  @Post('payment-claims/:id/reject') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:201,type:ClaimMutation})
  reject(@Req() r:Auth,@Param('id',ParseUUIDPipe) id:string,@Headers('Idempotency-Key') key:string,@Body() body:ClaimRejection){return this.claims.decide(r.session.userId,id,key,body,false);}
}
