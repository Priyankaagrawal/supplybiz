import "reflect-metadata";
import { writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { NestFactory } from "@nestjs/core";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import yaml from "js-yaml";
import { AppModule } from "../src/app.module";
import { configureHttpApp } from "../src/bootstrap";

async function main(): Promise<void> {
  process.env.NODE_ENV = process.env.NODE_ENV ?? "development";
  process.env.DATABASE_URL =
    process.env.DATABASE_URL ?? "postgresql://localhost:5432/supplybiz";
  process.env.REDIS_URL = process.env.REDIS_URL ?? "redis://localhost:6379";

  const app = await NestFactory.create(AppModule, { logger: false });
  configureHttpApp(app);

  const config = new DocumentBuilder()
    .setTitle("Supply Biz API")
    .setVersion("0.1.0")
    .addBearerAuth()
    .addServer("http://localhost:3000")
    .build();

  const document = SwaggerModule.createDocument(app, config);
  const outputPath = resolve(__dirname, "../../../contracts/openapi.yaml");
  writeFileSync(outputPath, yaml.dump(document, { noRefs: true, lineWidth: 120 }), "utf8");
  await app.close();
}

main().catch((error) => {
  // eslint-disable-next-line no-console
  console.error("Failed to generate OpenAPI document", error);
  process.exit(1);
});
