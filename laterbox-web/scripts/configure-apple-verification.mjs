// Public Apple verification settings only. No App Store private key is required.
import { X509Certificate } from 'node:crypto';
import { spawnSync } from 'node:child_process';

const roots = [
  'https://www.apple.com/appleca/AppleIncRootCertificate.cer',
  'https://www.apple.com/certificateauthority/AppleRootCA-G2.cer',
  'https://www.apple.com/certificateauthority/AppleRootCA-G3.cer',
];
const encoded = await Promise.all(roots.map(async (url) => {
  const response = await fetch(url, { signal: AbortSignal.timeout(20_000), redirect: 'error' });
  if (!response.ok) throw new Error(`Apple root download failed (${response.status}).`);
  const data = Buffer.from(await response.arrayBuffer());
  const certificate = new X509Certificate(data);
  const now = Date.now();
  if (!certificate.ca || !certificate.subject.includes('Apple') || !certificate.checkIssued(certificate)
    || !certificate.verify(certificate.publicKey) || Date.parse(certificate.validFrom) > now || Date.parse(certificate.validTo) <= now) {
    throw new Error('Apple root certificate validation failed.');
  }
  return data.toString('base64');
}));
console.log(`Validated ${encoded.length} trusted roots downloaded from Apple PKI.`);
if (!process.argv.includes('--check-only')) {
  if (!process.env.CLOUDFLARE_ACCOUNT_ID || !process.env.CLOUDFLARE_API_TOKEN) {
    throw new Error('Set the deployment Cloudflare account ID and API token before configuring the existing Worker.');
  }
  const wrangler = 'node_modules/wrangler/bin/wrangler.js';
  const inventory = spawnSync(process.execPath, [wrangler, 'secret', 'list', '--name', 'laterbox-web'], { encoding: 'utf8' });
  if (inventory.status !== 0) throw new Error('Unable to access the existing laterbox-web Worker in the configured account.');
  const result = spawnSync(process.execPath, [wrangler, 'secret', 'bulk', '--name', 'laterbox-web'], {
    input: JSON.stringify({
      APPLE_APP_ID: '6804139119',
      APPLE_BUNDLE_ID: 'pro.micorp.laterbox',
      APPLE_ROOT_CERTIFICATES_BASE64: encoded.join(','),
    }),
    encoding: 'utf8',
  });
  if (result.status !== 0) throw new Error('Unable to configure Apple verification on the existing Worker.');
  console.log('Configured Apple verification for the existing LaterBox App Store application.');
}
