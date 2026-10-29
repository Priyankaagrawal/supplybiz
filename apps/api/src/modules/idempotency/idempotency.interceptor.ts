import {
  BadRequestException,
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Observable, from, of } from "rxjs";
import { mergeMap } from "rxjs/operators";
import { Request, Response } from "express";
import { IdempotencyService } from "./idempotency.service";
import { IDEMPOTENCY_HEADER, NO_IDEMPOTENCY_CACHE } from "../../common/idempotency.constants";

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
  constructor(private readonly idempotencyService: IdempotencyService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const httpContext = context.switchToHttp();
    const request = httpContext.getRequest<Request>();
    const response = httpContext.getResponse<Response>();
    const method = request.method.toUpperCase();

    if (!["POST", "PUT", "PATCH", "DELETE"].includes(method)) {
      return next.handle();
    }

    const key = request.header(IDEMPOTENCY_HEADER);
    if (!key || !key.trim()) {
      throw new BadRequestException({
        code: "VALIDATION_FAILED",
        title: "Validation failed",
        detail: "Idempotency-Key header is required for mutation requests.",
        errors: [{ field: "Idempotency-Key", code: "REQUIRED", message: "Header is required" }],
      });
    }

    if (Reflect.getMetadata(NO_IDEMPOTENCY_CACHE, context.getHandler()) ||
        Reflect.getMetadata(NO_IDEMPOTENCY_CACHE, context.getClass())) {
      return next.handle();
    }

    const requestHash = this.idempotencyService.hashRequestBody(request.body ?? {});
    const path = request.path;

    return from(
      this.idempotencyService.getReplayResponse({
        key,
        method,
        path,
        requestHash,
      })
    ).pipe(
      mergeMap((cached) => {
        if (cached) {
          response.status(cached.responseStatus);
          return of(cached.responseBody);
        }

        return next.handle().pipe(
          mergeMap((handlerResponse) =>
            from(
              this.idempotencyService.storeResponse({
                key,
                method,
                path,
                requestHash,
                responseStatus: response.statusCode,
                responseBody: handlerResponse,
              })
            ).pipe(mergeMap(() => of(handlerResponse)))
          )
        );
      })
    );
  }
}
