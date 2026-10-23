import { Injectable, LoggerService } from "@nestjs/common";
import pino, { Logger } from "pino";

@Injectable()
export class PinoLogger implements LoggerService {
  private readonly logger: Logger;

  constructor() {
    this.logger = pino({
      level: process.env.NODE_ENV === "production" ? "info" : "debug",
      redact: {
        paths: [
          "req.headers.authorization",
          "authorization",
          "otp",
          "token",
          "refreshToken",
          "pan",
          "aadhaar",
          "bankAccountNumber",
        ],
        censor: "[REDACTED]",
      },
    });
  }

  log(message: string, context?: string): void {
    this.logger.info({ context }, message);
  }

  error(message: string, trace?: string, context?: string): void {
    this.logger.error({ context, trace }, message);
  }

  warn(message: string, context?: string): void {
    this.logger.warn({ context }, message);
  }

  debug(message: string, context?: string): void {
    this.logger.debug({ context }, message);
  }

  verbose(message: string, context?: string): void {
    this.logger.trace({ context }, message);
  }
}
