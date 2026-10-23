import {
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ApiOkResponse, ApiOperation, ApiServiceUnavailableResponse, ApiTags } from "@nestjs/swagger";
import { HealthService } from "./health.service";

@ApiTags("Health")
@Controller("health")
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @ApiOperation({ summary: "Liveness probe" })
  @ApiOkResponse({
    schema: {
      type: "object",
      properties: {
        status: { type: "string", example: "UP" },
        timestamp: { type: "string", format: "date-time" },
      },
      required: ["status", "timestamp"],
    },
  })
  @Get("live")
  @HttpCode(HttpStatus.OK)
  getLive() {
    return this.healthService.getLiveness();
  }

  @ApiOperation({ summary: "Readiness probe" })
  @ApiOkResponse({
    schema: {
      type: "object",
      additionalProperties: true,
    },
  })
  @ApiServiceUnavailableResponse({ description: "Service dependencies unavailable" })
  @Get("ready")
  async getReady() {
    const readiness = await this.healthService.getReadiness();
    if (readiness.shouldFailHttpStatus) {
      throw new ServiceUnavailableException({
        code: "DEPENDENCY_UNAVAILABLE",
        title: "Service is not ready",
        detail: readiness,
      });
    }
    return readiness;
  }
}
