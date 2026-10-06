# laterbox Browser Extensions

laterbox includes Manifest V3 browser extensions for **Google Chrome / Chromium browsers**, **Apple Safari**, and **Mozilla Firefox**.

---

## Directory Structure

```text
laterbox-extension/
├── manifests/
│   ├── chromium.json   # Chrome Web Store & Chromium MV3 Manifest
│   ├── safari.json     # Safari Web Extension Manifest
│   └── firefox.json    # Firefox Add-ons MV3 Manifest
├── src/
│   ├── background/     # Background service worker (context menus, save handlers)
│   ├── lib/            # Shared auth, storage, API clients, and constants
│   ├── popup/          # Extension popup UI (quick capture & status)
│   └── sidepanel/      # Browser sidepanel UI (library view & capture)
└── package.json        # Build and packaging scripts
```

---

## Features

1. **One-Click Page & Link Capture**:
   - Save the active tab URL, title, and selection directly from the toolbar popup or shortcut (`Option/Alt+Shift+S`).
   - Context menu items: "Save page to laterbox", "Save link to laterbox", "Save selection to laterbox".
2. **Sidepanel Support**:
   - Integrated sidepanel for Chromium and Firefox, allowing users to browse their saved library while reading articles.
3. **Secure Web-to-Extension Authentication Handshake**:
   - Uses `externally_connectable` and web redirects to pair the browser extension with your active web session securely.
   - Pending status, cancellation, and retry flows built right into the popup.

---

## Building and Packaging

Run these commands from within the `laterbox-extension/` directory:

### Install Dependencies
```bash
cd laterbox-extension
npm install
```

### Build for All Browsers
```bash
npm run build:all
```

### Create Distribution ZIPs for Web Stores
```bash
npm run package
```

The output archives will be generated in `laterbox-extension/dist/`:
- `laterbox-extension/dist/laterbox-chrome-extension.zip` (Chrome Web Store)
- `laterbox-extension/dist/laterbox-safari-extension.zip` (Safari Web Extension)
- `laterbox-extension/dist/laterbox-firefox-extension.zip` (Firefox Add-ons)

---

## Loading for Local Development

### Google Chrome
1. Navigate to `chrome://extensions`.
2. Enable **Developer mode** (top-right toggle).
3. Click **Load unpacked** and select `laterbox-extension/dist/chromium`.

### Safari
1. Open **Safari Settings → Advanced** and enable **Show features for web developers**.
2. Go to **Develop → Allow Unsigned Extensions**.
3. In Safari Settings → Extensions, enable **laterbox**.

### Firefox
1. Navigate to `about:debugging#/runtime/this-firefox`.
2. Click **Load Temporary Add-on...** and select `laterbox-extension/dist/firefox/manifest.json`.


## Rich capture and connection

Rendered pages become readable Markdown snapshots with source metadata. Explicit selection buttons save exact quotes with source highlights; social buttons target individual posts on X, Reddit, LinkedIn, Instagram, and Facebook. Injected controls can be disabled in the popup, and restricted or changed layouts retain page/selection capture where permitted.

Every save requires a connected Pro account. Offline saves are Pending, show an amber count and muted toolbar icon, and replay automatically for their originating account. Saved means the server acknowledged the item. Approval survives popup closure and worker suspension.

Use Option+Shift+S on macOS or Alt+Shift+S on Windows/Linux to save the page; Option/Alt+Shift+H saves selected text. Side-panel commands are unbound. The popup lists registered shortcuts and remapping guidance for conflicts.

Reload unpacked installations from the renamed `laterbox-extension/` directory. Apply the content migration and deploy the updated capture/connection functions and web reader before account smoke testing. See [the extension README](../laterbox-extension/README.md) for rollout and verification commands.
