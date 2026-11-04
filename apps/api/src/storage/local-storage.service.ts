import { Injectable, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { constants } from "node:fs";
import { lstat, mkdir, open, realpath, statfs, unlink } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { isAbsolute, join, parse, relative, resolve, sep } from "node:path";
import { tmpdir } from "node:os";

function within(root: string, candidate: string): boolean {
  const path = relative(root, candidate);
  return path === "" || (!path.startsWith(`..${sep}`) && path !== ".." && !isAbsolute(path));
}

/** T-182: establish storage without following symlinks or accepting source/temp roots. */
export async function prepareUploadRoot(root: string, forbidden: string[]): Promise<void> {
  if (!isAbsolute(root) || resolve(root) !== root || root === parse(root).root ||
      forbidden.some(path => within(resolve(path), root))) {
    throw new Error("Unsafe upload root configuration");
  }
  let current = parse(root).root;
  for (const part of root.slice(current.length).split(sep)) {
    current = join(current, part);
    try {
      if ((await lstat(current)).isSymbolicLink()) throw new Error("Upload paths must not contain symlinks");
    } catch (error) {
      if (!(typeof error === "object" && error !== null && "code" in error && error.code === "ENOENT")) throw error;
    }
  }
  for (const directory of [root, ...["staging", "media", "kyc"].map(name => join(root, name))]) {
    await mkdir(directory, { recursive: true, mode: 0o700 });
    const info = await lstat(directory);
    if (!info.isDirectory() || info.isSymbolicLink() ||
        (process.getuid && info.uid !== process.getuid()) || (info.mode & 0o077) !== 0) {
      throw new Error("Upload directories require service ownership and mode 0700");
    }
    await probeDirectory(directory);
  }
}

async function probeDirectory(directory: string): Promise<void> {
  const path = join(directory, `.probe-${randomUUID()}`);
  const file = await open(path, constants.O_CREAT | constants.O_EXCL | constants.O_WRONLY | constants.O_NOFOLLOW, 0o600);
  try {
    await file.writeFile("storage-check");
    await file.sync();
  } finally {
    await file.close();
    await unlink(path);
  }
}

@Injectable()
export class LocalStorageService implements OnModuleInit {
  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const temporary = await realpath(tmpdir());
    await prepareUploadRoot(this.root, [resolve(__dirname, "../../../.."), tmpdir(), temporary]);
  }

  get root(): string { return this.config.getOrThrow<string>("UPLOAD_ROOT"); }

  async check(): Promise<void> {
    // Recheck replacement/symlink/permission attacks as well as writable disk space.
    await this.onModuleInit();
    const disk = await statfs(this.root);
    if (disk.bavail <= 0) throw new Error("Upload volume is full");
  }
}
