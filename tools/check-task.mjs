#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const requested = process.argv[2] || process.env.TASK_ID || process.env.TASK_TITLE || '';
let tasks = [...new Set(requested.match(/\bT-\d{3}\b/g) ?? [])];
const api = (...args) => ['pnpm', '--filter', '@supplybiz/api', ...args];
const flutter = process.env.FLUTTER_BIN || 'flutter';
function run(args, cwd = root) {
  console.log(`Running ${args.join(' ')}`);
  const result = spawnSync(args[0], args.slice(1), { cwd, stdio: 'inherit', env: process.env });
  if (result.error || result.status !== 0) process.exit(result.status || 1);
}
const apiTests = {
  'T-028': ['src/modules/customers/customers.postgres.spec.ts'],
  'T-032': ['src/modules/notifications/fcm.service.spec.ts', 'src/modules/notifications/notifications.postgres.spec.ts', 'src/modules/kyc/kyc.postgres.spec.ts'],
  'T-027': ['src/modules/catalog/catalog.postgres.spec.ts'],
  'T-026': ['src/modules/catalog/catalog.postgres.spec.ts'],
  'T-153': ['src/modules/categories/categories.postgres.spec.ts'],
  'T-023': ['src/modules/vendors/vendors.postgres.spec.ts', 'src/storage/local-storage.service.spec.ts'],
  'T-151': ['src/modules/kyc/kyc.postgres.spec.ts'],
  'T-022': ['src/modules/kyc/kyc.postgres.spec.ts'],
  'T-152': ['src/modules/audit/audit.postgres.spec.ts'],
  'T-021': ['src/modules/vendors/vendors.postgres.spec.ts'],
  'T-020': ['src/modules/media/media.postgres.spec.ts'],
  'T-150': ['src/modules/admin-auth/admin-password.spec.ts', 'src/modules/admin-auth/admin-auth.postgres.spec.ts'],
  'T-017': ['src/modules/content/app-config.spec.ts'],
  'T-015': ['src/modules/auth/sessions.service.spec.ts', 'src/modules/auth/sessions.http.spec.ts',
    'src/modules/auth/sessions.postgres.spec.ts'],
  'T-181': ['src/outbox/outbox-dispatcher.postgres.spec.ts'],
  'T-180': ['src/modules/auth/postgres-otp.store.spec.ts', 'src/modules/auth/otp.service.spec.ts',
    'src/modules/auth/otp.http.spec.ts', 'src/modules/auth/otp.postgres.spec.ts'],
  'T-182': ['src/storage/local-storage.service.spec.ts', 'src/health/health.service.spec.ts'],
  'T-184': ['src/storage/local-storage.service.spec.ts', 'src/health/health.service.spec.ts'],
};
if (!tasks.length || tasks.some(id => ![...Object.keys(apiTests), 'T-002', 'T-009', 'T-016', 'T-024', 'T-025', 'T-029', 'T-183'].includes(id))) {
  console.error('Provide a supported T-ID in the PR title or TASK_ID. Add explicit focused checks for new tasks; unsupported tasks cannot silently pass.');
  process.exit(1);
}
if (process.env.CHECK_LAYER) {
  tasks = tasks.filter(id => process.env.CHECK_LAYER === 'api'
    ? id in apiTests || id === 'T-002' : ['T-009', 'T-016', 'T-017', 'T-024', 'T-025', 'T-027', 'T-029', 'T-183'].includes(id));
  if (!tasks.length) { console.error('No focused task for the affected layer. Register its task checks first.'); process.exit(1); }
}
for (const task of tasks) {
  if (task === 'T-002') { run(api('infra:check')); continue; }
  if (apiTests[task] && !(['T-017', 'T-027'].includes(task) && process.env.CHECK_LAYER === 'mobile')) {
    if (task === 'T-184') run(['node', '--test', 'tools/checks.spec.mjs']);
    if (!process.env.NATIVE_TEST_DATABASE_URL || !process.env.ABUSE_TEST_DATABASE_URL) {
      console.error('Native task checks require dedicated NATIVE_TEST_DATABASE_URL and ABUSE_TEST_DATABASE_URL; no skipped-DB success.');
      process.exit(1);
    }
    run(api('lint')); run(api('typecheck')); run(api('build'));
    if (task === 'T-150' || task === 'T-152' || task === 'T-151' || task === 'T-153') {
      process.env.ADMIN_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
      run(['pnpm', '--filter', '@supplybiz/admin', 'lint']);
      run(['pnpm', '--filter', '@supplybiz/admin', 'typecheck']);
      run(['pnpm', '--filter', '@supplybiz/admin', 'test']);
      run(['pnpm', '--filter', '@supplybiz/admin', 'build']);
    }
    if (task === 'T-181') process.env.WORKER_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-015') process.env.SESSIONS_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-151') process.env.KYC_ADMIN_SMOKE = '1';
    if (task === 'T-153') process.env.CATEGORIES_ADMIN_SMOKE = '1';
    if (task === 'T-022' || task === 'T-151') process.env.KYC_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-021' || task === 'T-023') process.env.VENDORS_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-020') process.env.MEDIA_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-028') process.env.CUSTOMERS_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-026' || task === 'T-027') process.env.CATALOG_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-032') {
      process.env.NOTIFICATIONS_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
      process.env.KYC_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    }
    if (task === 'T-017') process.env.CONFIG_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    run(api('exec', 'jest', '--runInBand', '--runTestsByPath', ...apiTests[task]));
    run(api('exec', 'jest', '--config', 'test/jest-e2e.json', '--runInBand', '--runTestsByPath', 'test/native-runtime.e2e-spec.ts'));
    if (!['T-017', 'T-027'].includes(task) || process.env.CHECK_LAYER === 'api') continue;
  }
  if (task === 'T-029') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/features/customers', 'test/core/router/guards_test.dart', 'test/core/router/app_router_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
    continue;
  }
  if (task === 'T-027') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/features/products', 'test/core/router/guards_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
    continue;
  }
  if (task === 'T-017') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/core/config/app_config_test.dart', 'test/features/auth/auth_pages_test.dart',
      'test/core/router/guards_test.dart', 'test/core/network/network_client_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
    continue;
  }
  if (task === 'T-025') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/features/service_area', 'test/core/router/guards_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
    continue;
  }
  if (task === 'T-024') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/features/onboarding', 'test/core/router/guards_test.dart',
      'test/core/storage/app_storage_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
    continue;
  }
  run([flutter, 'analyze'], resolve(root, 'packages/ui_kit'));
  run([flutter, 'test', 'test/src/components_test.dart'], resolve(root, 'packages/ui_kit'));
  if (task === 'T-016') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/features/auth', 'test/core/router/app_router_test.dart',
      'test/core/network/network_client_test.dart', 'test/core/storage/secure_store_test.dart',
      'test/core/storage/app_storage_test.dart', 'test/widget_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
  }
  if (task === 'T-183') {
    const mobile = resolve(root, 'apps/mobile');
    run([flutter, 'analyze'], mobile);
    run([flutter, 'test', 'test/widget_test.dart', 'test/core/router/app_router_test.dart',
      'test/core/router/guards_test.dart', 'test/core/network/app_failure_test.dart', 'test/core/utils/dates_test.dart'], mobile);
    run([flutter, 'build', 'apk', '--debug', '--flavor', 'dev', '-t', 'lib/main_dev.dart', '--dart-define-from-file=config/dev.json'], mobile);
  }
}
