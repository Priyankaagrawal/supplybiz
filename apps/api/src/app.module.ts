import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { ThrottlerGuard, ThrottlerModule } from "@nestjs/throttler";
import { APP_GUARD, APP_INTERCEPTOR } from "@nestjs/core";
import { validateEnv } from "./config/env.schema";
import { HealthModule } from "./health/health.module";
import { VersionController } from "./version.controller";
import { RequestIdMiddleware } from "./common/request-id.middleware";
import { HttpLoggerMiddleware } from "./common/http-logger.middleware";
import { PinoLogger } from "./common/logging/pino.logger";
import { PrismaService } from "./prisma/prisma.service";
import { IdempotencyInterceptor } from "./modules/idempotency/idempotency.interceptor";
import { IdempotencyService } from "./modules/idempotency/idempotency.service";
import { IdempotencyTestController } from "./modules/idempotency/idempotency-test.controller";
import { IdempotencyTestService } from "./modules/idempotency/idempotency-test.service";
import { OutboxDispatcherService } from "./outbox/outbox-dispatcher.service";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    ThrottlerModule.forRootAsync({
      useFactory: () => {
        const ttl = Number(process.env.RATE_LIMIT_TTL_SECONDS ?? 60);
        const limit = Number(process.env.RATE_LIMIT_MAX_REQUESTS ?? 120);
        return [{ ttl: ttl * 1000, limit }];
      },
    }),
    HealthModule,
  ],
  controllers: [VersionController, IdempotencyTestController],
  providers: [
    PrismaService,
    PinoLogger,
    IdempotencyService,
    IdempotencyTestService,
    OutboxDispatcherService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: IdempotencyInterceptor,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestIdMiddleware, HttpLoggerMiddleware).forRoutes("*");
  }
}
