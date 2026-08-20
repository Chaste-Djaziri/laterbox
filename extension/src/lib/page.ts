export type PageContext = {
  url: string;
  title: string;
  selection: string;
};

export async function getPageContext(
  tabId: number,
  fallback: PageContext = { url: "", title: "", selection: "" },
): Promise<PageContext> {
  try {
    const results = await chrome.scripting.executeScript({
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
  return {
    url,
    title: document.title,
    selection: window.getSelection()?.toString().trim() ?? "",
  };
}
