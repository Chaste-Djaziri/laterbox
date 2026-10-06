import { browser } from "./api";
import type { BrowserCapabilities } from "./capabilities";

const SIDE_PANEL_PATH = "src/sidepanel/sidepanel.html";

// `sidebarAction` is a Firefox-only API absent from the Chromium typings.
const firefox = browser as unknown as {
  sidebarAction?: { open(): Promise<void> };
  runtime: { getURL(path: string): string };
};

export const firefoxCapabilities: BrowserCapabilities = {
  supportsSidePanel: true,

  async openSidePanel(): Promise<void> {
    if (typeof firefox.sidebarAction?.open === "function") {
      // Must run inside a user action handler (command, popup click).
      await firefox.sidebarAction.open();
      return;
    }
    await browser.tabs.create({ url: browser.runtime.getURL(SIDE_PANEL_PATH) });
  },

  isRestrictedUrl(url?: string): boolean {
    if (!url) return true;
    return (
      url.startsWith("about:") ||
      url.startsWith("moz-extension:") ||
      url.startsWith("view-source:") ||
      url.startsWith("resource:")
    );
  },
};