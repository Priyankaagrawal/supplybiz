import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { HomeQuery } from './home.dto';

/** The optional instant supports deterministic DB timezone boundary checks; never supplied by HTTP. */
export async function homeClock(tx: Prisma.TransactionClient, instant?: Date) {
  const clock = instant ? Prisma.sql`${instant}::timestamptz` : Prisma.sql`statement_timestamp()`;
  const [result] = await tx.$queryRaw<{ day: string; now: Date }[]>`
    SELECT to_char(${clock} AT TIME ZONE 'Asia/Kolkata', 'YYYY-MM-DD') AS day, ${clock} AS now`;
  return result!;
}
@Injectable()
export class HomeService {
  constructor(private readonly db: PrismaService) {}
  get(userId: string, query: HomeQuery) {
    return this.db.$transaction(async tx => {
      const user = await tx.users.findUnique({ where: { id: userId }, include: { roles: true } });
      if (!user || user.status !== 'ACTIVE' || user.active_role !== 'CUSTOMER' || !user.roles.some(r => r.role === 'CUSTOMER')) {
        throw new ForbiddenException({ code: 'CUSTOMER_ROLE_REQUIRED' });
      }
      const clock = await homeClock(tx);
      const deliveryDate = new Date(`${clock.day}T00:00:00.000Z`);
      // Only accepted account linkage grants access. Matching mobile is never sufficient.
      const owned = { delivery_date: deliveryDate, customer: { user_id: userId } };
      const anchor = query.cursor ? await tx.orders.findFirst({ where: { ...owned, id: query.cursor }, select: { id: true, created_at: true } }) : null;
      if (query.cursor && !anchor) throw new BadRequestException({ code: 'INVALID_CURSOR' });
      const categories = await tx.categories.findMany({ where: { type: 'SUPPLY', status: { in: ['ENABLED', 'COMING_SOON'] } },
        orderBy: [{ sort_order: 'asc' }, { id: 'asc' }] });
      const orders = await tx.orders.findMany({ where: { ...owned, ...(anchor ? { OR: [
        { created_at: { lt: anchor.created_at } }, { created_at: anchor.created_at, id: { lt: anchor.id } },
      ] } : {}) }, take: (query.limit ?? 20) + 1, orderBy: [{ created_at: 'desc' }, { id: 'desc' }],
        include: { vendor: { select: { business_name: true } }, items: { orderBy: { id: 'asc' } } } });
      const page = orders.slice(0, query.limit ?? 20);
      return {
        serverTime: clock.now.toISOString(), businessDate: clock.day,
        categories: categories.map(c => ({ id: c.id, code: c.code, name: c.name_en, icon: c.icon,
          status: c.status, available: c.status === 'ENABLED',
          productTypes: Array.isArray(c.product_types) ? c.product_types.filter((t): t is string => typeof t === 'string') : [] })),
        deliveries: page.map(o => ({ id: o.id, orderNo: o.order_no, vendorId: o.vendor_id, vendorName: o.vendor.business_name,
          source: o.source, status: o.status, deliveryDate: clock.day, timeSlot: o.time_slot,
          items: o.items.map(i => ({ productId: i.product_id, name: i.product_name_snapshot, qty: i.qty })) })),
        nextCursor: orders.length > page.length ? page.at(-1)!.id : null,
      };
    }, { isolationLevel: 'RepeatableRead' });
  }
}
