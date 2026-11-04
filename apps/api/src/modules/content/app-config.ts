import { CanActivate, Controller, ExecutionContext, Get, Header, HttpException, Injectable, ServiceUnavailableException } from "@nestjs/common";
import { ApiOkResponse, ApiOperation, ApiProperty, ApiTags } from "@nestjs/swagger";
import { Request } from "express";
import { z } from "zod";
import { PrismaService } from "../../prisma/prisma.service";

const version = z.string().regex(/^(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})\.(0|[1-9]\d{0,5})$/);
const policy = z.object({ minVersionAndroid: version, flags: z.record(z.boolean()) }).strict();
export function isOlderVersion(current: string, minimum: string): boolean {
  const a = version.parse(current).split(".").map(Number);
  const b = version.parse(minimum).split(".").map(Number);
  for (let i = 0; i < 3; i++) { if (a[i] !== b[i]) return a[i] < b[i]; }
  return false;
}
export class AppConfigResponse {
  @ApiProperty({ example: "0.1.0", pattern: "^(0|[1-9]\\d{0,5})\\.(0|[1-9]\\d{0,5})\\.(0|[1-9]\\d{0,5})$" })
  minVersionAndroid!: string;
  @ApiProperty({ type: "object", additionalProperties: { type: "boolean" } })
  flags!: Record<string, boolean>;
}
@Injectable()
export class AppConfigService {
  constructor(private readonly prisma: PrismaService) {}
  async read(): Promise<AppConfigResponse> {
    try {
      const row = await this.prisma.app_config.findUnique({ where: { key: "mobile" } });
      return policy.parse(row?.value);
    } catch {
      // Configuration errors fail closed without exposing stored values or DB details.
      throw new ServiceUnavailableException({ code: "CONFIG_UNAVAILABLE", message: "App configuration is unavailable." });
    }
  }
}
@ApiTags("Configuration")
@Controller("config")
export class AppConfigController {
  constructor(private readonly config: AppConfigService) {}
  @Get()
  @Header("Cache-Control", "public, max-age=60")
  @ApiOperation({ summary: "Get public mobile minimum version and simple flags" })
  @ApiOkResponse({ type: AppConfigResponse })
  read(): Promise<AppConfigResponse> { return this.config.read(); }
}
@Injectable()
export class AppVersionGuard implements CanActivate {
  constructor(private readonly config: AppConfigService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    // Config and operational probes stay available to an outdated installation.
    if (request.method === "GET" && /^\/api\/v1\/(config|version|health\/(live|ready))\/?$/.test(request.path)) return true;
    if (request.header("X-Platform") !== "android") return true;
    const current = request.header("X-App-Version");
    if (!version.safeParse(current).success) throw new HttpException({ code: "INVALID_APP_VERSION", message: "A valid app version is required." }, 400);
    if (isOlderVersion(current!, (await this.config.read()).minVersionAndroid)) {
      throw new HttpException({ code: "UPGRADE_REQUIRED", message: "Update the app to continue." }, 426);
    }
    return true;
  }
}
