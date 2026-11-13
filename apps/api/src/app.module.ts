import { DashboardController } from './modules/dashboard/dashboard.controller';
import { DashboardService } from './modules/dashboard/dashboard.service';
import { HomeController } from './modules/home/home.controller';
import { HomeService } from './modules/home/home.service';
import { DiscoveryController } from './modules/discovery/discovery.controller';
import { DiscoveryService } from './modules/discovery/discovery.service';
import { AddressesController } from './modules/addresses/addresses.controller';
import { AddressesService } from './modules/addresses/addresses.service';
import { CatalogController } from './modules/catalog/catalog.controller';
import { ManagementController } from './modules/management/management.controller';
import { ManagementService } from './modules/management/management.service';
import { PlanEntitlementsService } from './modules/plans/plan-entitlements.service';
import { PlanGuard } from './modules/plans/plan.guard';
import { PlansService } from './modules/plans/plans.service';
import { PlanRemindersService } from './modules/plans/plan-reminders.service';
import { AdminPlansController, VendorPlansController } from './modules/plans/plans.controller';
import { LedgerService } from './modules/ledger/ledger.service';
import { LedgerReconciliationService } from './modules/ledger/ledger-reconciliation.service';
import { LedgerJobsService } from './modules/ledger/ledger-jobs.service';
import { CustomersController, CustomerLinksController } from './modules/customers/customers.controller';
import { CustomersService } from './modules/customers/customers.service';
import { NotificationsController } from './modules/notifications/notifications.controller';
import { NotificationsService } from './modules/notifications/notifications.service';
import { FcmService } from './modules/notifications/fcm.service';
import { CatalogService } from './modules/catalog/catalog.service';
import { OrdersService } from './modules/orders/orders.service';
import { DeliveryEffectsService } from './modules/orders/delivery-effects.service';
import { CustomerOrdersController, VendorOrdersController, VendorDeliveriesController } from './modules/orders/orders.controller';
import { CategoriesController } from './modules/categories/categories.controller';
import { KycController, AdminKycController } from './modules/kyc/kyc.controller';
import { KycService } from './modules/kyc/kyc.service';
import { AuditController } from './modules/audit/audit.controller';
import { VendorsController } from './modules/vendors/vendors.controller';
import { VendorsService } from './modules/vendors/vendors.service';
import { LocalStorageModule } from "./storage/local-storage.module";
import { MediaService } from "./modules/media/media.service";
import { MediaController, AdminMediaController } from "./modules/media/media.controller";
import { AdminAuthController, AdminGuard } from './modules/admin-auth/admin-auth.controller';
import { AdminAuthService } from './modules/admin-auth/admin-auth.service';
import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { ThrottlerGuard, ThrottlerModule } from "@nestjs/throttler";
import { APP_GUARD, APP_INTERCEPTOR } from "@nestjs/core";
import { AppConfigController, AppConfigService, AppVersionGuard } from "./modules/content/app-config";
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
import { AuthModule } from "./modules/auth/auth.module";
import { AbuseModule } from "./common/abuse/abuse.module";
import { PostgresAbuseState } from "./common/abuse/postgres-abuse-state";
import { PostgresThrottlerStorage } from "./common/abuse/postgres-throttler.storage";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    ThrottlerModule.forRootAsync({
      imports: [AbuseModule],
      inject: [PostgresAbuseState, ConfigService],
      useFactory: (state: PostgresAbuseState, config: ConfigService) => {
        const ttl = config.getOrThrow<number>("RATE_LIMIT_TTL_SECONDS");
        const limit = config.getOrThrow<number>("RATE_LIMIT_MAX_REQUESTS");
        return { throttlers: [{ ttl: ttl * 1000, limit }],
          storage: new PostgresThrottlerStorage(state, limit) };
      },
    }),
    HealthModule,
    LocalStorageModule,
    AuthModule,
  ],
  // Synthetic mutation fixtures are available only to automated tests.
  controllers: [CustomerOrdersController, VendorOrdersController, VendorDeliveriesController, DashboardController, HomeController, DiscoveryController, AddressesController, ManagementController, AdminPlansController, VendorPlansController, CustomersController, CustomerLinksController, NotificationsController, CatalogController, CategoriesController, KycController, AdminKycController, AuditController, VendorsController, MediaController, AdminMediaController, AdminAuthController, VersionController, AppConfigController, ...(process.env.NODE_ENV === "test" ? [IdempotencyTestController] : [])],
  providers: [
    PrismaService,
    OrdersService,
    DeliveryEffectsService,
    DashboardService,
    HomeService,
    DiscoveryService,
    AddressesService,
    ManagementService,
    PlanEntitlementsService,
    PlanGuard,
    PlansService,
    PlanRemindersService,
    LedgerService,
    LedgerReconciliationService,
    LedgerJobsService,
    CustomersService,
    MediaService,
    VendorsService,
    CatalogService,
    NotificationsService,
    FcmService,
    KycService,
    AdminAuthService,
    { provide: APP_GUARD, useClass: AdminGuard },
    AppConfigService,
    { provide: APP_GUARD, useClass: AppVersionGuard },
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
