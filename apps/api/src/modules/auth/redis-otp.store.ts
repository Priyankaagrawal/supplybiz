import { Injectable, OnModuleDestroy } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "redis";
import { CHANGE_OTP, CONSUME_OTP, RESERVE_OTP } from "./otp.scripts";
import { OtpChallenge, OtpDecision, OtpPolicy, OtpStore } from "./otp.types";

@Injectable()
export class RedisOtpStore implements OtpStore, OnModuleDestroy {
  private readonly client;
  private connection?: Promise<unknown>;
  constructor(private readonly config: ConfigService) {
    this.client = createClient({
      url: config.getOrThrow<string>("REDIS_URL"),
      disableOfflineQueue: true,
      socket: { connectTimeout: 2000, reconnectStrategy: false },
    });
    // The client requires an error handler. Never log Redis command arguments.
    this.client.on("error", () => {
      this.connection = undefined;
    });
    this.client.on("end", () => {
      this.connection = undefined;
    });
  }
  private key(kind: string, digest: string): string {
    const prefix = this.config.get<string>("OTP_REDIS_PREFIX", "otp");
    return `${prefix}:{${prefix}}:${kind}:${digest}`;
  }
  private async ready(): Promise<void> {
    if (this.config.get<string>("OTP_DELIVERY_MODE") === "disabled")
      throw new Error("OTP disabled");
    if (!this.client.isReady) {
      this.connection ??= this.client.connect().catch(() => {
        this.connection = undefined;
        throw new Error("OTP store unavailable");
      });
      await this.connection;
    }
  }
  async reserve(
    keys: { mobile: string; ip: string; device: string },
    challenge: OtpChallenge,
    policy: Omit<OtpPolicy, "pepper">
  ): Promise<OtpDecision> {
    await this.ready();
    return this.decision(
      await this.client.eval(RESERVE_OTP, {
        keys: [
          this.key("challenge", keys.mobile),
          this.key("sends", keys.mobile),
          this.key("ip", keys.ip),
          this.key("device", keys.device),
          this.key("lockout", keys.mobile),
        ],
        arguments: [
          challenge.revision,
          String(policy.deviceSendsPerHour),
          JSON.stringify({ ...challenge, status: "PENDING", attempts: 0 }),
        ],
      })
    );
  }
  async activate(mobile: string, revision: string): Promise<void> {
    await this.ready();
    const activated = await this.client.eval(CHANGE_OTP, {
      keys: [this.key("challenge", mobile)],
      arguments: [revision, "activate"],
    });
    if (activated !== 1) throw new Error("OTP delivery superseded or expired");
  }
  async discard(mobile: string, revision: string): Promise<void> {
    await this.ready();
    await this.client.eval(CHANGE_OTP, {
      keys: [this.key("challenge", mobile)],
      arguments: [revision, "discard"],
    });
  }
  async read(mobile: string): Promise<OtpChallenge | null> {
    await this.ready();
    const raw = await this.client.get(this.key("challenge", mobile));
    if (!raw) return null;
    const data: unknown = JSON.parse(raw);
    if (
      typeof data !== "object" ||
      data === null ||
      !("revision" in data) ||
      !("salt" in data) ||
      !("digest" in data) ||
      typeof data.revision !== "string" ||
      typeof data.salt !== "string" ||
      typeof data.digest !== "string"
    ) {
      throw new Error("Invalid OTP store record");
    }
    return { revision: data.revision, salt: data.salt, digest: data.digest };
  }
  async consume(
    mobile: string,
    revision: string,
    matches: boolean,
    policy: Omit<OtpPolicy, "pepper">
  ): Promise<OtpDecision> {
    await this.ready();
    return this.decision(
      await this.client.eval(CONSUME_OTP, {
        keys: [this.key("challenge", mobile), this.key("lockout", mobile)],
        arguments: [
          revision,
          String(matches),
          String(policy.lockoutBaseSeconds),
          String(policy.lockoutMaxSeconds),
        ],
      })
    );
  }
  private decision(value: unknown): OtpDecision {
    if (!Array.isArray(value)) throw new Error("Invalid OTP store response");
    switch (value[0]) {
      case "OK":
        return { result: "OK" };
      case "RATE_LIMITED":
        return { result: "RATE_LIMITED", retryAfterSec: Number(value[1]) };
      case "OTP_INVALID":
      case "OTP_EXPIRED":
      case "OTP_ATTEMPTS_EXCEEDED":
        return { result: value[0] };
      default:
        throw new Error("Invalid OTP store response");
    }
  }
  async onModuleDestroy(): Promise<void> {
    if (this.client.isOpen) this.client.destroy();
  }
}
