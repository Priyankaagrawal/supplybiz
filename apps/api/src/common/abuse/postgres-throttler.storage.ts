import { ServiceUnavailableException } from "@nestjs/common";
import { ThrottlerStorage } from "@nestjs/throttler";
import { createHash } from "node:crypto";
import { PostgresAbuseState } from "./postgres-abuse-state";

/** Shared sliding HTTP budget, including OTP verify and session refresh/logout. */
export class PostgresThrottlerStorage implements ThrottlerStorage {
  constructor(private readonly state: PostgresAbuseState, private readonly limit: number) {}

  async increment(input: string, ttl: number) {
    const key = `http:${createHash("sha256").update(`http-rate:${input}`).digest("hex")}`;
    try {
      return await this.state.atomic([key], async tx => {
        const hits = (await tx.read<number[]>(key) ?? []).filter(t => t > tx.now - ttl);
        const totalHits = hits.length + 1;
        // Rejected requests do not grow state or extend the block indefinitely.
        if (hits.length < this.limit) {
          hits.push(tx.now);
          await tx.write(key, hits, tx.now + ttl);
        }
        return { totalHits, timeToExpire: Math.max(1, Math.ceil(((hits[0] ?? tx.now) + ttl - tx.now) / 1000)) };
      });
    } catch {
      throw new ServiceUnavailableException({ code: "DEPENDENCY_UNAVAILABLE", detail: "Please try again later." });
    }
  }
}
