import type { BrowserCapabilities } from "./capabilities";

export const safariCapabilities: BrowserCapabilities = {
  supportsSidePanel: false,

  async openSidePanel() {
    // Safari has no equivalent WebExtension sidebar/side-panel API.
    return;
  },

  isRestrictedUrl(url?: string): boolean {
    return !url || !/^https?:\/\//i.test(url);
  },
};
