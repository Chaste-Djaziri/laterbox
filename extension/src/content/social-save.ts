const BUTTON_CLASS = "laterbox-post-save";
const instagramButtons = new Map<Element, HTMLButtonElement>();

const POST_SELECTORS = [
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
  "article",
];

scanPosts();
new MutationObserver(scanPosts).observe(document.documentElement, {
  childList: true,
  subtree: true,
});
window.setInterval(scanPosts, 1000);
window.addEventListener("scroll", updateInstagramButtons, { passive: true });
window.addEventListener("resize", updateInstagramButtons);

function scanPosts(): void {
  if (isInstagram()) {
    scanInstagramMedia();
    return;
  }

  const seen = new Set<Element>();
  for (const selector of POST_SELECTORS) {
    for (const post of document.querySelectorAll(selector)) {
      if (seen.has(post)) continue;
      seen.add(post);
      addPostButton(post);
    }
  }
}

function scanInstagramMedia(): void {
  for (const media of document.querySelectorAll("img, video")) {
    const post = media.closest("article");
    if (!post) continue;
    const bounds = media.getBoundingClientRect();
    if (bounds.width < 240 || bounds.height < 180) continue;
    if (bounds.bottom <= 0 || bounds.top >= window.innerHeight) continue;
    if (!instagramButtons.has(post)) addInstagramButton(post, media);
    positionInstagramButton(post, media);
  }
}

function addInstagramButton(post: Element, media: Element): void {
  const button = document.createElement("button");
  button.className = BUTTON_CLASS;
  button.type = "button";
  button.textContent = "LaterBox";
  button.title = "Save this Instagram post to LaterBox";
  button.setAttribute("aria-label", "Save this Instagram post to LaterBox");
  button.style.cssText = [
    "position: fixed",
    "z-index: 2147483647",
    "display: block",
    "padding: 6px 10px",
    "border: 1px solid rgba(23, 23, 17, .2)",
    "border-radius: 999px",
    "background: #e7ff57",
    "box-shadow: 0 4px 14px rgba(23, 23, 17, .24)",
    "color: #171711",
    "cursor: pointer",
    "font: 700 11px/1 system-ui, sans-serif",
    "opacity: 1",
    "pointer-events: auto",
  ].join(";");

  button.addEventListener("click", async (event) => {
    event.preventDefault();
    event.stopPropagation();
    button.disabled = true;
    button.textContent = "Saving";
    const result = await sendSave(permalinkFor(post) ?? window.location.href);
    applyResult(button, result, () => {
      instagramButtons.delete(post);
    });
  });

  document.documentElement.append(button);
  instagramButtons.set(post, button);
}

function positionInstagramButton(post: Element, media: Element): void {
  const button = instagramButtons.get(post);
  if (!button) return;
  const bounds = media.getBoundingClientRect();
  button.style.left = `${Math.max(8, bounds.right - button.offsetWidth - 12)}px`;
  button.style.top = `${Math.max(8, bounds.top + 12)}px`;
}

function updateInstagramButtons(): void {
  for (const post of instagramButtons.keys()) {
    const media = post.querySelector("img, video");
    if (media) positionInstagramButton(post, media);
  }
}

function addPostButton(post: Element): void {
  if (post.querySelector(`.${BUTTON_CLASS}`)) return;
  const url = permalinkFor(post);
  const actionBar = findActionBar(post);
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
  ].join(";");
  button.addEventListener("click", async (event) => {
    event.preventDefault();
    event.stopPropagation();
    button.disabled = true;
    button.textContent = "Saving";
    const result = await sendSave(url);
    applyResult(button, result);
  });
  actionBar.append(button);
}

function findActionBar(post: Element): Element | null {
  for (const selector of [
    '[role="group"]',
    '[data-testid*="action"]',
    '[data-e2e*="action"]',
    '[id="menu"]',
    "footer",
  ]) {
    const candidate = post.querySelector(selector);
    if (candidate && candidate.querySelector("button, [role=button]")) {
      return candidate;
    }
  }
  const action = post.querySelector(
    'button, [role="button"], [aria-label*="Like"], [aria-label*="like"]',
  );
  return action?.parentElement && action.parentElement !== post
      ? action.parentElement
      : null;
}

async function sendSave(url: string) {
  return chrome.runtime.sendMessage({
    type: "save-page",
    url,
    title: document.title,
  });
}

function applyResult(
  button: HTMLButtonElement,
  result: { status?: string },
  onSaved?: () => void,
): void {
  if (result?.status === "saved") {
    button.textContent = "Saved ✓";
    window.setTimeout(() => {
      onSaved?.();
      button.remove();
    }, 1200);
  } else if (result?.status === "needsAuth") {
    button.disabled = false;
    button.textContent = "Connect";
  } else {
    button.disabled = false;
    button.textContent = "Queued";
  }
}

function permalinkFor(post: Element): string | null {
  for (const link of post.querySelectorAll<HTMLAnchorElement>("a[href]")) {
    try {
      const url = new URL(link.href);
      if (isPostUrl(url)) return url.toString();
    } catch {
      // Ignore malformed links.
    }
  }
  return isPostUrl(new URL(window.location.href)) ? window.location.href : null;
}

function isInstagram(): boolean {
  return window.location.hostname.replace(/^www\./, "") === "instagram.com";
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
