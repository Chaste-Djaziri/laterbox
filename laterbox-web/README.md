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

## Cloudflare preview

Run `npm run preview` to build through OpenNext and preview on the Cloudflare runtime. `npm run build` builds Next.js; it does not deploy a Worker.

## Deployment

`npm run deploy` builds and deploys through OpenNext. CI deploys eligible main-branch runs using `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`; pull requests run validation and build without deployment. See [deployment](../docs/deployment.md).

## Application source

Routes live in `src/app/`, reusable UI in `src/components/`, and application services in `src/lib/`. `src/lib/docs-data.ts` supplies the in-app documentation content.

## Authentication and local data

Start with `src/lib/store/AuthContext.tsx` and `src/lib/supabase/client.ts` for account integration. Local capture queues and attachments are implemented in `src/lib/utils/`; extension imports are in `src/lib/extension/local-import.ts`.
