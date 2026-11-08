// laterbox-web/scripts/apple-verification-utils.test.mjs
import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { assertAppleBindingsFit, MAX_CLOUDFLARE_VARIABLE_BYTES, wranglerFailure } from './apple-verification-utils.mjs';

test('Apple verification bindings respect the Worker variable size cap', () => {
  assert.doesNotThrow(() => assertAppleBindingsFit({ APPLE_APP_ID: '6804139119', ROOTS: 'x'.repeat(MAX_CLOUDFLARE_VARIABLE_BYTES) }));
  assert.throws(() => assertAppleBindingsFit({ ROOTS: 'x'.repeat(MAX_CLOUDFLARE_VARIABLE_BYTES + 1) }), /ROOTS.*exceeding Cloudflare/);
  assert.throws(() => assertAppleBindingsFit({ ROOTS: null }), /must be a string/);
});

test('Wrangler failures show actionable output without leaking API tokens or Apple keys', () => {
  const apiToken = 'secret_cloudflare_api_token';
  const appleKey = '-----BEGIN PRIVATE KEY-----\nPRIVATE_SECRET\n-----END PRIVATE KEY-----';
  const error = wranglerFailure({
    status: 1,
    stderr: `Error: 403 Forbidden. Authorization: Bearer ${apiToken}\nInvalid key ${appleKey}`,
    stdout: 'Permission denied while updating Worker.',
  }, 'secret update', [apiToken, appleKey]);
  assert.match(error.message, /403 Forbidden/);
  assert.match(error.message, /Workers Editor/);
  assert.match(error.message, /Permission denied/);
  assert.doesNotMatch(error.message, /secret_cloudflare_api_token|PRIVATE_SECRET/);
});

test('Handles silent Wrangler errors and escaped newlines in sensitive values', () => {
  const secret = 'PRIVATE-LINE-ONE\nPRIVATE-LINE-TWO';
  const error = wranglerFailure(
    { status: null, signal: 'SIGTERM', stderr: `key: ${secret.replaceAll('\n', '\\n')}` },
    'Worker inventory', [secret],
  );
  assert.match(error.message, /signal SIGTERM/);
  assert.doesNotMatch(error.message, /PRIVATE-LINE/);
  const silent = wranglerFailure({ status: 1 }, 'secret update');
  assert.match(silent.message, /no diagnostic output/);
});

test('Cloudflare release deploys the Worker before editing Apple verification secrets', () => {
  const workflow = readFileSync(new URL('../../.github/workflows/release.yml', import.meta.url), 'utf8');
  const deployed = workflow.indexOf('      - name: Deploy Cloudflare application');
  const configured = workflow.indexOf('      - name: Configure Apple purchase verification');
  assert.ok(deployed > 0, 'Deploy Cloudflare application step must exist');
  assert.ok(configured > deployed, 'Secret provisioning must run after deploying the latest Worker version to avoid Cloudflare 10215');
  assert.match(workflow.slice(deployed, configured), /npx opennextjs-cloudflare deploy/);
  assert.match(workflow.slice(configured), /node scripts\/configure-apple-verification\.mjs/);
});
