import type { BrowserCapabilities } from "./capabilities";

export const safariCapabilities: BrowserCapabilities = {
  supportsSidePanel: false,

  async openSidePanel() {
    // Safari has no equivalent WebExtension sidebar/side-panel API.
    throw new Error("Side panel is not available in Safari.");
  },

  isRestrictedUrl(url?: string): boolean {
    if (!url) return true;
    // Safari renders its own chrome as `safari-web-extension://`; keep the
    // older `safari-extension:` scheme guarded too for safety.
    return (
      url.startsWith("safari-extension:") ||
      url.startsWith("safari-web-extension:") ||
      url.startsWith("about:") ||
      url.startsWith("file:")
    );
  },
};