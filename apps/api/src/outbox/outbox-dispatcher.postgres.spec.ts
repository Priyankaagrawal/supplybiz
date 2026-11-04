import { randomUUID } from "node:crypto";
import { PrismaService } from "../prisma/prisma.service";
import { PinoLogger } from "../common/logging/pino.logger";
import { OutboxDispatcherService } from "./outbox-dispatcher.service";

const databaseTests = process.env.WORKER_TEST_DATABASE_URL ? describe : describe.skip;
databaseTests("T-181 durable worker native PostgreSQL smoke (TC-501)", () => {
  const url = process.env.WORKER_TEST_DATABASE_URL;
  const prisma = new PrismaService({ datasources: { db: { url } } });
  const replica = new PrismaService({ datasources: { db: { url } } });
  const logger = { error: jest.fn(), warn: jest.fn() } as unknown as PinoLogger;
  const first = new OutboxDispatcherService(prisma, logger);
  const second = new OutboxDispatcherService(replica, logger);
  const ids: string[] = [];
  const effectIds: string[] = [];
  const scope = randomUUID();
  beforeAll(async () => { await Promise.all([prisma.$connect(), replica.$connect()]); });
  afterEach(() => jest.clearAllMocks());
  afterAll(async () => {
    await Promise.all([first.onModuleDestroy(), second.onModuleDestroy()]);
    await prisma.job_runs.deleteMany({ where: { event_id: { in: ids } } });
    await prisma.outbox_events.deleteMany({ where: { id: { in: [...ids, ...effectIds] } } });
    await Promise.all([prisma.$disconnect(), replica.$disconnect()]);
  });
  async function enqueue(type: string, future = false) {
    const event = await prisma.outbox_events.create({ data: {
      aggregate_type: "TEST", event_type: type, payload: {},
      available_at: new Date(Date.now() + (future ? 3600000 : -1000)),
    } });
    ids.push(event.id);
    return event;
  }
  async function due(id: string) {
    await prisma.$executeRaw`UPDATE outbox_events SET available_at = clock_timestamp() - interval '1 second'
      WHERE id = ${id}::uuid`;
  }
  it("claims across two workers once; DB effects and acknowledgement commit together", async () => {
    let calls = 0;
    const handler = async () => { calls++; };
    first.register("SUCCESS", handler); second.register("SUCCESS", handler);
    const event = await enqueue("SUCCESS");
    await Promise.all([first.dispatchPendingBatch(), second.dispatchPendingBatch()]);
    expect(calls).toBe(1);
    expect(await prisma.outbox_events.findUniqueOrThrow({ where: { id: event.id } }))
      .toMatchObject({ status: "DISPATCHED", attempt_count: 1, lease_token: null });
    expect(await first.dispatchPendingBatch()).toBe(0);
  });
  it("rolls back financial-style DB effects on failure, backs off, bounds retries and alerts without raw errors", async () => {
    first.register("FAIL", async (_event, tx) => {
      const effect = await tx.outbox_events.create({ data: { aggregate_type: "TEST", event_type: "EFFECT", payload: {} } });
      effectIds.push(effect.id);
      throw new Error("private payload must never be persisted or logged");
    });
    const event = await enqueue("FAIL");
    for (let attempt = 1; attempt <= 5; attempt++) {
      await due(event.id);
      expect(await first.dispatchPendingBatch()).toBe(0);
      const row = await prisma.outbox_events.findUniqueOrThrow({ where: { id: event.id } });
      expect(row).toMatchObject({ status: attempt === 5 ? "FAILED" : "PENDING",
        attempt_count: attempt, last_error: "WORKER_HANDLER_FAILED", lease_token: null });
      expect(row.available_at.getTime()).toBeGreaterThan(Date.now());
      expect(await first.dispatchPendingBatch()).toBe(0);
    }
    expect(await prisma.outbox_events.count({ where: { id: { in: effectIds } } })).toBe(0);
    expect(logger.error).toHaveBeenCalledWith("WORKER_DELIVERY_EXHAUSTED", undefined, "OutboxDispatcher");
  });
  it("does not acknowledge unknown consumers", async () => {
    const event = await enqueue("UNKNOWN");
    await first.dispatchPendingBatch();
    expect(await prisma.outbox_events.findUniqueOrThrow({ where: { id: event.id } }))
      .toMatchObject({ status: "PENDING", last_error: "WORKER_HANDLER_MISSING" });
    await prisma.outbox_events.update({ where: { id: event.id }, data: { status: "FAILED" } });
  });
  it("keeps an executing row locked against a competing worker and commits its DB effect once", async () => {
    let release!: () => void;
    let entered!: () => void;
    const gate = new Promise<void>(resolve => { release = resolve; });
    const ready = new Promise<void>(resolve => { entered = resolve; });
    first.register("LOCKED", async (_event, tx) => {
      entered();
      await gate;
      const effect = await tx.outbox_events.create({ data: {
        aggregate_type: "TEST", event_type: "EFFECT", payload: {}, status: "DISPATCHED",
      } });
      effectIds.push(effect.id);
    });
    const event = await enqueue("LOCKED");
    const running = first.dispatchPendingBatch(1);
    await ready;
    try { expect(await second.dispatchPendingBatch()).toBe(0); }
    finally { release(); await running; }
    expect(await prisma.outbox_events.count({ where: { id: { in: effectIds } } })).toBe(1);
    expect((await prisma.outbox_events.findUniqueOrThrow({ where: { id: event.id } })).status).toBe("DISPATCHED");
  });
  it("bounds repeated crashed leases without running a sixth handler", async () => {
    const event = await enqueue("SUCCESS");
    await prisma.$executeRaw`UPDATE outbox_events SET lease_token = ${randomUUID()}::uuid,
      lease_until = clock_timestamp() - interval '1 second', attempt_count = 5 WHERE id = ${event.id}::uuid`;
    expect(await second.dispatchPendingBatch()).toBe(0);
    expect(await prisma.outbox_events.findUniqueOrThrow({ where: { id: event.id } }))
      .toMatchObject({ status: "FAILED", last_error: "WORKER_LEASE_EXHAUSTED", lease_token: null });
    expect(logger.error).toHaveBeenCalledWith("WORKER_DELIVERY_EXHAUSTED", undefined, "OutboxDispatcher");
  });
  it("reclaims crashed leases after reconnect but leaves live leases and future jobs untouched", async () => {
    const expired = await enqueue("SUCCESS"), active = await enqueue("SUCCESS"), future = await enqueue("SUCCESS", true);
    await prisma.$executeRaw`UPDATE outbox_events SET lease_token = ${randomUUID()}::uuid,
      lease_until = clock_timestamp() - interval '1 second', attempt_count = 1 WHERE id = ${expired.id}::uuid`;
    await prisma.$executeRaw`UPDATE outbox_events SET lease_token = ${randomUUID()}::uuid,
      lease_until = clock_timestamp() + interval '1 hour' WHERE id = ${active.id}::uuid`;
    await replica.$disconnect(); await replica.$connect();
    expect(await second.dispatchPendingBatch()).toBe(1);
    expect(await prisma.outbox_events.findUniqueOrThrow({ where: { id: expired.id } }))
      .toMatchObject({ status: "DISPATCHED", attempt_count: 2 });
    for (const id of [active.id, future.id]) {
      expect((await prisma.outbox_events.findUniqueOrThrow({ where: { id } })).status).toBe("PENDING");
      await prisma.outbox_events.update({ where: { id }, data: { status: "FAILED" } });
    }
  });
  it("deduplicates due jobs across workers and persists completion counts", async () => {
    const handler = async () => ({ created: 3 });
    first.register("DAILY_TEST", handler); second.register("DAILY_TEST", handler);
    const results = await Promise.all(Array.from({ length: 8 }, (_, i) =>
      (i % 2 ? first : second).schedule("DAILY_TEST", "2026-11-04", scope, new Date(0), { synthetic: true })));
    const id = results[0]!;
    ids.push(id);
    expect(new Set(results).size).toBe(1);
    await second.dispatchPendingBatch();
    expect(await prisma.job_runs.findUniqueOrThrow({ where: { event_id: id } }))
      .toMatchObject({ counts: { created: 3 }, finished_at: expect.any(Date) });
    expect(await first.schedule("DAILY_TEST", "2026-11-04", scope, new Date(), {})).toBe(id);
    expect(await first.dispatchPendingBatch()).toBe(0);
  });
  it("start immediately polls overdue persisted jobs and catches DB failures", async () => {
    const event = await enqueue("SUCCESS");
    second.start();
    await second.onModuleDestroy();
    expect((await prisma.outbox_events.findUniqueOrThrow({ where: { id: event.id } })).status).toBe("DISPATCHED");
    const broken = new OutboxDispatcherService({ $queryRaw: () => Promise.reject(new Error("secret")) } as unknown as PrismaService, logger);
    broken.start(); await broken.onModuleDestroy();
    expect(logger.error).toHaveBeenCalledWith("WORKER_POLL_FAILED", undefined, "OutboxDispatcher");
  });
});
