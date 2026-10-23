import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Socket } from "node:net";

type DependencyResult = "up" | "down";

type HealthDependency = {
  status: DependencyResult;
  details?: string;
};

@Injectable()
export class HealthService {
  constructor(private readonly configService: ConfigService) {}

  getLiveness() {
    return {
      status: "UP",
      timestamp: new Date().toISOString(),
    };
  }

  async getReadiness() {
    const checks = {
      database: await this.checkTcpDependency("DATABASE_URL", "postgresql", 5432),
      redis: await this.checkTcpDependency("REDIS_URL", "redis", 6379),
    };

    const strict = this.configService.get<boolean>("HEALTHCHECK_STRICT", false);
    const hasFailure = Object.values(checks).some((value) => value.status === "down");
    const status = hasFailure ? "DOWN" : "UP";

    return {
      status,
      strict,
      checks,
      shouldFailHttpStatus: strict && hasFailure,
      timestamp: new Date().toISOString(),
    };
  }

  private async checkTcpDependency(
    key: string,
    defaultProtocol: string,
    defaultPort: number
  ): Promise<HealthDependency> {
    const value = this.configService.get<string>(key);
    if (!value) {
      return { status: "down", details: `${key} is not set` };
    }

    try {
      const parsed = this.parseHostAndPort(value, defaultProtocol, defaultPort);
      await this.assertTcpReachable(parsed.host, parsed.port, 1500);
      return { status: "up" };
    } catch (error) {
      return {
        status: "down",
        details: error instanceof Error ? error.message : "unknown error",
      };
    }
  }

  private parseHostAndPort(value: string, defaultProtocol: string, defaultPort: number) {
    const withProtocol = /^[a-zA-Z]+:\/\//.test(value) ? value : `${defaultProtocol}://${value}`;
    const parsed = new URL(withProtocol);
    const host = parsed.hostname;
    const port = parsed.port ? Number(parsed.port) : defaultPort;
    if (!host || !Number.isInteger(port) || port <= 0 || port > 65535) {
      throw new Error(`Invalid endpoint: ${value}`);
    }
    return { host, port };
  }

  private assertTcpReachable(host: string, port: number, timeoutMs: number): Promise<void> {
    return new Promise((resolve, reject) => {
      const socket = new Socket();
      const timeout = setTimeout(() => {
        socket.destroy();
        reject(new Error(`connection timeout to ${host}:${port}`));
      }, timeoutMs);

      socket.once("error", (error) => {
        clearTimeout(timeout);
        const errorCode = "code" in error && typeof error.code === "string" ? error.code : null;
        const errorMessage = error.message?.trim() ? error.message.trim() : null;
        const detail = [errorCode, errorMessage].filter(Boolean).join(" ");
        reject(new Error(`${host}:${port}${detail ? ` ${detail}` : ""}`));
      });

      socket.connect(port, host, () => {
        clearTimeout(timeout);
        socket.end();
        resolve();
      });
    });
  }
}
