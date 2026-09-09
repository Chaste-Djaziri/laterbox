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
- Shared links, selected text and webpage URLs are preserved together so browser selections become highlights instead of plain notes.

## 4. macOS Notch Companion
- On a MacBook with a camera notch, the idle panel matches the detected hardware notch and displays no branding, border or status content.
- Hovering briefly expands a native capture panel with haptic feedback. Copied links and meaningful text require explicit confirmation before they are saved.
- Successful clipboard, Watch Mode, drag, Services and Share Extension captures produce a receipt. The three latest receipts remain available for the current app session.
- Clipboard candidates are not persisted or uploaded until **Save** is selected. Failed direct captures remain available for retry.

## 5. macOS Services and Context Menus
- **Save to LaterBox** is registered as a macOS Service for URLs and selected text. It automatically classifies links, highlights and notes.
- Each app controls whether Services appear directly in its right click menu. When an app does not expose Services there, use **Services > Save to LaterBox** from its application menu or choose LaterBox from the macOS Share menu.

---

## 6. Window Behavior & State Persistence
- Remembers window dimensions, position, and active tab.
- Automatically handles backgrounding, minimizing to tray, and login launch behavior.
