// T-073 / FR-074: durable scan + bounded same-vendor batches, using T-181 leases.
import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import { PinoLogger } from '../../common/logging/pino.logger';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { PrismaService } from '../../prisma/prisma.service';
import { CatalogService } from '../catalog/catalog.service';
import { CustomersService } from '../customers/customers.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { PLAN_FEATURES } from '../plans/plan-policy';
import { addDays, dateOnly, dayString, pausedOn, revisionForDate, subscriptionForDate, subscriptionRead, SubscriptionRead } from './subscription-policy';
import { BATCH_SIZE, GENERATION_BATCH, GENERATION_SCAN, generationDueAt, GenerationClock, latestDueDelivery, SCAN_SIZE, SCHEDULE_DAYS } from './subscription-generation.policy';
type Tx=Prisma.TransactionClient;
const daySchema=z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const scanSchema=z.object({date:daySchema,cursor:z.string().uuid().nullable()}).strict();
const batchSchema=z.object({date:daySchema,vendorId:z.string().uuid(),ids:z.array(z.string().uuid()).min(1).max(BATCH_SIZE)}).strict();
@Injectable()
export class SubscriptionGenerationService implements OnModuleInit,OnModuleDestroy {
  private timer:NodeJS.Timeout|null=null;
  private active:Promise<void>|null=null;
  constructor(private readonly db:PrismaService,private readonly dispatcher:OutboxDispatcherService,
    private readonly plans:PlanEntitlementsService,private readonly catalog:CatalogService,
    private readonly customers:CustomersService,private readonly notifications:NotificationsService,
    private readonly clock:GenerationClock,private readonly logger:PinoLogger) {}
  onModuleInit() {
    this.dispatcher.register(GENERATION_SCAN,(event,tx)=>this.scan(tx,scanSchema.parse(event.payload)));
    this.dispatcher.register(GENERATION_BATCH,(event,tx)=>this.batch(tx,batchSchema.parse(event.payload)));
  }
  /** Worker-only; API initialization registers consumers without timers or jobs. */
  start(){if(this.timer)return;void this.poll();this.timer=setInterval(()=>{void this.poll();},60000);}
  async onModuleDestroy(){if(this.timer)clearInterval(this.timer);this.timer=null;await this.active;}
  private poll():Promise<void> {
    return this.active??=this.ensureScheduled().then(()=>this.alertOverdue()).then(()=>undefined)
      .catch(()=>{this.logger.error('SUBSCRIPTION_GENERATION_SCHEDULE_FAILED',undefined,'Subscriptions');})
      .finally(()=>{this.active=null;});
  }
  private async dateLock(tx:Tx,date:string) {
    dateOnly(date);await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`subscription-generation:${date}`},0))::text`;
  }
  private async run(tx:Tx,date:string) {
    await this.dateLock(tx,date);
    return tx.subscription_generation_runs.upsert({where:{delivery_date:dateOnly(date)},create:{delivery_date:dateOnly(date),due_at:generationDueAt(date)},update:{}});
  }
  private async job(tx:Tx,type:string,date:string,scope:string,payload:Prisma.InputJsonObject) {
    // Caller holds the date advisory lock; requests and scanners use the same lock order.
    const known=await tx.job_runs.findUnique({where:{job_type_business_date_scope_id:{job_type:type,business_date:dateOnly(date),scope_id:scope}}});
    if(known)return {id:known.event_id,added:false};
    const [clock]=await tx.$queryRaw<{at:Date}[]>`SELECT GREATEST(${generationDueAt(date)}::timestamptz,clock_timestamp()) AS at`;
    const event=await tx.outbox_events.create({data:{aggregate_type:'JOB',event_type:type,payload,available_at:clock!.at}});
    await tx.job_runs.create({data:{job_type:type,business_date:dateOnly(date),scope_id:scope,event_id:event.id}});
    return {id:event.id,added:true};
  }
  private async ensureDate(tx:Tx,date:string) {
    await this.run(tx,date);
    return (await this.job(tx,GENERATION_SCAN,date,'GLOBAL',{date,cursor:null})).id;
  }
  private async queueBatch(tx:Tx,date:string,vendorId:string,ids:string[],scope:string) {
    const event=await this.job(tx,GENERATION_BATCH,date,scope,{date,vendorId,ids});
    if(event.added)await tx.subscription_generation_runs.update({where:{delivery_date:dateOnly(date)},data:{expected_work:{increment:1},finished_at:null}});
    return event.id;
  }
  /** Called in the subscription creation transaction. Covers enrolment after the scan passed. */
  async scheduleCreated(tx:Tx,id:string,vendorId:string,start:string) {
    const scan=await this.ensureDate(tx,start),clock=await this.clock.now(tx);
    if(clock.now>=generationDueAt(start)) return this.queueBatch(tx,start,vendorId,[id],`FIRST:${id}`);
    return scan;
  }
  async ensureScheduled() {
    const clock=await this.clock.now(this.db),latest=latestDueDelivery(clock.now),through=addDays(clock.day,1);
    return this.db.$transaction(async tx=>{
      await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended('subscription-generation-scheduler',0))::text`;
      // Current work is queued first; historical catch-up cannot starve tonight's scan.
      await this.ensureDate(tx,latest);await this.ensureDate(tx,through);
      const state=await tx.subscription_schedule_state.findUnique({where:{id:'GLOBAL'}});
      const oldest=await tx.subscriptions.aggregate({_min:{start_date:true}});
      let date=state?addDays(dayString(state.through_date),1):[oldest._min.start_date?dayString(oldest._min.start_date):clock.day,clock.day].sort()[0]!;
      const scheduled:string[]=[];
      for(let i=0;i<SCHEDULE_DAYS && date<=through;i++,date=addDays(date,1)) {
        await this.ensureDate(tx,date);scheduled.push(date);
      }
      if(scheduled.length)await tx.subscription_schedule_state.upsert({where:{id:'GLOBAL'},create:{id:'GLOBAL',through_date:dateOnly(scheduled.at(-1)!)},update:{through_date:dateOnly(scheduled.at(-1)!)}});
      return {latestDueDate:latest,scheduledDates:scheduled};
    },{timeout:15000});
  }
  private async finish(tx:Tx,date:string) {
    await tx.$executeRaw`UPDATE subscription_generation_runs SET finished_at=clock_timestamp()
      WHERE delivery_date=${date}::date AND scan_complete AND completed_work=expected_work AND finished_at IS NULL`;
  }
  private async scan(tx:Tx,payload:z.infer<typeof scanSchema>) {
    const {date,cursor}=payload,run=await this.run(tx,date),clock=await this.clock.now(tx);
    if(clock.now<run.due_at)throw new Error('Generation not due');
    if(run.scan_complete || run.scan_cursor!==cursor)return {alreadyScanned:1};
    const rows=await tx.subscriptions.findMany({where:{start_date:{lte:dateOnly(date)},...(cursor?{id:{gt:cursor}}:{})},
      orderBy:{id:'asc'},take:SCAN_SIZE+1,select:{id:true,vendor_id:true}});
    const page=rows.slice(0,SCAN_SIZE),groups=new Map<string,string[]>();
    for(const row of page)groups.set(row.vendor_id,[...(groups.get(row.vendor_id)??[]),row.id]);
    let batches=0;
    for(const [vendorId,ids] of groups)for(let i=0;i<ids.length;i+=BATCH_SIZE) {
      const group=ids.slice(i,i+BATCH_SIZE);await this.queueBatch(tx,date,vendorId,group,`BATCH:${group[0]!}`);batches++;
    }
    const more=rows.length>SCAN_SIZE,next=page.at(-1)?.id??cursor;
    await tx.subscription_generation_runs.update({where:{delivery_date:dateOnly(date)},data:{scan_cursor:next,scan_complete:!more}});
    if(more)await this.job(tx,GENERATION_SCAN,date,`AFTER:${next!}`,{date,cursor:next});
    await this.finish(tx,date);
    return {scanned:page.length,batches,more};
  }
  private async retireReferences(tx:Tx,row:SubscriptionRead,date:string,today:string) {
    const latest=row.revisions.at(-1)!,horizon=[date,today].sort().at(-1)!;
    const effective=revisionForDate(row,horizon)??latest;
    const terminal=['CANCELLED','REJECTED'].includes(latest.status) && dayString(latest.effective_from)<=horizon;
    const status=terminal?latest.status:row.end_date && dayString(row.end_date)<horizon?'ENDED':
      effective.status==='PENDING_APPROVAL'?'PENDING':pausedOn(row,horizon)?'PAUSED':'ACTIVE';
    await this.catalog.setSubscriptionReference(tx,row.id,row.product_id,status as 'ACTIVE'|'PAUSED'|'PENDING'|'ENDED'|'CANCELLED'|'REJECTED');
    await this.customers.setSubscriptionReference(tx,row.id,row.vendor_customer_id,status as 'ACTIVE'|'PAUSED'|'PENDING'|'ENDED'|'CANCELLED'|'REJECTED');
  }
  private async batch(tx:Tx,payload:z.infer<typeof batchSchema>) {
    const {date,vendorId,ids}=payload;
    if(new Set(ids).size!==ids.length)throw new Error('Invalid generation batch');
    const clock=await this.clock.now(tx);if(clock.now<generationDueAt(date))throw new Error('Generation not due');
    const identity=await tx.vendors.findUniqueOrThrow({where:{id:vendorId},select:{user_id:true}});
    // Match catalog/session/financial lock order: actor -> vendor -> ordered products.
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${identity.user_id},0))::text`;
    await tx.$queryRaw`SELECT id FROM vendors WHERE id=${vendorId}::uuid FOR UPDATE`;
    const vendor=await tx.vendors.findUniqueOrThrow({where:{id:vendorId},include:{settings:true,category:true,user:{include:{roles:true}}}});
    const productIds=await tx.subscriptions.findMany({where:{id:{in:ids},vendor_id:vendorId},select:{product_id:true}});
    if(productIds.length!==ids.length)throw new Error('Generation scope mismatch');
    const products=[...new Set(productIds.map(p=>p.product_id))];
    await tx.$queryRaw`SELECT id FROM products WHERE vendor_id=${vendorId}::uuid AND id IN (${Prisma.join(products.map(id=>Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`;
    const rows=await tx.subscriptions.findMany({where:{id:{in:ids},vendor_id:vendorId},orderBy:{id:'asc'},
      include:{...subscriptionRead,customer:{include:{user:{include:{roles:true}}}}}});
    const counts:Record<string,number>={created:0,skipped:0};
    const skip=(reason:string)=>{counts.skipped!++;counts[reason]=(counts[reason]??0)+1;};
    let enabled=!vendor.is_suspended && vendor.user.status==='ACTIVE' && vendor.user.roles.some(r=>r.role==='VENDOR') && vendor.category.type==='SUPPLY' && vendor.category.status==='ENABLED';
    let auto=false;
    if(enabled) {
      if(!vendor.settings)throw new Error('Generation settings missing');
      const entitlement=await this.plans.resolve(tx,vendorId);
      enabled=!!(entitlement.active && entitlement.assignment && PLAN_FEATURES[entitlement.assignment.plan.code].includes('SUBSCRIPTIONS'));
      auto=!!(enabled && entitlement.assignment && PLAN_FEATURES[entitlement.assignment.plan.code].includes('AUTO_ACCEPT') && vendor.settings.auto_accept_subscriptions);
    }
    const holiday=await tx.vendor_holidays.findUnique({where:{vendor_id_date:{vendor_id:vendorId,date:dateOnly(date)}}});
    for(const row of rows) {
      await this.retireReferences(tx,row,date,clock.day);
      if(await tx.orders.findFirst({where:{subscription_id:row.id,delivery_date:dateOnly(date)},select:{id:true}})){skip('existing');continue;}
      if(!enabled){skip('vendorOrPlan');continue;}
      const settings=vendor.settings!,revision=subscriptionForDate(row,date,settings);
      const pausedUntil=settings.delivery_paused_until?dayString(new Date(settings.delivery_paused_until.getTime()+19800000)):null;
      if(!revision || holiday || settings.delivery_paused && (!pausedUntil || date<=pausedUntil)){skip('calendarOrPause');continue;}
      if(row.product.deleted_at || !row.product.is_active || row.customer.deleted_at || row.customer.status!=='ACTIVE' ||
        row.customer.user && (row.customer.user.status!=='ACTIVE' || !row.customer.user.roles.some(r=>r.role==='CUSTOMER'))){skip('productOrCustomer');continue;}
      if(!Array.isArray(settings.time_slots) || !settings.time_slots.includes(revision.time_slot)){skip('slot');continue;}
      const milk=row.product.product_type==='MILK' && ['L','ML'].includes(row.product.unit_type)?
        row.product.unit_value.mul(revision.qty).mul(row.product.unit_type==='L'?1000:1):new Prisma.Decimal(0);
      const where={vendor_id:vendorId,delivery_date:dateOnly(date),status:{notIn:['REJECTED','CANCELLED','FAILED']}};
      if(settings.max_daily_orders!==null && await tx.orders.count({where})>=settings.max_daily_orders){skip('capacity');continue;}
      if(settings.daily_milk_capacity_ml!==null) {
        const used=await tx.order_items.aggregate({where:{order:where},_sum:{milk_quantity_ml:true}});
        if((used._sum.milk_quantity_ml??new Prisma.Decimal(0)).add(milk).gt(settings.daily_milk_capacity_ml)){skip('capacity');continue;}
      }
      const rate=BigInt(row.product.subscription_price_paise??row.product.selling_price_paise),subtotal=rate*BigInt(revision.qty),charge=BigInt(settings.delivery_charge_paise),total=subtotal+charge;
      if(total<0n || total>9223372036854775807n)throw new Error('Generation amount invalid');
      const [number]=await tx.$queryRaw<{value:bigint}[]>`SELECT nextval('order_number_sequence') AS value`;
      const status=auto?'ACCEPTED':'NEW';
      const order=await tx.orders.create({data:{order_no:`ORD${String(number!.value).padStart(8,'0')}`,vendor_id:vendorId,vendor_customer_id:row.vendor_customer_id,
        source:'SUBSCRIPTION',subscription_id:row.id,status,delivery_date:dateOnly(date),time_slot:revision.time_slot,address_snapshot:row.address_snapshot as Prisma.InputJsonObject,
        subtotal_paise:subtotal,delivery_charge_paise:charge,total_paise:total,payment_mode:'KHATA',payment_status:total===0n?'PAID':'UNPAID',
        items:{create:{product_id:row.product_id,product_name_snapshot:row.product.name,unit_snapshot:{value:row.product.unit_value.toString(),type:row.product.unit_type},unit_price_paise:rate,qty:revision.qty,line_total_paise:subtotal,milk_quantity_ml:milk}},
        timeline:{create:{status}}}});
      await this.notifications.enqueue(tx,{recipientId:vendor.user_id,role:'VENDOR',type:'ORDER_NEW',sourceKey:`order:${order.id}:new`,entityId:order.id});
      if(auto && row.customer.user_id)await this.notifications.enqueue(tx,{recipientId:row.customer.user_id,role:'CUSTOMER',type:'ORDER_ACCEPTED',sourceKey:`order:${order.id}:1`,entityId:order.id});
      counts.created!++;
    }
    await tx.subscription_generation_runs.update({where:{delivery_date:dateOnly(date)},data:{completed_work:{increment:1},generated_orders:{increment:counts.created!},skipped_subscriptions:{increment:counts.skipped!}}});
    await this.finish(tx,date);
    return counts;
  }
  async alertOverdue() {
    const clock=await this.clock.now(this.db);
    const dates=await this.db.$transaction(async tx=>{
      const runs=await tx.$queryRaw<{delivery_date:Date;expected_work:number;completed_work:number}[]>`SELECT delivery_date,expected_work,completed_work
        FROM subscription_generation_runs WHERE finished_at IS NULL AND alerted_at IS NULL AND due_at+interval '30 minutes'<=${clock.now}
        ORDER BY due_at LIMIT 100 FOR UPDATE SKIP LOCKED`;
      for(const run of runs) {
        await tx.subscription_generation_runs.update({where:{delivery_date:run.delivery_date},data:{alerted_at:clock.now}});
        await tx.audit_logs.create({data:{actor_type:'SYSTEM',action:'SUBSCRIPTION_GENERATION_INCOMPLETE',entity:'SUBSCRIPTION_GENERATION',
          after:{deliveryDate:dayString(run.delivery_date),expectedWork:run.expected_work,completedWork:run.completed_work}}});
      }
      return runs.map(r=>dayString(r.delivery_date));
    });
    for(const date of dates)this.logger.error(`SUBSCRIPTION_GENERATION_INCOMPLETE:${date}`,undefined,'Subscriptions');
    return dates;
  }
}
