// T-073 / TC-080/082: schedule boundaries and independently computed eligibility.
import { Prisma } from '@prisma/client';
import { dateOnly, subscriptionForDate, SubscriptionRead } from './subscription-policy';
import { generationDueAt, latestDueDelivery } from './subscription-generation.policy';
const id='11111111-1111-4111-8111-111111111111';
function row():SubscriptionRead {
  return {id,vendor_id:id,vendor_customer_id:id,product_id:id,start_date:dateOnly('2026-10-01'),end_date:null,address_snapshot:{},payment_method:'CASH',created_by:'VENDOR',creator_user_id:id,version:1,created_at:new Date(),
    product:{id,vendor_id:id,name:'Synthetic',product_type:'MILK',milk_type:'COW',unit_value:new Prisma.Decimal(1),unit_type:'L',selling_price_paise:4800,subscription_price_paise:null,stock_qty:100,moq:1,description:'',image_media_id:null,is_active:true,deleted_at:null,version:1,created_at:new Date(),updated_at:new Date()},
    customer:{id,vendor_id:id,user_id:null,name:'Synthetic',mobile:'+919000000000',email:null,address_text:'',preferred_payment:'CASH',status:'ACTIVE',deleted_at:null,created_at:new Date(),updated_at:new Date()},
    revisions:[{subscription_id:id,version:1,effective_from:dateOnly('2026-10-01'),qty:1,weekdays:127,time_slot:'AM',status:'ACTIVE',action:'CREATE',reason:null,actor_id:id,created_at:new Date()}],pauses:[],skips:[]};
}
describe('T-073 generation policy',()=>{
  it('TC-082 22:00 IST is 16:30 UTC, including exact minute and date rollover',()=>{
    expect(generationDueAt('2026-10-02').toISOString()).toBe('2026-10-01T16:30:00.000Z');
    expect(latestDueDelivery(new Date('2026-10-01T16:29:59Z'))).toBe('2026-10-01');
    expect(latestDueDelivery(new Date('2026-10-01T16:30:00Z'))).toBe('2026-10-02');
    expect(generationDueAt('2027-01-01').toISOString()).toBe('2026-12-31T16:30:00.000Z');
    expect(()=>generationDueAt('2026-02-30')).toThrow();
  });
  it('TC-080 deterministic property matrix matches an independent calendar oracle',()=>{
    let seed=8317;const next=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed;};
    for(let i=0;i<500;i++) {
      const sub=row(),date=`2026-10-${String(1+next()%31).padStart(2,'0')}`,day=Number(date.slice(-2));
      const mask=1+next()%127,paused=next()%2===0,skipped=next()%2===0,active=next()%3!==0,globalPause=next()%3===0,available=next()%3!==0;
      sub.revisions[0]!.weekdays=mask;sub.revisions[0]!.status=active?'ACTIVE':'PENDING_APPROVAL';
      sub.start_date=dateOnly('2026-10-03');sub.end_date=dateOnly('2026-10-28');
      if(paused)sub.pauses.push({id,subscription_id:id,from_date:dateOnly('2026-10-10'),to_date:dateOnly('2026-10-15'),resumed_from:null});
      if(skipped)sub.skips.push({subscription_id:id,date:dateOnly(date)});
      const jsWeekday=new Date(`${date}T12:00:00Z`).getUTCDay(),iso=jsWeekday===0?7:jsWeekday;
      const selected=(Math.floor(mask/2**(iso-1))%2)===1;
      const expected=active && day>=3 && day<=28 && selected && !(paused && day>=10 && day<=15) && !skipped && !globalPause && available;
      expect(subscriptionForDate(sub,date,{pause_all_subscriptions:globalPause,subscription_delivery_available:available})!==null).toBe(expected);
    }
  });
});
