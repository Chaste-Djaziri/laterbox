import type { BrowserCapabilities } from "./capabilities";

const SIDE_PANEL_PATH = "src/sidepanel/sidepanel.html";

// Track the focused window so `sidePanel.open({ windowId })` can run with no
// preceding await. Awaiting unrelated chrome.* calls between a command gesture
// and `sidePanel.open()` can invalidate the gesture ("may only be called in
// response to a user gesture").
let lastFocusedWindowId: number | undefined;

chrome.windows.onFocusChanged.addListener((windowId) => {
  if (windowId !== chrome.windows.WINDOW_ID_NONE) {
    lastFocusedWindowId = windowId;
  }
});
chrome.tabs.onActivated.addListener(({ windowId }) => {
  lastFocusedWindowId = windowId;
});
void chrome.windows.getLastFocused({ windowTypes: ["normal"] }).then((window) => {
  if (window?.id !== undefined) lastFocusedWindowId = window.id;
});

export const chromiumCapabilities: BrowserCapabilities = {
  supportsSidePanel: typeof chrome.sidePanel?.open === "function",

  async openSidePanel(): Promise<void> {
    if (!chrome.sidePanel?.open) {
      await chrome.tabs.create({ url: chrome.runtime.getURL(SIDE_PANEL_PATH) });
      return;
    }

    const windowId =
      lastFocusedWindowId ?? (await chrome.windows.getLastFocused()).id;
    if (windowId === undefined) throw new Error("No active browser window.");

    // The manifest declares side_panel.default_path, so no setOptions call is
    // needed. Opening the global panel with windowId keeps it following the
    // active tab. If the browser rejects the gesture the error propagates so
    // the underlying limitation stays visible instead of silently opening a tab.
    await chrome.sidePanel.open({ windowId });
  },

  isRestrictedUrl(url?: string): boolean {
    return !url || !/^https?:\/\//i.test(url);
  },
};
