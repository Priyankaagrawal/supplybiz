// T-126 / FR-290. Owner-only profile; phone, roles, identity and status are immutable here.
import { BadRequestException, Body, ConflictException, Controller, ForbiddenException, Get, Header, Headers, HttpException, Injectable, NotFoundException, Put, Req, ServiceUnavailableException, SetMetadata, UnprocessableEntityException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOkResponse, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsString, IsUUID, Length, Matches, ValidateIf } from 'class-validator';
import { Transform } from 'class-transformer';
import { createHash } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { Request } from 'express';
import { PrismaService } from '../../prisma/prisma.service';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { IdempotencyService } from '../idempotency/idempotency.service';
export class ProfileInput {
 @ApiProperty() @IsString() @Length(1,40) expectedUpdatedAt!: string;
 @ApiProperty() @Transform(({value}:{value:unknown})=>typeof value==='string'?value.trim():value) @IsString() @Length(1,120) @Matches(/\S/) name!: string;
 @ApiProperty({type:String,nullable:true,description:'Contact email only; not verified by this operation.'}) @ValidateIf((_o,v:unknown)=>v!==null) @IsEmail() @Length(1,254) email!: string|null;
 @ApiProperty({type:String,format:'uuid',nullable:true}) @ValidateIf((_o,v:unknown)=>v!==null) @IsUUID() photoMediaId!: string|null;
}
export class ProfileResponse {
 @ApiProperty({format:'uuid'}) id!: string;
 @ApiProperty({description:'Read-only authenticated mobile.'}) mobile!: string;
 @ApiProperty({type:String,nullable:true}) name!: string|null;
 @ApiProperty({type:String,nullable:true}) email!: string|null;
 @ApiProperty({type:String,format:'uuid',nullable:true}) photoMediaId!: string|null;
 @ApiProperty({format:'date-time'}) updatedAt!: string;
}
@Injectable()
export class ProfileService {
 constructor(private readonly db:PrismaService,private readonly keys:IdempotencyService){}
 private async user(tx:Prisma.TransactionClient,id:string){
  await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${id},0))::text`;
  const user=await tx.users.findUnique({where:{id}});
  if(!user||user.status!=='ACTIVE')throw new ForbiddenException({code:'ACCOUNT_BLOCKED'});
  return user;
 }
 private present(row:{id:string;mobile:string;name:string|null;email:string|null;photo_media_id:string|null;updated_at:Date}):ProfileResponse{
  return{id:row.id,mobile:row.mobile,name:row.name,email:row.email,photoMediaId:row.photo_media_id,updatedAt:row.updated_at.toISOString()};
 }
 get(id:string){return this.db.$transaction(async tx=>this.present(await this.user(tx,id)));}
 save(id:string,key:string,input:ProfileInput){
  if(!key?.trim()||key.length>120)throw new BadRequestException({code:'VALIDATION_FAILED'});
  const requestKey=`profile:${createHash('sha256').update(`${id}:${key}`).digest('hex')}`,hash=this.keys.hashRequestBody(input);
  return this.db.$transaction(async tx=>{
   const before=await this.user(tx,id),known=await tx.idempotency_keys.findUnique({where:{idempotency_key:requestKey}});
   if(known&&known.expires_at>new Date()){
    if(known.request_hash!==hash)throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});
    return known.response_body as unknown as ProfileResponse;
   }
   if(known)await tx.idempotency_keys.delete({where:{idempotency_key:requestKey}});
   if(before.updated_at.toISOString()!==input.expectedUpdatedAt)throw new ConflictException({code:'VERSION_CONFLICT'});
   if(input.photoMediaId&&!await tx.media_files.findFirst({where:{id:input.photoMediaId,owner_user_id:id,purpose:'PROFILE',status:'READY'}}))throw new NotFoundException({code:'MEDIA_NOT_FOUND'});
   const result=this.present(await tx.users.update({where:{id},data:{name:input.name,email:input.email,photo_media_id:input.photoMediaId,updated_at:new Date(Math.max(Date.now(),before.updated_at.getTime()+1))}}));
   await tx.audit_logs.create({data:{actor_type:'USER',actor_id:id,action:'PROFILE_UPDATED',entity:'USER',entity_id:id,after:{nameChanged:before.name!==input.name,emailChanged:before.email!==input.email,photoChanged:before.photo_media_id!==input.photoMediaId}}});
   await tx.idempotency_keys.create({data:{idempotency_key:requestKey,user_id:id,method:'PUT',path:'me/profile',request_hash:hash,response_status:200,response_body:result as unknown as Prisma.InputJsonObject,expires_at:new Date(Date.now()+86400000)}});
   return result;
  }).catch((e:unknown)=>{if(e instanceof HttpException)throw e;throw new ServiceUnavailableException({code:'PROFILE_UNAVAILABLE'});});
 }
}
type ActorRequest=Request&{session:{userId:string}};
@ApiTags('profile') @ApiBearerAuth() @UseGuards(SessionGuard) @SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('me/profile')
export class ProfileController {
 constructor(private readonly profile:ProfileService){}
 @Get() @Header('Cache-Control','no-store') @ApiOkResponse({type:ProfileResponse})
 get(@Req() req:ActorRequest){return this.profile.get(req.session.userId);}
 @Put() @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiOkResponse({type:ProfileResponse})
 save(@Req() req:ActorRequest,@Headers('Idempotency-Key') key:string,@Body() body:ProfileInput){return this.profile.save(req.session.userId,key,body);}
}
