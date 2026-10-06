import { browser } from "../platform/api";

export type TextSelector = {
  before: string;
  after: string;
};

export type PageContext = {
  url: string;
  title: string;
  selection: string;
  selector?: TextSelector | null;
  description?: string;
  previewImageUrl?: string;
  faviconUrl?: string;
  siteName?: string;
  os?: string;
};

export async function getPageContext(
  tabId: number,
  fallback: PageContext = { url: "", title: "", selection: "" },
): Promise<PageContext> {
  try {
    const results = await browser.scripting.executeScript({
      target: { tabId },
      func: readPageContext,
    });
    return results[0]?.result ?? fallback;
  } catch {
    return fallback;
  }
}

function readPageContext(): PageContext {
  const canonical = document.querySelector<HTMLLinkElement>(
    'link[rel="canonical"]',
  )?.href;
  const url = canonical && /^https?:\/\//i.test(canonical)
    ? canonical
    : window.location.href;
  const selection = window.getSelection();
  const selectedText = selection?.toString().trim() ?? "";
  let selector: TextSelector | null = null;
  if (selection && !selection.isCollapsed && selection.rangeCount > 0) {
    selector = selectionContext(selection.getRangeAt(0));
  }

  // Extract high-fidelity Open Graph / Twitter / Meta info from active DOM
  const ogTitle = document.querySelector<HTMLMetaElement>(
    'meta[property="og:title"], meta[name="twitter:title"]'
  )?.content?.trim();
  const title = ogTitle || document.title || "";

  const description = (
    document.querySelector<HTMLMetaElement>(
      'meta[property="og:description"], meta[name="description"], meta[name="twitter:description"]'
    )?.content || ""
  ).trim();

  const previewImageUrl = (
    document.querySelector<HTMLMetaElement>(
      'meta[property="og:image"], meta[property="og:image:url"], meta[name="twitter:image"], meta[name="twitter:image:src"], meta[itemprop="image"]'
    )?.content || ""
  ).trim();

  const siteName = (
    document.querySelector<HTMLMetaElement>(
      'meta[property="og:site_name"], meta[name="application-name"]'
    )?.content || ""
  ).trim();

  let faviconUrl = "";
  const iconLink = document.querySelector<HTMLLinkElement>(
    'link[rel="apple-touch-icon"], link[rel="icon"], link[rel="shortcut icon"]'
  );
  if (iconLink?.href) {
    faviconUrl = iconLink.href;
  } else {
    try {
      faviconUrl = new URL("/favicon.ico", window.location.origin).href;
    } catch {
      faviconUrl = "";
    }
  }

  const platform = (window.navigator as any).userAgentData?.platform || window.navigator.platform || "";
  let os = "Desktop";
  if (/Mac/i.test(platform) || /Macintosh/i.test(navigator.userAgent)) os = "macOS";
  else if (/Win/i.test(platform) || /Windows/i.test(navigator.userAgent)) os = "Windows";
  else if (/Linux/i.test(platform) || /Linux/i.test(navigator.userAgent)) os = "Linux";
  else if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) os = "iOS";
  else if (/Android/i.test(navigator.userAgent)) os = "Android";

  return {
    url,
    title,
    selection: selectedText,
    selector,
    description: description || undefined,
    previewImageUrl: previewImageUrl || undefined,
    faviconUrl: faviconUrl || undefined,
    siteName: siteName || undefined,
    os,
  };
}

// Surrounding text before and after the selection, used as the context anchor
// for a browser text fragment so the quote can be scrolled to and highlighted
// when reopened from LaterBox.
function selectionContext(range: Range, limit = 200): TextSelector | null {
  const selected = range.toString();
  if (!selected) return null;

  let element: HTMLElement | null = range.startContainer instanceof Element
    ? (range.startContainer as HTMLElement)
    : (range.startContainer.parentElement ?? null);

  for (let i = 0; element && i < 4; i++) {
    const text = element.textContent ?? "";
    const index = text.indexOf(selected);
    if (index !== -1) {
      return {
        before: text.slice(Math.max(0, index - limit), index).trim(),
        after: text
          .slice(index + selected.length, index + selected.length + limit)
          .trim(),
      };
    }
    element = element.parentElement;
  }
  return null;
}

export function buildScrollToTextFragment(
  baseUrl: string,
  exact: string,
  selector?: TextSelector | null
): string {
  const cleanUrl = baseUrl.split('#')[0];
  const exactClean = exact.trim();
  if (!exactClean) return baseUrl;

  const parts: string[] = [];

  // Prefix: grab the last few words before selection to anchor it accurately
  if (selector?.before) {
    const beforeWords = selector.before.trim().split(/\s+/);
    const prefix = beforeWords.slice(-4).join(' ').trim();
    if (prefix.length > 0) {
      parts.push(`${encodeURIComponent(prefix)}-,`);
    }
  }

  // Exact text or start,end range if long
  if (exactClean.length > 150) {
    const words = exactClean.split(/\s+/);
    const start = words.slice(0, 4).join(' ');
    const end = words.slice(-4).join(' ');
    parts.push(`${encodeURIComponent(start)},${encodeURIComponent(end)}`);
  } else {
    parts.push(encodeURIComponent(exactClean));
  }

  // Suffix: grab the first few words after selection to anchor it accurately
  if (selector?.after) {
    const afterWords = selector.after.trim().split(/\s+/);
    const suffix = afterWords.slice(0, 4).join(' ').trim();
    if (suffix.length > 0) {
      parts.push(`,-${encodeURIComponent(suffix)}`);
    }
  }

  return `${cleanUrl}#:~:text=${parts.join('')}`;
}
