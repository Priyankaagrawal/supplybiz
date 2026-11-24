// T-072 / TC-070,074–077,079: independent calendar/cutoff/schedule boundaries.
import { addDays, dateOnly, effectiveDay, monthlyEstimate, subscriptionForDate, SubscriptionRead } from './subscription-policy';
import { Prisma } from '@prisma/client';
const id='11111111-1111-4111-8111-111111111111';
function schedule():SubscriptionRead {
  return {id,vendor_id:id,vendor_customer_id:id,product_id:id,start_date:dateOnly('2026-10-01'),end_date:null,
    address_snapshot:{},payment_method:'CASH',created_by:'VENDOR',creator_user_id:id,version:1,created_at:new Date(),
    product:{id,vendor_id:id,name:'Synthetic',product_type:'MILK',milk_type:'COW',unit_value:new Prisma.Decimal('1'),unit_type:'L',selling_price_paise:4800,subscription_price_paise:null,stock_qty:1,moq:1,description:'',image_media_id:null,is_active:true,deleted_at:null,version:1,created_at:new Date(),updated_at:new Date()},
    customer:{privacy_erased_at:null,id,vendor_id:id,user_id:null,name:'Synthetic',mobile:'+919000000000',email:null,address_text:'',preferred_payment:'CASH',status:'ACTIVE',deleted_at:null,created_at:new Date(),updated_at:new Date()},
    revisions:[{subscription_id:id,version:1,effective_from:dateOnly('2026-10-01'),qty:1,weekdays:127,time_slot:'AM',status:'ACTIVE',action:'CREATE',reason:null,actor_id:id,created_at:new Date()}],pauses:[],skips:[]};
}
describe('T-072 pure subscription policy',()=>{
  it('TC-070 exact October calendar estimates, weekday mask and clipped ranges',()=>{
    expect(monthlyEstimate(4800n,1,127,'2026-10-01',null,'2026-10')).toEqual({dailyAmountPaise:'4800',monthlyEstimatePaise:'148800'});
    expect(monthlyEstimate(4800n,1,21,'2026-10-01',null,'2026-10').monthlyEstimatePaise).toBe('62400');
    expect(monthlyEstimate(4800n,2,127,'2026-10-10','2026-10-12','2026-10').monthlyEstimatePaise).toBe('28800');
    expect(monthlyEstimate(2147483647n,2147483647,127,'2026-11-01',null,'2026-10').monthlyEstimatePaise).toBe('0');
    expect(monthlyEstimate(2147483647n,2147483647,127,'2026-10-01',null,'2026-10')).toEqual({dailyAmountPaise:'4611686014132420609',monthlyEstimatePaise:'142962266438105038879'});
  });
  it('TC-075–077 cutoff is 21:00 IST, including exact boundary and year rollover',()=>{
    expect(effectiveDay(new Date('2026-10-01T15:29:59Z'))).toBe('2026-10-02');
    expect(effectiveDay(new Date('2026-10-01T15:30:00Z'))).toBe('2026-10-03');
    expect(effectiveDay(new Date('2026-12-31T15:30:00Z'))).toBe('2027-01-02');
  });
  it('strict calendar dates reject rollover and accept leap days',()=>{
    expect(()=>dateOnly('2026-02-30')).toThrow();expect(()=>dateOnly('2026-02-29')).toThrow();
    expect(addDays('2028-02-28',1)).toBe('2028-02-29');expect(()=>monthlyEstimate(1n,1,127,'2026-01-01',null,'2026-13')).toThrow();
  });
  it('TC-077 revisions preserve frozen qty; a vendor skip audit cannot apply a future config early',()=>{
    const row=schedule(),first=row.revisions[0]!;
    row.revisions.push({...first,version:2,qty:3,effective_from:dateOnly('2026-10-03'),action:'EDIT'});
    row.revisions.push({...first,version:3,qty:3,effective_from:dateOnly('2026-10-01'),action:'SKIP'});
    expect(subscriptionForDate(row,'2026-10-02')?.qty).toBe(1);
    expect(subscriptionForDate(row,'2026-10-03')?.qty).toBe(3);
  });
  it('TC-074/079 pause endpoints inclusive, resume preserves history, skips/cancel/end block correct dates',()=>{
    const row=schedule();row.pauses.push({id,subscription_id:id,from_date:dateOnly('2026-10-10'),to_date:dateOnly('2026-10-12'),resumed_from:null});
    expect(subscriptionForDate(row,'2026-10-10')).toBeNull();expect(subscriptionForDate(row,'2026-10-12')).toBeNull();
    expect(subscriptionForDate(row,'2026-10-13')).not.toBeNull();
    row.pauses[0]!.resumed_from=dateOnly('2026-10-12');expect(subscriptionForDate(row,'2026-10-11')).toBeNull();expect(subscriptionForDate(row,'2026-10-12')).not.toBeNull();
    row.skips.push({subscription_id:id,date:dateOnly('2026-10-13')});expect(subscriptionForDate(row,'2026-10-13')).toBeNull();
    row.revisions.push({...row.revisions[0]!,version:2,status:'CANCELLED',action:'CANCEL',effective_from:dateOnly('2026-10-15')});
    expect(subscriptionForDate(row,'2026-10-14')).not.toBeNull();expect(subscriptionForDate(row,'2026-10-15')).toBeNull();
    row.end_date=dateOnly('2026-10-01');expect(subscriptionForDate(row,'2026-10-02')).toBeNull();
  });
});
