import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { PinoLogger } from "./common/logging/pino.logger";
import { OutboxDispatcherService } from "./outbox/outbox-dispatcher.service";

async function bootstrapWorker(): Promise<void> {
  const app = await NestFactory.createApplicationContext(AppModule, {
    bufferLogs: true,
  });
  const logger = app.get(PinoLogger);
  app.useLogger(logger);
  logger.log("Worker context bootstrapped", "Worker");
  const dispatcher = app.get(OutboxDispatcherService);
  dispatcher.start();

  const shutdown = async () => {
    dispatcher.stop();
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
