import { z } from "zod";
import { homedir } from "node:os";
import { isAbsolute, join } from "node:path";

export const envSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "staging", "production"]).default("development"),
    PORT: z.coerce.number().int().positive().default(3000),
    DATABASE_URL: z.string().url().default("postgresql://localhost:5432/supplybiz"),
    FIELD_ENCRYPTION_KEY: z.string().regex(/^[a-f0-9]{64}$/i).optional(),
    ADMIN_TOTP_KEY: z.string().regex(/^[a-f0-9]{64}$/i).optional(),
    AUTH_SIGNING_PRIVATE_KEY: z.string().min(1).optional(),
    AUTH_SIGNING_KEY_ID: z.string().regex(/^[a-zA-Z0-9_-]{1,80}$/).default("development"),
    AUTH_PREVIOUS_PUBLIC_KEYS: z.string().default("{}").transform((value, context) => {
      try {
        return z.record(z.string()).parse(JSON.parse(value));
      } catch {
        context.addIssue({ code: z.ZodIssueCode.custom, message: "Must be a JSON object of public PEM keys." });
        return z.NEVER;
      }
    }),
    OTP_DELIVERY_MODE: z.enum(["disabled", "console"]).default("disabled"),
    FCM_ENABLED: z.enum(["true", "false"]).default("false").transform(value => value === "true"),
    FCM_SERVICE_ACCOUNT_JSON: z.string().min(16).max(20000).optional(),
    OTP_HMAC_PEPPER: z.string().min(32).optional(),
    OTP_DEVICE_SENDS_PER_HOUR: z.coerce.number().int().positive().default(5),
    OTP_LOCKOUT_BASE_SECONDS: z.coerce.number().int().positive().default(30),
    OTP_LOCKOUT_MAX_SECONDS: z.coerce.number().int().positive().max(3600).default(3600),
    UPLOAD_ROOT: z.string().min(1).refine(isAbsolute, "Must be an absolute path").optional(),
    UPLOAD_MAX_BYTES: z.coerce.number().int().positive().max(5242880).default(5242880),
    UPLOAD_MAX_PIXELS: z.coerce.number().int().positive().max(20000000).default(20000000),
    HEALTHCHECK_STRICT: z
      .enum(["true", "false"])
      .default("true")
      .transform((value) => value === "true"),
    RATE_LIMIT_TTL_SECONDS: z.coerce.number().int().positive().default(60),
    RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(120),

  })
  .superRefine((value, context) => {
    if (value.FCM_ENABLED && !value.FCM_SERVICE_ACCOUNT_JSON) {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ['FCM_SERVICE_ACCOUNT_JSON'], message: 'Required when FCM is enabled.' });
    }
    if (["staging", "production"].includes(value.NODE_ENV) && !value.UPLOAD_ROOT) {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ["UPLOAD_ROOT"],
        message: "Persistent storage must be explicitly configured outside development/test." });
    }
    if (["staging", "production"].includes(value.NODE_ENV) &&
        (!value.AUTH_SIGNING_PRIVATE_KEY || value.AUTH_SIGNING_KEY_ID === "development")) {
      context.addIssue({ code: z.ZodIssueCode.custom, path: ["AUTH_SIGNING_PRIVATE_KEY"],
        message: "A persistent Ed25519 signing key and non-development key ID are required." });
    }
    if (
      value.OTP_DELIVERY_MODE === "console" &&
      (!["development", "test"].includes(value.NODE_ENV) || !value.OTP_HMAC_PEPPER)
    ) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["OTP_DELIVERY_MODE"],
        message: "Console simulation requires development/test and OTP_HMAC_PEPPER.",
      });
    }
    if (value.OTP_LOCKOUT_MAX_SECONDS < value.OTP_LOCKOUT_BASE_SECONDS) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["OTP_LOCKOUT_MAX_SECONDS"],
        message: "Must be at least OTP_LOCKOUT_BASE_SECONDS.",
      });
    }
  })
  .transform(value => ({ ...value, UPLOAD_ROOT: value.UPLOAD_ROOT ?? join(homedir(), ".local", "share", "supplybiz", "uploads") }));

export type AppEnv = z.infer<typeof envSchema>;

export function validateEnv(input: Record<string, unknown>): AppEnv {
  const parsed = envSchema.safeParse(input);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Invalid environment variables: ${issues}`);
  }
  return parsed.data;
}
