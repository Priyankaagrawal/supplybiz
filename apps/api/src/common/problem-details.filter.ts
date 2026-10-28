import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from "@nestjs/common";
import { Request, Response } from "express";
import { REQUEST_ID_HEADER } from "./request-id.middleware";

type ValidationErrorEntry = {
  field: string;
  code: string;
  message: string;
};

@Catch()
export class ProblemDetailsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = request.header(REQUEST_ID_HEADER) ?? "unknown";

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      const responseBody =
        typeof exceptionResponse === "string"
          ? { message: exceptionResponse }
          : (exceptionResponse as Record<string, unknown>);
      const validationErrors = this.getValidationErrors(responseBody, status);

      const title = this.getTitle(status, responseBody);
      const code = this.getCode(status, responseBody);
      const detail = this.getDetail(responseBody);
      const retryAfter = responseBody.retryAfterSec;
      if (
        status === HttpStatus.TOO_MANY_REQUESTS &&
        typeof retryAfter === "number" &&
        Number.isInteger(retryAfter) &&
        retryAfter > 0
      ) {
        response.setHeader("Retry-After", String(retryAfter));
      }

      response.status(status).json({
        type: `https://docs.supplybiz.app/errors/${code}`,
        title,
        status,
        code,
        detail,
        requestId,
        ...(validationErrors ? { errors: validationErrors } : {}),
      });
      return;
    }

    // eslint-disable-next-line no-console
    console.error("Unhandled exception", exception);
    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      type: "https://docs.supplybiz.app/errors/INTERNAL",
      title: "Internal server error",
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      code: "INTERNAL",
      detail: "Unexpected server error",
      requestId,
    });
  }

  private getCode(status: number, body: Record<string, unknown>): string {
    const bodyCode = body.code;
    if (typeof bodyCode === "string" && bodyCode.length > 0) {
      return bodyCode;
    }
    if (status === HttpStatus.BAD_REQUEST) {
      return "VALIDATION_FAILED";
    }
    if (status === HttpStatus.UNAUTHORIZED) {
      return "UNAUTHENTICATED";
    }
    if (status === HttpStatus.FORBIDDEN) {
      return "FORBIDDEN";
    }
    if (status === HttpStatus.NOT_FOUND) {
      return "NOT_FOUND";
    }
    if (status === HttpStatus.CONFLICT) {
      return "CONFLICT";
    }
    if (status === HttpStatus.UNPROCESSABLE_ENTITY) {
      return "BUSINESS_RULE_VIOLATION";
    }
    if (status === HttpStatus.TOO_MANY_REQUESTS) {
      return "RATE_LIMITED";
    }
    if (status === 426) {
      return "UPGRADE_REQUIRED";
    }
    return "INTERNAL";
  }

  private getTitle(status: number, body: Record<string, unknown>): string {
    const bodyTitle = body.title;
    if (typeof bodyTitle === "string" && bodyTitle.length > 0) {
      return bodyTitle;
    }
    if (status === HttpStatus.BAD_REQUEST) {
      return "Validation failed";
    }
    return "Request failed";
  }

  private getDetail(body: Record<string, unknown>): string {
    const detail = body.detail ?? body.message;
    if (typeof detail === "string") {
      return detail;
    }
    return "Request failed";
  }

  private getValidationErrors(
    body: Record<string, unknown>,
    status: number
  ): ValidationErrorEntry[] | undefined {
    if (status !== HttpStatus.BAD_REQUEST) {
      return undefined;
    }

    const message = body.message;
    if (!Array.isArray(message)) {
      return undefined;
    }

    return message
      .filter((entry): entry is string => typeof entry === "string")
      .map((entry) => ({
        field: "unknown",
        code: "INVALID",
        message: entry,
      }));
  }
}
