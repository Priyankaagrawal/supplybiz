import { Module } from "@nestjs/common";
import { PrismaService } from "../../prisma/prisma.service";
import { PostgresAbuseState } from "./postgres-abuse-state";

@Module({
  providers: [PrismaService, PostgresAbuseState],
  exports: [PostgresAbuseState],
})
export class AbuseModule {}
