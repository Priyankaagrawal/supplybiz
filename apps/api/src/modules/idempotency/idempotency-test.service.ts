import { Injectable } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { PrismaService } from "../../prisma/prisma.service";

@Injectable()
export class IdempotencyTestService {
  private sideEffectCount = 0;

  constructor(private readonly prisma: PrismaService) {}

  async createOrder(payload: { sku: string; qty: number }) {
    this.sideEffectCount += 1;

    const orderId = randomUUID();
    await this.prisma.outbox_events.create({
      data: {
        aggregate_type: "ORDER",
        aggregate_id: orderId,
        event_type: "ORDER_CREATED",
        payload: {
          orderId,
          sku: payload.sku,
          qty: payload.qty,
          sideEffectCount: this.sideEffectCount,
        },
      },
    });

    return {
      orderId,
      sku: payload.sku,
      qty: payload.qty,
      sideEffectCount: this.sideEffectCount,
    };
  }
}
