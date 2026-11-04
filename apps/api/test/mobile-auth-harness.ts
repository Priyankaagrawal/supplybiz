import "reflect-metadata";
import { Test } from "@nestjs/testing";
import { generateKeyPairSync, randomBytes } from "node:crypto";
import { configureHttpApp } from "../src/bootstrap";
import { ConsoleOtpProvider } from "../src/modules/auth/otp.providers";
import { OTP_PROVIDERS, OtpDelivery } from "../src/modules/auth/otp.types";

/** Debugger-only capture: break here to inspect this synthetic delivery, then resume.
 * Never print, persist or expose the code through an HTTP endpoint.
 */
async function inspectDelivery(delivery: OtpDelivery): Promise<void> {
  void delivery;
}

async function bootstrap(): Promise<void> {
  if (["production", "staging"].includes(process.env.NODE_ENV ?? "")) {
    throw new Error("Test harness unavailable outside development/test");
  }
  const url = new URL(process.env.MOBILE_AUTH_TEST_DATABASE_URL ?? "");
  if (!url.pathname.endsWith("_test")) throw new Error("A dedicated _test database is required");
  Object.assign(process.env, {
    NODE_ENV: "test", DATABASE_URL: url.toString(), OTP_DELIVERY_MODE: "console",
    OTP_HMAC_PEPPER: randomBytes(32).toString("hex"),
    AUTH_SIGNING_KEY_ID: "synthetic-mobile-harness", AUTH_PREVIOUS_PUBLIC_KEYS: "{}",
    AUTH_SIGNING_PRIVATE_KEY: generateKeyPairSync("ed25519").privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
  });
  const { AppModule } = await import("../src/app.module");
  const provider = new ConsoleOtpProvider("test", inspectDelivery);
  const module = await Test.createTestingModule({ imports: [AppModule] })
    .overrideProvider(OTP_PROVIDERS).useValue({ SMS: provider, WHATSAPP: provider }).compile();
  const app = module.createNestApplication();
  configureHttpApp(app);
  try { await app.listen(3000, "127.0.0.1"); }
  catch (error) { await app.close(); throw error; }
  app.enableShutdownHooks();
  console.info("T-016 test-only API listening on http://127.0.0.1:3000; inspect delivery in the debugger, never log OTPs.");
}
void bootstrap().catch(() => {
  console.error("T-016 harness startup failed; check isolated test database/private storage configuration.");
  process.exitCode = 1;
});
