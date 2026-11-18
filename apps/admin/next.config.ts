import type { NextConfig } from 'next';
const config: NextConfig = {
  poweredByHeader: false,
  async headers() { return [{ source: '/:path*', headers: [
    { key: 'Cache-Control', value: 'no-store' },
    { key: 'X-Frame-Options', value: 'DENY' },
    { key: 'X-Content-Type-Options', value: 'nosniff' },
    // Form POSTs need their real Origin for the strict origin guard.
    // no-referrer makes browsers send Origin: null on these submissions.
    { key: 'Referrer-Policy', value: 'same-origin' },
    { key: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; frame-ancestors 'none'; form-action 'self'; base-uri 'none'" },
  ] }, { source: '/kyc/:id/documents/:kind', headers: [
    { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
    { key: 'Content-Security-Policy', value: "default-src 'none'; frame-ancestors 'self'" },
  ] }]; },
};
export default config;
