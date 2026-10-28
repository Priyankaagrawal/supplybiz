# AUTH & SECURITY

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect + Security reviewer |
| Last updated | 2026-10-19 |
| Related | [API_SPECIFICATION](API_SPECIFICATION.md), [DATA_DESIGN](DATA_DESIGN.md), [MOBILE_STRATEGY](MOBILE_STRATEGY.md), [DECISIONS ADR-007, ADR-014](../05-ai-development/DECISIONS.md) |

## 1. Scope & Standards
Authentication, authorization, secure storage, token management, network security, data protection and privacy for mobile, API and admin. Baselines: **OWASP MASVS** (L1, L2 controls for KYC/financial), **OWASP ASVS L2** (API/admin), **OWASP Top 10 / API Top 10**, **DPDP Act 2023**, UIDAI Aadhaar regulations.

## 2. Authentication

### 2.1 Mobile OTP login (FR-001–FR-006, ADR-007)
```mermaid
sequenceDiagram
    participant A as App
    participant API
    participant R as Redis
    participant P as SMS/WhatsApp provider
    A->>API: POST /auth/otp/send {mobile, channel, appHash}
    API->>R: rate-limit check (IP, mobile, device)
    API->>R: store hash(OTP)+salt, TTL 5m, attempts=0
    API->>P: send OTP (DLT template)
    A->>API: POST /auth/otp/verify {mobile, code, device}
    API->>R: compare constant-time; attempts++
    API->>API: upsert user, create session (family)
    API-->>A: {accessToken(15m), refreshToken(30d), user}
```
| Control | Value |
|---|---|
| OTP generation | CSPRNG 6 digits; stored as HMAC-SHA256 with server pepper; never logged |
| Limits | RULE-19 + per-IP 20 sends/hour + per-device 5 sends/hour; after an OTP exhausts its 5 attempts, mobile send lockout is 30 s × 2 per exhaustion, capped at 1 h; escalation resets after 1 h without another exhaustion. Device/base/cap are configurable (T-014 defaults approved 2026-10-28). |
| Anti-enumeration | Same response for new/existing numbers |
| SMS pumping protection | Allow only +91 numbers; per-prefix anomaly alerting; CAPTCHA/Play Integrity/App Attest challenge on abuse (proposed) |
| Autofill | Android SMS Retriever (11-char app hash in template); iOS `oneTimeCode` content type |

### 2.2 Tokens
| Token | Format | Lifetime | Storage (mobile) |
|---|---|---|---|
| Access | JWT (EdDSA/ES256), claims: `sub`, `roles`, `sid`, `exp`, `iat`, `aud=mobile` | 15 min | Memory only |
| Refresh | Opaque 256-bit random; server stores SHA-256 hash | 30 days sliding, single use | flutter_secure_storage (Keychain `afterFirstUnlockThisDeviceOnly`; Android Keystore-backed) |
- **Rotation & reuse detection:** each refresh issues a new token in the same `family_id`; reuse of a consumed token revokes the family (`REFRESH_REUSED`).
- Refresh is single-flight in the app (one in-flight refresh; queued requests retry once).
- Logout revokes session server-side and wipes secure storage + local DB.
- Signing keys rotated every 90 days (JWKS with `kid`).

### 2.3 Admin authentication (FR-400)
Email + password (argon2id, ≥ 12 chars, breached-password check), **mandatory TOTP**, httpOnly `Secure` `SameSite=Strict` session cookie (8 h absolute, 30 min idle), CSRF token on mutations, lockout after 5 failures, optional IP allowlist, all logins audit-logged.

## 3. Authorization
| Layer | Rule |
|---|---|
| Role guard | `/vendor/**` → VENDOR in roles; `/customer/**` → CUSTOMER; `/admin/**` → admin permission |
| Tenant isolation | Every vendor query filtered by `vendorId` from token (never from request body). Customer queries by `userId`. Cross-tenant IDs return 404 |
| Resource ownership | Orders: customer (via vendor_customers.user_id) or vendor; ledger: vendor or linked customer (read-only) |
| Plan guard | `@RequiresPlanFeature` → 403 `PLAN_FEATURE_LOCKED` |
| KYC guard | Discovery/visibility endpoints require VERIFIED; payout-related N/A |
| Admin RBAC (proposed, Q-25) | SUPER_ADMIN (all), OPS (KYC, vendors, customers, categories, content), SUPPORT (read vendors/customers/orders, reviews), FINANCE (plans, plan payments, reports) |
| Suspended/blocked | Middleware rejects with `ACCOUNT_BLOCKED` |

