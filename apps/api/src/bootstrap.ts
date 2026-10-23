import { INestApplication, ValidationPipe } from "@nestjs/common";
import { PinoLogger } from "./common/logging/pino.logger";
import { ProblemDetailsFilter } from "./common/problem-details.filter";

export function configureHttpApp(app: INestApplication): void {
  app.useLogger(app.get(PinoLogger));
  app.useGlobalFilters(new ProblemDetailsFilter());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    })
  );
  app.setGlobalPrefix("api/v1");
}
