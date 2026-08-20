import { browser } from "../platform/api";

export interface TextSelector {
  exact: string;
  prefix?: string | null;
  suffix?: string | null;
}

type TextRange = {
  startNode: Text;
  startOffset: number;
  endNode: Text;
  endOffset: number;
};

/**
 * Locates a saved quote in the page at `tabId` and scrolls to it with the text
 * selected. Uses the surrounding `prefix`/`suffix` context to pick the right
 * occurrence when the same sentence appears more than once on the page.
 *
 * Runs as the browser-native-text-fragment fallback: the URL stays clean and
 * the DOM is searched after the page has loaded.
 */
export async function highlightTextInTab(
  tabId: number,
  selector: TextSelector,
): Promise<boolean> {
  const [{ result }] = await browser.scripting.executeScript({
    target: { tabId },
    args: [selector],
    func: locateAndSelect,
  });
  return result === true;
}

function locateAndSelect(selector: TextSelector): boolean {
  const exact = selector.exact.trim();
  if (!exact) return false;
  const prefix = selector.prefix?.trim() || null;
  const suffix = selector.suffix?.trim() || null;

  const nodes: Text[] = [];
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  let node: Node | null;
  while ((node = walker.nextNode())) {
    const textNode = node as Text;
    if (textNode.data) nodes.push(textNode);
  }
  if (nodes.length === 0) return false;

  const starts: number[] = [];
  const chunks: string[] = [];
  let offset = 0;
  for (const textNode of nodes) {
    starts.push(offset);
    chunks.push(textNode.data);
    offset += textNode.data.length;
  }
  const fullText = chunks.join("");

  const occurrences: number[] = [];
  let from = 0;
  let index = fullText.indexOf(exact, from);
  while (index !== -1) {
    occurrences.push(index);
    from = index + 1;
    index = fullText.indexOf(exact, from);
  }
  if (occurrences.length === 0) return false;

  let best = occurrences[0];
  let bestScore = -1;
  for (const occurrence of occurrences) {
    let score = 0;
    if (prefix) {
      const before = fullText.slice(
        Math.max(0, occurrence - prefix.length),
        occurrence,
      );
      if (before.endsWith(prefix)) score += 2;
    }
    if (suffix) {
      const after = fullText.slice(
        occurrence + exact.length,
        occurrence + exact.length + suffix.length,
      );
      if (after.startsWith(suffix)) score += 2;
    }
    if (score > bestScore) {
      bestScore = score;
      best = occurrence;
    }
  }

  const range = rangeForText(nodes, starts, best, best + exact.length);
  if (!range) return false;

  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);

  range.startContainer.parentElement?.scrollIntoView({
    behavior: "smooth",
    block: "center",
  });
  return true;
}

function rangeForText(
  nodes: Text[],
  starts: number[],
  startIndex: number,
  endIndex: number,
): Range | null {
  let startNode: Text | null = null;
  let startOffset = 0;
  let endNode: Text | null = null;
  let endOffset = 0;

  for (let i = 0; i < nodes.length; i++) {
    const nodeStart = starts[i];
    const nodeEnd = nodeStart + nodes[i].data.length;
    if (startNode === null && startIndex >= nodeStart && startIndex <= nodeEnd) {
      startNode = nodes[i];
      startOffset = startIndex - nodeStart;
    }
    if (endIndex >= nodeStart && endIndex <= nodeEnd) {
      endNode = nodes[i];
      endOffset = endIndex - nodeStart;
      break;
    }
  }

  if (startNode === null || endNode === null) return null;
  const range = document.createRange();
  range.setStart(startNode, startOffset);
  range.setEnd(endNode, endOffset);
  return range;
}