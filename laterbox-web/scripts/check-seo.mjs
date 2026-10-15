import assert from 'node:assert/strict';

const origin = process.env.SEO_TEST_ORIGIN || 'http://localhost:3100';
async function request(path, host = 'laterbox.dev') {
  return fetch(origin + path, { headers: { host }, redirect: 'manual' });
}
const paths = ['/', '/features', '/about', '/browser-extension', '/download', '/guide', '/pricing', '/privacy', '/terms', '/refund'];
const titles = new Set();
for (const path of paths) {
  const response = await request(path);
  assert.equal(response.status, 200, path);
  const html = await response.text();
  const title = html.match(/<title>(.*?)<\/title>/)?.[1];
  assert.ok(title, path + ' title');
  assert.ok(!titles.has(title), path + ' unique title');
  titles.add(title);
  assert.ok(html.includes('rel="canonical" href="https://laterbox.dev' + (path === '/' ? '' : path) + '"'), path + ' canonical');
  assert.match(html, /name="description" content="[^"]+"/);
  assert.match(html, /property="og:image:width" content="1200"/);
  assert.match(html, /name="twitter:card" content="summary_large_image"/);
  assert.ok(!html.includes('id="mobile-block-overlay"'));
  for (const match of html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/g)) JSON.parse(match[1]);
}
for (const [path, host, expected] of [
  ['/plans?ref=seo', 'laterbox.dev', 'https://laterbox.dev/pricing?ref=seo'],
  ['/features?ref=seo', 'www.laterbox.dev', 'https://laterbox.dev/features?ref=seo'],
]) {
  const response = await request(path, host);
  assert.equal(response.status, 308);
  assert.equal(response.headers.get('location'), expected);
}
for (const path of ['/login', '/inbox', '/plans', '/pricing', '/guide', '/download', '/extension/connect']) {
  const response = await request(path, 'app.laterbox.dev');
  assert.match(response.headers.get('x-robots-tag'), /noindex/);
}
const marketing = await (await request('/sitemap.xml')).text();
assert.ok(!marketing.includes('lastmod'));
assert.ok(!marketing.includes('docs.laterbox.dev'));
assert.ok(!marketing.includes('/login'));
for (const path of paths.slice(1)) assert.ok(marketing.includes('https://laterbox.dev' + path));
const docs = await (await request('/sitemap.xml', 'docs.laterbox.dev')).text();
assert.ok(docs.includes('https://docs.laterbox.dev/introduction'));
assert.ok(!docs.includes('https://laterbox.dev'));
assert.equal((await request('/not-a-real-document', 'docs.laterbox.dev')).status, 404);
for (const url of [...docs.matchAll(/<loc>(.*?)<\/loc>/g)].map(m => new URL(m[1]))) {
  assert.equal((await request(url.pathname, url.hostname)).status, 200, url.href);
}
const image = await request('/branding/og-preview.png');
assert.equal(image.status, 200);
const bytes = new DataView(await image.arrayBuffer());
assert.equal(bytes.getUint32(16), 1200);
assert.equal(bytes.getUint32(20), 630);
console.log('Public metadata, canonical redirects, app noindex, sitemaps, docs status, and social image checks passed.');
