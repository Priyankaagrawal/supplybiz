import { mkdtemp, mkdir, readdir, realpath, rm, chmod, stat, symlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { prepareUploadRoot } from "./local-storage.service";
import { validateEnv } from "../config/env.schema";

describe("T-182 native upload configuration", () => {
  let sandbox: string;
  beforeEach(async () => { sandbox = await mkdtemp(join(await realpath(tmpdir()), "sb-storage-test-")); });
  afterEach(async () => { await rm(sandbox, { recursive: true, force: true }); });

  it("creates private directories and removes its exclusive write probes", async () => {
    const root = join(sandbox, "uploads");
    await prepareUploadRoot(root, []);
    expect((await readdir(root)).sort()).toEqual(["kyc", "media", "staging"]);
    for (const name of ["", "kyc", "media", "staging"]) {
      const directory = join(root, name);
      expect((await stat(directory)).mode & 0o777).toBe(0o700);
      if (name) expect(await readdir(directory)).toEqual([]);
    }
  });
  it("rejects source/temp roots, traversal and root paths before creating files", async () => {
    for (const root of ["relative", "/", join(sandbox, "private"), `${sandbox}/../uploads`]) {
      await expect(prepareUploadRoot(root, [sandbox])).rejects.toThrow();
    }
  });
  it("rejects symlink ancestors and upload subdirectories", async () => {
    const target = join(sandbox, "target"), root = join(sandbox, "root");
    await mkdir(target, { mode: 0o700 });
    await symlink(target, root);
    await expect(prepareUploadRoot(root, [])).rejects.toThrow();
    const other = join(sandbox, "other");
    await mkdir(other, { mode: 0o700 });
    await symlink(target, join(other, "kyc"));
    await expect(prepareUploadRoot(other, [])).rejects.toThrow();
    expect(await readdir(target)).toEqual([]);
  });
  it("fails closed on an existing public root rather than silently changing ownership", async () => {
    const root = join(sandbox, "uploads");
    await mkdir(root);
    await chmod(root, 0o755);
    await expect(prepareUploadRoot(root, [])).rejects.toThrow("0700");
  });
  it("validates storage bounds and requires explicit deployed storage", () => {
    expect(validateEnv({ NODE_ENV: "test" }).UPLOAD_ROOT).toMatch(/supplybiz\/uploads$/);
    for (const input of [{ UPLOAD_ROOT: "relative" }, { UPLOAD_MAX_BYTES: -1 },
      { UPLOAD_MAX_BYTES: 5242881 }, { UPLOAD_MAX_PIXELS: 20000001 }, { NODE_ENV: "production" }]) {
      expect(() => validateEnv(input)).toThrow();
    }
    const config = validateEnv({ NODE_ENV: "test", REDIS_URL: "obsolete", STORAGE_ENDPOINT: "obsolete", OTEL_ENABLED: "true" });
    expect(config).not.toHaveProperty("REDIS_URL");
    expect(config).not.toHaveProperty("STORAGE_ENDPOINT");
    expect(config).not.toHaveProperty("OTEL_ENABLED");
  });
});
