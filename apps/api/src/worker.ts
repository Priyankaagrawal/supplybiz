import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { PinoLogger } from "./common/logging/pino.logger";
import { initOpenTelemetry, shutdownOpenTelemetry } from "./telemetry/otel";
import { OutboxDispatcherService } from "./outbox/outbox-dispatcher.service";

async function bootstrapWorker(): Promise<void> {
  await initOpenTelemetry(process.env.OTEL_ENABLED === "true");
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
    await shutdownOpenTelemetry();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

bootstrapWorker().catch(async (error) => {
  // eslint-disable-next-line no-console
  console.error("Failed to bootstrap worker", error);
  await shutdownOpenTelemetry();
  process.exit(1);
});
