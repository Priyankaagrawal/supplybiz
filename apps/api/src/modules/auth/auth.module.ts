import { Module } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { OtpController } from "./otp.controller";
import { OtpService } from "./otp.service";
import { RedisOtpStore } from "./redis-otp.store";
import { ConsoleOtpProvider, SmsOtpProvider, WhatsAppOtpProvider } from "./otp.providers";
import {
  OTP_POLICY,
  OTP_PROVIDERS,
  OTP_STORE,
  OtpChannel,
  OtpPolicy,
  OtpProvider,
} from "./otp.types";

@Module({
  controllers: [OtpController],
  providers: [
    OtpService,
    RedisOtpStore,
    { provide: OTP_STORE, useExisting: RedisOtpStore },
    {
      provide: OTP_POLICY,
      inject: [ConfigService],
      useFactory: (config: ConfigService): OtpPolicy => ({
        pepper: config.get<string>("OTP_HMAC_PEPPER", ""),
        deviceSendsPerHour: config.getOrThrow<number>("OTP_DEVICE_SENDS_PER_HOUR"),
        lockoutBaseSeconds: config.getOrThrow<number>("OTP_LOCKOUT_BASE_SECONDS"),
        lockoutMaxSeconds: config.getOrThrow<number>("OTP_LOCKOUT_MAX_SECONDS"),
      }),
    },
    {
      provide: OTP_PROVIDERS,
      inject: [ConfigService],
      useFactory: (config: ConfigService): Record<OtpChannel, OtpProvider> => {
        if (config.get<string>("OTP_DELIVERY_MODE") === "console") {
          const consoleProvider = new ConsoleOtpProvider(config.getOrThrow<string>("NODE_ENV"));
          return { SMS: consoleProvider, WHATSAPP: consoleProvider };
        }
        return { SMS: new SmsOtpProvider(), WHATSAPP: new WhatsAppOtpProvider() };
      },
    },
  ],
  exports: [OtpService],
})
export class AuthModule {}
