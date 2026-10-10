# LaterBox browser extension

Shared Manifest V3 capture extension for Chromium (Chrome, Edge, Brave), Firefox, and Safari.

## Configure

Build against the hosted LaterBox project:

```bash
npm run build:hosted        # Chromium
npm run build:firefox       # Firefox
npm run build:safari        # Safari
```

Build for the local Next.js web library (no account or Supabase required):

```bash
npm run build:local         # Chromium
npm run build:firefox:local # Firefox
npm run build:safari:local  # Safari
```

Run the local Next.js web app on the matching fixed port:

```bash
cd ../laterbox-web
npm run dev -- --port 8080
```

The local extension opens `http://localhost:8080` for approval. If the old
`127.0.0.1:8080` origin is blank, clear its site data or use the localhost
origin consistently.

Open `http://localhost:8080/home`. Local builds default to **Local library**. Captures persist in browser extension storage while the web app is closed and import when you open it. Use the popup mode buttons to choose **Local library** or **Connect account**. Switching modes preserves both queues. Account connection still requires the configured Supabase backend; local library capture never calls it or remote enrichment.

## Load locally

### Chromium

1. Run `npm run build:local` (or `build:hosted`).
2. Open `chrome://extensions`.
3. Enable Developer mode.
4. Choose Load unpacked.
5. Select `laterbox-extension/dist/chromium`.

### Firefox

1. Run `npm run build:firefox:local` (or `build:firefox`).
2. Open `about:debugging#/runtime/this-firefox`.
3. Choose Load Temporary Add-on.
4. Select `laterbox-extension/dist/firefox/manifest.json`.

### Safari

1. Run `npm run build:safari:local` (or `build:safari`).
2. In Safari: Settings → Developer → enable "Show features for web developers" if the Developer tab is hidden.
3. Open `../safari_app/laterbox/laterbox.xcodeproj`, build and run the macOS app scheme. The Safari extension target bundles `dist/safari` assets. For local unsigned development, enable Safari’s Develop → Allow Unsigned Extensions.
4. Enable the extension and grant website access under Safari Settings → Extensions.

Safari has no WebExtension sidebar API; use the toolbar popup, right-click actions, and capture shortcuts. Native Safari packaging uses `safari_app/laterbox/laterbox.xcodeproj`, whose resource references include the built content script.

## Capture and recovery

Connect any LaterBox account through `https://app.laterbox.dev` for free hosted capture, or select Local library for account-free capture. Page, link, quote, popup, and shortcut saves share the same capture pipeline. Snapshots preserve readable rendered Markdown, metadata, and image URLs; fields and hidden content are excluded, and audio/video files are never downloaded. Highlight captures keep their exact quote and surrounding context separately and open using text fragments, with a DOM fallback where website access permits.

A floating selection button saves quotes. During the Instagram trial, post buttons appear beside Share on supported Instagram feed posts, opened dialogs, and Reels. Injected post buttons on other social sites are disabled; their adapters remain available for future rollout. Stories are excluded. Website layout changes can make a post unsupported; use selected text or page capture in that case. Disable injected buttons in the popup. Website access is requested on installation; browser site restrictions still apply.

Account mode shows Saved only after server acknowledgement. Local mode shows Saved locally only after extension storage succeeds; web import acknowledges after durable guest-library storage. Connected accounts can queue captures offline; Pending, an amber count, and a muted icon identify this state. Persistent account-scoped queues replay on connectivity, browser alarms, and popup opening. Another account cannot upload those captures. Approval resumes after popup closure or worker suspension, and exchange retries reuse the same scoped credential.

Default capture shortcuts are **Option+Shift+S** (macOS) / **Alt+Shift+S** (Windows/Linux) for the page and **Option/Alt+Shift+H** for selected text. Side-panel opening has no default. The popup displays assigned shortcuts and flags unassigned commands. Remap at `chrome://extensions/shortcuts` or Firefox's Manage Extension Shortcuts. OS and extension conflicts can prevent assignment; see [Chrome Commands](https://developer.chrome.com/docs/extensions/reference/api/commands).

Snapshots are limited to 200 KB of UTF-8 Markdown, 10 KB of exact quote, and 8 KB of source URL. Truncated snapshots show a warning in item details. Missing public metadata uses the existing enrichment endpoint; failures keep the local capture.

## Rename and rollout

Unpacked installations previously loaded from `extension/` must be removed/reloaded from `laterbox-extension/dist/chromium` or the corresponding browser build. Manifest identities and existing storage keys are retained; preserve the extension identity/profile to retain credentials and pending captures.

Apply `supabase/migrations/202610060001_extension_content.sql` before deploying the updated `capture` and `extension-connect` functions and web reader. The migration provides owner-only content reads and a service-only atomic capture function. Publish browser artifacts separately after live account smoke testing. No deployment is performed by these build commands.

## Verification

Run `npm test`, `npm run typecheck`, `npm run build:all`, and `npm run zip`. Backend migration tests run through `deno test -A supabase/tests`; capture and connection tests live beside their functions. A real browser/account smoke test still needs the migration and functions deployed to the chosen environment. Native Safari signing and Windows/Linux browser checks require their corresponding environments.

## Free extension rollout

Apply `supabase/migrations/202610100001_free_extension_capture.sql`, then deploy the capture function and web app before releasing the extension. Other Pro features remain paid. Local captures stay in the guest library when signing in; they are never automatically uploaded. Browser-profile storage is local to this browser and origin, so export important captures before clearing browser data.
