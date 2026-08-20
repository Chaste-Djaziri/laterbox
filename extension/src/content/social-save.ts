const BUTTON_CLASS = "laterbox-post-save";

const POST_SELECTORS = [
  "article",
  '[data-testid="tweet"]',
  '[data-testid="feedItem"]',
  '[data-e2e="recommend-list-item-container"]',
  '[data-e2e="browse-video"]',
  "ytd-rich-item-renderer",
  "ytd-video-renderer",
  "ytd-reel-item-renderer",
  "shreddit-post",
  '[role="article"]',
  '[data-test-id="pin"]',
];

scanPosts();
new MutationObserver(scanPosts).observe(document.documentElement, {
  childList: true,
  subtree: true,
});
window.setInterval(scanPosts, 1500);

function scanPosts(): void {
  const seen = new Set<Element>();
  for (const selector of POST_SELECTORS) {
    for (const post of document.querySelectorAll(selector)) {
      if (seen.has(post)) continue;
      seen.add(post);
      addSaveControl(post);
    }
  }
}

function addSaveControl(post: Element): void {
  if (post.querySelector(`.${BUTTON_CLASS}`)) return;
  const url = permalinkFor(post);
  const instagramMoreButton = findInstagramMoreButton(post);
  const instagramOverlay =
      isInstagramMediaPost(post) && instagramMoreButton === null;
  const actionBar = instagramMoreButton?.parentElement ??
      (instagramOverlay ? post : findActionBar(post));
  if (!url || !actionBar) return;

  const button = document.createElement("button");
  button.className = BUTTON_CLASS;
  button.type = "button";
  button.textContent = "LaterBox";
  button.title = "Save this post to LaterBox";
  button.setAttribute("aria-label", "Save this post to LaterBox");
  button.style.cssText = [
    "display: inline-flex",
    "align-items: center",
    "justify-content: center",
    "min-width: 58px",
    "margin: 0 4px",
    "padding: 4px 8px",
    "border: 1px solid rgba(23, 23, 17, .2)",
    "border-radius: 999px",
    "background: #e7ff57",
    "box-shadow: 0 2px 8px rgba(23, 23, 17, .12)",
    "color: #171711",
    "cursor: pointer",
    "font: 700 11px/1 system-ui, sans-serif",
    "vertical-align: middle",
    ...(instagramOverlay
      ? [
          "position: absolute",
          "top: 12px",
          "right: 12px",
          "z-index: 10",
        ]
      : []),
  ].join(";");

  if (
    instagramOverlay &&
    post instanceof HTMLElement &&
    getComputedStyle(post).position === "static"
  ) {
    post.style.position = "relative";
  }

  button.addEventListener("click", async (event) => {
    event.preventDefault();
    event.stopPropagation();
    button.disabled = true;
    button.textContent = "Saving";
    const result = await chrome.runtime.sendMessage({
      type: "save-page",
      url,
      title: document.title,
    });
    if (result?.status === "saved") {
      button.textContent = "Saved ✓";
      window.setTimeout(() => button.remove(), 1200);
    } else if (result?.status === "needsAuth") {
      button.disabled = false;
      button.textContent = "Connect";
    } else {
      button.disabled = false;
      button.textContent = "Queued";
    }
  });

  if (instagramMoreButton instanceof HTMLElement) {
    instagramMoreButton.insertAdjacentElement("afterend", button);
  } else {
    actionBar.append(button);
  }
}

function isInstagramMediaPost(post: Element): boolean {
  return window.location.hostname.replace(/^www\./, "") === "instagram.com" &&
      post.querySelector("img, video") !== null;
}

function findInstagramMoreButton(post: Element): Element | null {
  if (window.location.hostname.replace(/^www\./, "") !== "instagram.com") {
    return null;
  }
  return post.querySelector(
    'button[aria-label*="More"], button[aria-label*="more"], [role="button"][aria-label*="More"], [role="button"][aria-label*="more"]',
  );
}

function findActionBar(post: Element): Element | null {
  const candidates = [
    '[role="group"]',
    '[data-testid*="action"]',
    '[data-e2e*="action"]',
    '[id="menu"]',
    "footer",
  ];
  for (const selector of candidates) {
    const candidate = post.querySelector(selector);
    if (candidate && candidate.querySelector("button, [role=button]")) {
      return candidate;
    }
  }

  const action = post.querySelector(
    'button, [role="button"], [aria-label*="Like"], [aria-label*="like"]',
  );
  if (action?.parentElement && action.parentElement !== post) {
    return action.parentElement;
  }
  return null;
}

function permalinkFor(post: Element): string | null {
  const links = Array.from(post.querySelectorAll<HTMLAnchorElement>("a[href]"));
  for (const link of links) {
    try {
      const url = new URL(link.href);
      if (isPostUrl(url)) return url.toString();
    } catch {
      // Ignore malformed or placeholder links.
    }
  }
  return isPostUrl(new URL(window.location.href)) ? window.location.href : null;
}

function isPostUrl(url: URL): boolean {
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
}
