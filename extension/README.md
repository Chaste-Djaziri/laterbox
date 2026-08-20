# LaterBox browser extension

Manifest V3 capture MVP for Chromium (Chrome, Edge, Brave) and Firefox.

## Configure

Build against the hosted LaterBox project:

```bash
npm run build:hosted        # Chromium
npm run build:firefox       # Firefox
```

Build against local Supabase and the local Flutter web app:

```bash
npm run build:local         # Chromium
npm run build:firefox:local # Firefox
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
supabase status -o env > /tmp/laterbox-supabase.env
supabase functions serve --no-verify-jwt --env-file /tmp/laterbox-supabase.env
```

The popup connects through the LaterBox web approval screen. The extension stores only its scoped `lb_ext_` credential in `chrome.storage.local`.

## Load locally

### Chromium

1. Run `npm run build:local` (or `build:hosted`).
2. Open `chrome://extensions`.
3. Enable Developer mode.
4. Choose Load unpacked.
5. Select `extension/dist/chromium`.

### Firefox

1. Run `npm run build:firefox:local` (or `build:firefox`).
2. Open `about:debugging#/runtime/this-firefox`.
3. Choose Load Temporary Add-on.
4. Select `extension/dist/firefox/manifest.json`.

The extension also adds page, link, and selection context menu actions, plus `Command+Shift+L` / `Ctrl+Shift+L` for quick capture and a side panel (Chromium side panel, Firefox sidebar). Failed captures remain in `chrome.storage.local` and retry when the service worker starts or the popup opens.

If the browser does not assign the suggested shortcuts, configure them at `chrome://extensions/shortcuts` (Chromium) or `about:addons` → gear icon → Manage Extension Shortcuts (Firefox).

The generic page context reader uses a canonical URL when the page provides one. Opening the popup or side panel while text is selected shows a highlight card that saves the exact selection as a quoted note with its source title and URL. Social links are captured through the same toolbar and context menu actions without relying on social site markup.
