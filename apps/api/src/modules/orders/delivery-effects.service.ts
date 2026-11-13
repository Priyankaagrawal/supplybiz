// T-049: called only inside the owned, versioned order transaction/vendor lock.
import { BadRequestException, ConflictException, Injectable } from '@nestjs/common';
import { orders, Prisma } from '@prisma/client';
import { CatalogService } from '../catalog/catalog.service';
import { LedgerService } from '../ledger/ledger.service';
import { PlanEntitlementsService } from '../plans/plan-entitlements.service';
import { homeClock } from '../home/home.service';
import { OrderTransitionInput } from './orders.dto';
@Injectable()
export class DeliveryEffectsService {
  constructor(private readonly catalog:CatalogService,private readonly ledger:LedgerService,private readonly plans:PlanEntitlementsService) {}
  async complete(tx:Prisma.TransactionClient,actorId:string,order:orders,input:OrderTransitionInput) {
    const payment=input.payment;
    if (!payment || typeof payment.collected!=='boolean' || payment.collected && (!payment.method || !payment.amountPaise) ||
      !payment.collected && (payment.method!==undefined || payment.amountPaise!==undefined)) throw new BadRequestException({code:'DELIVERY_PAYMENT_REQUIRED'});
    const amount=payment.collected?BigInt(payment.amountPaise!):0n;
    if (amount<0n || amount>9223372036854775807n || payment.collected && amount===0n) throw new BadRequestException({code:'INVALID_PAYMENT_AMOUNT'});
    if (order.total_paise<=0n) throw new ConflictException({code:'ORDER_TOTAL_INVALID'});
    await this.ledger.assertPrivileges(tx);
    if (payment.collected) await this.plans.requireOperation(tx,order.vendor_id,'RECORD_PAYMENT');
    const items=await tx.order_items.findMany({where:{order_id:order.id},orderBy:{product_id:'asc'}});
    if (!items.length) throw new ConflictException({code:'ORDER_ITEMS_MISSING'});
    const subtotal=items.reduce((sum,item)=>sum+item.line_total_paise,0n);
    if(items.some(i=>i.qty<=0 || i.unit_price_paise<0n || i.line_total_paise!==i.unit_price_paise*BigInt(i.qty)) ||
      subtotal!==order.subtotal_paise || subtotal+order.delivery_charge_paise-order.discount_paise!==order.total_paise) {
      throw new ConflictException({code:'ORDER_TOTAL_INVALID'});
    }
    const quantities=new Map<string,bigint>();
    for(const item of items) quantities.set(item.product_id,(quantities.get(item.product_id) ?? 0n)+BigInt(item.qty));
    for(const [productId,qty] of quantities) {
      if(qty>2147483647n) throw new ConflictException({code:'INSUFFICIENT_STOCK'});
      await this.catalog.changeStock(tx,{vendorId:order.vendor_id,productId,actorId,delta:-Number(qty),reason:'ORDER',note:'Delivered order',refId:order.id});
    }
    const clock=await homeClock(tx);
    // Snapshot total, including vendor charges, is authoritative; current prices are irrelevant.
    await this.ledger.post(tx,{actorId,vendorId:order.vendor_id,customerId:order.vendor_customer_id,type:'DEBIT',amountPaise:order.total_paise,
      refType:'ORDER',refId:order.id,note:'Delivered order',entryDate:clock.day});
    if(payment.collected) {
      const receipt=await tx.payments.create({data:{vendor_id:order.vendor_id,vendor_customer_id:order.vendor_customer_id,order_id:order.id,created_by:actorId,
        amount_paise:amount,method:payment.method!,received_on:new Date(clock.day),note:'Payment collected at delivery',client_ref:`delivery:${order.id}`}});
      await this.ledger.post(tx,{actorId,vendorId:order.vendor_id,customerId:order.vendor_customer_id,type:'CREDIT',amountPaise:amount,
        refType:'PAYMENT',refId:receipt.id,note:'Payment collected at delivery',entryDate:clock.day});
    }
    return {completedAt:clock.now,paymentStatus:order.payment_status==='PAID' || amount>=order.total_paise?'PAID':'UNPAID'};
  }
}
