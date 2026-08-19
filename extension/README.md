# LaterBox browser extension

Chromium Manifest V3 capture MVP for Chrome, Edge, and Brave.

## Configure

Build against the hosted LaterBox project:

```bash
npm run build:hosted
```

Build against local Supabase and the local Flutter web app:

```bash
npm run build:local
```

Run the local Flutter web app on the matching fixed port:

```bash
flutter run -d chrome --web-port 8080
```

The local extension opens `http://localhost:8080` for approval. If the old
`127.0.0.1:8080` origin is blank, clear its site data or use the localhost
origin consistently.

Serve the local capture functions in another terminal:

```bash
supabase migration up --local
supabase functions serve --no-verify-jwt
```

The popup connects through the LaterBox web approval screen. The extension stores only its scoped `lb_ext_` credential in `chrome.storage.local`.

## Load locally

1. Run `npm run build`.
2. Open `chrome://extensions`.
3. Enable Developer mode.
4. Choose Load unpacked.
5. Select `extension/dist`.

The extension also adds page, link, and selection context menu actions. Failed captures remain in `chrome.storage.local` and retry when the service worker starts or the popup opens.
