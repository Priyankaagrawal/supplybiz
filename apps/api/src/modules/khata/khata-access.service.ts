import { BadRequestException,ForbiddenException,HttpException,Injectable,NotFoundException,ServiceUnavailableException,UnprocessableEntityException } from '@nestjs/common';
import { Prisma,user_role_type } from '@prisma/client';
import { createHash } from 'node:crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { IdempotencyService } from '../idempotency/idempotency.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
export type KhataTx=Prisma.TransactionClient;
export function khataUnavailable(error:unknown):never{if(error instanceof HttpException)throw error;throw new ServiceUnavailableException({code:'KHATA_UNAVAILABLE'});}
export function khataAmount(value:string){const amount=BigInt(value);if(amount<=0n||amount>9223372036854775807n)throw new BadRequestException({code:'INVALID_AMOUNT'});return amount;}
export function khataMonth(month:string){
  if(!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)||Number(month.slice(0,4))<1)throw new BadRequestException({code:'INVALID_MONTH'});
  const from=new Date(`${month}-01T00:00:00Z`),to=new Date(from);to.setUTCMonth(to.getUTCMonth()+1);return {from,to};
}
@Injectable()
export class KhataAccess {
  constructor(readonly db:PrismaService,private readonly keys:IdempotencyService,private readonly plans:PlanEntitlementsService){}
  async actor(tx:KhataTx,id:string,role:user_role_type,write=false){
    if(write)await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${id},0))::text`;
    const user=await tx.users.findUnique({where:{id},include:{roles:true}});
    if(!user||user.status!=='ACTIVE'||user.active_role!==role||!user.roles.some(r=>r.role===role))throw new ForbiddenException({code:`${role}_ROLE_REQUIRED`});return user;
  }
  async vendor(tx:KhataTx,userId:string){
    const v=await tx.vendors.findUnique({where:{user_id:userId}});if(!v)throw new NotFoundException({code:'VENDOR_NOT_FOUND'});
    await tx.$queryRaw`SELECT id FROM vendors WHERE id=${v.id}::uuid FOR UPDATE`;await this.plans.requireOperation(tx,v.id,'READ_HISTORY');return v;
  }
  mutate(userId:string,role:user_role_type,key:string,path:string,input:object,write:(tx:KhataTx)=>Promise<object>){
    if(typeof key!=='string'||!key.trim()||key.length>120)throw new BadRequestException({code:'INVALID_IDEMPOTENCY_KEY'});
    const requestKey=createHash('sha256').update(`${role}:${userId}:${key}`).digest('hex'),hash=this.keys.hashRequestBody(input);
    return this.db.$transaction(async tx=>{
      await this.actor(tx,userId,role,true);if(role==='VENDOR')await this.vendor(tx,userId);
      const prior=await tx.khata_requests.findUnique({where:{request_key:requestKey}});
      if(prior){if(prior.path!==path||prior.request_hash!==hash)throw new UnprocessableEntityException({code:'IDEMPOTENCY_MISMATCH'});return prior.response;}
      const result=await write(tx);await tx.khata_requests.create({data:{request_key:requestKey,user_id:userId,path,request_hash:hash,response:result as Prisma.InputJsonObject}});return result;
    },{timeout:30000}).catch(khataUnavailable);
  }
}
