import { NextRequest, NextResponse } from 'next/server';
import { extractArticleContent } from '@/lib/reader/articleExtractor';

const MAX_HTML_BYTES = 1_500_000;
const FETCH_TIMEOUT_MS = 10_000;

// Rotate user agents to improve success rate across different sites
const USER_AGENTS = [
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
  'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
  'Twitterbot/1.0',
];

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

function extractKeywords(html: string): string[] {
  const raw: string[] = [];

  // <meta name="keywords" content="...">
  const kwMeta = extractMeta(html, 'keywords');
  if (kwMeta) {
    raw.push(...kwMeta.split(/[,;|]/).map((k) => k.trim()).filter(Boolean));
  }

  // article:tag
  const tagPattern = /<meta[^>]+(?:property|name)=["']article:tag["'][^>]*>/gi;
  let tm: RegExpExecArray | null;
  while ((tm = tagPattern.exec(html)) !== null) {
    const c = tm[0].match(/content=["']([^"']+)["']/i)?.[1];
    if (c) raw.push(decodeHtmlEntities(c).trim());
  }

  // og:tag (some CMSes)
  const ogTag = extractMeta(html, 'og:tag');
  if (ogTag) raw.push(...ogTag.split(/[,;|]/).map((k) => k.trim()).filter(Boolean));

  // Deduplicate, lowercase, trim, max 8 tags
  const seen = new Set<string>();
  return raw
    .map((k) => k.toLowerCase().replace(/[#_]/g, ' ').trim())
    .filter((k) => k.length > 1 && k.length < 40)
    .filter((k) => {
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    })
    .slice(0, 8);
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
  if (host.includes('spotify.com') || host.includes('soundcloud.com') || host.includes('lyricarw.com') || (ogType && ogType.startsWith('music'))) {
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

interface EmbedInfo {
  embedProvider: string;
  embedUrl: string;
  embedHeight: number;
}

function detectEmbed(rawUrl: string): EmbedInfo | null {
  try {
    const url = new URL(rawUrl);
    const host = url.hostname.toLowerCase().replace(/^www\./, '');
    const path = url.pathname;

    // YouTube
    const ytMatch = rawUrl.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\\w-]{11})/);
    if (ytMatch?.[1]) {
      return {
        embedProvider: 'YouTube',
        embedUrl: `https://www.youtube-nocookie.com/embed/${ytMatch[1]}?autoplay=0&rel=0`,
        embedHeight: 315,
      };
    }

    // Vimeo
    const vimeoMatch = rawUrl.match(/vimeo\.com\/(?:video\/)?(\d+)/);
    if (vimeoMatch?.[1]) {
      return {
        embedProvider: 'Vimeo',
        embedUrl: `https://player.vimeo.com/video/${vimeoMatch[1]}`,
        embedHeight: 315,
      };
    }

    // Spotify
    const spotifyMatch = rawUrl.match(/open\.spotify\.com\/(track|album|playlist|episode|show)\/([a-zA-Z0-9]+)/);
    if (spotifyMatch) {
      const type = spotifyMatch[1];
      const id = spotifyMatch[2];
      return {
        embedProvider: 'Spotify',
        embedUrl: `https://open.spotify.com/embed/${type}/${id}?utm_source=generator`,
        embedHeight: type === 'track' ? 152 : 352,
      };
    }

    // SoundCloud
    if (host.includes('soundcloud.com') && path.length > 3 && path.includes('/')) {
      const encoded = encodeURIComponent(rawUrl);
      return {
        embedProvider: 'SoundCloud',
        embedUrl: `https://w.soundcloud.com/player/?url=${encoded}&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true`,
        embedHeight: 166,
      };
    }

    // Lyrica
    const lyricaMatch = rawUrl.match(/lyricarw\.com\/(?:embed\/song|songs)\/([a-zA-Z0-9_-]+)/);
    if (lyricaMatch?.[1]) {
      return {
        embedProvider: 'Lyrica',
        embedUrl: `https://lyricarw.com/embed/song/${lyricaMatch[1]}`,
        embedHeight: 152,
      };
    }
  } catch {
    // ignore
  }
  return null;
}

interface OEmbedData {
  title?: string;
  author_name?: string;
  thumbnail_url?: string;
  provider_name?: string;
  description?: string;
}

async function fetchOEmbed(rawUrl: string, host: string): Promise<OEmbedData | null> {
  try {
    let oembedEndpoint = '';
    if (host.includes('youtube.com') || host === 'youtu.be') {
      oembedEndpoint = `https://www.youtube.com/oembed?url=${encodeURIComponent(rawUrl)}&format=json`;
    } else if (host.includes('vimeo.com')) {
      oembedEndpoint = `https://vimeo.com/api/oembed.json?url=${encodeURIComponent(rawUrl)}`;
    } else if (host.includes('spotify.com')) {
      oembedEndpoint = `https://open.spotify.com/oembed?url=${encodeURIComponent(rawUrl)}`;
    } else if (host.includes('soundcloud.com')) {
      oembedEndpoint = `https://soundcloud.com/oembed?url=${encodeURIComponent(rawUrl)}&format=json`;
    }
    if (!oembedEndpoint) return null;
    const res = await fetch(oembedEndpoint, { signal: AbortSignal.timeout(6000) });
    if (!res.ok) return null;
    return (await res.json()) as OEmbedData;
  } catch {
    return null;
  }
}

function isGenericTitle(t: string | null | undefined): boolean {
  if (!t) return true;
  const l = t.trim().toLowerCase();
  return (
    l.length === 0 ||
    l === 'youtube' ||
    l.includes('video playlist') ||
    l === 'untitled' ||
    l.startsWith('http://') ||
    l.startsWith('https://') ||
    l === 'watch' ||
    l === 'before you continue to youtube'
  );
}

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const rawUrl = typeof body?.url === 'string' ? body.url.trim() : '';

    if (!rawUrl || !/^https?:\/\//i.test(rawUrl)) {
      return NextResponse.json({ error: 'Valid http/https URL required' }, { status: 400 });
    }

    const target = new URL(rawUrl);
    const domain = target.hostname.replace(/^www\./i, '');
    const host = target.hostname.toLowerCase().replace(/^www\./i, '');

    // Fast-path oEmbed query for media sites (YouTube, Vimeo, Spotify, SoundCloud)
    const oembedPromise = fetchOEmbed(rawUrl, host);

    let html = '';
    let finalUrl = target.toString();

    // Try each UA in turn — stop as soon as we get a valid HTML response
    for (const ua of USER_AGENTS) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
      try {
        const isBot = ua.startsWith('facebook') || ua.startsWith('Twitter');
        const headers: Record<string, string> = {
          'user-agent': ua,
          accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'accept-language': 'en-US,en;q=0.9',
        };
        if (!isBot) {
          headers['sec-ch-ua'] = '"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"';
          headers['sec-ch-ua-mobile'] = '?0';
          headers['sec-fetch-dest'] = 'document';
          headers['sec-fetch-mode'] = 'navigate';
          headers['sec-fetch-site'] = 'none';
        }
        const response = await fetch(target, { signal: controller.signal, headers, redirect: 'follow' });
        clearTimeout(timer);
        if (response.ok) {
          const ct = response.headers.get('content-type') || '';
          if (ct.includes('text/html') || ct.includes('application/xhtml')) {
            finalUrl = response.url || target.toString();
            const text = await response.text();
            html = text.slice(0, MAX_HTML_BYTES);
            if (html.length > 200) break; // Got real content, stop trying
          }
        }
      } catch {
        clearTimeout(timer);
      }
    }

    const oembed = await oembedPromise;
    const finalUri = new URL(finalUrl);
    const article = html ? extractArticleContent(html, finalUrl) : null;

    let title =
      (oembed?.title && !isGenericTitle(oembed.title) ? oembed.title : null) ||
      article?.title ||
      extractMeta(html, 'og:title') ||
      extractMeta(html, 'twitter:title') ||
      extractTitle(html);

    if (isGenericTitle(title) && oembed?.title) {
      title = oembed.title;
    }
    if (!title || isGenericTitle(title)) {
      title = domain;
    }

    const description =
      extractMeta(html, 'og:description') ||
      extractMeta(html, 'twitter:description') ||
      extractMeta(html, 'description') ||
      article?.description ||
      oembed?.description ||
      (oembed?.author_name ? `${oembed.provider_name || 'Media'} by ${oembed.author_name}` : null) ||
      (article?.textContent ? article.textContent.slice(0, 240).trim() : null);

    const rawImage =
      extractMeta(html, 'og:image') ||
      extractMeta(html, 'og:image:url') ||
      extractMeta(html, 'og:image:secure_url') ||
      extractMeta(html, 'twitter:image') ||
      extractMeta(html, 'twitter:image:src') ||
      extractMeta(html, 'thumbnail') ||
      extractMeta(html, 'image');

    let previewImageUrl =
      resolveAbsoluteUrl(rawImage, finalUrl) ||
      oembed?.thumbnail_url ||
      article?.previewImageUrl ||
      null;

    // Fallback: check link[rel="image_src"] or apple-touch-icon if no image found yet
    if (!previewImageUrl && html) {
      const linkImg = html.match(/<link[^>]+rel=["'](?:image_src|apple-touch-icon)["'][^>]+href=["']([^"']+)["']/i);
      if (linkImg?.[1]) {
        previewImageUrl = resolveAbsoluteUrl(decodeHtmlEntities(linkImg[1]), finalUrl);
      }
    }

    // For YouTube, ensure high-quality thumbnail if present
    const ytMatch = rawUrl.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})/);
    if (ytMatch?.[1] && (!previewImageUrl || previewImageUrl.includes('hqdefault'))) {
      previewImageUrl = `https://i.ytimg.com/vi/${ytMatch[1]}/hqdefault.jpg`;
    }

    const siteName =
      oembed?.provider_name ||
      extractMeta(html, 'og:site_name') ||
      extractMeta(html, 'application-name') ||
      (host.includes('youtube') ? 'YouTube' : domain);

    const faviconUrl = extractFavicon(html, finalUrl) || `https://www.google.com/s2/favicons?domain=${domain}&sz=128`;
    const ogType = extractMeta(html, 'og:type');
    const contentType = classifyUrl(finalUri, ogType);
    const embed = detectEmbed(rawUrl);

    // Build author, publish time, and reading stats
    const author =
      article?.author ||
      extractMeta(html, 'author') ||
      extractMeta(html, 'article:author') ||
      oembed?.author_name ||
      null;

    const publishedTime =
      article?.publishedTime ||
      extractMeta(html, 'article:published_time') ||
      null;

    const readingTimeMinutes = article?.readingTimeMinutes || 1;
    const markdown = article?.markdown || '';
    const htmlContent = article?.htmlContent || '';
    const textContent = article?.textContent || '';

    // Build intelligent, contextual keywords from page and oEmbed metadata
    const extractedKeywords = extractKeywords(html);
    if (oembed?.title) {
      const titleTokens = oembed.title
        .split(/[/|\\:–—•[\](){}"]+/)
        .map((t) => t.trim().toLowerCase())
        .filter((t) => t.length > 2 && t.length < 35);
      extractedKeywords.push(...titleTokens);
    }
    if (oembed?.author_name) {
      extractedKeywords.push(oembed.author_name.toLowerCase());
    }
    if (host.includes('youtube') || host === 'youtu.be') {
      extractedKeywords.push('video', 'youtube');
    }

    // Deduplicate and filter out standalone generic 'playlist'
    const seen = new Set<string>();
    const keywords = extractedKeywords
      .map((k) => k.replace(/[#_]/g, ' ').trim().toLowerCase())
      .filter((k) => k.length > 1 && k !== 'playlist' && k !== 'video playlist')
      .filter((k) => {
        if (seen.has(k)) return false;
        seen.add(k);
        return true;
      })
      .slice(0, 10);

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
      keywords,
      author,
      publishedTime,
      readingTimeMinutes,
      markdown,
      htmlContent,
      textContent,
      embedProvider: embed?.embedProvider ?? oembed?.provider_name ?? null,
      embedUrl: embed?.embedUrl ?? null,
      embedHeight: embed?.embedHeight ?? null,
      classification: {
        contentType,
        type: contentType,
        content_type: contentType,
        confidence: 0.95,
        source: oembed ? 'oEmbed' : 'htmlMeta',
      },
    };

    return NextResponse.json(result, { status: 200 });
  } catch (error) {
    console.error('[API/Enrich] error:', error);
    return NextResponse.json({ error: 'Internal enrich error' }, { status: 500 });
  }
}
