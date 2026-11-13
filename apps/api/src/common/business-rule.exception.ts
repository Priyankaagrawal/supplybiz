import { HttpException } from '@nestjs/common';

/** Explicit public extensions only; never serialize arbitrary exception internals. */
export class BusinessRuleException extends HttpException {
  constructor(status: number, code: string, readonly extensions: { quote?: object; productId?: string }) {
    super({ code }, status);
  }
}
