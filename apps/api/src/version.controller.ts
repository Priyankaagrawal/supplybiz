import { Controller, Get } from "@nestjs/common";
import { ApiOkResponse, ApiOperation, ApiTags } from "@nestjs/swagger";

@ApiTags("Version")
@Controller("version")
export class VersionController {
  @ApiOperation({ summary: "Get build metadata" })
  @ApiOkResponse({
    schema: {
      type: "object",
      properties: {
        service: { type: "string", example: "api" },
        version: { type: "string", example: "0.1.0" },
        nodeEnv: { type: "string", example: "development" },
        buildTime: { type: "string", nullable: true },
        gitSha: { type: "string", nullable: true },
      },
      required: ["service", "version", "nodeEnv"],
    },
  })
  @Get()
  getVersion() {
    return {
      service: "api",
      version: process.env.npm_package_version ?? "0.1.0",
      nodeEnv: process.env.NODE_ENV ?? "development",
      buildTime: process.env.BUILD_TIME ?? null,
      gitSha: process.env.GIT_SHA ?? null,
    };
  }
}
