# Public SEO verification and launch

Run from laterbox-web:

1. Run npm run build.
2. Run npm run start -- --port 3100.
3. In another terminal run node scripts/check-seo.mjs.

The checker validates rendered public metadata, canonical redirects, application noindex headers, separate host sitemaps, documentation responses, and the 1200 × 630 social image.

After deploying through the existing Cloudflare release workflow, inspect https://laterbox.dev/features and https://docs.laterbox.dev/introduction and confirm their canonical metadata. Check that www redirects to the apex, /plans redirects to /pricing, and application responses contain X-Robots-Tag: noindex, follow.

In Google Search Console:
1. Select or add the laterbox.dev Domain property. If it is unverified, complete Google's DNS TXT verification with the domain owner.
2. Open Sitemaps and submit https://laterbox.dev/sitemap.xml and https://docs.laterbox.dev/sitemap.xml.
3. Use URL Inspection for the homepage, /features, /about, /browser-extension, and /pricing. Run Test Live URL, verify indexing is allowed and the declared canonical is correct, then request indexing.
4. Monitor Page Indexing for exclusions and canonical problems. In Performance, filter queries for laterbox and compare impressions, clicks, and average position over time.

Do not repeatedly request indexing or change sitemap modification times without content changes. Rankings and indexing are controlled by search engines; no position is guaranteed.
