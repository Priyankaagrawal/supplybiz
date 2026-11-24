import { ExpiredRetentionService } from './modules/privacy/expired-retention.service';
import { PersonalErasureService } from './modules/privacy/personal-erasure.service';
import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { PinoLogger } from "./common/logging/pino.logger";
import { OutboxDispatcherService } from "./outbox/outbox-dispatcher.service";
import { NotificationsService } from './modules/notifications/notifications.service';
import { LedgerJobsService } from './modules/ledger/ledger-jobs.service';
import { ReportExportsService } from './modules/reports/report-exports.service';
import { SubscriptionGenerationService } from './modules/subscriptions/subscription-generation.service';

async function bootstrapWorker(): Promise<void> {
  const app = await NestFactory.createApplicationContext(AppModule, {
    bufferLogs: true,
  });
  const logger = app.get(PinoLogger);
  app.useLogger(logger);
  logger.log("Worker context bootstrapped", "Worker");
  const dispatcher = app.get(OutboxDispatcherService);
  dispatcher.start();
  const ledgerJobs = app.get(LedgerJobsService);
  ledgerJobs.start();
  const subscriptionJobs = app.get(SubscriptionGenerationService);
  subscriptionJobs.start();
  const notifications = app.get(NotificationsService);
  const reportExports = app.get(ReportExportsService);
  const personalErasure = app.get(PersonalErasureService);
  const expiredRetention = app.get(ExpiredRetentionService);
  let cleanupRun: Promise<void> | undefined;
  const cleanup = () => cleanupRun ??= (async () => {
    for (let i = 0; i < 100; i++) if (await notifications.cleanupExpired() < 500) break;
  })().catch(() => { logger.warn('NOTIFICATION_CLEANUP_FAILED', 'Worker'); })
    .then(async () => { for (let i = 0; i < 100; i++) if (await reportExports.cleanupExpired() < 500) break; })
    .catch(() => { logger.warn('REPORT_EXPORT_CLEANUP_FAILED', 'Worker'); })
    .then(async () => { for(let i=0;i<100;i++)if(await personalErasure.runBatch()<10)break; })
    .catch(() => { logger.warn('PERSONAL_ERASURE_FAILED', 'Worker'); })
    .then(async () => { await expiredRetention.runFinancialBatch(); for(let i=0;i<100;i++)if(await expiredRetention.runAuditBatch()===0)break; })
    .catch(() => { logger.warn('EXPIRED_PRIVACY_RETENTION_FAILED', 'Worker'); })
    .finally(() => { cleanupRun = undefined; });
  void cleanup();
  const cleanupTimer = setInterval(() => { void cleanup(); }, 3600000);

  const shutdown = async () => {
    clearInterval(cleanupTimer);
    await ledgerJobs.onModuleDestroy();
    await subscriptionJobs.onModuleDestroy();
    await cleanupRun;
    dispatcher.stop();
    await dispatcher.onModuleDestroy();
    await app.close();
    process.exit(0);
  };

  process.on("SIGINT", () => { void shutdown(); });
  process.on("SIGTERM", () => { void shutdown(); });
}

bootstrapWorker().catch(() => {
  console.error("Failed to bootstrap worker; check database and persistent storage configuration.");
  process.exit(1);
});
