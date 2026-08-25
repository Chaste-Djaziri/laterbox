import { NextRequest, NextResponse } from 'next/server';

const MAX_HTML_BYTES = 1_500_000;
const FETCH_TIMEOUT_MS = 8_000;
const USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

function decodeHtmlEntities(value: string): string {
  return value
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&apos;/gi, "'")
    .replace(/&#0*39;/gi, "'")
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&#(\d+);/g, (_, digits: string) => String.fromCodePoint(Number(digits)))
    .replace(/&#x([0-9a-f]+);/gi, (_, hex: string) => String.fromCodePoint(parseInt(hex, 16)));
}

function extractMeta(html: string, key: string): string | null {
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  
  // 1. <meta property="key" content="..."> or <meta name="key" content="...">
  const pattern = new RegExp(`<meta[^>]+(?:name|property|itemprop)=["']${escaped}["'][^>]*>`, 'gi');
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(html)) !== null) {
    const content = match[0].match(/content=["']([\s\S]*?)["']/i);
    if (content?.[1]) {
      const value = decodeHtmlEntities(content[1]).replace(/\s+/g, ' ').trim();
      if (value.length > 0) return value;
    }
  }

  // 2. Reversed <meta content="..." property="key">
  const revPattern = new RegExp(
    `<meta[^>]+content=["']([^"']+)["'][^>]+(?:name|property|itemprop)=["']${escaped}["'][^>]*>`,
    'i'
  );
  const revMatch = html.match(revPattern);
  if (revMatch?.[1]) {
    const value = decodeHtmlEntities(revMatch[1]).replace(/\s+/g, ' ').trim();
    if (value.length > 0) return value;
  }

  return null;
}

function extractTitle(html: string): string | null {
  const match = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  if (!match) return null;
  const title = decodeHtmlEntities(match[1]).replace(/\s+/g, ' ').trim();
  return title.length === 0 ? null : title;
}

function extractFavicon(html: string, baseUrl: string): string | null {
  const pattern = /<link[^>]+rel=["'][^"']*icon[^"']*["'][^>]*>/gi;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(html)) !== null) {
    const href = match[0].match(/href=["']([^"']*)["']/i)?.[1];
    if (href) {
      const clean = decodeHtmlEntities(href).trim();
      if (clean) {
        try {
          return new URL(clean, baseUrl).toString();
        } catch {
          // Ignore invalid URL
        }
      }
    }
  }
  try {
    return new URL('/favicon.ico', baseUrl).toString();
  } catch {
    return null;
  }
}

function resolveAbsoluteUrl(value: string | null, base: string): string | null {
  if (!value) return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  try {
    const resolved = new URL(trimmed, base).toString();
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return resolved;
    }
  } catch {
    // Ignore invalid URL
  }
  return null;
}

function classifyUrl(url: URL, ogType: string | null): string {
  const host = url.hostname.toLowerCase().replace(/^www\./, '');
  const path = url.pathname.toLowerCase();

  if (host.includes('youtube.com') || host === 'youtu.be' || host.includes('vimeo.com') || (ogType && ogType.startsWith('video'))) {
    return 'video';
  }
  if (host.includes('spotify.com') || host.includes('soundcloud.com') || (ogType && ogType.startsWith('music'))) {
    return 'music';
  }
  if (host === 'github.com' || host === 'gitlab.com') {
    return 'repository';
  }
  if (ogType === 'article' || path.includes('/blog/') || path.includes('/post/') || path.includes('/article/')) {
    return 'article';
  }
  return 'link';
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const rawUrl = typeof body?.url === 'string' ? body.url.trim() : '';

    if (!rawUrl || !/^https?:\/\//i.test(rawUrl)) {
      return NextResponse.json({ error: 'Valid http/https URL required' }, { status: 400 });
    }

    const target = new URL(rawUrl);
    const domain = target.hostname.replace(/^www\./i, '');

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    let html = '';
    let finalUrl = target.toString();

    try {
      const response = await fetch(target, {
        signal: controller.signal,
        headers: {
          'user-agent': USER_AGENT,
          accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
          'accept-language': 'en-US,en;q=0.9',
          'sec-ch-ua': '"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"',
          'sec-ch-ua-mobile': '?0',
          'sec-fetch-dest': 'document',
          'sec-fetch-mode': 'navigate',
          'sec-fetch-site': 'none',
        },
      });

      clearTimeout(timer);

      if (response.ok) {
        finalUrl = response.url || target.toString();
        const text = await response.text();
        html = text.slice(0, MAX_HTML_BYTES);
      }
    } catch {
      clearTimeout(timer);
    }

    const finalUri = new URL(finalUrl);
    const title =
      extractMeta(html, 'og:title') ||
      extractMeta(html, 'twitter:title') ||
      extractTitle(html) ||
      domain;

    const description =
      extractMeta(html, 'og:description') ||
      extractMeta(html, 'twitter:description') ||
      extractMeta(html, 'description') ||
      null;

    const rawImage =
      extractMeta(html, 'og:image') ||
      extractMeta(html, 'og:image:url') ||
      extractMeta(html, 'twitter:image') ||
      extractMeta(html, 'twitter:image:src');

    const previewImageUrl = resolveAbsoluteUrl(rawImage, finalUrl);
    const siteName = extractMeta(html, 'og:site_name') || extractMeta(html, 'application-name') || domain;
    const faviconUrl = extractFavicon(html, finalUrl) || `https://www.google.com/s2/favicons?domain=${domain}&sz=128`;
    const ogType = extractMeta(html, 'og:type');
    const contentType = classifyUrl(finalUri, ogType);

    const result = {
      domain,
      siteName,
      site_name: siteName,
      title,
      description,
      faviconUrl,
      favicon_url: faviconUrl,
      previewImageUrl,
      preview_image_url: previewImageUrl,
      classification: {
        contentType,
        type: contentType,
        content_type: contentType,
        confidence: 0.9,
        source: 'htmlMeta',
      },
    };

    return NextResponse.json(result, { status: 200 });
  } catch (error) {
    console.error('[API/Enrich] error:', error);
    return NextResponse.json({ error: 'Internal enrich error' }, { status: 500 });
  }
}
