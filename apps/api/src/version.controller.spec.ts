import { VersionController } from "./version.controller";

describe("VersionController", () => {
  it("returns API version metadata", () => {
    const controller = new VersionController();
    const result = controller.getVersion();

    expect(result.service).toBe("api");
    expect(result.version).toBeDefined();
    expect(result.nodeEnv).toBeDefined();
  });
});
