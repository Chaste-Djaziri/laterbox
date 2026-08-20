import type { BrowserCapabilities } from "./capabilities";

export const chromiumCapabilities: BrowserCapabilities = {
  supportsSidePanel: typeof chrome.sidePanel?.open === "function",

  async openSidePanel(): Promise<void> {
    const [tab] = await chrome.tabs.query({
      active: true,
      lastFocusedWindow: true,
    });
    if (tab?.windowId === undefined) throw new Error("No active browser window.");

    try {
      if (chrome.sidePanel?.setOptions && chrome.sidePanel?.open) {
        await chrome.sidePanel.setOptions({
          path: "src/sidepanel/sidepanel.html",
          enabled: true,
        });
        await chrome.sidePanel.open({ windowId: tab.windowId });
        return;
      }
    } catch (error) {
      console.warn("Native side panel unavailable", error);
    }

    await chrome.tabs.create({
      url: chrome.runtime.getURL("src/sidepanel/sidepanel.html"),
    });
  },

  isRestrictedUrl(url?: string): boolean {
    return !url || !/^https?:\/\//i.test(url);
  },
};