Tests for every endpoint include an **IDOR test** (other tenant's ID) — see [TEST_STRATEGY](../07-testing/TEST_STRATEGY.md).

## 4. Mobile Secure Storage & Device Security
| Data | Where | Protection |
|---|---|---|
| Refresh token | Secure storage | Keychain/Keystore |
| DB key (SQLCipher) | Secure storage | random 256-bit, generated on first run |
| Cached business data | drift + SQLCipher | Encrypted at rest; wiped on logout |
| KYC images before upload | App temp dir | Deleted after upload or cancel |
| Logs | Crashlytics | No PII, no tokens, mobile numbers masked |
Additional controls:
- `FLAG_SECURE` / iOS snapshot blur on KYC and bank screens.
- Release builds: `--obfuscate --split-debug-info`, R8 enabled; debug logging disabled.
- Root/jailbreak & emulator detection: **warn only** (no blocking) + attach signal to sessions for risk analytics.
- Google Play Integrity / Apple App Attest on OTP send (proposed) to reduce bot abuse.
- `android:allowBackup="false"`; exclude DB from iCloud backup.
- No sensitive data in notifications payload (amounts allowed; no KYC/bank).
- Clipboard: UPI ID copy allowed; bank account never copied.

## 5. Network Security
- HTTPS only, TLS 1.2+ (prefer 1.3), HSTS on web domains; Android `network_security_config` disallows cleartext; iOS ATS default.
- **Certificate pinning**: SPKI pinning of the API host's intermediate CA with ≥ 2 backup pins; pin set updatable only via app release — decision recorded as ADR-020 (proposed) given bricking risk.
- WAF in front of API (OWASP CRS), request body limit 1 MB (uploads go direct to storage).
- CORS: admin origin only; mobile not CORS-relevant.
- Webhooks: HMAC signature verification + timestamp tolerance 5 min + replay cache.

## 6. Data Protection
| Data | Classification | Control |
|---|---|---|
| Aadhaar | Highly sensitive | Store only masked images (first 8 digits masked) and last 4 digits; never full number; private bucket; access via 60 s pre-signed URL for OPS/SUPER_ADMIN only; every view audit-logged; admin view watermarked |
| PAN, bank account | Sensitive | Field-level AES-256-GCM (KMS envelope); last-4 for display; never in logs/analytics |
| Mobile, address, name | Personal | Encrypted at rest (DB/storage encryption); masked in logs |
| Ledger/orders | Confidential business | Tenant isolation, audit |
| Location | Personal | Only when-in-use; not tracked in background |
| Voice/images for grocery | Personal | Processed on-device where possible; not uploaded/stored server-side (Q-28) |
- Uploads: allow-listed MIME (image/jpeg, image/png, application/pdf), magic-byte check, size ≤ 5 MB, malware scan (ClamAV in worker) before marking usable, EXIF stripped from images.
- Backups encrypted; restore tested quarterly.
- Secrets in cloud secret manager; rotated; never in repo or app binary (Firebase config files are not secrets but restricted via API key restrictions & App Check).

## 7. Privacy (DPDP Act 2023)
| Requirement | Implementation |
|---|---|
| Notice & consent | Versioned consent at signup (FR-009) in EN/HI; purpose-specific; re-consent on material change |
| Purpose limitation & minimization | Collect only fields in SRS; KYC only for vendors |
| Data principal rights | Access/export (FR-412), correction (profile edit), erasure (FR-008), grievance contact in app (TBD officer, Q-20) |
| Retention | Per [DATA_DESIGN §6](DATA_DESIGN.md#6-data-lifecycle--retention-proposed-q-20) |
| Breach response | Incident runbook ([DEPLOYMENT_OPERATIONS §8](../08-deployment-operations/DEPLOYMENT_OPERATIONS.md)); notify Board & users per DPDP Rules |
| Children | App for 18+ users (account creation asserts age) — TBD confirm |
| Third parties | DPAs with SMS, KYC, cloud, Firebase; data residency India where available |
| Store disclosures | Google Data safety form & Apple privacy nutrition labels kept in sync with this table |

## 8. Permissions (mobile)
| Permission | Platform key | When requested | Feature |
|---|---|---|---|
| Notifications | Android 13+ `POST_NOTIFICATIONS`; iOS UNUserNotificationCenter | After first order/onboarding complete (S-COM-09) | FR-101 |
| Location (when in use) | `ACCESS_FINE/COARSE_LOCATION`; `NSLocationWhenInUseUsageDescription` | Customer location; vendor shop pin; address pin | FR-200, FR-011, FR-291 |
| Camera | `CAMERA`; `NSCameraUsageDescription` | Upload photo, KYC, image order | FR-012, FR-013, FR-281 |
| Photos | Android Photo Picker (no permission); iOS PHPicker (no permission) | Pick images | — |
| Microphone + Speech | `RECORD_AUDIO`; `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` | Voice order | FR-280 |
| Contacts | Not requested; use OS contact picker intent where available | Personal Khata contact | FR-252 |
| Phone | Not requested (`tel:` intent) | Call actions | FR-045 |
All requests use a pre-permission rationale and handle "denied" / "permanently denied" (open settings).

## 9. Security Testing & Process
- SAST (CodeQL / Semgrep), dependency scanning (Dependabot, `pnpm audit`, `dart pub outdated`), secret scanning (gitleaks) on every PR.
- MobSF scan of release builds; OWASP ZAP baseline against staging API & admin.
- Pre-launch third-party penetration test (mobile + API + admin) — required before v1.0.
- Threat model (STRIDE) reviewed per milestone; top threats: OTP abuse, IDOR on ledger, KYC data leakage, admin account takeover, webhook spoofing.

## 10. Open Questions
Q-08 (Aadhaar method), Q-20 (retention, grievance officer), Q-25 (admin roles), certificate pinning approval (ADR-020).
