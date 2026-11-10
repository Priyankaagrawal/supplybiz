import { mkdtemp, mkdir, readdir, realpath, rm, chmod, stat, symlink } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { prepareUploadRoot } from "./local-storage.service";
import { validateEnv } from "../config/env.schema";
import { windowsPrivateDirectory } from './windows-private-directory';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

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
      if (process.platform === 'win32') await windowsPrivateDirectory(directory, false);
      else expect((await stat(directory)).mode & 0o777).toBe(0o700);
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
    await symlink(target, root, process.platform === 'win32' ? 'junction' : 'dir');
    await expect(prepareUploadRoot(root, [])).rejects.toThrow();
    const other = join(sandbox, "other");
    await mkdir(other, { mode: 0o700 });
    if (process.platform === 'win32') await windowsPrivateDirectory(other, true);
    await symlink(target, join(other, "kyc"), process.platform === 'win32' ? 'junction' : 'dir');
    await expect(prepareUploadRoot(other, [])).rejects.toThrow();
    expect(await readdir(target)).toEqual([]);
  });
  it("fails closed on an existing public root rather than silently changing ownership", async () => {
    const root = join(sandbox, "uploads");
    await mkdir(root);
    await chmod(root, 0o755);
    await expect(prepareUploadRoot(root, [])).rejects.toThrow(process.platform === 'win32' ? 'private Windows ACLs' : '0700');
  });
  (process.platform === 'win32' ? it : it.skip)('rejects a protected Windows ACL granting Everyone access', async () => {
    const root = join(sandbox, "quoted' uploads");
    await prepareUploadRoot(root, []);
    // Reopening a private root must validate it without rewriting existing ACLs.
    await prepareUploadRoot(root, []);
    await promisify(execFile)('icacls.exe', [root, '/grant', '*S-1-1-0:(RX)'], { windowsHide: true, timeout: 15000 });
    await expect(prepareUploadRoot(root, [])).rejects.toThrow('private Windows ACLs');
    await expect(windowsPrivateDirectory(root, false)).rejects.toThrow('private Windows ACLs');
  });
  it("validates storage bounds and requires explicit deployed storage", () => {
    expect(validateEnv({ NODE_ENV: "test" }).UPLOAD_ROOT).toBe(join(homedir(), '.local', 'share', 'supplybiz', 'uploads'));
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
