import { Injectable, OnModuleInit } from '@nestjs/common';
import { Prisma, vendor_plan_assignments } from '@prisma/client';
import { OutboxDispatcherService } from '../../outbox/outbox-dispatcher.service';
import { NotificationsService } from '../notifications/notifications.service';
import { z } from 'zod';

export const PLAN_REMINDER = 'PLAN_REMINDER';
const DAY = 86400000;
@Injectable()
export class PlanRemindersService implements OnModuleInit {
  constructor(private readonly dispatcher: OutboxDispatcherService, private readonly notifications: NotificationsService) {}
  onModuleInit() {
    this.dispatcher.register(PLAN_REMINDER, async (event, tx) => {
      const payload = z.object({ assignmentId: z.string().uuid(), days: z.union([z.literal(7), z.literal(3), z.literal(1), z.literal(0)]) }).strict().parse(event.payload);
      const candidate = await tx.vendor_plan_assignments.findUnique({ where: { id: payload.assignmentId } });
      if (!candidate) return { skipped: 1 };
      // Same vendor lock as grant/extension: an obsolete reminder cannot race a renewal.
      await tx.$queryRaw`SELECT id FROM vendors WHERE id = ${candidate.vendor_id}::uuid FOR UPDATE`;
      const row = await tx.vendor_plan_assignments.findUniqueOrThrow({ where: { id: candidate.id }, include: { vendor: true, plan: true } });
      const [clock] = await tx.$queryRaw<{ now: Date }[]>`SELECT clock_timestamp() AS now`;
      const days = Number(payload.days), remaining = row.ends_at.getTime() - clock!.now.getTime();
      const next = days === 7 ? 3 : days === 3 ? 1 : 0;
      // Catch up the latest meaningful stage after downtime; suppress obsolete stages.
      if (row.superseded_at || row.vendor.is_suspended || row.plan.status !== 'ACTIVE' || row.starts_at > clock!.now ||
        remaining > days * DAY || (days > 0 && remaining <= next * DAY)) return { skipped: 1 };
      const id = await this.notifications.enqueue(tx, { recipientId: row.vendor.user_id, role: 'VENDOR',
        type: days === 0 ? 'PLAN_EXPIRED' : 'PLAN_EXPIRING', sourceKey: `plan:${row.id}:${days}` });
      return { notified: id ? 1 : 0 };
    });
  }
  async schedule(tx: Prisma.TransactionClient, row: vendor_plan_assignments, now: Date) {
    for (const days of [7, 3, 1, 0]) {
      const due = new Date(row.ends_at.getTime() - days * DAY);
      // A short grant does not retroactively send reminders for time before assignment.
      if (due < now || due < row.starts_at) continue;
      const event = await tx.outbox_events.create({ data: { aggregate_type: 'JOB', aggregate_id: row.id, event_type: PLAN_REMINDER,
        available_at: due, payload: { assignmentId: row.id, days } } });
      const businessDate = new Date(due.getTime() + 19800000).toISOString().slice(0, 10);
      await tx.job_runs.create({ data: { job_type: PLAN_REMINDER, business_date: new Date(businessDate), scope_id: `${row.id}:${days}`, event_id: event.id } });
    }
  }
}
