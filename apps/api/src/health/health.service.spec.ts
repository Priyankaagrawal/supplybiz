import { ConfigService } from "@nestjs/config";
import { Test } from "@nestjs/testing";
import { HealthService } from "./health.service";
import { LocalStorageService } from "../storage/local-storage.service";
import { PrismaService } from "../prisma/prisma.service";

describe("T-182 native readiness", () => {
  const query = jest.fn(), check = jest.fn();
  let service: HealthService;
  beforeEach(async () => {
    query.mockReset().mockResolvedValue([{ result: 1 }]);
    check.mockReset().mockResolvedValue(undefined);
    const module = await Test.createTestingModule({ providers: [HealthService,
      { provide: ConfigService, useValue: new ConfigService({ HEALTHCHECK_STRICT: true }) },
      { provide: PrismaService, useValue: { $queryRaw: query } },
      { provide: LocalStorageService, useValue: { check } },
    ] }).compile();
    service = module.get(HealthService);
  });
  it("checks authenticated SQL and persistent storage", async () => {
    expect(await service.getReadiness()).toMatchObject({ status: "UP", shouldFailHttpStatus: false,
      checks: { database: { status: "up" }, storage: { status: "up" } } });
    expect(query).toHaveBeenCalled();
    expect(check).toHaveBeenCalled();
  });
  it.each(["database", "storage"])("reports %s failure without leaking errors or paths", async dependency => {
    (dependency === "database" ? query : check).mockRejectedValue(new Error("synthetic-private-detail"));
    const result = await service.getReadiness();
    expect(result.shouldFailHttpStatus).toBe(true);
    expect(result.status).toBe("DOWN");
    expect(JSON.stringify(result)).not.toContain("synthetic-private-detail");
  });
});
