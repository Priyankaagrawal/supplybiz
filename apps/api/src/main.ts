import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { initOpenTelemetry, shutdownOpenTelemetry } from "./telemetry/otel";
import { configureHttpApp } from "./bootstrap";

async function bootstrap(): Promise<void> {
  const otelEnabled = process.env.OTEL_ENABLED === "true";
  await initOpenTelemetry(otelEnabled);

  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });
  configureHttpApp(app);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
}

bootstrap().catch(async (error) => {
  // eslint-disable-next-line no-console
  console.error("Failed to bootstrap API", error);
  await shutdownOpenTelemetry();
  process.exit(1);
});
