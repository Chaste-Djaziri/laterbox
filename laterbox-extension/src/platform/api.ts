const globalApi = globalThis as typeof globalThis & { browser?: typeof chrome };

/**
 * Cross-browser WebExtension namespace normalized on promise-based APIs.
 *
 * Firefox exposes `browser.*` natively with Promises; Chromium exposes
 * `chrome.*` (also promise-based in MV3). Everything else in the extension
 * talks only to `browser.*`, so business logic never branches per browser.
 *
 * Types stay on the `chrome.*` namespace (a superset of what we use), so the
 * Firefox-specific surfaces (e.g. `sidebarAction`) are typed locally where
 * they are used.
 */
export const browser: typeof chrome = globalApi.browser ?? chrome;