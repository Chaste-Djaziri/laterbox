# LaterBox browser extension

Chromium Manifest V3 capture MVP for Chrome, Edge, and Brave.

## Configure

Set the capture endpoint before building:

```bash
VITE_CAPTURE_API_URL=https://YOUR_PROJECT.supabase.co/functions/v1/capture npm run build
```

For local Supabase:

```bash
VITE_CAPTURE_API_URL=http://127.0.0.1:54321/functions/v1/capture npm run build
```

The popup currently accepts a Supabase access token for the Phase 13.0A developer flow. The token is stored in `chrome.storage.local` and is sent as a bearer token to the capture function.

## Load locally

1. Run `npm run build`.
2. Open `chrome://extensions`.
3. Enable Developer mode.
4. Choose Load unpacked.
5. Select `extension/dist`.

The extension also adds page, link, and selection context menu actions. Failed captures remain in `chrome.storage.local` and retry when the service worker starts or the popup opens.
