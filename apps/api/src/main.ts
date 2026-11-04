import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { configureHttpApp } from "./bootstrap";

async function bootstrap(): Promise<void> {

  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });
  configureHttpApp(app);
  app.enableShutdownHooks();

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
}

bootstrap().catch(() => {
  console.error("Failed to bootstrap API; check database and persistent storage configuration.");
  process.exit(1);
});
