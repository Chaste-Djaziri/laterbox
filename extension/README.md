# LaterBox browser extension

Chromium Manifest V3 capture MVP for Chrome, Edge, and Brave.

## Configure

Set the capture endpoint and hosted LaterBox web URL before building:

```bash
VITE_CAPTURE_API_URL=https://YOUR_PROJECT.supabase.co/functions/v1/capture \
VITE_LATERBOX_WEB_URL=https://app.laterbox.com \
npm run build
```

For local Supabase:

```bash
VITE_CAPTURE_API_URL=http://127.0.0.1:54321/functions/v1/capture npm run build
```

The popup connects through the LaterBox web approval screen. The extension stores only its scoped `lb_ext_` credential in `chrome.storage.local`.

## Load locally

1. Run `npm run build`.
2. Open `chrome://extensions`.
3. Enable Developer mode.
4. Choose Load unpacked.
5. Select `extension/dist`.

The extension also adds page, link, and selection context menu actions. Failed captures remain in `chrome.storage.local` and retry when the service worker starts or the popup opens.
