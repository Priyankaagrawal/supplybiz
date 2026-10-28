import { ServiceUnavailableException } from "@nestjs/common";
import { OtpDelivery, OtpProvider } from "./otp.types";

/** Q-09: production delivery remains disabled until provider/DLT approval. */
export class SmsOtpProvider implements OtpProvider {
  assertAvailable(): never {
    throw new ServiceUnavailableException({
      code: "OTP_PROVIDER_UNAVAILABLE",
      detail: "OTP delivery is unavailable.",
    });
  }
  async deliver(_delivery: OtpDelivery): Promise<void> {
    this.assertAvailable();
  }
}
export class WhatsAppOtpProvider extends SmsOtpProvider {}

/** Development/test simulation. Never prints or retains mobile numbers/OTPs.
 * A test may inject a capture callback; no HTTP or diagnostic route exposes it.
 */
export class ConsoleOtpProvider implements OtpProvider {
  constructor(
    private readonly environment: string,
    private readonly sink: (delivery: OtpDelivery) => Promise<void> = async () => {}
  ) {}

  assertAvailable(): void {
    if (!["development", "test"].includes(this.environment)) {
      throw new ServiceUnavailableException({
        code: "OTP_PROVIDER_UNAVAILABLE",
        detail: "OTP delivery is unavailable.",
      });
    }
  }
  async deliver(delivery: OtpDelivery): Promise<void> {
    this.assertAvailable();
    await this.sink(delivery);
  }
}
