import { z } from "zod";

const urlAllowingProtocolOptional = z
  .string()
  .min(1)
  .transform((value) => {
    if (/^[a-zA-Z]+:\/\//.test(value)) {
      return value;
    }
    return `http://${value}`;
  })
  .pipe(z.string().url());

export const envSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "staging", "production"]).default("development"),
    PORT: z.coerce.number().int().positive().default(3000),
    DATABASE_URL: z.string().url().default("postgresql://localhost:5432/supplybiz"),
    REDIS_URL: z.string().url().default("redis://localhost:6379"),
    OTP_DELIVERY_MODE: z.enum(["disabled", "console"]).default("disabled"),
    OTP_REDIS_PREFIX: z
      .string()
      .regex(/^[a-zA-Z0-9-]{1,80}$/)
      .default("otp"),
    OTP_HMAC_PEPPER: z.string().min(32).optional(),
    OTP_DEVICE_SENDS_PER_HOUR: z.coerce.number().int().positive().default(5),
    OTP_LOCKOUT_BASE_SECONDS: z.coerce.number().int().positive().default(30),
    OTP_LOCKOUT_MAX_SECONDS: z.coerce.number().int().positive().max(3600).default(3600),
    STORAGE_ENDPOINT: urlAllowingProtocolOptional.default("http://localhost:9000"),
    HEALTHCHECK_STRICT: z
      .enum(["true", "false"])
      .default("false")
      .transform((value) => value === "true"),
    RATE_LIMIT_TTL_SECONDS: z.coerce.number().int().positive().default(60),
    RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(120),
    OTEL_ENABLED: z
      .enum(["true", "false"])
      .default("false")
      .transform((value) => value === "true"),
  })
  .superRefine((value, context) => {
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
  });

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
