// laterbox-web/scripts/configure-apple-verification.mjs
// Public certificate roots plus optional dedicated, server-only App Store account-link credentials.
import { createPrivateKey, X509Certificate } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { assertAppleBindingsFit, wranglerFailure } from './apple-verification-utils.mjs';

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
const rootCertificateBundle = encoded.join(',');
assertAppleBindingsFit({ APPLE_ROOT_CERTIFICATES_BASE64: rootCertificateBundle });
console.log(`Validated ${encoded.length} trusted roots downloaded from Apple PKI (${Buffer.byteLength(rootCertificateBundle)} bytes).`);
if (!process.argv.includes('--check-only')) {
  if (!process.env.CLOUDFLARE_ACCOUNT_ID || !process.env.CLOUDFLARE_API_TOKEN) {
    throw new Error('Set the deployment Cloudflare account ID and API token before configuring the existing Worker.');
  }
  const wrangler = 'node_modules/wrangler/bin/wrangler.js';
  const inventory = spawnSync(process.execPath, [wrangler, 'secret', 'list', '--name', 'laterbox-web'], { encoding: 'utf8' });
  const sensitiveValues = [
    process.env.CLOUDFLARE_API_TOKEN,
    process.env.APPLE_PRIVATE_KEY,
    process.env.APPLE_KEY_ID,
    process.env.APPLE_ISSUER_ID,
    rootCertificateBundle,
  ];
  if (inventory.status !== 0) throw wranglerFailure(inventory, 'Worker inventory', sensitiveValues);
  const accountLinkCredentials = {};
  const credentialNames = ['APPLE_PRIVATE_KEY', 'APPLE_KEY_ID', 'APPLE_ISSUER_ID'];
  const supplied = credentialNames.filter((name) => process.env[name]);
  if (supplied.length && supplied.length !== credentialNames.length) throw new Error('Provide all three dedicated In-App Purchase API credentials together.');
  if (supplied.length) {
    const privateKey = process.env.APPLE_PRIVATE_KEY.replace(/\\n/g, '\n');
    const key = createPrivateKey(privateKey);
    if (key.asymmetricKeyType !== 'ec' || key.asymmetricKeyDetails?.namedCurve !== 'prime256v1') throw new Error('Apple In-App Purchase key must be a P-256 private key.');
    if (!/^[A-Z0-9]{10}$/.test(process.env.APPLE_KEY_ID) || !/^[0-9a-f-]{36}$/i.test(process.env.APPLE_ISSUER_ID)) throw new Error('Invalid Apple key ID or issuer ID.');
    Object.assign(accountLinkCredentials, { APPLE_PRIVATE_KEY: privateKey, APPLE_KEY_ID: process.env.APPLE_KEY_ID, APPLE_ISSUER_ID: process.env.APPLE_ISSUER_ID });
  }
  const payload = {
    ...accountLinkCredentials,
    APPLE_APP_ID: '6804139119',
    APPLE_BUNDLE_ID: 'pro.micorp.laterbox',
    APPLE_ROOT_CERTIFICATES_BASE64: rootCertificateBundle,
  };
  assertAppleBindingsFit(payload);
  console.log(`Uploading ${Object.keys(payload).length} Apple verification variables to existing Worker laterbox-web.`);
  const result = spawnSync(process.execPath, [wrangler, 'secret', 'bulk', '--name', 'laterbox-web'], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
    timeout: 60_000,
    maxBuffer: 4 * 1024 * 1024,
  });
  if (result.status !== 0) throw wranglerFailure(result, 'Apple secret update', [
    ...sensitiveValues,
    ...Object.values(accountLinkCredentials),
  ]);
  if (supplied.length) console.log('Configured dedicated server-only Apple account-link credentials.');
  else console.log('Existing account-link credentials are retained; missing credentials leave optional account connection unavailable.');
  console.log('Configured Apple verification for the existing LaterBox App Store application.');
}
