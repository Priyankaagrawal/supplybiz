import { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";
import { AppModule } from "../src/app.module";
import { configureHttpApp } from "../src/bootstrap";
import { PrismaService } from "../src/prisma/prisma.service";

type IdempotencyRecord = {
  idempotency_key: string;
  method: string;
  path: string;
  request_hash: string;
  response_status: number;
  response_body: unknown;
  expires_at: Date;
};

describe("API skeleton e2e", () => {
  let app: INestApplication;
  const idempotencyStore = new Map<string, IdempotencyRecord>();
  const outboxEvents: Array<{ id: string; status: string; created_at: Date; available_at: Date }> = [];

  beforeAll(async () => {
    process.env.NODE_ENV = "test";
    process.env.DATABASE_URL = "postgresql://localhost:5432/supplybiz";
    process.env.REDIS_URL = "redis://localhost:6379";
    process.env.HEALTHCHECK_STRICT = "false";

    const prismaMock = {
      idempotency_keys: {
        findUnique: jest.fn(async ({ where }: { where: { idempotency_key: string } }) => {
          return idempotencyStore.get(where.idempotency_key) ?? null;
        }),
        create: jest.fn(async ({ data }: { data: IdempotencyRecord }) => {
          idempotencyStore.set(data.idempotency_key, data);
          return data;
        }),
        delete: jest.fn(async ({ where }: { where: { idempotency_key: string } }) => {
          idempotencyStore.delete(where.idempotency_key);
          return { count: 1 };
        }),
      },
      outbox_events: {
        create: jest.fn(async ({ data }: { data: { aggregate_type: string; aggregate_id: string; event_type: string; payload: unknown } }) => {
          const event = {
            id: data.aggregate_id,
            status: "PENDING",
            created_at: new Date(),
            available_at: new Date(),
          };
          outboxEvents.push(event);
          return event;
        }),
        findMany: jest.fn(async () => {
          return outboxEvents;
        }),
        update: jest.fn(async ({ where }: { where: { id: string } }) => {
          const found = outboxEvents.find((event) => event.id === where.id);
          if (found) {
            found.status = "DISPATCHED";
          }
          return found ?? null;
        }),
      },
    };

    const moduleBuilder = Test.createTestingModule({
      imports: [AppModule],
    });

    moduleBuilder.overrideProvider(PrismaService).useValue(prismaMock);
    const moduleRef = await moduleBuilder.compile();

    app = moduleRef.createNestApplication();
    configureHttpApp(app);
    await app.init();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it("GET /api/v1/health/ready returns 200", async () => {
    const response = await request(app.getHttpServer()).get("/api/v1/health/ready").expect(200);
    expect(response.body.status).toBeDefined();
    expect(response.body.checks).toBeDefined();
  });

  it("returns Problem Details payload for 404", async () => {
    const response = await request(app.getHttpServer()).get("/api/v1/unknown-path").expect(404);
    expect(response.body).toMatchObject({
      type: expect.stringContaining("https://docs.supplybiz.app/errors/"),
      title: expect.any(String),
      status: 404,
      code: expect.any(String),
      detail: expect.any(String),
      requestId: expect.any(String),
    });
  });

  it("TC-500 same key + same body replays response", async () => {
    const key = "00000000-0000-0000-0000-00000000a500";
    const payload = { sku: "milk-500ml", qty: 2 };

    const first = await request(app.getHttpServer())
      .post("/api/v1/test/idempotency/orders")
      .set("Idempotency-Key", key)
      .send(payload)
      .expect(201);

    const second = await request(app.getHttpServer())
      .post("/api/v1/test/idempotency/orders")
      .set("Idempotency-Key", key)
      .send(payload)
      .expect(201);

    expect(second.body).toEqual(first.body);
    expect(first.body.sideEffectCount).toBe(1);
    expect(second.body.sideEffectCount).toBe(1);
  });

  it("TC-501 same key + different body returns IDEMPOTENCY_MISMATCH", async () => {
    const key = "00000000-0000-0000-0000-00000000a501";

    await request(app.getHttpServer())
      .post("/api/v1/test/idempotency/orders")
      .set("Idempotency-Key", key)
      .send({ sku: "milk-1l", qty: 1 })
      .expect(201);

    const response = await request(app.getHttpServer())
      .post("/api/v1/test/idempotency/orders")
      .set("Idempotency-Key", key)
      .send({ sku: "milk-1l", qty: 3 })
      .expect(422);

    expect(response.body.code).toBe("IDEMPOTENCY_MISMATCH");
  });
});
