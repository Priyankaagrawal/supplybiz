// Bounded retention. Amounts, balances and immutable financial identities never change.
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
@Injectable()
export class ExpiredRetentionService {
 constructor(private readonly db:PrismaService){}
 async runFinancialBatch(){
  const saved=await this.db.app_config.findUnique({where:{key:'privacy:financial-cursor'}});
  const cursor=saved?.value&&typeof saved.value==='object'&&!Array.isArray(saved.value)&&typeof saved.value.id==='string'?saved.value.id:undefined;
  const subjects=await this.db.account_deletions.findMany({where:{status:'ERASED',retention_hold_reason:null,...(cursor?{id:{gt:cursor}}:{})},orderBy:{id:'asc'},take:100});
  let changed=0;
  for(const subject of subjects)changed+=await this.db.$transaction(async tx=>{
   await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${subject.user_id},0))::text`;
   await tx.$queryRaw`SELECT id FROM account_deletions WHERE id=${subject.id}::uuid FOR UPDATE`;
   const current=await tx.account_deletions.findUniqueOrThrow({where:{id:subject.id}});
   if(current.status!=='ERASED'||current.retention_hold_reason)return 0;
   await tx.$queryRaw`SELECT set_config('supplybiz.financial_erasure',${subject.user_id},true)`;
   const [clock]=await tx.$queryRaw<{cutoff:Date;day:Date}[]>`SELECT privacy_financial_cutoff() AS cutoff,(privacy_financial_cutoff() AT TIME ZONE 'Asia/Kolkata')::date AS day`;
   const vendor=await tx.vendors.findUnique({where:{user_id:subject.user_id},select:{id:true}}),links=await tx.vendor_customers.findMany({where:{user_id:subject.user_id},select:{id:true}});
   const scope={OR:[{vendor_customer_id:{in:links.map(r=>r.id)}},...(vendor?[{vendor_id:vendor.id}]:[])]};
   let immutableChanges=0;
   const old=await tx.ledger_entries.findMany({where:{...scope,created_at:{lt:clock!.cutoff},entry_date:{lt:clock!.day},note:{notIn:['','Expired retained record']}},take:100,orderBy:{id:'asc'},select:{id:true}});
   for(const row of old){const [result]=await tx.$queryRaw<{changed:number}[]>`SELECT privacy_redact_ledger(${row.id}::uuid,${subject.user_id}::uuid) AS changed`;immutableChanges+=result!.changed;}
   const payments=await tx.payments.findMany({where:{...scope,created_at:{lt:clock!.cutoff},received_on:{lt:clock!.day},OR:scope.OR,note:{not:''}},take:100,orderBy:{id:'asc'},select:{id:true}});
   for(const row of payments){const [result]=await tx.$queryRaw<{changed:number}[]>`SELECT privacy_redact_payment(${row.id}::uuid,${subject.user_id}::uuid) AS changed`;immutableChanges+=result!.changed;}
   const orderWhere:Prisma.ordersWhereInput={...scope,created_at:{lt:clock!.cutoff},delivery_date:{lt:clock!.day},OR:scope.OR,timeline:{none:{at:{gte:clock!.cutoff}}},AND:[{OR:[{completed_at:null},{completed_at:{lt:clock!.cutoff}}]},{OR:[{address_snapshot:{not:{}}},{cancel_reason:{not:null}},{reject_reason:{not:null}},{fail_reason:{not:null}}]}]};
   const orders=await tx.orders.findMany({where:orderWhere,take:100,orderBy:{id:'asc'},select:{id:true}});
   let orderChanges=0;
   for(const row of orders){await tx.$queryRaw`SELECT id FROM orders WHERE id=${row.id}::uuid FOR UPDATE`;if(await tx.orders.findFirst({where:{...orderWhere,id:row.id},select:{id:true}})){await tx.orders.update({where:{id:row.id},data:{address_snapshot:{},cancel_reason:null,reject_reason:null,fail_reason:null}});orderChanges++;}}
   const subscriptionWhere:Prisma.subscriptionsWhereInput={...scope,created_at:{lt:clock!.cutoff},revisions:{none:{created_at:{gte:clock!.cutoff}}},address_snapshot:{not:{}}};
   const subscriptions=await tx.subscriptions.findMany({where:subscriptionWhere,take:100,select:{id:true}});
   let subscriptionChanges=0;
   for(const row of subscriptions){await tx.$queryRaw`SELECT id FROM subscriptions WHERE id=${row.id}::uuid FOR UPDATE`;if(await tx.subscriptions.findFirst({where:{...subscriptionWhere,id:row.id},select:{id:true}})){await tx.subscriptions.update({where:{id:row.id},data:{address_snapshot:{}}});subscriptionChanges++;}}
   const claims=await tx.payment_claims.findMany({where:{customer:{OR:[{user_id:subject.user_id},...(vendor?[{vendor_id:vendor.id}]:[])]},created_at:{lt:clock!.cutoff},AND:[{OR:[{decided_at:null},{decided_at:{lt:clock!.cutoff}}]},{OR:[{upi_txn_ref:{not:null}},{reject_reason:{not:null,notIn:['Expired retained record']}}]}]},take:100,select:{id:true}});
   for(const row of claims){const [result]=await tx.$queryRaw<{changed:number}[]>`SELECT privacy_redact_claim(${row.id}::uuid,${subject.user_id}::uuid) AS changed`;immutableChanges+=result!.changed;}
   const entries=await tx.personal_entries.findMany({where:{user_id:subject.user_id,created_at:{lt:clock!.cutoff},date:{lt:clock!.day},note:{not:''}},take:100,select:{id:true}});
   for(const row of entries)await tx.personal_entries.update({where:{id:row.id},data:{note:''}});
   const contacts=await tx.personal_contacts.findMany({where:{user_id:subject.user_id,created_at:{lt:clock!.cutoff},entries:{none:{OR:[{created_at:{gte:clock!.cutoff}},{date:{gte:clock!.day}}]}},OR:[{name:{not:'Deleted contact'}},{mobile:{not:null}}]},take:100,select:{id:true}});
   for(const row of contacts)await tx.personal_contacts.update({where:{id:row.id},data:{name:'Deleted contact',mobile:null}});
   const customerWhere:Prisma.vendor_customersWhereInput={OR:[{user_id:subject.user_id},...(vendor?[{vendor_id:vendor.id}]:[])],created_at:{lt:clock!.cutoff},privacy_erased_at:null,orders:{none:{OR:[{created_at:{gte:clock!.cutoff}},{completed_at:{gte:clock!.cutoff}},{delivery_date:{gte:clock!.day}}]}},sales:{none:{OR:[{created_at:{gte:clock!.cutoff}},{sale_date:{gte:clock!.day}}]}},payments:{none:{OR:[{created_at:{gte:clock!.cutoff}},{received_on:{gte:clock!.day}}]}},ledger_entries:{none:{OR:[{created_at:{gte:clock!.cutoff}},{entry_date:{gte:clock!.day}}]}},payment_claims:{none:{OR:[{created_at:{gte:clock!.cutoff}},{decided_at:{gte:clock!.cutoff}}]}},subscriptions:{none:{OR:[{created_at:{gte:clock!.cutoff}},{revisions:{some:{created_at:{gte:clock!.cutoff}}}}]}}};
   const customers=await tx.vendor_customers.findMany({where:customerWhere,take:100,select:{id:true}});
   let customerChanges=0;
   for(const row of customers){await tx.$queryRaw`SELECT id FROM vendor_customers WHERE id=${row.id}::uuid FOR UPDATE`;if(await tx.vendor_customers.findFirst({where:{...customerWhere,id:row.id},select:{id:true}})){await tx.vendor_customers.update({where:{id:row.id},data:{name:'Deleted account',mobile:'',email:null,address_text:'',status:'INACTIVE',privacy_erased_at:new Date()}});customerChanges++;}}
   const count=immutableChanges+orderChanges+subscriptionChanges+entries.length+contacts.length+customerChanges;
   if(count)await tx.audit_logs.create({data:{actor_type:'SYSTEM',action:'FINANCIAL_PERSONAL_DATA_EXPIRED',entity:'account_deletions',entity_id:subject.id,after:{redacted:count,cutoff:clock!.cutoff.toISOString()}}});
   return count;
  },{timeout:15000});
  await this.db.app_config.upsert({where:{key:'privacy:financial-cursor'},create:{key:'privacy:financial-cursor',value:subjects.length?{id:subjects[subjects.length-1]!.id}:{}},update:{value:subjects.length?{id:subjects[subjects.length-1]!.id}:{}}});
  return changed;
 }
 async runAuditBatch(){
  return this.db.$transaction(async tx=>{
   const [row]=await tx.$queryRaw<{removed:number;minimized:number}[]>`SELECT * FROM privacy_expire_audits()`;
   const [sources]=await tx.$queryRaw<{count:number}[]>`SELECT privacy_expire_sources() AS count`;
   return (row?.removed??0)+(row?.minimized??0)+(sources?.count??0);
  },{timeout:15000});
 }
}
