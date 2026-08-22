# laterbox Desktop & System Features

laterbox provides deep operating system integrations for desktop platforms (macOS, Windows, and Linux).

---

## 1. Global Quick Capture Hotkey
- Allows capturing URLs, text snippets, and notes instantly without switching away from your current application.
- Configurable in Settings (default hotkey: `Cmd+Shift+Space` or `Cmd+T`).
- Implemented via `hotkey_manager` and [`lib/core/desktop/desktop_actions.dart`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/lib/core/desktop/desktop_actions.dart).

---

## 2. Menu Bar & System Tray
- macOS menu bar icon with quick actions:
  - **Quick Capture**: Opens the floating capture window.
  - **Open laterbox**: Restores the primary inbox window.
  - **Preferences & Sync Status**.
- Implemented in [`lib/core/desktop/tray_service_io.dart`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/lib/core/desktop/tray_service_io.dart).

---

## 3. macOS Share Extension
- Integrated Share Extension (`macos/ShareExtension`) allows saving from Safari, Finder, and any native macOS app directly into laterbox.
- App Group container sharing (`group.pro.micorp.laterbox`) syncs shared items with the main application database seamlessly.

---

## 4. Window Behavior & State Persistence
- Remembers window dimensions, position, and active tab.
- Automatically handles backgrounding, minimizing to tray, and login launch behavior.
