// T-082: accepted account linkage, exact signed balances, immutable vendor ledger parity.
import { ForbiddenException,Injectable,NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { homeClock } from '../home/home.service';
import { KhataAccess,KhataTx,khataMonth,khataUnavailable } from './khata-access.service';
import { KhataMonthQuery,KhataSummaryQuery } from './khata.dto';
import { ledgerRoots } from '../ledger/ledger-roots';
@Injectable()
export class KhataReadService {
  constructor(private readonly access:KhataAccess,private readonly plans:PlanEntitlementsService){}
  private accounts(userId:string){return Prisma.sql`WITH accounts AS (
    SELECT v.id,'VENDOR'::text AS kind,COALESCE(v.business_name,'') AS name,-COALESCE(SUM(b.due_paise),0)::numeric AS balance
      FROM vendor_customers c JOIN vendors v ON v.id=c.vendor_id LEFT JOIN ledger_balances b ON b.vendor_customer_id=c.id
      WHERE c.user_id=${userId}::uuid GROUP BY v.id
    UNION ALL
    SELECT c.id,'PERSONAL'::text,c.name,COALESCE(SUM(CASE WHEN e.direction='GAVE' THEN e.amount_paise ELSE -e.amount_paise END),0)::numeric
      FROM personal_contacts c LEFT JOIN personal_entries e ON e.contact_id=c.id AND e.deleted_at IS NULL
      WHERE c.user_id=${userId}::uuid AND c.deleted_at IS NULL GROUP BY c.id
    )`;}
  summary(userId:string,q:KhataSummaryQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');const tab=q.tab??'ALL',kind=tab==='VENDORS'?'VENDOR':tab==='CUSTOMERS'?'PERSONAL':'ALL',search=q.q??'';
    const cte=this.accounts(userId),filter=Prisma.sql`(${kind}='ALL' OR kind=${kind}) AND position(lower(${search}) in lower(name))>0`;
    const items=await tx.$queryRaw<{id:string;kind:string;name:string;balancePaise:string;status:string}[]>`${cte}
      SELECT id,kind,name,balance::text AS "balancePaise",CASE WHEN balance>0 THEN 'RECEIVABLE' WHEN balance<0 THEN 'PAYABLE' ELSE 'SETTLED' END AS status
      FROM accounts WHERE ${filter} ORDER BY kind,name,id LIMIT ${q.limit??20} OFFSET ${q.offset??0}`;
    const [totals]=await tx.$queryRaw<{receivable:string;payable:string;net:string;total:number}[]>`${cte}
      SELECT COALESCE(SUM(GREATEST(balance,0)),0)::text AS receivable,COALESCE(SUM(GREATEST(-balance,0)),0)::text AS payable,
        COALESCE(SUM(balance),0)::text AS net,COUNT(*) FILTER(WHERE ${filter})::int AS total FROM accounts`;
    const clock=await homeClock(tx);return {totalReceivablePaise:totals!.receivable,totalPayablePaise:totals!.payable,netBalancePaise:totals!.net,items,total:totals!.total,serverTime:clock.now.toISOString(),businessDate:clock.day};
  },{isolationLevel:'RepeatableRead',timeout:15000}).catch(khataUnavailable);}
  async canSettle(tx:KhataTx,vendorId:string){
    const v=await tx.vendors.findUniqueOrThrow({where:{id:vendorId},include:{user:{include:{roles:true}}}});
    if(v.is_suspended||v.user.status!=='ACTIVE'||!v.user.roles.some(r=>r.role==='VENDOR'))return false;
    try{await this.plans.requireOperation(tx,vendorId,'CONFIRM_PAYMENT');return true;}catch(error){if(error instanceof ForbiddenException)return false;throw error;}
  }
  customerEntries(userId:string,vendorId:string,q:KhataMonthQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'CUSTOMER');const links=await tx.vendor_customers.findMany({where:{user_id:userId,vendor_id:vendorId}});
    if(!links.length)throw new NotFoundException({code:'KHATA_LINK_NOT_FOUND'});return this.entries(tx,vendorId,links,q);
  },{isolationLevel:'RepeatableRead',timeout:15000}).catch(khataUnavailable);}
  vendorEntries(userId:string,customerId:string,q:KhataMonthQuery){return this.access.db.$transaction(async tx=>{
    await this.access.actor(tx,userId,'VENDOR');const v=await this.access.vendor(tx,userId),link=await tx.vendor_customers.findFirst({where:{id:customerId,vendor_id:v.id}});
    if(!link)throw new NotFoundException({code:'CUSTOMER_NOT_FOUND'});return this.entries(tx,v.id,[link],q);
  },{isolationLevel:'RepeatableRead',timeout:15000}).catch(khataUnavailable);}
  // Internal transaction-scoped reader; callers must establish accepted-link ownership.
  async entries(tx:KhataTx,vendorId:string,links:{id:string;deleted_at:Date|null;user_id:string|null}[],q:KhataMonthQuery){
    const clock=await homeClock(tx),month=q.month??clock.day.slice(0,7),{from,to}=khataMonth(month),ids=links.map(c=>c.id),parameters=Prisma.join(ids.map(id=>Prisma.sql`${id}::uuid`));
    const where={vendor_customer_id:{in:ids},entry_date:{gte:from,lt:to}},rows=await tx.ledger_entries.findMany({where,orderBy:[{entry_date:'desc'},{created_at:'desc'},{id:'desc'}],take:q.limit??20,skip:q.offset??0});
    const [totals]=await tx.$queryRaw<{opening:string;debit:string;credit:string;paid:string}[]>`${ledgerRoots(vendorId)} SELECT
      COALESCE(SUM(CASE WHEN e.entry_date<${from}::date THEN CASE WHEN e.type='DEBIT' THEN e.amount_paise::numeric ELSE -e.amount_paise::numeric END ELSE 0 END),0)::text AS opening,
      COALESCE(SUM(e.amount_paise) FILTER(WHERE e.entry_date>=${from}::date AND e.type='DEBIT'),0)::text AS debit,
      COALESCE(SUM(e.amount_paise) FILTER(WHERE e.entry_date>=${from}::date AND e.type='CREDIT'),0)::text AS credit,
      COALESCE(SUM(CASE WHEN e.entry_date>=${from}::date THEN CASE
        WHEN root.root_type='CREDIT' AND root.ref_type IN ('PAYMENT','SALE','CLAIM') THEN CASE WHEN e.type='CREDIT' THEN e.amount_paise::numeric ELSE -e.amount_paise::numeric END ELSE 0 END ELSE 0 END),0)::text AS paid
      FROM ledger_entries e JOIN ledger_roots root ON root.id=e.id
      WHERE e.vendor_customer_id IN (${parameters}) AND e.entry_date<${to}::date`;
    const balances=await tx.ledger_balances.findMany({where:{vendor_customer_id:{in:ids}}}),due=balances.reduce((n,b)=>n+b.due_paise,0n),allowed=await this.canSettle(tx,vendorId);
    const sources=rows.length?await tx.$queryRaw<{id:string;ref_type:string;ref_id:string}[]>`${ledgerRoots(vendorId)} SELECT id,ref_type,ref_id FROM ledger_roots WHERE id IN (${Prisma.join(rows.map(r=>Prisma.sql`${r.id}::uuid`))})`:[];
    const refs=rows.map(r=>sources.find(o=>o.id===r.id)??r);
    const orders=await tx.orders.findMany({where:{id:{in:refs.filter(r=>r.ref_type==='ORDER').map(r=>r.ref_id)},vendor_id:vendorId},include:{items:true}});
    const sales=await tx.sales.findMany({where:{id:{in:refs.filter(r=>r.ref_type==='SALE').map(r=>r.ref_id)},vendor_id:vendorId},include:{items:true}});
    const v=await tx.vendors.findUniqueOrThrow({where:{id:vendorId}});
    return {vendorId,vendorName:v.business_name??'',month,duePaise:String(due),openingDuePaise:totals!.opening,closingDuePaise:String(BigInt(totals!.opening)+BigInt(totals!.debit)-BigInt(totals!.credit)),
      monthDebitPaise:totals!.debit,monthCreditPaise:totals!.credit,monthPaidPaise:totals!.paid,
      accounts:links.map(l=>{const amount=balances.find(b=>b.vendor_customer_id===l.id)?.due_paise??0n,maxClaim=amount<due?amount:due;return {vendorCustomerId:l.id,duePaise:String(amount),maxClaimPaise:String(maxClaim>0n?maxClaim:0n),canClaim:allowed&&!!l.user_id&&!l.deleted_at&&amount>0n&&due>0n};}),
      items:rows.map((r,i)=>{const ref=refs[i]!,o=orders.find(o=>ref.ref_type==='ORDER'&&o.id===ref.ref_id),s=sales.find(s=>ref.ref_type==='SALE'&&s.id===ref.ref_id);
        return {id:r.id,vendorCustomerId:r.vendor_customer_id,type:r.type,amountPaise:String(r.amount_paise),entryDate:r.entry_date.toISOString().slice(0,10),refType:r.ref_type,refId:r.ref_id,reversesEntryId:r.reverses_entry_id,note:r.note,
          productSummary:o?o.items.map(i=>`${i.product_name_snapshot} × ${i.qty}`).join(', '):s?s.items.map(i=>`${i.name_snapshot} × ${i.qty}`).join(', '):null,paymentStatus:o?.payment_status??(s?s.balance_paise===0n?'PAID':'UNPAID':null)};}),
      total:await tx.ledger_entries.count({where}),serverTime:clock.now.toISOString(),businessDate:clock.day};
  }
}
