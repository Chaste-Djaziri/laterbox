export interface GoogleSearchResult {
  root: Element;
  url: string;
  title: string;
  snippet?: string;
  insertionPoint: HTMLElement;
}

export function isGoogleSearch(pageUrl: string): boolean {
  try {
    const url = new URL(pageUrl);
    const host = url.hostname.toLowerCase();
    const isGoogle =
      host === "google.com" ||
      host === "www.google.com" ||
      host.endsWith(".google.com") ||
      /(^|\.)google\.[a-z]{2,3}(\.[a-z]{2})?$/.test(host);
    return (
      isGoogle &&
      (url.pathname === "/search" ||
        (url.pathname === "/" && url.searchParams.has("q")))
    );
  } catch {
    return false;
  }
}

export function extractGoogleTargetUrl(raw: string | null, baseUrl: string): string | null {
  if (!raw) return null;
  try {
    const parsed = new URL(raw, baseUrl);
    if (parsed.pathname === "/url") {
      const q = parsed.searchParams.get("q") || parsed.searchParams.get("url");
      if (q && /^https?:\/\//i.test(q)) {
        return q;
      }
    }
    if (/^https?:$/.test(parsed.protocol)) {
      const host = parsed.hostname.toLowerCase();
      if (
        host.includes("google.") ||
        host.includes("googleusercontent.com") ||
        host.includes("gstatic.com")
      ) {
        return null;
      }
      return parsed.href;
    }
  } catch {}
  return null;
}

export function findGoogleSearchResults(doc: Document, pageUrl: string): GoogleSearchResult[] {
  if (!isGoogleSearch(pageUrl)) return [];

  const results: GoogleSearchResult[] = [];
  const seenRoots = new Set<Element>();
  const seenUrls = new Set<string>();

  const headings = Array.from(doc.querySelectorAll("h3"));
  for (const h3 of headings) {
    if (h3.closest("[data-laterbox-control],[hidden],[aria-hidden=\"true\"]")) {
      continue;
    }

    const anchor =
      h3.closest<HTMLAnchorElement>("a") ||
      h3.querySelector<HTMLAnchorElement>("a") ||
      h3.parentElement?.closest<HTMLAnchorElement>("a");
    if (!anchor) continue;

    const targetUrl = extractGoogleTargetUrl(anchor.getAttribute("href"), pageUrl);
    if (!targetUrl || seenUrls.has(targetUrl)) continue;

    let root: Element | null =
      h3.closest(".g, [data-sokoban-container], .MjjYud, .hlcw0c, [data-hveid]") ||
      anchor.parentElement ||
      h3.parentElement;

    if (!root || seenRoots.has(root)) continue;

    const title = h3.textContent?.trim() || anchor.textContent?.trim() || "";
    if (!title) continue;

    const snippet =
      root.querySelector(".VwiC3b, [data-sncf], .yXK7lf")?.textContent?.trim() || "";

    const headerContainer =
      h3.closest<HTMLElement>(".yuRUbf, .tF2Cxc") || anchor;
    const insertionPoint = headerContainer;

    seenRoots.add(root);
    seenUrls.add(targetUrl);
    results.push({
      root,
      url: targetUrl,
      title,
      snippet,
      insertionPoint,
    });
  }

  return results;
}

export function createGoogleSearchControls(
  doc: Document,
  create: (
    result: GoogleSearchResult,
    resolve: () => GoogleSearchResult | undefined,
  ) => HTMLElement,
): (enabled: boolean, pageUrl: string) => void {
  const controls = new Map<Element, { result: GoogleSearchResult; container: HTMLElement }>();

  return (enabled: boolean, pageUrl: string) => {
    const results = enabled ? findGoogleSearchResults(doc, pageUrl) : [];

    for (const [root, record] of controls) {
      const match = results.find((r) => r.root === root);
      if (
        !match ||
        match.url !== record.result.url ||
        match.insertionPoint !== record.result.insertionPoint ||
        !record.container.isConnected
      ) {
        record.container.remove();
        controls.delete(root);
      }
    }

    for (const result of results) {
      let record = controls.get(result.root);
      if (!record) {
        const container = create(result, () =>
          findGoogleSearchResults(doc, doc.location.href).find(
            (current) => current.root === result.root && current.url === result.url,
          ),
        );
        record = { result, container };
        controls.set(result.root, record);
      }
      if (result.insertionPoint.nextElementSibling !== record.container) {
        result.insertionPoint.after(record.container);
      }
    }
  };
}
