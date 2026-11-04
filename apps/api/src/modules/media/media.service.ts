import { BadRequestException, HttpException, Injectable, NotFoundException, PayloadTooLargeException, ServiceUnavailableException, StreamableFile, UnprocessableEntityException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'node:crypto';
import { constants } from 'node:fs';
import { lstat, open, opendir, readFile, rename, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { Request } from 'express';
import { PrismaService } from '../../prisma/prisma.service';
import { LocalStorageService } from '../../storage/local-storage.service';
import { AdminAuthService } from '../admin-auth/admin-auth.service';
import { receiveUpload } from './multipart';
import { purposeOf, validateMedia } from './media-validation';

const hash = (value: string | Buffer) => createHash('sha256').update(value).digest('hex');
@Injectable()
export class MediaService {
  constructor(private readonly prisma: PrismaService, private readonly storage: LocalStorageService,
    private readonly config: ConfigService, private readonly adminAuth: AdminAuthService) {}

  async upload(owner: string, req: Request) {
    const key = req.header('Idempotency-Key');
    if (!key || !key.trim() || key.length > 200) throw new BadRequestException('Idempotency-Key required (max 200 characters)');
    await this.storage.check().catch(() => { throw new ServiceUnavailableException('Media storage unavailable'); });
    await this.cleanupStale().catch(() => { throw new ServiceUnavailableException('Media storage unavailable'); });
    const maxBytes = this.config.getOrThrow<number>('UPLOAD_MAX_BYTES');
    const staged = await receiveUpload(req, this.storage.root, maxBytes);
    let finalPath: string | undefined;
    let committed = false;
    try {
      const purpose = purposeOf(staged.purpose);
      const source = await readFile(staged.path);
      const validated = await validateMedia(source, staged.mime, staged.filename, purpose,
        this.config.getOrThrow<number>('UPLOAD_MAX_PIXELS'));
      if (validated.data.length > maxBytes) throw new PayloadTooLargeException();
      const requestHash = hash(`${purpose}:${staged.mime}:${hash(source)}`);
      const requestKey = hash(key);
      const result = await this.prisma.$transaction(async tx => {
        // Includes owner and serializes competing retries across API processes.
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtextextended(${`media:${owner}:${requestKey}`}, 0))`;
        const existing = await tx.media_files.findUnique({ where: { owner_user_id_request_key: {
          owner_user_id: owner, request_key: requestKey } } });
        if (existing) {
          if (existing.request_hash !== requestHash) throw new UnprocessableEntityException({ code: 'IDEMPOTENCY_MISMATCH' });
          return { mediaId: existing.id, status: existing.status };
        }
        const id = randomUUID();
        const relativeKey = `${purpose === 'KYC_DOC' ? 'kyc' : 'media'}/${id}.${validated.extension}`;
        const cleanPath = `${staged.path}.clean`;
        try {
          await writeFile(cleanPath, validated.data, { flag: 'wx', mode: 0o600, flush: true });
          // The target UUID is server-generated and private; rename is on the same volume.
          finalPath = join(this.storage.root, relativeKey);
          await rename(cleanPath, finalPath);
        } finally { await this.remove(cleanPath); }
        const row = await tx.media_files.create({ data: { id, owner_user_id: owner, purpose,
          relative_storage_key: relativeKey, mime: validated.mime, size: validated.data.length,
          sha256: hash(validated.data), status: 'READY', request_key: requestKey, request_hash: requestHash } });
        return { mediaId: row.id, status: row.status };
      }, { timeout: 15000 });
      committed = true;
      return result;
    } catch (error) {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException('Media upload unavailable');
    } finally {
      await this.remove(staged.path);
      if (finalPath && !committed) await this.remove(finalPath);
    }
  }

  /** Stable attachment hook for the owning business module's transaction. */
  async requireOwnedReady(id: string, owner: string, purpose: string) {
    const media = await this.prisma.media_files.findFirst({ where: { id, owner_user_id: owner, purpose, status: 'READY' } });
    if (!media) throw new NotFoundException();
    return media.id;
  }

  async content(id: string, actor: { owner?: string; adminToken?: string }) {
    const admin = actor.adminToken === undefined ? undefined : await this.adminAuth.authenticate(actor.adminToken, 'kyc.documents');
    const media = await this.prisma.media_files.findFirst({ where: { id, status: 'READY',
      ...(admin ? { purpose: { in: ['KYC_DOC', 'SHOP_PHOTO'] } } : { owner_user_id: actor.owner ?? '' }) } });
    if (!media) throw new NotFoundException();
    if (!/^(media|kyc)\/[a-f0-9-]{36}\.(jpg|png|pdf)$/.test(media.relative_storage_key)) throw new NotFoundException();
    await this.storage.check().catch(() => { throw new ServiceUnavailableException('Media storage unavailable'); });
    const file = await open(join(this.storage.root, media.relative_storage_key), constants.O_RDONLY | constants.O_NOFOLLOW)
      .catch(() => { throw new NotFoundException(); });
    try {
      const info = await file.stat();
      if (!info.isFile() || info.size !== media.size || (info.mode & 0o077) !== 0) throw new NotFoundException();
      if (admin) await this.prisma.media_access_events.create({ data: { media_id: id, admin_user_id: admin.id } });
      return new StreamableFile(file.createReadStream(), { type: media.mime, length: media.size,
        disposition: `attachment; filename="${media.id}.${media.relative_storage_key.split('.').pop()}"` });
    } catch (error) { await file.close(); throw error; }
  }
  /** Only stale quarantine/orphans; retained metadata always protects finalized files. */
  async cleanupStale() {
    for (const directory of ['staging', 'media', 'kyc']) {
      const entries = await opendir(join(this.storage.root, directory));
      let seen = 0;
      for await (const entry of entries) {
        if (++seen > 100) break;
        if (!/^[a-f0-9-]{36}(\.clean|\.jpg|\.png|\.pdf)?$/.test(entry.name) || !entry.isFile()) continue;
        const key = `${directory}/${entry.name}`;
        const path = join(this.storage.root, key);
        const info = await lstat(path).catch((error: NodeJS.ErrnoException) => {
          if (error.code === 'ENOENT') return null;
          throw error;
        });
        if (!info || info.isSymbolicLink() || info.mtimeMs > Date.now() - 86400000) continue;
        if (directory !== 'staging' && await this.prisma.media_files.findUnique({ where: { relative_storage_key: key } })) continue;
        await this.remove(path);
      }
    }
  }
  private async remove(path: string) {
    await unlink(path).catch((error: NodeJS.ErrnoException) => {
      if (error.code !== 'ENOENT') throw new ServiceUnavailableException('Media cleanup failed');
    });
  }
}
