import type { BrowserCapabilities } from "./capabilities";

const SIDE_PANEL_PATH = "src/sidepanel/sidepanel.html";

export const chromiumCapabilities: BrowserCapabilities = {
  supportsSidePanel: typeof chrome.sidePanel?.open === "function",

  async openSidePanel(): Promise<void> {
    const [tab] = await chrome.tabs.query({
      active: true,
      lastFocusedWindow: true,
    });
    if (tab?.windowId === undefined) throw new Error("No active browser window.");

    // Real Chrome and Chromium with the Side Panel API. The panel is global
    // (window-scoped) and follows the active tab on its own. If the API exists
    // but throws, the error propagates instead of silently opening a tab so the
    // underlying failure is visible rather than masked.
    if (chrome.sidePanel?.open) {
      await chrome.sidePanel.setOptions({
        path: SIDE_PANEL_PATH,
        enabled: true,
      });
      await chrome.sidePanel.open({ windowId: tab.windowId });
      return;
    }

    // Only browsers genuinely lacking the Side Panel API (for example an
    // unsupported Arc configuration) fall back to an extension tab.
    await chrome.tabs.create({ url: chrome.runtime.getURL(SIDE_PANEL_PATH) });
  },

  isRestrictedUrl(url?: string): boolean {
    return !url || !/^https?:\/\//i.test(url);
  },
};
