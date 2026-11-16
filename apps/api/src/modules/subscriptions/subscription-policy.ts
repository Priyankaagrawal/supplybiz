// T-072 / ADR-033 / RULE-08,16. Dates are server IST business dates, never device time.
import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { homeClock } from '../home/home.service';
export function dateOnly(value:string) {
  const date=new Date(`${value}T00:00:00Z`);
  if(!/^\d{4}-\d{2}-\d{2}$/.test(value) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0,10)!==value) throw new BadRequestException({code:'INVALID_DATE'});
  return date;
}
export const dayString=(value:Date)=>value.toISOString().slice(0,10);
export const addDays=(day:string,n:number)=>dayString(new Date(dateOnly(day).getTime()+n*86400000));
export function effectiveDay(now:Date) {
  const ist=new Date(now.getTime()+19800000).toISOString();
  return addDays(ist.slice(0,10),ist.slice(11,19)>='21:00:00'?2:1);
}
export function monthlyEstimate(rate:bigint,qty:number,mask:number,start:string,end:string|null,month:string) {
  if(!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) throw new BadRequestException({code:'INVALID_MONTH'});
  let count=0;
  for(let day=`${month}-01`;day.startsWith(month);day=addDays(day,1)) {
    const weekday=(dateOnly(day).getUTCDay()+6)%7;
    if(day>=start && (!end || day<=end) && (mask & (1<<weekday))) count++;
  }
  const daily=rate*BigInt(qty),monthly=daily*BigInt(count);
  if(daily>9223372036854775807n) throw new BadRequestException({code:'AMOUNT_OVERFLOW'});
  return {dailyAmountPaise:String(daily),monthlyEstimatePaise:String(monthly)};
}
@Injectable()
export class SubscriptionClock { now(tx:Prisma.TransactionClient){ return homeClock(tx); } }

export const subscriptionRead={revisions:{orderBy:{version:'asc' as const}},pauses:true,skips:true,product:true,customer:true} satisfies Prisma.subscriptionsInclude;
export type SubscriptionRead=Prisma.subscriptionsGetPayload<{include:typeof subscriptionRead}>;
export function revisionForDate(row:SubscriptionRead,day:string) {
  return [...row.revisions].filter(r=>['CREATE','EDIT','APPROVE','REJECT','CANCEL'].includes(r.action) && dayString(r.effective_from)<=day)
    .sort((a,b)=>dayString(b.effective_from).localeCompare(dayString(a.effective_from)) || b.version-a.version)[0];
}
export function pausedOn(row:SubscriptionRead,day:string) {
  return row.pauses.some(p=>day>=dayString(p.from_date) && (!p.to_date || day<=dayString(p.to_date)) && (!p.resumed_from || day<dayString(p.resumed_from)));
}
/** T-073 must additionally enforce vendor/plan/product eligibility and capacity. */
export function subscriptionForDate(row:SubscriptionRead,day:string) {
  const revision=revisionForDate(row,day);
  if(day<dayString(row.start_date) || row.end_date && day>dayString(row.end_date) ||
      revision?.status!=='ACTIVE' || pausedOn(row,day) || row.skips.some(s=>dayString(s.date)===day) ||
      !(revision.weekdays & (1<<((dateOnly(day).getUTCDay()+6)%7)))) return null;
  return revision;
}
