import { browser } from '../platform/api';
import type { Capture, CaptureKind } from '../types/capture';
export interface TextSelector { before: string; after: string; exact?: string }
export interface PageContext {
  url: string; title: string; selection: string; selector?: TextSelector | null;
  description?: string; previewImageUrl?: string; faviconUrl?: string; siteName?: string;
  os?: string; markdown?: string; author?: string; publishedAt?: string; canonicalUrl?: string; truncated?: boolean;
}
export async function getPageContext(tabId: number, fallback: PageContext = { url: '', title: '', selection: '' }): Promise<PageContext> {
  try {
    const results = await browser.scripting.executeScript({ target: { tabId }, func: extractRenderedPage });
    return results[0]?.result || fallback;
  } catch { return fallback; }
}

// Self-contained so scripting.executeScript can serialize it without module closures.
export function extractRenderedPage(rootSelector: string | null = null): PageContext {
  const absolute = (value: string | null) => {
    try { const u = new URL(value || '', location.href); return /^https?:$/.test(u.protocol) && value ? u.href : ''; } catch { return ''; }
  };
  const meta = (selector: string) => document.querySelector<HTMLMetaElement>(selector)?.content.trim() || '';
  const selection = window.getSelection();
  let selected = selection?.toString().trim() || '';
  let selector: TextSelector | null = null;
  const privateNode = selection?.anchorNode?.parentElement?.closest('input,textarea,select,[contenteditable="true"],form');
  if (privateNode) selected = '';
  if (selected && selection?.rangeCount) {
    const range = selection.getRangeAt(0);
    let element = range.commonAncestorContainer.nodeType === Node.ELEMENT_NODE ? range.commonAncestorContainer as Element : range.commonAncestorContainer.parentElement;
    for (let i=0; element && i<5; i++, element=element.parentElement) {
      const full = element.textContent || ''; const index = full.indexOf(selected);
      if (index >= 0) { selector = { exact: selected.slice(0,10000), before: full.slice(Math.max(0,index-300),index).trim(), after: full.slice(index+selected.length,index+selected.length+300).trim() }; break; }
    }
  }
  const root = rootSelector ? document.querySelector(rootSelector) : document.querySelector('article,[role="main"],main') || document.body;
  let visited = 0;
  const escape = (value: string) => value.replace(/([\\`*_\[\]<>])/g,'\\$1');
  const render = (node: Node, depth=0): string => {
    if (depth > 40 || ++visited > 15000) return '';
    if (node.nodeType === Node.TEXT_NODE) return escape((node.textContent || '').replace(/\s+/g,' '));
    if (!(node instanceof Element)) return '';
    const tag = node.tagName.toLowerCase();
    if (node.hasAttribute('data-laterbox-control') || node.closest('form,[contenteditable="true"]') || /^(script|style|noscript|nav|footer|header|form|input|textarea|select|button|svg|iframe)$/.test(tag)) return '';
    if (node.hasAttribute('hidden') || node.getAttribute('aria-hidden') === 'true' || getComputedStyle(node).display === 'none' || getComputedStyle(node).visibility === 'hidden') return '';
    if (tag === 'pre') return '\n\n```\n'+(node.textContent || '').replace(/```/g,'``\\`')+'\n```\n\n';
    if (tag === 'img') { const src = absolute(node.getAttribute('src')); return src ? `\n![${escape(node.getAttribute('alt') || '')}](${src.replace(/\(/g,'%28').replace(/\)/g,'%29')})\n` : ''; }
    const text = Array.from(node.childNodes).map(child => render(child,depth+1)).join('');
    if (/^h[1-6]$/.test(tag)) return '\n\n'+'#'.repeat(Number(tag[1]))+' '+text.trim()+'\n\n';
    if (tag === 'a') { const href = absolute(node.getAttribute('href')); return href ? `[${text.trim() || href}](${href.replace(/\(/g,'%28').replace(/\)/g,'%29')})` : text; }
    if (tag === 'strong' || tag === 'b') return `**${text}**`;
    if (tag === 'em' || tag === 'i') return `*${text}*`;
    if (tag === 'code') return '`'+text+'`';
    if (tag === 'blockquote') return '\n\n'+text.trim().split('\n').map(line=>'> '+line).join('\n')+'\n\n';
    if (tag === 'li') { const index = Array.from(node.parentElement?.children || []).indexOf(node)+1; return '\n'+(node.parentElement?.tagName === 'OL' ? index+'. ' : '- ')+text.trim(); }
    if (tag === 'br') return '\n';
    if (/^(p|div|section|article|ul|ol|figure)$/.test(tag)) return '\n\n'+text.trim()+'\n\n';
    return text;
  };
  let markdown = root ? render(root).replace(/\n[ \t]+/g,'\n').replace(/\n{3,}/g,'\n\n').trim() : '';
  const bytes = new TextEncoder().encode(markdown); const truncated = bytes.length > 204800 || visited > 15000;
  if (bytes.length > 204800) markdown = new TextDecoder().decode(bytes.slice(0,204800)).replace(/\uFFFD$/,'');
  return { url: location.href, title: meta('meta[property="og:title"]') || document.title,
    selection: selected.slice(0,10000), selector, markdown, truncated,
    canonicalUrl: absolute(document.querySelector('link[rel="canonical"]')?.getAttribute('href') || null) || location.href.split('#')[0],
    description: meta('meta[property="og:description"]') || meta('meta[name="description"]'),
    previewImageUrl: absolute(meta('meta[property="og:image"]') || meta('meta[name="twitter:image"]')),
    faviconUrl: absolute(document.querySelector('link[rel~="icon"]')?.getAttribute('href') || '/favicon.ico'),
    siteName: meta('meta[property="og:site_name"]') || location.hostname,
    author: meta('meta[name="author"]') || meta('meta[property="article:author"]'),
    publishedAt: meta('meta[property="article:published_time"]'),
    os: /Mac/i.test(navigator.platform) ? 'macOS' : /Win/i.test(navigator.platform) ? 'Windows' : 'Linux' };
}

export function buildScrollToTextFragment(baseUrl: string, exact: string, selector?: TextSelector | null): string {
  if (!exact.trim()) return baseUrl;
  // Preserve ordinary anchors; replace only an existing text directive.
  const base = baseUrl.split(':~:')[0];
  const encode = (value: string) => encodeURIComponent(value).replace(/[-!'()*]/g,c=>'%'+c.charCodeAt(0).toString(16).toUpperCase());
  const prefix = selector?.before.trim().split(/\s+/).slice(-4).join(' ');
  const suffix = selector?.after.trim().split(/\s+/).slice(0,4).join(' ');
  const words = exact.trim().split(/\s+/);
  const quote = exact.length > 150 && words.length > 8 ? encode(words.slice(0,4).join(' '))+','+encode(words.slice(-4).join(' ')) : encode(exact.trim());
  return base+(base.includes('#') ? ':~:text=' : '#:~:text=')+(prefix ? encode(prefix)+'-,' : '')+quote+(suffix ? ',-'+encode(suffix) : '');
}
export function captureFromPage(page: PageContext, kind: CaptureKind = 'page', exact = page.selection): Capture {
  const selector = exact ? { exact: exact.slice(0,10000), before: page.selector?.before || '', after: page.selector?.after || '' } : undefined;
  const url = kind === 'highlight' ? buildScrollToTextFragment(page.url,exact,selector) : page.url;
  if (url.length > 8192) throw new Error('The source URL is too long to save. Select a shorter quote.');
  return { ...page, url, kind, text: kind === 'highlight' ? exact.slice(0,10000) : undefined,
    selector: kind === 'highlight' ? selector : undefined, captureId: crypto.randomUUID(), source: 'browserExtension', createdAt: new Date().toISOString() };
}
