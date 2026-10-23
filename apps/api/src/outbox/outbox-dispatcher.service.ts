import { Injectable } from "@nestjs/common";
import { outbox_event_status } from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";
import { PinoLogger } from "../common/logging/pino.logger";

@Injectable()
export class OutboxDispatcherService {
  private interval: NodeJS.Timeout | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly logger: PinoLogger
  ) {}

  start(): void {
    if (this.interval) {
      return;
    }
    this.interval = setInterval(() => {
      void this.dispatchPendingBatch();
    }, 5000);
  }

  stop(): void {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }

  async dispatchPendingBatch(batchSize = 50): Promise<number> {
    const events = await this.prisma.outbox_events.findMany({
      where: {
        status: outbox_event_status.PENDING,
        available_at: { lte: new Date() },
      },
      orderBy: { created_at: "asc" },
      take: batchSize,
    });

    if (events.length === 0) {
      return 0;
    }

    for (const event of events) {
      await this.prisma.outbox_events.update({
        where: { id: event.id },
        data: {
          status: outbox_event_status.DISPATCHED,
          attempt_count: { increment: 1 },
          dispatched_at: new Date(),
        },
      });
    }

    this.logger.log(`Dispatched ${events.length} outbox event(s)`, "OutboxDispatcher");
    return events.length;
  }
}
