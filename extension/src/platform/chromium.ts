import type { BrowserCapabilities } from "./capabilities";

export const chromiumCapabilities: BrowserCapabilities = {
  supportsSidePanel: typeof chrome.sidePanel?.open === "function",

  async openSidePanel(tabId: number): Promise<void> {
    try {
      if (chrome.sidePanel?.setOptions && chrome.sidePanel?.open) {
        await chrome.sidePanel.setOptions({
          tabId,
          path: "src/sidepanel/sidepanel.html",
          enabled: true,
        });
        await chrome.sidePanel.open({ tabId });
        return;
      }
    } catch (error) {
      console.warn("Native side panel unavailable", error);
    }

    await chrome.tabs.create({
      url: `${chrome.runtime.getURL("src/sidepanel/sidepanel.html")}?tabId=${tabId}`,
    });
  },

  isRestrictedUrl(url?: string): boolean {
    return !url || !/^https?:\/\//i.test(url);
  },
};
