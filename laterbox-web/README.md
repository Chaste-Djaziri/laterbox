# LaterBox web

The Next.js and React application provides the web library, marketing pages, documentation, and server API routes. It is deployed to Cloudflare Workers through OpenNext.

## Local development

Use Node.js 22, matching `.github/workflows/release.yml`. From this directory:

```sh
npm ci
npm run dev
```

Open http://localhost:3000.

## Extension integration

For local extension capture, run `npm run dev -- --port 8080` and open http://localhost:8080/home. Use the same localhost origin throughout approval and import. See [extension setup](../laterbox-extension/README.md).

## Verification

```sh
npx tsc --noEmit --incremental false
npm test
```

These checks match the web type and unit-test checks in release CI.
