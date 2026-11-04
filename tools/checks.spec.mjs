import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { missingPrerequisites } from './module-prerequisites.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
function run(script, arg) {
  return spawnSync(process.execPath, [script, arg], { cwd: root, encoding: 'utf8',
    env: { ...process.env, TASK_ID: '', TASK_TITLE: '', NATIVE_TEST_DATABASE_URL: '', ABUSE_TEST_DATABASE_URL: '' } });
}
test('unknown tasks cannot report success without focused checks', () => {
  const result = run('tools/check-task.mjs', 'T-999');
  assert.equal(result.status, 1);
  assert.match(result.stderr, /supported T-ID/);
});
test('task mode refuses silently skipped native database coverage', () => {
  const result = run('tools/check-task.mjs', 'T-182');
  assert.equal(result.status, 1);
  assert.match(result.stderr, /no skipped-DB success/);
});
test('module readiness requires manual DONE and the prior gate PASS', () => {
  const approved = '| T-017 | task | DONE |\n| T-018 | task | DONE |\n| T-122 | task | DONE |\n| G4 Business/admin | PASS | evidence |';
  assert.deepEqual(missingPrerequisites('G5', approved), []);
  assert.deepEqual(missingPrerequisites('G5', approved.replace('| DONE |', '| READY_FOR_VERIFY |')), ['T-017']);
  assert.deepEqual(missingPrerequisites('G5', approved.replace('| PASS |', '| NOT RUN |')), ['G4 PASS']);
});
test('unknown module IDs cannot execute arbitrary commands', () => {
  const result = run('tools/check-module.mjs', 'not-a-module');
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Choose G0/);
});
