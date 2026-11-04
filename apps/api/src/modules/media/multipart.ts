import { BadRequestException, PayloadTooLargeException, ServiceUnavailableException } from '@nestjs/common';
import busboy from 'busboy';
import { Request } from 'express';
import { createWriteStream } from 'node:fs';
import { unlink } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { join } from 'node:path';
import { pipeline } from 'node:stream/promises';

/** Bounded streaming to a private exclusive quarantine file; always remove on failure. */
export async function receiveUpload(req: Request, root: string, maxBytes: number) {
  const path = join(root, 'staging', randomUUID());
  let purpose = '', mime = '', filename = '', files = 0;
  let invalid = false, oversized = false, storageFailure = false;
  const writes: Promise<void>[] = [];
  let parser: ReturnType<typeof busboy>;
  try { parser = busboy({ headers: req.headers, preservePath: true,
    limits: { fileSize: maxBytes + 1, files: 1, fields: 1, fieldSize: 32, parts: 3, headerPairs: 32 } }); } catch { throw new BadRequestException('Expected multipart upload'); }
  parser.on('field', (name, value, info) => {
    if (name !== 'purpose' || info.valueTruncated) invalid = true;
    purpose = value;
  });
  parser.on('file', (name, stream, info) => {
    files++;
    mime = info.mimeType; filename = info.filename;
    if (name !== 'file' || /[/\\]/.test(filename) || filename.includes(String.fromCharCode(0)) || filename.includes('..')) invalid = true;
    let bytes = 0;
    stream.on('data', (chunk: Buffer) => { bytes += chunk.length; if (bytes > maxBytes) oversized = true; });
    stream.on('limit', () => { oversized = true; });
    const write = pipeline(stream, createWriteStream(path, { flags: 'wx', mode: 0o600 }));
    // Attach a rejection handler immediately while the parser finishes.
    writes.push(write); void write.catch((error: NodeJS.ErrnoException) => {
      storageFailure = ['ENOSPC', 'EIO', 'EACCES', 'EROFS'].includes(error.code ?? '');
      parser.destroy(new Error('Upload write failed'));
    });
  });
  for (const event of ['filesLimit', 'fieldsLimit', 'partsLimit']) parser.on(event, () => { invalid = true; });
  const abort = () => { parser.destroy(new Error('Upload interrupted')); };
  req.once('aborted', abort);
  const timeout = setTimeout(() => parser.destroy(new Error('Upload timed out')), 30000);
  try {
    await new Promise<void>((resolve, reject) => {
      parser.once('close', resolve);
      parser.once('error', reject);
      req.once('error', reject);
      req.pipe(parser);
    });
    await Promise.all(writes);
    if (oversized) throw new PayloadTooLargeException();
    if (invalid || files !== 1 || !purpose) throw new BadRequestException('Invalid multipart upload');
    return { path, purpose, mime, filename };
  } catch (error) {
    await Promise.allSettled(writes);
    await unlink(path).catch((failure: NodeJS.ErrnoException) => { if (failure.code !== 'ENOENT') throw failure; });
    if (storageFailure) throw new ServiceUnavailableException('Media storage unavailable');
    if (error instanceof PayloadTooLargeException || error instanceof BadRequestException) throw error;
    throw new BadRequestException('Upload could not be received');
  } finally {
    clearTimeout(timeout); req.off('aborted', abort);
    req.unpipe(parser); if (!req.readableEnded) req.resume();
  }
}
