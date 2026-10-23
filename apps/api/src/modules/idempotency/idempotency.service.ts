import { Injectable, UnprocessableEntityException } from "@nestjs/common";
import { createHash } from "node:crypto";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../../prisma/prisma.service";

type CachedResponse = {
  responseStatus: number;
  responseBody: unknown;
};

@Injectable()
export class IdempotencyService {
  constructor(private readonly prisma: PrismaService) {}

  hashRequestBody(body: unknown): string {
    const normalized = JSON.stringify(this.normalize(body));
    return createHash("sha256").update(normalized).digest("hex");
  }

  async getReplayResponse(params: {
    key: string;
    method: string;
    path: string;
    requestHash: string;
  }): Promise<CachedResponse | null> {
    const record = await this.prisma.idempotency_keys.findUnique({
      where: { idempotency_key: params.key },
    });

    if (!record) {
      return null;
    }

    if (record.expires_at <= new Date()) {
      await this.prisma.idempotency_keys.delete({
        where: { idempotency_key: params.key },
      });
      return null;
    }

    if (
      record.request_hash !== params.requestHash ||
      record.path !== params.path ||
      record.method !== params.method
    ) {
      throw new UnprocessableEntityException({
        code: "IDEMPOTENCY_MISMATCH",
        title: "Idempotency key reuse with different request",
        detail: "The same Idempotency-Key was used with a different request payload.",
      });
    }

    return {
      responseStatus: record.response_status,
      responseBody: record.response_body,
    };
  }

  async storeResponse(params: {
    key: string;
    method: string;
    path: string;
    requestHash: string;
    responseStatus: number;
    responseBody: unknown;
  }): Promise<void> {
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const normalizedResponse = this.normalize(params.responseBody);

    await this.prisma.idempotency_keys.create({
      data: {
        idempotency_key: params.key,
        method: params.method,
        path: params.path,
        request_hash: params.requestHash,
        response_status: params.responseStatus,
        response_body:
          normalizedResponse === null
            ? Prisma.JsonNull
            : (normalizedResponse as Prisma.InputJsonValue),
        expires_at: expiresAt,
      },
    });
  }

  private normalize(value: unknown): unknown {
    if (Array.isArray(value)) {
      return value.map((entry) => this.normalize(entry));
    }

    if (value && typeof value === "object") {
      const objectValue = value as Record<string, unknown>;
      const sortedKeys = Object.keys(objectValue).sort();
      const normalizedObject: Record<string, unknown> = {};
      for (const key of sortedKeys) {
        normalizedObject[key] = this.normalize(objectValue[key]);
      }
      return normalizedObject;
    }

    return value;
  }
}
