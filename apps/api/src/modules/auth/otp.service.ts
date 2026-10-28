import {
  BadRequestException,
  HttpException,
  Inject,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import { createHmac, randomBytes, randomInt, randomUUID, timingSafeEqual } from "node:crypto";
import { isIP } from "node:net";
import {
  OTP_POLICY,
  OTP_PROVIDERS,
  OTP_STORE,
  OtpChannel,
  OtpDecision,
  OtpPolicy,
  OtpProvider,
  OtpStore,
} from "./otp.types";

@Injectable()
export class OtpService {
  constructor(
    @Inject(OTP_STORE) private readonly store: OtpStore,
    @Inject(OTP_PROVIDERS) private readonly providers: Record<OtpChannel, OtpProvider>,
    @Inject(OTP_POLICY) private readonly policy: OtpPolicy
  ) {}

  async send(
    input: { mobile: string; channel?: OtpChannel; appHash?: string },
    context: { ip: string; deviceId: string }
  ): Promise<{ resendAfterSec: number; expiresInSec: number }> {
    const mobile = this.mobile(input.mobile);
    const channel = input.channel ?? "SMS";
    if (
      !["SMS", "WHATSAPP"].includes(channel) ||
      (input.appHash !== undefined && !/^[A-Za-z0-9+/]{11}$/.test(input.appHash)) ||
      typeof context.ip !== "string" ||
      !isIP(context.ip) ||
      typeof context.deviceId !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(context.deviceId)
    ) {
      throw new BadRequestException({ code: "VALIDATION_FAILED", detail: "Invalid OTP request." });
    }
    const provider = this.providers[channel];
    provider.assertAvailable();
    const key = this.key("mobile", mobile);
    const code = randomInt(0, 1_000_000).toString().padStart(6, "0");
    const salt = randomBytes(16).toString("hex");
    const revision = randomUUID();
    const challenge = { revision, salt, digest: this.digest(key, salt, code).toString("hex") };
    this.assertDecision(
      await this.safe(() =>
        this.store.reserve(
          {
            mobile: key,
            ip: this.key("ip", context.ip),
            device: this.key("device", context.deviceId),
          },
          challenge,
          this.policy
        )
      )
    );
    try {
      await provider.deliver({
        mobile,
        code,
        channel,
        ...(input.appHash ? { appHash: input.appHash } : {}),
      });
    } catch {
      await this.safe(() => this.store.discard(key, revision));
      throw new ServiceUnavailableException({
        code: "OTP_PROVIDER_UNAVAILABLE",
        detail: "OTP delivery is unavailable.",
      });
    }
    await this.safe(() => this.store.activate(key, revision));
    return { resendAfterSec: 30, expiresInSec: 300 };
  }

  /** T-015 calls this before issuing tokens. Success atomically consumes the OTP.
   * No public verify endpoint returns a fake session in T-014.
   */
  async verify(mobileInput: string, code: string): Promise<void> {
    const mobile = this.mobile(mobileInput);
    if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
      throw new BadRequestException({ code: "VALIDATION_FAILED", detail: "Invalid OTP request." });
    }
    const key = this.key("mobile", mobile);
    const challenge = await this.safe(() => this.store.read(key));
    if (!challenge) {
      throw new HttpException({ code: "OTP_EXPIRED", detail: "OTP verification failed." }, 410);
    }
    const actual = this.digest(key, challenge.salt, code);
    const expected = Buffer.from(challenge.digest, "hex");
    const matches = expected.length === actual.length && timingSafeEqual(expected, actual);
    this.assertDecision(
      await this.safe(() => this.store.consume(key, challenge.revision, matches, this.policy))
    );
  }

  private mobile(value: string): string {
    if (typeof value !== "string" || !/^(?:\+91)?[6-9]\d{9}$/.test(value)) {
      throw new BadRequestException({
        code: "VALIDATION_FAILED",
        detail: "Invalid Indian mobile number.",
      });
    }
    return value.startsWith("+91") ? value : `+91${value}`;
  }
  private key(kind: string, value: string): string {
    return createHmac("sha256", this.policy.pepper).update(`${kind}:${value}`).digest("hex");
  }
  private digest(key: string, salt: string, code: string): Buffer {
    return createHmac("sha256", this.policy.pepper).update(`otp:${key}:${salt}:${code}`).digest();
  }
  private assertDecision(decision: OtpDecision): void {
    if (decision.result === "OK") return;
    if (decision.result === "RATE_LIMITED") {
      throw new HttpException(
        {
          code: decision.result,
          detail: "Please wait before trying again.",
          retryAfterSec: decision.retryAfterSec,
        },
        429
      );
    }
    throw new HttpException(
      { code: decision.result, detail: "OTP verification failed." },
      decision.result === "OTP_EXPIRED" ? 410 : 422
    );
  }
  private async safe<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch {
      // Redis/provider errors can include command arguments and secrets.
      throw new ServiceUnavailableException({
        code: "OTP_UNAVAILABLE",
        detail: "OTP service is unavailable.",
      });
    }
  }
}
