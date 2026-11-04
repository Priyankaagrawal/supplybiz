#!/usr/bin/env node
import { readFileSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { required, missingPrerequisites } from './module-prerequisites.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const gate = process.argv[2];
if (!Object.hasOwn(required, gate)) { console.error('Choose G0–G6.'); process.exit(1); }
const register = readFileSync(resolve(root, 'docs/05-ai-development/TASKS.md'), 'utf8');
const missing = missingPrerequisites(gate, register);
if (missing.length) {
  console.error(`Module ${gate} is not ready: ${missing.join(', ')}. READY_FOR_VERIFY is not manual PASS.`);
  process.exit(1);
}
// Each module needs an actual integrated journey, not just the mocked skeleton suite.
const suites = [`apps/api/test/${gate.toLowerCase()}.e2e-spec.ts`,
  `apps/mobile/integration_test/${gate.toLowerCase()}_test.dart`];
if (gate !== 'G0') suites.push(`apps/admin/e2e/${gate.toLowerCase()}.spec.ts`);
if (suites.some(path => !existsSync(resolve(root, path)))) {
  console.error(`Missing comprehensive journey suites: ${suites.filter(path => !existsSync(resolve(root, path))).join(', ')}`);
  process.exit(1);
}
if (process.argv.includes('--check-ready')) { console.log('Module prerequisites and suites present.'); process.exit(0); }
if (!process.env.ANDROID_DEVICE_ID || !process.env.NATIVE_TEST_DATABASE_URL || !process.env.ABUSE_TEST_DATABASE_URL) {
  console.error('Module checks require a configured Android device and dedicated native test databases.'); process.exit(1);
}
function run(args, cwd = root) {
  const result = spawnSync(args[0], args.slice(1), { cwd, stdio: 'inherit', env: process.env });
  if (result.error || result.status !== 0) process.exit(result.status || 1);
}
run(['pnpm', '--filter', '@supplybiz/api', 'lint']);
run(['pnpm', '--filter', '@supplybiz/api', 'test']);
run(['pnpm', '--filter', '@supplybiz/api', 'test:e2e']);
if (gate !== 'G0') run(['pnpm', '--filter', '@supplybiz/admin', 'exec', 'playwright', 'test']);
run([process.env.FLUTTER_BIN || 'flutter', 'test', `integration_test/${gate.toLowerCase()}_test.dart`,
  '-d', process.env.ANDROID_DEVICE_ID, '--flavor', 'dev', '--dart-define-from-file=config/dev.json'], resolve(root, 'apps/mobile'));
console.log('Automated module checks passed. Record manual evidence and review TASKS before claiming the gate PASS.');
