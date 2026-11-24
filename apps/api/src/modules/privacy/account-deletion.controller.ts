import { Body, Controller, Get, Header, Headers, HttpCode, Post, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsBoolean, Matches } from 'class-validator';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { SendOtpResponse } from '../auth/otp.controller';
import { AccountDeletionService } from './account-deletion.service';
class ConfirmDeletionInput {
 @ApiProperty({pattern:'^\\d{6}$'}) @Matches(/^\d{6}$/) code!:string;
 @ApiProperty() @IsBoolean() acknowledgeReceivables!:boolean;
}
export class DeletionPreview {
 @ApiProperty({description:'Exact positive vendor receivables in paise; deletion does not settle dues.'}) outstandingReceivablesPaise!:string;
 @ApiProperty() vendor!:boolean;
}
export class DeletionReceipt {
 @ApiProperty() requestId!:string;
 @ApiProperty() requestedAt!:string;
 @ApiProperty() eraseBy!:string;
 @ApiProperty() status!:string;
}
type Actor=Request & {session:{userId:string;sessionId:string}};
@ApiTags('account-deletion') @ApiBearerAuth() @Controller('me/deletion') @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true)
export class AccountDeletionController {
 constructor(private readonly service:AccountDeletionService){}
 @Get() @Header('Cache-Control','no-store') @ApiOkResponse({type:DeletionPreview})
 preview(@Req() r:Actor){return this.service.preview(r.session.userId);}
 @Post('otp') @HttpCode(200) @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiHeader({name:'X-Device-Id',required:true}) @ApiOkResponse({type:SendOtpResponse})
 send(@Req() r:Actor,@Headers('X-Device-Id') device:string){return this.service.send(r.session.userId,r.session.sessionId,device,r.ip??'');}
 @Post() @HttpCode(200) @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiOkResponse({type:DeletionReceipt})
 confirm(@Req() r:Actor,@Headers('Idempotency-Key') key:string,@Body() input:ConfirmDeletionInput){return this.service.confirm(r.session.userId,r.session.sessionId,key,input.code,input.acknowledgeReceivables,r.ip);}
}
