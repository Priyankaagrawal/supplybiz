import { Body, Controller, Post } from "@nestjs/common";
import { IsInt, IsString, Min } from "class-validator";
import { ApiExcludeController } from "@nestjs/swagger";
import { IdempotencyTestService } from "./idempotency-test.service";

class CreateOrderDto {
  @IsString()
  sku!: string;

  @IsInt()
  @Min(1)
  qty!: number;
}

@ApiExcludeController()
@Controller("test/idempotency")
export class IdempotencyTestController {
  constructor(private readonly service: IdempotencyTestService) {}

  @Post("orders")
  async createOrder(@Body() body: CreateOrderDto) {
    return this.service.createOrder(body);
  }
}
