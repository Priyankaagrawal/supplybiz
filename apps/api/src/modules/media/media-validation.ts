import { BadRequestException } from '@nestjs/common';
import { PDFDocument } from 'pdf-lib';
import sharp from 'sharp';
import { extname } from 'node:path';

export const PURPOSES = ['PRODUCT_IMAGE', 'SHOP_PHOTO', 'PROFILE', 'KYC_DOC'] as const;
export type MediaPurpose = typeof PURPOSES[number];
export function purposeOf(value: string): MediaPurpose {
  if (!PURPOSES.includes(value as MediaPurpose)) throw new BadRequestException('Invalid media purpose');
  return value as MediaPurpose;
}
export async function validateMedia(data: Buffer, mime: string, filename: string, purpose: MediaPurpose, maxPixels: number) {
  const extension = extname(filename).toLowerCase();
  try {
    if (mime === 'application/pdf' && ['SHOP_PHOTO', 'KYC_DOC'].includes(purpose) && extension === '.pdf' &&
        data.subarray(0, 5).toString() === '%PDF-') {
      const pdf = await PDFDocument.load(data, { updateMetadata: false });
      if (pdf.getPageCount() < 1) throw new Error('Empty PDF');
      return { data, extension: 'pdf', mime };
    }
    const png = data.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
    const jpeg = data[0] === 255 && data[1] === 216 && data[2] === 255;
    if (!(png && mime === 'image/png' && extension === '.png') &&
        !(jpeg && mime === 'image/jpeg' && ['.jpg', '.jpeg'].includes(extension))) throw new Error('Type mismatch');
    const image = sharp(data, { limitInputPixels: maxPixels, failOn: 'warning', animated: true }).timeout({ seconds: 10 });
    const metadata = await image.metadata();
    if ((metadata.pages ?? 1) !== 1) throw new Error('Multi-frame image');
    // Re-encoding strips EXIF and requires full decode; no client metadata is copied.
    const clean = await (png ? image.png() : image.jpeg()).toBuffer();
    return { data: clean, extension: png ? 'png' : 'jpg', mime };
  } catch { throw new BadRequestException('Invalid or unsupported media'); }
}
