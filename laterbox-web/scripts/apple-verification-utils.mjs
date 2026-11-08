// laterbox-web/scripts/apple-verification-utils.mjs
// Safe diagnostics and Cloudflare Worker binding validation for Apple receipt verification.
export const MAX_CLOUDFLARE_VARIABLE_BYTES = 5_000;

export function assertAppleBindingsFit(payload) {
  for (const [name, value] of Object.entries(payload)) {
    if (typeof value !== 'string') {
      throw new Error(`Apple Worker variable ${name} must be a string.`);
    }
    const size = Buffer.byteLength(value, 'utf8');
    if (size > MAX_CLOUDFLARE_VARIABLE_BYTES) {
      throw new Error(
        `Apple Worker variable ${name} is ${size} bytes, exceeding Cloudflare's 5 KB per-variable limit. ` +
        'Use separate certificate bindings or another supported storage mechanism instead of uploading this value.',
      );
    }
  }
}

export function wranglerFailure(result, action, secretValues = []) {
  const code = result.status ?? (result.signal ? `signal ${result.signal}` : 'unknown');
  const output = [result.error?.message, result.stderr, result.stdout].filter(Boolean).join('\n');
  let sanitized = output.replace(/\x1b\[[0-9;]*m/g, '');
  for (const value of secretValues.filter(value => typeof value === 'string' && value.length > 2)) {
    sanitized = sanitized.replaceAll(value, '[REDACTED]');
    sanitized = sanitized.replaceAll(value.replaceAll('\n', '\\n'), '[REDACTED]');
  }
  // Wrangler normally redacts credentials, but also handle common HTTP auth diagnostic patterns.
  sanitized = sanitized.replace(/(Bearer\s+)[^\s]+/gi, '$1[REDACTED]');
  sanitized = sanitized.replace(/(Authorization:\s*)[^\r\n]+/gi, '$1[REDACTED]');
  const details = sanitized.trim().slice(-3_000) || 'Wrangler returned no diagnostic output.';
  return new Error(
    `Cloudflare ${action} failed (exit ${code}).\n${details}\n` +
    'Check that GitHub secrets CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN target the existing laterbox-web Worker, ' +
    'and that the token has Workers Editor (or legacy Workers Scripts Edit) access to that Worker. ' +
    'Cloudflare also limits each secret to 5 KB.',
  );
}
