// T-019: bounded crash-safe personal erasure. Financial/audit retention is T-161.
import { Injectable } from '@nestjs/common';
import { unlink } from 'node:fs/promises';
import { join } from 'node:path';
import { PrismaService } from '../../prisma/prisma.service';
import { LocalStorageService } from '../../storage/local-storage.service';
@Injectable()
export class PersonalErasureService {
 constructor(private readonly db:PrismaService,private readonly storage:LocalStorageService){}
 async runBatch():Promise<number> {
  // Start a day before the 30-day deadline, leaving room for transient retries.
  const work=await this.db.account_deletions.findMany({where:{OR:[{status:'ERASING'},{status:'PENDING_ERASURE',erase_by:{lte:new Date(Date.now()+86400000)}}]},orderBy:[{erase_by:'asc'},{id:'asc'}],take:10});
  let failure:unknown;
  for(const item of work)await this.db.$transaction(async tx=>{
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${item.user_id},0))::text`;
   await tx.$queryRaw`SELECT id FROM account_deletions WHERE id=${item.id}::uuid FOR UPDATE`;
   const current=await tx.account_deletions.findUniqueOrThrow({where:{id:item.id}});
   const user=await tx.users.findUniqueOrThrow({where:{id:item.user_id}});
   if(user.status!=='DELETED'||current.hold_reason||!['PENDING_ERASURE','ERASING'].includes(current.status)||current.erase_by.getTime()>Date.now()+86400000)return;
   if(current.status==='ERASING')return;
   await tx.account_deletions.update({where:{id:item.id},data:{status:'ERASING'}});
   await tx.$queryRaw`SELECT set_config('supplybiz.retention_user',${item.user_id},true)`;
   const vendor=await tx.vendors.findUnique({where:{user_id:item.user_id}});
   if(vendor){
    await tx.vendor_kyc.updateMany({where:{vendor_id:vendor.id},data:{business_name:null,pan_enc:'',pan_last4:'',account_number_enc:'',account_last4:'',holder_name:'Deleted account',bank_name:'',ifsc:'',upi_id:null}});
    await tx.vendors.update({where:{id:vendor.id},data:{business_name:'Deleted account',gstin:null,address_line:null,city:null,state:null,pincode:null,latitude:null,longitude:null,shop_photo_media_id:null}});
    await tx.vendor_settings.updateMany({where:{vendor_id:vendor.id},data:{payment_upi_id:null}});
    await tx.vendor_service_pincodes.deleteMany({where:{vendor_id:vendor.id}});
   }
   await tx.users.update({where:{id:item.user_id},data:{mobile:`deleted:${item.user_id}`,name:null,email:null,photo_media_id:null}});
   await tx.addresses.deleteMany({where:{user_id:item.user_id}});
   await tx.favorites.deleteMany({where:{user_id:item.user_id}});
   await tx.user_preferences.deleteMany({where:{user_id:item.user_id}});
   await tx.devices.updateMany({where:{user_id:item.user_id},data:{push_token:null,push_enabled:false,app_version:null,os_version:null}});
   await tx.consents.updateMany({where:{user_id:item.user_id},data:{ip:null}});
   await tx.media_files.updateMany({where:{owner_user_id:item.user_id,status:'READY'},data:{status:'ERASING'}});
   await tx.audit_logs.create({data:{actor_type:'SYSTEM',action:'ACCOUNT_PERSONAL_ERASURE_STARTED',entity:'account_deletions',entity_id:item.id}});
  },{timeout:15000}).catch((error:unknown)=>{failure??=error;});
  for(const item of work)await this.files(item.id,item.user_id).catch((error:unknown)=>{failure??=error;});
  if(failure)throw failure;
  return work.length;
 }
 private async files(id:string,userId:string) {
  await this.db.$transaction(async tx=>{
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId},0))::text`;
   await tx.$queryRaw`SELECT id FROM account_deletions WHERE id=${id}::uuid FOR UPDATE`;
   const row=await tx.account_deletions.findUniqueOrThrow({where:{id}});
   if(row.status!=='ERASING'||row.hold_reason)return;
   const media=await tx.media_files.findMany({where:{owner_user_id:userId,status:'ERASING'},take:50,orderBy:{id:'asc'}});
   if(media.length)await this.storage.check();
   for(const file of media){
    if(!/^(media|kyc)\/[a-f0-9-]{36}\.(jpg|png|pdf)$/.test(file.relative_storage_key))throw new Error('Invalid retention media key');
    await unlink(join(this.storage.root,file.relative_storage_key)).catch((e:NodeJS.ErrnoException)=>{if(e.code!=='ENOENT')throw e;});
    await tx.media_files.update({where:{id:file.id},data:{status:'ERASED'}});
   }
   if(await tx.media_files.count({where:{owner_user_id:userId,status:{not:'ERASED'}}})===0){
    await tx.account_deletions.update({where:{id},data:{status:'ERASED',erased_at:new Date()}});
    await tx.audit_logs.create({data:{actor_type:'SYSTEM',action:'ACCOUNT_PERSONAL_ERASED',entity:'account_deletions',entity_id:id}});
   }
  },{timeout:15000});
 }
}
