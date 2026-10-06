import { chromiumCapabilities } from "./chromium";
import { firefoxCapabilities } from "./firefox";
import { safariCapabilities } from "./safari";

export type { BrowserCapabilities } from "./capabilities";

const globalApi = globalThis as typeof globalThis & {
  browser?: unknown;
  safari?: unknown;
};

/** Capability implementation for the browser the extension is running in. */
export const browserCapabilities =
  typeof globalApi.safari !== "undefined"
    ? safariCapabilities
    : typeof globalApi.browser !== "undefined"
      ? firefoxCapabilities
      : chromiumCapabilities;