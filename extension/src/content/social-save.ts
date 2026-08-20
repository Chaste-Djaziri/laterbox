const BUTTON_ID = "laterbox-social-save";

let button: HTMLButtonElement | null = null;

syncButton();
window.setInterval(syncButton, 1000);

function syncButton(): void {
  if (isSaveableContentUrl(window.location.href)) {
    if (button === null) button = createButton();
    return;
  }
  button?.remove();
  button = null;
}

function createButton(): HTMLButtonElement {
  const existing = document.getElementById(BUTTON_ID);
  if (existing instanceof HTMLButtonElement) return existing;

  const next = document.createElement("button");
  next.id = BUTTON_ID;
  next.type = "button";
  next.textContent = "Save to LaterBox";
  next.setAttribute("aria-label", "Save this post to LaterBox");
  next.style.cssText = [
    "position: fixed",
    "right: 20px",
    "bottom: 20px",
    "z-index: 2147483647",
    "padding: 12px 16px",
    "border: 1px solid rgba(23, 23, 17, .14)",
    "border-radius: 999px",
    "background: #e7ff57",
    "box-shadow: 0 8px 24px rgba(23, 23, 17, .2)",
    "color: #171711",
    "cursor: pointer",
    "font: 700 13px/1 system-ui, sans-serif",
  ].join(";");

  next.addEventListener("click", async () => {
    next.disabled = true;
    next.textContent = "Saving...";
    const result = await chrome.runtime.sendMessage({
      type: "save-page",
      url: window.location.href,
      title: document.title,
    });
    if (result?.status === "saved") {
      next.textContent = "Saved ✓";
      window.setTimeout(() => next.remove(), 1200);
    } else if (result?.status === "needsAuth") {
      next.disabled = false;
      next.textContent = "Connect in LaterBox";
    } else {
      next.disabled = false;
      next.textContent = "Queued offline";
    }
  });

  document.documentElement.appendChild(next);
  return next;
}

function isSaveableContentUrl(value: string): boolean {
  try {
    const url = new URL(value);
    const host = url.hostname.replace(/^www\./, "");
    const path = url.pathname;
    return [
      /^(instagram\.com)\/(p|reel|reels|tv)\//,
      /^(threads\.net|threads\.com)\/@[^/]+\/post\//,
      /^(x\.com|twitter\.com)\/[^/]+\/status\/\d+/,
      /^bsky\.app\/profile\/[^/]+\/post\//,
      /^tiktok\.com\/@[^/]+\/(video|photo)\//,
      /^youtube\.com\/(watch|shorts|live)(\/|$)/,
      /^youtu\.be\/[^/]+/,
      /^reddit\.com\/r\/[^/]+\/comments\//,
      /^(linkedin\.com)\/(posts|feed\/update)\//,
      /^facebook\.com\/.+\/(posts|reel|videos)\//,
      /^pinterest\.com\/pin\/\d+/,
    ].some((pattern) => pattern.test(`${host}${path}`));
  } catch {
    return false;
  }
}
