import { chromiumCapabilities } from "./chromium";
import { firefoxCapabilities } from "./firefox";
import { safariCapabilities } from "./safari";

export type { BrowserCapabilities } from "./capabilities";

// Detect APIs rather than browser names: Safari also exposes browser.*.
export const browserCapabilities = chromiumCapabilities.supportsSidePanel
  ? chromiumCapabilities
  : firefoxCapabilities.supportsSidePanel
    ? firefoxCapabilities
    : safariCapabilities;
