import { Injectable, NestMiddleware } from "@nestjs/common";
import { NextFunction, Request, Response } from "express";
import pino from "pino";
import { REQUEST_ID_HEADER } from "./request-id.middleware";

const logger = pino({
  level: process.env.NODE_ENV === "production" ? "info" : "debug",
});

@Injectable()
export class HttpLoggerMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const startTime = Date.now();
    res.on("finish", () => {
      logger.info({
        requestId: req.header(REQUEST_ID_HEADER),
        method: req.method,
        path: req.path,
        status: res.statusCode,
        latencyMs: Date.now() - startTime,
      });
    });
    next();
  }
}
