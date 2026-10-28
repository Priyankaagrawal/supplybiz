export type OtpChannel = "SMS" | "WHATSAPP";
export type OtpDelivery = {
  mobile: string;
  code: string;
  channel: OtpChannel;
  appHash?: string;
};
export interface OtpProvider {
  assertAvailable(): void;
  deliver(delivery: OtpDelivery): Promise<void>;
}
export type OtpPolicy = {
  pepper: string;
  deviceSendsPerHour: number;
  lockoutBaseSeconds: number;
  lockoutMaxSeconds: number;
};
export type OtpChallenge = {
  revision: string;
  salt: string;
  digest: string;
};
export type OtpDecision =
  | { result: "OK" }
  | { result: "RATE_LIMITED"; retryAfterSec: number }
  | { result: "OTP_INVALID" | "OTP_EXPIRED" | "OTP_ATTEMPTS_EXCEEDED" };
export interface OtpStore {
  reserve(
    keys: { mobile: string; ip: string; device: string },
    challenge: OtpChallenge,
    policy: Omit<OtpPolicy, "pepper">
  ): Promise<OtpDecision>;
  activate(mobile: string, revision: string): Promise<void>;
  discard(mobile: string, revision: string): Promise<void>;
  read(mobile: string): Promise<OtpChallenge | null>;
  consume(
    mobile: string,
    revision: string,
    matches: boolean,
    policy: Omit<OtpPolicy, "pepper">
  ): Promise<OtpDecision>;
}
export const OTP_STORE = Symbol("OTP_STORE");
export const OTP_PROVIDERS = Symbol("OTP_PROVIDERS");
export const OTP_POLICY = Symbol("OTP_POLICY");
