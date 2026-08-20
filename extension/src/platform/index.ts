import { chromiumCapabilities } from "./chromium";
import { firefoxCapabilities } from "./firefox";

export type { BrowserCapabilities } from "./capabilities";

const globalApi = globalThis as typeof globalThis & { browser?: unknown };

/** Capability implementation for the browser the extension is running in. */
export const browserCapabilities =
  typeof globalApi.browser !== "undefined"
    ? firefoxCapabilities
    : chromiumCapabilities;