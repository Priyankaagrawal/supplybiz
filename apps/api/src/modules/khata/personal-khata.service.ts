import { BadRequestException,ConflictException,Injectable,NotFoundException } from '@nestjs/common';
import { dateOnly,dayString } from '../subscriptions/subscription-policy';
import { KhataAccess,KhataTx,khataAmount,khataMonth,khataUnavailable } from './khata-access.service';
import { KhataPage,PersonalContactInput,PersonalContactPatch,PersonalEntryInput,PersonalEntryPatch,PersonalEntryQuery } from './khata.dto';
@Injectable()
export class PersonalKhataService {
  constructor(private readonly access:KhataAccess){}
  getContact(userId:string,id:string){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');const row=await this.contact(tx,userId,id);
    const [sum]=await tx.$queryRaw<{balance:string}[]>`SELECT COALESCE(SUM(CASE WHEN direction='GAVE' THEN amount_paise::numeric ELSE -amount_paise::numeric END),0)::text AS balance FROM personal_entries WHERE contact_id=${id}::uuid AND deleted_at IS NULL`;
    return {id:row.id,version:row.version,name:row.name,mobile:row.mobile,balancePaise:sum!.balance};
  },{isolationLevel:'RepeatableRead'}).catch(khataUnavailable);}
  getEntry(userId:string,id:string){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');const row=await this.entry(tx,userId,id);return {id:row.id,version:row.version,contactId:row.contact_id,direction:row.direction,amountPaise:String(row.amount_paise),date:dayString(row.date),note:row.note};
  }).catch(khataUnavailable);}
  private async contact(tx:KhataTx,userId:string,id:string){const row=await tx.personal_contacts.findFirst({where:{id,user_id:userId,deleted_at:null}});if(!row)throw new NotFoundException({code:'PERSONAL_CONTACT_NOT_FOUND'});return row;}
  private async entry(tx:KhataTx,userId:string,id:string){const row=await tx.personal_entries.findFirst({where:{id,user_id:userId,deleted_at:null,contact:{deleted_at:null,user_id:userId}}});if(!row)throw new NotFoundException({code:'PERSONAL_ENTRY_NOT_FOUND'});return row;}
  private async audit(tx:KhataTx,userId:string,kind:string,id:string,version:number,deleted=false){await tx.audit_logs.create({data:{actor_type:'USER',actor_id:userId,action:`PERSONAL_${kind}_CHANGED`,entity:`PERSONAL_${kind}`,entity_id:id,after:{version,deleted}}});}
  contacts(userId:string,q:KhataPage){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');const rows=await tx.personal_contacts.findMany({where:{user_id:userId,deleted_at:null},orderBy:[{name:'asc'},{id:'asc'}],take:q.limit??20,skip:q.offset??0});
    const items=[];for(const row of rows){const [sum]=await tx.$queryRaw<{balance:string}[]>`SELECT COALESCE(SUM(CASE WHEN direction='GAVE' THEN amount_paise::numeric ELSE -amount_paise::numeric END),0)::text AS balance FROM personal_entries WHERE contact_id=${row.id}::uuid AND deleted_at IS NULL`;
      items.push({id:row.id,version:row.version,name:row.name,mobile:row.mobile,balancePaise:sum!.balance});}
    return {items,total:await tx.personal_contacts.count({where:{user_id:userId,deleted_at:null}})};
  },{isolationLevel:'RepeatableRead'}).catch(khataUnavailable);}
  createContact(userId:string,key:string,input:PersonalContactInput){return this.access.mutate(userId,'CUSTOMER',key,'POST personal-contact',input,async tx=>{
    const name=input.name.trim();if(!name)throw new BadRequestException({code:'CONTACT_NAME_REQUIRED'});
    const row=await tx.personal_contacts.create({data:{user_id:userId,name,mobile:input.mobile}});await this.audit(tx,userId,'CONTACT',row.id,1);return {id:row.id,version:1,deleted:false};
  });}
  patchContact(userId:string,key:string,id:string,input:PersonalContactPatch){return this.access.mutate(userId,'CUSTOMER',key,`PATCH personal-contact/${id}`,input,async tx=>{
    const row=await this.contact(tx,userId,id);if(row.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});
    if(input.name===undefined&&input.mobile===undefined&&!input.clearMobile)throw new BadRequestException({code:'EMPTY_PATCH'});
    if(input.name!==undefined&&!input.name.trim()||input.clearMobile===false||input.clearMobile&&input.mobile!=null)throw new BadRequestException({code:'INVALID_CONTACT_PATCH'});
    const result=await tx.personal_contacts.update({where:{id},data:{name:input.name?.trim(),mobile:input.clearMobile?null:input.mobile,version:{increment:1}}});await this.audit(tx,userId,'CONTACT',id,result.version);return {id,version:result.version,deleted:false};
  });}
  deleteContact(userId:string,key:string,id:string,input:{version:number}){return this.access.mutate(userId,'CUSTOMER',key,`DELETE personal-contact/${id}`,input,async tx=>{
    const row=await this.contact(tx,userId,id);if(row.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});
    await tx.personal_contacts.update({where:{id},data:{deleted_at:new Date(),version:{increment:1}}});await this.audit(tx,userId,'CONTACT',id,row.version+1,true);return {id,version:row.version+1,deleted:true};
  });}
  entries(userId:string,q:PersonalEntryQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');if(q.contactId)await this.contact(tx,userId,q.contactId);
    const range=q.month?khataMonth(q.month):null,where={user_id:userId,deleted_at:null,contact:{user_id:userId,deleted_at:null},...(q.contactId?{contact_id:q.contactId}:{}),...(range?{date:{gte:range.from,lt:range.to}}:{})};
    const rows=await tx.personal_entries.findMany({where,orderBy:[{date:'desc'},{created_at:'desc'},{id:'desc'}],take:q.limit??20,skip:q.offset??0});
    return {items:rows.map(r=>({id:r.id,version:r.version,contactId:r.contact_id,direction:r.direction,amountPaise:String(r.amount_paise),date:dayString(r.date),note:r.note})),total:await tx.personal_entries.count({where})};
  },{isolationLevel:'RepeatableRead'}).catch(khataUnavailable);}
  createEntry(userId:string,key:string,input:PersonalEntryInput){return this.access.mutate(userId,'CUSTOMER',key,'POST personal-entry',input,async tx=>{
    await this.contact(tx,userId,input.contactId);const row=await tx.personal_entries.create({data:{user_id:userId,contact_id:input.contactId,direction:input.direction,amount_paise:khataAmount(input.amountPaise),date:dateOnly(input.date),note:input.note?.trim()??''}});
    await this.audit(tx,userId,'ENTRY',row.id,1);return {id:row.id,version:1,deleted:false};
  });}
  patchEntry(userId:string,key:string,id:string,input:PersonalEntryPatch){return this.access.mutate(userId,'CUSTOMER',key,`PATCH personal-entry/${id}`,input,async tx=>{
    const row=await this.entry(tx,userId,id);if(row.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});if(Object.keys(input).length===1)throw new BadRequestException({code:'EMPTY_PATCH'});
    if(input.contactId)await this.contact(tx,userId,input.contactId);
    const result=await tx.personal_entries.update({where:{id},data:{contact_id:input.contactId,direction:input.direction,amount_paise:input.amountPaise===undefined?undefined:khataAmount(input.amountPaise),date:input.date===undefined?undefined:dateOnly(input.date),note:input.note?.trim(),version:{increment:1}}});
    await this.audit(tx,userId,'ENTRY',id,result.version);return {id,version:result.version,deleted:false};
  });}
  deleteEntry(userId:string,key:string,id:string,input:{version:number}){return this.access.mutate(userId,'CUSTOMER',key,`DELETE personal-entry/${id}`,input,async tx=>{
    const row=await this.entry(tx,userId,id);if(row.version!==input.version)throw new ConflictException({code:'VERSION_CONFLICT'});await tx.personal_entries.update({where:{id},data:{deleted_at:new Date(),version:{increment:1}}});await this.audit(tx,userId,'ENTRY',id,row.version+1,true);return {id,version:row.version+1,deleted:true};
  });}
}
