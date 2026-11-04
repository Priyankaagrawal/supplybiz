import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { AbuseTransaction, PostgresAbuseState } from "../../common/abuse/postgres-abuse-state";
import { OtpChallenge, OtpDecision, OtpPolicy, OtpStore } from "./otp.types";

type Challenge = OtpChallenge & { status: "PENDING" | "ACTIVE" | "EXHAUSTED"; attempts: number; expires: number };
type Lockout = { streak: number; until: number };
type Policy = Omit<OtpPolicy, "pepper">;
const HOUR = 3600000;

@Injectable()
export class PostgresOtpStore implements OtpStore {
  constructor(private readonly state: PostgresAbuseState, private readonly config: ConfigService) {}

  private key(kind: string, digest: string): string {
    return `otp:${kind}:${digest}`;
  }

  private atomic<T>(keys: string[], operation: (tx: AbuseTransaction) => Promise<T>): Promise<T> {
    if (this.config.get<string>("OTP_DELIVERY_MODE") === "disabled") {
      throw new Error("OTP disabled");
    }
    return this.state.atomic(keys, operation);
  }

  async reserve(keys: { mobile: string; ip: string; device: string },
    challenge: OtpChallenge, policy: Policy): Promise<OtpDecision> {
    const challengeKey = this.key("challenge", keys.mobile);
    const lockoutKey = this.key("lockout", keys.mobile);
    const budgets = [
      { key: this.key("mobile", keys.mobile), limit: 5 },
      { key: this.key("ip", keys.ip), limit: 20 },
      { key: this.key("device", keys.device), limit: policy.deviceSendsPerHour },
    ];
    return this.atomic([challengeKey, lockoutKey, ...budgets.map(b => b.key)], async tx => {
      const lockout = await tx.read<Lockout>(lockoutKey);
      let retry = Math.max(0, (lockout?.until ?? 0) - tx.now);
      const histories: number[][] = [];
      for (const [index, budget] of budgets.entries()) {
        const history = (await tx.read<number[]>(budget.key) ?? []).filter(t => t > tx.now - HOUR);
        histories.push(history);
        if (history.length >= budget.limit) retry = Math.max(retry, history[0]! + HOUR - tx.now);
        if (index === 0 && history.length) retry = Math.max(retry, history[history.length - 1]! + 30000 - tx.now);
      }
      if (retry > 0) return { result: "RATE_LIMITED", retryAfterSec: Math.ceil(retry / 1000) };
      for (const [index, budget] of budgets.entries()) {
        await tx.write(budget.key, [...histories[index]!, tx.now], tx.now + HOUR);
      }
      await tx.write(challengeKey, { ...challenge, status: "PENDING", attempts: 0,
        expires: tx.now + 300000 } satisfies Challenge, tx.now + 300000);
      return { result: "OK" };
    });
  }

  async activate(mobile: string, revision: string): Promise<void> {
    const key = this.key("challenge", mobile);
    await this.atomic([key], async tx => {
      const challenge = await tx.read<Challenge>(key);
      if (!challenge || challenge.revision !== revision || challenge.status !== "PENDING") {
        throw new Error("OTP delivery superseded or expired");
      }
      await tx.write(key, { ...challenge, status: "ACTIVE" }, challenge.expires);
    });
  }

  async discard(mobile: string, revision: string): Promise<void> {
    const key = this.key("challenge", mobile);
    await this.atomic([key], async tx => {
      if ((await tx.read<Challenge>(key))?.revision === revision) await tx.remove(key);
    });
  }

  async read(mobile: string): Promise<OtpChallenge | null> {
    const key = this.key("challenge", mobile);
    return this.atomic([key], async tx => {
      const value = await tx.read<Challenge>(key);
      return value ? { revision: value.revision, salt: value.salt, digest: value.digest } : null;
    });
  }

  async consume(mobile: string, revision: string, matches: boolean, policy: Policy): Promise<OtpDecision> {
    const key = this.key("challenge", mobile);
    const lockoutKey = this.key("lockout", mobile);
    return this.atomic([key, lockoutKey], async tx => {
      const challenge = await tx.read<Challenge>(key);
      if (!challenge) return { result: "OTP_EXPIRED" };
      if (challenge.revision !== revision) return { result: "OTP_INVALID" };
      if (challenge.status === "EXHAUSTED") return { result: "OTP_ATTEMPTS_EXCEEDED" };
      if (challenge.status !== "ACTIVE") return { result: "OTP_INVALID" };
      if (matches) {
        await tx.remove(key);
        return { result: "OK" };
      }
      challenge.attempts++;
      if (challenge.attempts >= 5) {
        challenge.status = "EXHAUSTED";
        const streak = (await tx.read<Lockout>(lockoutKey))?.streak ?? 0;
        const delay = Math.min(policy.lockoutMaxSeconds, policy.lockoutBaseSeconds * 2 ** Math.min(streak, 30));
        await tx.write(lockoutKey, { streak: streak + 1, until: tx.now + delay * 1000 }, tx.now + HOUR);
      }
      await tx.write(key, challenge, challenge.expires);
      return { result: challenge.status === "EXHAUSTED" ? "OTP_ATTEMPTS_EXCEEDED" : "OTP_INVALID" };
    });
  }
}
