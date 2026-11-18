import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { homeClock } from '../home/home.service';
import { LedgerService } from '../ledger/ledger.service';
import { ledgerRoots } from '../ledger/ledger-roots';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { KhataAccess,khataAmount,khataMonth,khataUnavailable } from './khata-access.service';
import { KhataMonthQuery } from './khata.dto';
import { KhataReadService } from './khata-read.service';
import { LedgerOpeningInput,LedgerReversalInput,VendorKhataQuery } from './vendor-khata.dto';
const isReceipt=Prisma.sql`r.root_type='CREDIT' AND r.ref_type IN ('PAYMENT','SALE','CLAIM')`;
@Injectable()
export class VendorKhataService {
  constructor(private readonly access:KhataAccess,private readonly ledger:LedgerService,private readonly plans:PlanEntitlementsService,private readonly reads:KhataReadService){}
  list(userId:string,q:VendorKhataQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'VENDOR');const v=await this.access.vendor(tx,userId),clock=await homeClock(tx),{from,to}=khataMonth(clock.day.slice(0,7));
    const tab=q.tab??'ALL',search=q.q??'',filter=Prisma.sql`(${tab}='ALL' OR ${tab}='RECEIVABLE' AND due>0 OR ${tab}='PAID' AND due=0) AND (position(lower(${search}) in lower(name))>0 OR position(${search} in mobile)>0)`;
    const cte=Prisma.sql`${ledgerRoots(v.id)}, paid AS (
      SELECT e.vendor_customer_id,SUM(CASE WHEN e.type='CREDIT' THEN e.amount_paise::numeric ELSE -e.amount_paise::numeric END) AS amount FROM ledger_entries e JOIN ledger_roots r ON r.id=e.id WHERE ${isReceipt} GROUP BY e.vendor_customer_id
    ), accounts AS (
      SELECT c.id,c.name,c.mobile,c.status,(c.deleted_at IS NOT NULL) AS archived,COALESCE(b.total_debit_paise,0)::text AS "totalDebitPaise",COALESCE(b.total_credit_paise,0)::text AS "totalCreditPaise",COALESCE(b.due_paise,0) AS due,
        COALESCE(paid.amount,0)::text AS "totalPaidPaise"
      FROM vendor_customers c LEFT JOIN ledger_balances b ON b.vendor_customer_id=c.id LEFT JOIN paid ON paid.vendor_customer_id=c.id WHERE c.vendor_id=${v.id}::uuid
    )`;
    const items=await tx.$queryRaw`${cte} SELECT id,name,mobile,status,archived,"totalDebitPaise","totalCreditPaise","totalPaidPaise",due::text AS "duePaise" FROM accounts WHERE ${filter} ORDER BY lower(name),id LIMIT ${q.limit??20} OFFSET ${q.offset??0}`;
    const [totals]=await tx.$queryRaw<{total:number;receivable:string}[]>`${cte} SELECT COUNT(*) FILTER(WHERE ${filter})::int AS total,COALESCE(SUM(GREATEST(due,0)),0)::text AS receivable FROM accounts`;
    const [cash]=await tx.$queryRaw<{received:string}[]>`${ledgerRoots(v.id)} SELECT COALESCE(SUM(CASE WHEN e.type='CREDIT' THEN e.amount_paise::numeric ELSE -e.amount_paise::numeric END),0)::text AS received FROM ledger_entries e JOIN ledger_roots r ON r.id=e.id WHERE e.vendor_id=${v.id}::uuid AND e.entry_date>=${from}::date AND e.entry_date<${to}::date AND ${isReceipt}`;
    const policy=await this.plans.resolve(tx,v.id);
    return {items,total:totals!.total,totalReceivablePaise:totals!.receivable,thisMonthReceivedPaise:cash!.received,canAdjust:policy.active,canRecordPayment:await this.reads.canSettle(tx,v.id),serverTime:clock.now.toISOString(),businessDate:clock.day};
  },{isolationLevel:'RepeatableRead',timeout:30000}).catch(khataUnavailable);}
  collections(userId:string,q:KhataMonthQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'VENDOR');const v=await this.access.vendor(tx,userId),clock=await homeClock(tx),month=q.month??clock.day.slice(0,7),{from,to}=khataMonth(month);
    const base=Prisma.sql`FROM ledger_entries e JOIN ledger_roots r ON r.id=e.id JOIN vendor_customers c ON c.id=e.vendor_customer_id
      LEFT JOIN payments p ON r.ref_type='PAYMENT' AND p.id=r.ref_id LEFT JOIN sales s ON r.ref_type='SALE' AND s.id=r.ref_id LEFT JOIN payment_claims claim ON r.ref_type='CLAIM' AND claim.id=r.ref_id
      WHERE e.vendor_id=${v.id}::uuid AND e.entry_date>=${from}::date AND e.entry_date<${to}::date AND ${isReceipt}`;
    const items=await tx.$queryRaw`${ledgerRoots(v.id)} SELECT e.id,e.vendor_customer_id AS "vendorCustomerId",c.name AS "customerName",(CASE WHEN e.type='CREDIT' THEN e.amount_paise::numeric ELSE -e.amount_paise::numeric END)::text AS "amountPaise",COALESCE(p.method,s.payment_method,claim.method,'') AS method,to_char(e.entry_date,'YYYY-MM-DD') AS "entryDate",e.created_at AS "createdAt",(e.ref_type='REVERSAL') AS reversal,r.ref_type AS source ${base} ORDER BY e.entry_date DESC,e.created_at DESC,e.id DESC LIMIT ${q.limit??20} OFFSET ${q.offset??0}`;
    const [count]=await tx.$queryRaw<{total:number}[]>`${ledgerRoots(v.id)} SELECT COUNT(*)::int AS total ${base}`;return {items,total:count!.total,month};
  },{isolationLevel:'RepeatableRead',timeout:30000}).catch(khataUnavailable);}
  opening(userId:string,id:string,key:string,input:LedgerOpeningInput){return this.access.mutate(userId,'VENDOR',key,`OPENING ${id}`,input,async tx=>{
    const v=await this.access.vendor(tx,userId);await this.plans.requireFeature(tx,v.id,'KHATA');
    const entry=await this.ledger.opening(userId,key,id,{type:input.type,amountPaise:khataAmount(input.amountPaise),note:input.note},tx);return {id:entry.id};
  });}
  reverse(userId:string,id:string,key:string,input:LedgerReversalInput){return this.access.mutate(userId,'VENDOR',key,`REVERSE ${id}`,input,async tx=>{
    const v=await this.access.vendor(tx,userId);await this.plans.requireFeature(tx,v.id,'KHATA');
    const entry=await this.ledger.reverse(userId,key,id,input.reason,tx);return {id:entry.id};
  });}
}
