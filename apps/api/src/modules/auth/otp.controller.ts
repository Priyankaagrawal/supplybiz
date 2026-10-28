import { BadRequestException, Body, Controller, HttpCode, Post, Req } from "@nestjs/common";
import {
  ApiHeader,
  ApiOperation,
  ApiProperty,
  ApiPropertyOptional,
  ApiResponse,
  ApiTags,
} from "@nestjs/swagger";
import { IsIn, IsString, Matches, ValidateIf } from "class-validator";
import { Request } from "express";
import { OtpChannel } from "./otp.types";
import { OtpService } from "./otp.service";

export class SendOtpDto {
  @ApiProperty({ pattern: "^(?:\\+91)?[6-9]\\d{9}$" })
  @IsString()
  @Matches(/^(?:\+91)?[6-9]\d{9}$/)
  mobile!: string;

  @ApiPropertyOptional({ enum: ["SMS", "WHATSAPP"], description: "Defaults to SMS." })
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsIn(["SMS", "WHATSAPP"])
  channel?: OtpChannel;

  @ApiPropertyOptional({ pattern: "^[A-Za-z0-9+/]{11}$" })
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsString()
  @Matches(/^[A-Za-z0-9+/]{11}$/)
  appHash?: string;
}
export class SendOtpResponse {
  @ApiProperty({ type: "integer", minimum: 30, maximum: 30, example: 30 }) resendAfterSec!: number;
  @ApiProperty({ type: "integer", minimum: 300, maximum: 300, example: 300 }) expiresInSec!: number;
}

@ApiTags("auth")
@Controller("auth/otp")
export class OtpController {
  constructor(private readonly otp: OtpService) {}

  @Post("send")
  @HttpCode(200)
  @ApiOperation({ summary: "Send OTP (development simulation until Q-09 is resolved)" })
  @ApiHeader({ name: "Idempotency-Key", required: true })
  @ApiHeader({
    name: "X-Device-Id",
    required: true,
    description:
      "Stable installation identifier, 1–128 ASCII letters, digits, hyphens or underscores.",
  })
  @ApiResponse({ status: 200, type: SendOtpResponse })
  @ApiResponse({
    status: 400,
    description: "Invalid request or missing device/idempotency header.",
  })
  @ApiResponse({
    status: 429,
    description: "RATE_LIMITED; Retry-After header is seconds until retry.",
  })
  @ApiResponse({ status: 503, description: "OTP delivery disabled or unavailable." })
  send(@Body() input: SendOtpDto, @Req() request: Request): Promise<SendOtpResponse> {
    const deviceId = request.header("X-Device-Id");
    if (!deviceId || !request.ip) {
      throw new BadRequestException({
        code: "VALIDATION_FAILED",
        detail: "Device identifier is required.",
      });
    }
    // Express uses the socket IP; do not accept spoofed forwarded-IP headers.
    return this.otp.send(input, { ip: request.ip, deviceId });
  }
}
