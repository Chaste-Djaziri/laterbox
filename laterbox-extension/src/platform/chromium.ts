import { browser } from "./api";
import type { BrowserCapabilities } from "./capabilities";

const SIDE_PANEL_PATH = "src/sidepanel/sidepanel.html";

// Track the focused window so `sidePanel.open({ windowId })` can run with no
// preceding await. Awaiting unrelated browser.* calls between a command gesture
// and `sidePanel.open()` can invalidate the gesture ("may only be called in
// response to a user gesture").
let lastFocusedWindowId: number | undefined;

browser.windows.onFocusChanged.addListener((windowId) => {
  if (windowId !== browser.windows.WINDOW_ID_NONE) {
    lastFocusedWindowId = windowId;
  }
});
browser.tabs.onActivated.addListener(({ windowId }) => {
  lastFocusedWindowId = windowId;
});
void browser.windows.getLastFocused({ windowTypes: ["normal"] }).then((window) => {
  if (window?.id !== undefined) lastFocusedWindowId = window.id;
});

export const chromiumCapabilities: BrowserCapabilities = {
  supportsSidePanel: typeof browser.sidePanel?.open === "function",

  async openSidePanel(): Promise<void> {
    if (!browser.sidePanel?.open) {
      await browser.tabs.create({ url: browser.runtime.getURL(SIDE_PANEL_PATH) });
      return;
    }

    const windowId =
      lastFocusedWindowId ?? (await browser.windows.getLastFocused()).id;
    if (windowId === undefined) throw new Error("No active browser window.");

    // The manifest declares side_panel.default_path, so no setOptions call is
    // needed. Opening the global panel with windowId keeps it following the
    // active tab. If the browser rejects the gesture the error propagates so
    // the underlying limitation stays visible instead of silently opening a tab.
    await browser.sidePanel.open({ windowId });
  },

  isRestrictedUrl(url?: string): boolean {
    return !url || !/^https?:\/\//i.test(url);
  },
};