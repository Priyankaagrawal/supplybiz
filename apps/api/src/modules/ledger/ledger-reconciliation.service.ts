import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PinoLogger } from '../../common/logging/pino.logger';
import { LedgerService } from './ledger.service';

type BalanceRow = { id: string; debit: string; credit: string; actual_debit: string | null;
  actual_credit: string | null; actual_due: string | null };
@Injectable()
export class LedgerReconciliationService {
  constructor(private readonly ledger: LedgerService, private readonly logger: PinoLogger) {}
  /** Each single SQL statement sees entries and their trigger-maintained balance
   * in one MVCC snapshot, avoiding false alerts from concurrent committed posts. */
  async batch(tx: Prisma.TransactionClient, date: string, cursor: string | null = null, limit = 100) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0,10) !== date ||
      (cursor !== null && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(cursor)) || !Number.isInteger(limit) || limit < 1 || limit > 100) throw new Error('Invalid reconciliation batch');
    await this.ledger.assertPrivileges(tx);
    const rows = await tx.$queryRaw<BalanceRow[]>`
      WITH batch AS (
        SELECT c.id FROM vendor_customers c WHERE (${cursor}::uuid IS NULL OR c.id > ${cursor}::uuid)
          AND (EXISTS (SELECT 1 FROM ledger_entries e WHERE e.vendor_customer_id = c.id)
            OR EXISTS (SELECT 1 FROM ledger_balances b WHERE b.vendor_customer_id = c.id))
        ORDER BY c.id LIMIT ${limit + 1}
      ) SELECT c.id, sums.debit::text AS debit, sums.credit::text AS credit,
        b.total_debit_paise::text AS actual_debit, b.total_credit_paise::text AS actual_credit, b.due_paise::text AS actual_due
      FROM batch c LEFT JOIN ledger_balances b ON b.vendor_customer_id = c.id
      CROSS JOIN LATERAL (SELECT COALESCE(SUM(e.amount_paise) FILTER (WHERE e.type = 'DEBIT'),0) AS debit,
        COALESCE(SUM(e.amount_paise) FILTER (WHERE e.type = 'CREDIT'),0) AS credit
        FROM ledger_entries e WHERE e.vendor_customer_id = c.id) sums ORDER BY c.id`;
    let driftCount = 0, findingsCreated = 0;
    const page = rows.slice(0,limit);
    for (const row of page) {
      const due = String(BigInt(row.debit) - BigInt(row.credit));
      if (row.debit === row.actual_debit && row.credit === row.actual_credit && due === row.actual_due) continue;
      driftCount++;
      findingsCreated += (await tx.ledger_reconciliation_findings.createMany({ skipDuplicates: true, data: {
        business_date: new Date(date), vendor_customer_id: row.id,
        expected: { totalDebitPaise: row.debit, totalCreditPaise: row.credit, duePaise: due },
        observed: row.actual_debit === null ? Prisma.JsonNull : { totalDebitPaise: row.actual_debit,
          totalCreditPaise: row.actual_credit, duePaise: row.actual_due },
      } })).count;
    }
    if (driftCount) this.logger.error('LEDGER_RECONCILIATION_DRIFT', undefined, 'Ledger');
    return { checked: page.length, driftCount, findingsCreated, nextCursor: rows.length > limit ? page.at(-1)!.id : null };
  }
}
