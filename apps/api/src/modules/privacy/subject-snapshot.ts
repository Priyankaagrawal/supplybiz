// Explicit projection: never serialize whole Prisma records with future fields.
import { PayloadTooLargeException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
const LIMIT=1000;
async function bounded<T>(rows:Promise<T[]>){const result=await rows;if(result.length>LIMIT)throw new PayloadTooLargeException({code:'SUBJECT_EXPORT_TOO_LARGE'});return result;}
export async function subjectSnapshot(tx:Prisma.TransactionClient,userId:string,now:Date){
 const profile=await tx.users.findUniqueOrThrow({where:{id:userId},select:{id:true,mobile:true,name:true,email:true,language:true,status:true,created_at:true}});
 const roles=await tx.user_roles.findMany({where:{user_id:userId},select:{role:true}});
 const consents=await bounded(tx.consents.findMany({where:{user_id:userId},take:LIMIT+1,select:{doc_type:true,doc_version:true,accepted_at:true}}));
 const addresses=await bounded(tx.addresses.findMany({where:{user_id:userId},take:LIMIT+1,select:{id:true,label:true,line1:true,line2:true,landmark:true,city:true,state:true,pincode:true,latitude:true,longitude:true,deleted_at:true}}));
 const vendor=await tx.vendors.findUnique({where:{user_id:userId},select:{id:true,business_name:true,gstin:true,address_line:true,city:true,state:true,pincode:true,latitude:true,longitude:true,kyc_status:true,is_suspended:true,settings:{select:{payment_upi_id:true,service_radius_km:true,delivery_charge_paise:true,min_order_paise:true,time_slots:true,same_day_cutoff:true,auto_accept_subscriptions:true,subscription_delivery_available:true,subscription_delivery_start:true,subscription_delivery_end:true,pause_all_subscriptions:true,accepting_today:true,delivery_paused:true,delivery_paused_until:true,max_daily_orders:true,daily_milk_capacity_ml:true,low_stock_threshold:true,allow_khata_orders:true}}}});
 // Keep counterparties' identities outside a subject export, including a vendor's customers.
 const links=await bounded(tx.vendor_customers.findMany({where:{user_id:userId},take:LIMIT+1,select:{id:true,vendor_id:true,status:true}}));
 const scope={OR:[{vendor_customer_id:{in:links.map(r=>r.id)}},...(vendor?[{vendor_id:vendor.id}]:[])]};
 const orders=await bounded(tx.orders.findMany({where:scope,take:LIMIT+1,orderBy:{id:'asc'},select:{id:true,order_no:true,vendor_id:true,vendor_customer_id:true,status:true,delivery_date:true,total_paise:true,subtotal_paise:true,delivery_charge_paise:true,discount_paise:true,payment_mode:true,payment_status:true,created_at:true,completed_at:true}}));
 const orderItems=await bounded(tx.order_items.findMany({where:{order_id:{in:orders.map(r=>r.id)}},take:LIMIT+1,select:{order_id:true,product_name_snapshot:true,qty:true,unit_snapshot:true,unit_price_paise:true,line_total_paise:true}}));
 const sales=await bounded(tx.sales.findMany({where:scope,take:LIMIT+1,orderBy:{id:'asc'},select:{id:true,sale_no:true,vendor_id:true,vendor_customer_id:true,total_paise:true,paid_paise:true,balance_paise:true,payment_method:true,sale_date:true}}));
 const payments=await bounded(tx.payments.findMany({where:scope,take:LIMIT+1,select:{id:true,vendor_id:true,vendor_customer_id:true,order_id:true,amount_paise:true,method:true,received_on:true,created_at:true}}));
 const ledger=await bounded(tx.ledger_entries.findMany({where:scope,take:LIMIT+1,orderBy:{id:'asc'},select:{id:true,vendor_id:true,vendor_customer_id:true,type:true,amount_paise:true,ref_type:true,ref_id:true,entry_date:true,reverses_entry_id:true}}));
 const subscriptions=await bounded(tx.subscriptions.findMany({where:scope,take:LIMIT+1,select:{id:true,vendor_id:true,vendor_customer_id:true,product_id:true,start_date:true,end_date:true,payment_method:true,revisions:{take:LIMIT+1,select:{version:true,effective_from:true,qty:true,weekdays:true,time_slot:true,status:true,action:true}}}}));
 if(subscriptions.some(r=>r.revisions.length>LIMIT))throw new PayloadTooLargeException({code:'SUBJECT_EXPORT_TOO_LARGE'});
 const personalEntries=await bounded(tx.personal_entries.findMany({where:{user_id:userId},take:LIMIT+1,select:{id:true,contact_id:true,direction:true,amount_paise:true,date:true,deleted_at:true}}));
 const claims=await bounded(tx.payment_claims.findMany({where:{user_id:userId},take:LIMIT+1,select:{id:true,vendor_customer_id:true,amount_paise:true,method:true,status:true,created_at:true,decided_at:true}}));
 const kyc=vendor?await bounded(tx.vendor_kyc.findMany({where:{vendor_id:vendor.id},take:LIMIT+1,select:{id:true,status:true,submitted_at:true,reviewed_at:true,verification_method:true,provider_checks:true,pan_last4:true,account_last4:true,holder_name:true,bank_name:true,ifsc:true,upi_id:true}})):[];
 return {schemaVersion:1,snapshotAt:now.toISOString(),subjectId:userId,
  scope:'Structured subject account and transaction data. Counterparty contacts, free-text notes, credentials, session tokens, encrypted full bank/PAN identifiers and private-document bytes are excluded. Private KYC document access remains separately protected. No source data is modified.',
  profile,roles,consents,addresses,vendor,links,orders,orderItems,sales,payments,ledger,subscriptions,personalEntries,claims,kyc};
}
