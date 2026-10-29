# Local server file storage

Accepted baseline: ADR-023. Implementation owner: T-020 and T-182. This is a target contract; source and generated contracts change only during implementation.

## Configuration and layout
- `UPLOAD_ROOT`: absolute persistent directory outside the source tree, deployment artifact, temporary directory and web root; no default in production. Development example: `/var/tmp/supplybiz-dev-uploads`.
- `UPLOAD_MAX_BYTES`: default 5,242,880 per file; per-purpose restrictions may be tighter. `UPLOAD_MAX_PIXELS`: default 20,000,000; bound decoding memory/time as well as bytes. Reject invalid config at startup.
- Separate `staging/`, `media/` and `kyc/` subdirectories, with generated UUID names and server-selected extensions. Store a relative opaque storage key, purpose, owner/tenant, validated MIME, byte count, hash, validation status and timestamps in `media_files`. Never expose absolute paths.
- Service account owns root (0700 directories / 0600 files); encrypted volume and encrypted backups. Separate roots and keys for each environment. Check free space, directory writability and disk alerts; no uploads in ephemeral build directories.

## Upload and validation
`POST /api/v1/media` accepts authenticated multipart `file` and allow-listed `purpose` (`PRODUCT_IMAGE`, `SHOP_PHOTO`, `PROFILE`, `KYC_DOC`) and returns an opaque `mediaId` and status. Use the existing idempotency policy. Stream with a hard byte limit into a quarantine/staging file; do not buffer unbounded content.

Allow JPEG/PNG images and PDF only for existing shop/KYC document requirements; profile/product media are images only. Verify magic bytes and successful decode against claimed MIME and extension, enforce byte/pixel limits, strip EXIF by re-encoding images, reject SVG, executables, mismatches and malformed files. Keep PDF documents quarantined until malware validation; no active PDF content served inline. Preserve the existing malware check for document uploads, with unavailable/failed checks failing closed. Mask Aadhaar before any persistence, including temporary files; reject unmasked input rather than retain it for later masking. Log no image contents or PII.

Ignore client filenames/paths. Reject traversal and absolute-path input; do not follow symlinks. Resolve keys beneath the configured root, use exclusive file creation and atomic rename on the same volume. Persist metadata and READY state after validation; only READY files can be attached to business records. Compensate failed DB/file operations; bounded cleanup removes stale quarantine/orphans after checking DB references, never active files. A replay must not create duplicate attachments.

## Access and lifecycle
`GET /api/v1/media/{id}/content` streams a READY file after authentication and resource-level authorization. Public catalog consumers may access only media attached to a currently visible vendor/product via the authorized discovery flow; possession of an ID grants no access. KYC: vendor owner or explicitly permitted reviewing admin, with every admin view audited. Cross-tenant access returns 404. No static directory exposure or public KYC URLs.

Use validated `Content-Type`, `X-Content-Type-Options: nosniff`, safe server-generated disposition; PDFs download as attachments, sensitive responses use `Cache-Control: no-store`. Mobile uses the authenticated client; the admin BFF streams without exposing admin tokens. Deletion/retention follows approved Q-20 policy, with reference checks and audited access; no ad hoc destructive cleanup.

## Acceptance and recovery
TC-503 and TC-508 cover allowed files, limit boundaries, forged MIME, malformed image, decompression/pixel bombs, traversal, symlink escape, cross-tenant/KYC denial, audit, duplicate request, interrupted upload, disk-full and failed validation. Module integration checks upload → DB metadata → business attachment → UI display and confirm denied files cannot be read.

Back up DB metadata and files at a recorded consistent checkpoint or with writes paused; encrypt copies on a separate disk/host. Restore both into a clean location and verify hashes, references, ownership, KYC access rules and UI display. Record observed RPO/RTO and get agreement on targets before production; local disk alone is not a backup. Initial topology has a single-host failure domain; do not run independent API replicas with separate upload roots.
