# laterbox Browser Extensions

laterbox includes Manifest V3 browser extensions for **Google Chrome / Chromium browsers**, **Apple Safari**, and **Mozilla Firefox**.

---

## Directory Structure

```text
extension/
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
   - Save the active tab URL, title, and selection directly from the toolbar popup or shortcut (`Cmd+Shift+L`).
   - Context menu items: "Save page to laterbox", "Save link to laterbox", "Save selection to laterbox".
2. **Sidepanel Support**:
   - Integrated sidepanel for Chromium and Safari, allowing users to browse their saved library while reading articles.
3. **Secure Web-to-Extension Authentication Handshake**:
   - Uses `externally_connectable` and web redirects to pair the browser extension with your active web session securely.
   - Pending status, cancellation, and retry flows built right into the popup.

---

## Building and Packaging

Run these commands from within the `extension/` directory:

### Install Dependencies
```bash
cd extension
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

The output archives will be generated in `extension/dist/`:
- `extension/dist/laterbox-chrome-extension.zip` (Chrome Web Store)
- `extension/dist/laterbox-safari-extension.zip` (Safari Web Extension)
- `extension/dist/laterbox-firefox-extension.zip` (Firefox Add-ons)

---

## Loading for Local Development

### Google Chrome
1. Navigate to `chrome://extensions`.
2. Enable **Developer mode** (top-right toggle).
3. Click **Load unpacked** and select `extension/dist/chromium`.

### Safari
1. Open **Safari Settings → Advanced** and enable **Show features for web developers**.
2. Go to **Develop → Allow Unsigned Extensions**.
3. In Safari Settings → Extensions, enable **laterbox**.

### Firefox
1. Navigate to `about:debugging#/runtime/this-firefox`.
2. Click **Load Temporary Add-on...** and select `extension/dist/firefox/manifest.json`.
