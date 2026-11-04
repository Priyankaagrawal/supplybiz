import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../../prisma/prisma.service";

export class AbuseTransaction {
  constructor(private readonly tx: Prisma.TransactionClient, readonly now: number) {}

  async read<T>(key: string): Promise<T | null> {
    const rows = await this.tx.$queryRaw<{ value: T }[]>`
      SELECT value FROM auth_abuse_state
      WHERE key = ${key} AND expires_at > to_timestamp(${this.now}::double precision / 1000)`;
    return rows[0]?.value ?? null;
  }

  async write(key: string, value: unknown, expiresAt: number): Promise<void> {
    await this.tx.$executeRaw`
      INSERT INTO auth_abuse_state (key, value, expires_at)
      VALUES (${key}, ${JSON.stringify(value)}::jsonb,
        to_timestamp(${expiresAt}::double precision / 1000))
      ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, expires_at = EXCLUDED.expires_at`;
  }

  async remove(key: string): Promise<void> {
    await this.tx.$executeRaw`DELETE FROM auth_abuse_state WHERE key = ${key}`;
  }
}

/** T-180: all writers lock purpose-hashed keys, including absent rows. */
@Injectable()
export class PostgresAbuseState implements OnModuleInit, OnModuleDestroy {
  private timer?: ReturnType<typeof setInterval>;
  private cleaning = false;
  private readonly logger = new Logger(PostgresAbuseState.name);

  constructor(private readonly prisma: PrismaService) {}

  async atomic<T>(keys: string[], operation: (tx: AbuseTransaction) => Promise<T>): Promise<T> {
    return this.prisma.$transaction(async (tx) => {
      // A deterministic order avoids deadlocks between overlapping mobile/IP/device sets.
      for (const key of [...new Set(keys)].sort()) {
        await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${key}, 180))::text`;
      }
      // Read time after lock waits; transaction_timestamp() would be stale here.
      const [clock] = await tx.$queryRaw<{ now: number }[]>`
        SELECT floor(extract(epoch FROM clock_timestamp()) * 1000)::double precision AS now`;
      if (!clock) throw new Error("Database clock unavailable");
      return operation(new AbuseTransaction(tx, clock.now));
    }, { maxWait: 5000, timeout: 10000 });
  }

  async cleanup(): Promise<void> {
    // Bounded batches, with row locking so replicas can clean concurrently.
    await this.prisma.$executeRaw`
      DELETE FROM auth_abuse_state WHERE key IN (
        SELECT key FROM auth_abuse_state WHERE expires_at <= clock_timestamp()
        ORDER BY expires_at LIMIT 500 FOR UPDATE SKIP LOCKED
      )`;
  }

  onModuleInit(): void {
    this.timer = setInterval(() => {
      if (this.cleaning) return;
      this.cleaning = true;
      void this.cleanup().catch(() => {
        this.logger.warn("Auth abuse-state expiry cleanup failed");
      }).finally(() => { this.cleaning = false; });
    }, 60000);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }
}
