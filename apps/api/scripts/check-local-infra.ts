import "reflect-metadata";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { PrismaService } from "../src/prisma/prisma.service";
import { validateEnv } from "../src/config/env.schema";
import { LocalStorageService } from "../src/storage/local-storage.service";

async function main(): Promise<void> {
  await ConfigModule.forRoot({ validate: validateEnv });
  const prisma = new PrismaService();
  try {
    await prisma.$connect();
    await prisma.$queryRaw`SELECT 1`;
    console.log("PASS: PostgreSQL authentication and query");
    const [extension] = await prisma.$queryRaw<{ enabled: boolean }[]>`
      SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis') AS enabled`;
    if (!extension?.enabled) throw new Error("POSTGIS_MISSING");
    await prisma.$queryRaw`SELECT PostGIS_Version()`;
    console.log("PASS: PostGIS query");
    const config = new ConfigService(validateEnv(process.env));
    await new LocalStorageService(config).check();
    console.log("PASS: persistent upload directories, permissions, write and disk checks");
  } catch (error) {
    console.error(error instanceof Error && error.message === "POSTGIS_MISSING"
      ? "FAIL: PostGIS must be installed and enabled in this database (CREATE EXTENSION postgis)."
      : "FAIL: native database or upload storage unavailable; check local configuration and permissions.");
    process.exitCode = 1;
  } finally { await prisma.$disconnect(); }
}

void main().catch(() => { console.error("FAIL: invalid native runtime configuration"); process.exitCode = 1; });
