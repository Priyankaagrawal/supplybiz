import { Controller, Delete, Get, Header, Headers, Param, ParseUUIDPipe, Put, Query, Req, SetMetadata, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { NO_IDEMPOTENCY_CACHE } from '../../common/idempotency.constants';
import { SessionGuard } from '../auth/sessions.controller';
import { ProductList } from '../catalog/catalog.dto';
import { DiscoveryPage, DiscoveryQuery, FavoriteResult, VendorAbout } from './discovery.dto';
import { DiscoveryService } from './discovery.service';
type AuthRequest = Request & {session:{userId:string}};
@ApiTags('discovery') @ApiBearerAuth() @UseGuards(SessionGuard)
@SetMetadata(NO_IDEMPOTENCY_CACHE,true) @Controller('customer')
@ApiResponse({status:400,description:'Invalid coordinates/pincode/cursor or missing mutation key.'})
@ApiResponse({status:403,description:'CUSTOMER_ROLE_REQUIRED.'})
@ApiResponse({status:404,description:'VENDOR_UNAVAILABLE or PRODUCT_NOT_FOUND.'})
export class DiscoveryController {
  constructor(private readonly discovery:DiscoveryService) {}
  @Get('vendors') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:DiscoveryPage})
  list(@Req() r:AuthRequest,@Query() q:DiscoveryQuery) { return this.discovery.list(r.session.userId,q); }
  @Get('search') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:DiscoveryPage,description:'Matches eligible vendor names or active product names.'})
  search(@Req() r:AuthRequest,@Query() q:DiscoveryQuery) { return this.discovery.list(r.session.userId,q); }
  @Get('favorites') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:DiscoveryPage})
  favorites(@Req() r:AuthRequest,@Query() q:DiscoveryQuery) { return this.discovery.list(r.session.userId,q,true); }
  @Get('vendors/:id') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:VendorAbout})
  about(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Query() q:DiscoveryQuery) { return this.discovery.about(r.session.userId,id,q); }
  @Get('vendors/:id/products') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:ProductList})
  products(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Query() q:DiscoveryQuery) { return this.discovery.products(r.session.userId,id,q); }
  @Get('vendors/:id/products/:productId') @Header('Cache-Control','no-store') @ApiResponse({status:200,type:ProductList})
  product(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Param('productId',ParseUUIDPipe) product:string,@Query() q:DiscoveryQuery) { return this.discovery.products(r.session.userId,id,q,product); }
  @Get('vendors/:id/media/:mediaId/content') @Header('Cache-Control','no-store') @Header('X-Content-Type-Options','nosniff')
  @ApiResponse({status:200,schema:{type:'string',format:'binary'}})
  image(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Param('mediaId',ParseUUIDPipe) media:string,@Query() q:DiscoveryQuery) { return this.discovery.image(r.session.userId,id,media,q); }
  @Put('favorites/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:FavoriteResult})
  add(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Query() q:DiscoveryQuery,@Headers('Idempotency-Key') key:string) { return this.discovery.favorite(r.session.userId,id,true,q,key); }
  @Delete('favorites/:id') @Header('Cache-Control','no-store') @ApiHeader({name:'Idempotency-Key',required:true}) @ApiResponse({status:200,type:FavoriteResult})
  remove(@Req() r:AuthRequest,@Param('id',ParseUUIDPipe) id:string,@Query() q:DiscoveryQuery,@Headers('Idempotency-Key') key:string) { return this.discovery.favorite(r.session.userId,id,false,q,key); }
}
