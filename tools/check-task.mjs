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
  'T-015': ['src/modules/auth/sessions.service.spec.ts', 'src/modules/auth/sessions.http.spec.ts',
    'src/modules/auth/sessions.postgres.spec.ts'],
  'T-181': ['src/outbox/outbox-dispatcher.postgres.spec.ts'],
  'T-180': ['src/modules/auth/postgres-otp.store.spec.ts', 'src/modules/auth/otp.service.spec.ts',
    'src/modules/auth/otp.http.spec.ts', 'src/modules/auth/otp.postgres.spec.ts'],
  'T-182': ['src/storage/local-storage.service.spec.ts', 'src/health/health.service.spec.ts'],
  'T-184': ['src/storage/local-storage.service.spec.ts', 'src/health/health.service.spec.ts'],
};
if (!tasks.length || tasks.some(id => ![...Object.keys(apiTests), 'T-002', 'T-009', 'T-016', 'T-183'].includes(id))) {
  console.error('Provide a supported T-ID in the PR title or TASK_ID. Add explicit focused checks for new tasks; unsupported tasks cannot silently pass.');
  process.exit(1);
}
if (process.env.CHECK_LAYER) {
  tasks = tasks.filter(id => process.env.CHECK_LAYER === 'api'
    ? id in apiTests || id === 'T-002' : ['T-009', 'T-016', 'T-183'].includes(id));
  if (!tasks.length) { console.error('No focused task for the affected layer. Register its task checks first.'); process.exit(1); }
}
for (const task of tasks) {
  if (task === 'T-002') { run(api('infra:check')); continue; }
  if (apiTests[task]) {
    if (task === 'T-184') run(['node', '--test', 'tools/checks.spec.mjs']);
    if (!process.env.NATIVE_TEST_DATABASE_URL || !process.env.ABUSE_TEST_DATABASE_URL) {
      console.error('Native task checks require dedicated NATIVE_TEST_DATABASE_URL and ABUSE_TEST_DATABASE_URL; no skipped-DB success.');
      process.exit(1);
    }
    run(api('lint')); run(api('typecheck')); run(api('build'));
    if (task === 'T-181') process.env.WORKER_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    if (task === 'T-015') process.env.SESSIONS_TEST_DATABASE_URL ||= process.env.NATIVE_TEST_DATABASE_URL;
    run(api('exec', 'jest', '--runInBand', '--runTestsByPath', ...apiTests[task]));
    run(api('exec', 'jest', '--config', 'test/jest-e2e.json', '--runInBand', '--runTestsByPath', 'test/native-runtime.e2e-spec.ts'));
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
