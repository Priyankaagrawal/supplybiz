import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { PrismaService } from "../prisma/prisma.service";
import { LocalStorageService } from "../storage/local-storage.service";

@Injectable()
export class HealthService {
  constructor(private readonly config: ConfigService, private readonly prisma: PrismaService,
    private readonly storage: LocalStorageService) {}

  getLiveness() { return { status: "UP", timestamp: new Date().toISOString() }; }

  async getReadiness() {
    const checks = {
      database: await this.check(async () => { await this.prisma.$queryRaw`SELECT 1`; }),
      storage: await this.check(() => this.storage.check()),
    };
    const strict = this.config.get<boolean>("HEALTHCHECK_STRICT", true);
    const hasFailure = Object.values(checks).some(value => value.status === "down");
    return { status: hasFailure ? "DOWN" : "UP", strict, checks,
      shouldFailHttpStatus: strict && hasFailure, timestamp: new Date().toISOString() };
  }

  private async check(operation: () => Promise<void>): Promise<{ status: "up" | "down" }> {
    try { await operation(); return { status: "up" }; }
    // Paths, SQL parameters and connection errors must not appear in public probes.
    catch { return { status: "down" }; }
  }
}
