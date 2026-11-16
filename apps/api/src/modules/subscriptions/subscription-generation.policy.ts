import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { homeClock } from '../home/home.service';
import { addDays, dateOnly } from './subscription-policy';
export const GENERATION_SCAN='SUBSCRIPTION_GENERATION_SCAN';
export const GENERATION_BATCH='SUBSCRIPTION_GENERATION_BATCH';
export const SCAN_SIZE=100,BATCH_SIZE=25,SCHEDULE_DAYS=7;
export function generationDueAt(deliveryDate:string) {
  dateOnly(deliveryDate);
  return new Date(`${addDays(deliveryDate,-1)}T22:00:00+05:30`);
}
export function latestDueDelivery(now:Date) {
  const ist=new Date(now.getTime()+19800000).toISOString();
  return addDays(ist.slice(0,10),ist.slice(11,19)>='22:00:00'?1:0);
}
@Injectable()
export class GenerationClock { now(tx:Prisma.TransactionClient){return homeClock(tx);} }
