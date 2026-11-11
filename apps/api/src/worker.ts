import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { PinoLogger } from "./common/logging/pino.logger";
import { OutboxDispatcherService } from "./outbox/outbox-dispatcher.service";
import { NotificationsService } from './modules/notifications/notifications.service';
import { LedgerJobsService } from './modules/ledger/ledger-jobs.service';

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
  const notifications = app.get(NotificationsService);
  let cleanupRun: Promise<void> | undefined;
  const cleanup = () => cleanupRun ??= (async () => {
    for (let i = 0; i < 100; i++) if (await notifications.cleanupExpired() < 500) break;
  })().catch(() => { logger.warn('NOTIFICATION_CLEANUP_FAILED', 'Worker'); })
    .finally(() => { cleanupRun = undefined; });
  void cleanup();
  const cleanupTimer = setInterval(() => { void cleanup(); }, 3600000);

  const shutdown = async () => {
    clearInterval(cleanupTimer);
    await ledgerJobs.onModuleDestroy();
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
