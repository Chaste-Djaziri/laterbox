/**
 * Article reader and content extractor for LaterBox web captures.
 * Extracts article text, clean sanitized reader HTML, Markdown, and rich metadata.
 */

export interface ExtractedArticle {
  title: string | null;
  description: string | null;
  author: string | null;
  publishedTime: string | null;
  previewImageUrl: string | null;
  markdown: string;
  htmlContent: string;
  textContent: string;
  readingTimeMinutes: number;
}

function decodeEntities(str: string): string {
  return str
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

function resolveUrl(href: string, baseUrl: string): string {
  try {
    return new URL(href, baseUrl).toString();
  } catch {
    return href;
  }
}

/**
 * Strips script tags, styles, navigation, footer, forms, and ad containers.
 */
function stripNoise(html: string): string {
  return html
    .replace(/<!--[\s\S]*?-->/g, '') // comments
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<noscript\b[^<]*(?:(?!<\/noscript>)<[^<]*)*<\/noscript>/gi, '')
    .replace(/<svg\b[^<]*(?:(?!<\/svg>)<[^<]*)*<\/svg>/gi, '')
    .replace(/<nav\b[^<]*(?:(?!<\/nav>)<[^<]*)*<\/nav>/gi, '')
    .replace(/<header\b[^<]*(?:(?!<\/header>)<[^<]*)*<\/header>/gi, '')
    .replace(/<footer\b[^<]*(?:(?!<\/footer>)<[^<]*)*<\/footer>/gi, '')
    .replace(/<aside\b[^<]*(?:(?!<\/aside>)<[^<]*)*<\/aside>/gi, '')
    .replace(/<form\b[^<]*(?:(?!<\/form>)<[^<]*)*<\/form>/gi, '')
    .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '');
}

/**
 * Locates the main article / content container from HTML.
 */
function findArticleRoot(cleanHtml: string): string {
  // 1. Try <article> tag
  const articleMatch = cleanHtml.match(/<article\b[^>]*>([\s\S]*?)<\/article>/i);
  if (articleMatch && articleMatch[1].trim().length > 150) {
    return articleMatch[1];
  }

  // 2. Try <main> tag or role="main"
  const mainMatch = cleanHtml.match(/<main\b[^>]*>([\s\S]*?)<\/main>/i);
  if (mainMatch && mainMatch[1].trim().length > 150) {
    return mainMatch[1];
  }

  const roleMainMatch = cleanHtml.match(/<div[^>]+role=["']main["'][^>]*>([\s\S]*?)<\/div>/i);
  if (roleMainMatch && roleMainMatch[1].trim().length > 150) {
    return roleMainMatch[1];
  }

  // 3. Try common content containers
  const contentClassMatch = cleanHtml.match(
    /<(?:div|section)[^>]+class=["'][^"']*(?:post-content|article-body|entry-content|markdown-body|story-content|article__body|prose)[^"']*["'][^>]*>([\s\S]*?)<\/(?:div|section)>/i
  );
  if (contentClassMatch && contentClassMatch[1].trim().length > 150) {
    return contentClassMatch[1];
  }

  // 4. Fallback to <body>
  const bodyMatch = cleanHtml.match(/<body\b[^>]*>([\s\S]*?)<\/body>/i);
  return bodyMatch ? bodyMatch[1] : cleanHtml;
}

/**
 * Extracts JSON-LD schema metadata if present.
 */
function extractJsonLd(html: string): Partial<ExtractedArticle> {
  const result: Partial<ExtractedArticle> = {};
  const regex = /<script\b[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(html)) !== null) {
    try {
      const data = JSON.parse(match[1].trim());
      const items = Array.isArray(data) ? data : data['@graph'] ? data['@graph'] : [data];

      for (const item of items) {
        if (!item || typeof item !== 'object') continue;
        const type = String(item['@type'] || '');

        if (
          type.includes('Article') ||
          type.includes('BlogPosting') ||
          type.includes('NewsArticle') ||
          type.includes('WebPage')
        ) {
          if (!result.title && typeof item.headline === 'string') result.title = item.headline;
          if (!result.description && typeof item.description === 'string') result.description = item.description;
          if (!result.publishedTime && typeof item.datePublished === 'string') result.publishedTime = item.datePublished;
          if (!result.author) {
            if (typeof item.author === 'string') result.author = item.author;
            else if (item.author?.name && typeof item.author.name === 'string') result.author = item.author.name;
          }
          if (!result.previewImageUrl) {
            if (typeof item.image === 'string') result.previewImageUrl = item.image;
            else if (Array.isArray(item.image) && typeof item.image[0] === 'string') result.previewImageUrl = item.image[0];
            else if (item.image?.url && typeof item.image.url === 'string') result.previewImageUrl = item.image.url;
          }
        }
      }
    } catch {
      // ignore json-ld parse errors
    }
  }

  return result;
}

/**
 * Converts HTML snippet to Markdown and sanitized reader HTML.
 */
export function extractArticleContent(rawHtml: string, baseUrl: string): ExtractedArticle {
  const jsonLd = extractJsonLd(rawHtml);
  const clean = stripNoise(rawHtml);
  const root = findArticleRoot(clean);

  const markdownBlocks: string[] = [];
  const htmlBlocks: string[] = [];
  const textBlocks: string[] = [];

  // Match block-level elements: h1-h6, p, blockquote, pre, ul, ol, img, hr
  const blockRegex = /<(h[1-6]|p|blockquote|pre|ul|ol|hr)\b([^>]*)>([\s\S]*?)<\/\1>|<img\b([^>]*)>|<hr\b[^>]*>/gi;
  let blockMatch: RegExpExecArray | null;

  const seenImages = new Set<string>();

  const convertInline = (inlineHtml: string): { md: string; cleanHtml: string; text: string } => {
    let md = inlineHtml;
    let ch = inlineHtml;

    // Convert links
    md = md.replace(/<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi, (_, href: string, text: string) => {
      const fullUrl = resolveUrl(href, baseUrl);
      const cleanText = text.replace(/<[^>]+>/g, '').trim();
      return cleanText ? `[${cleanText}](${fullUrl})` : '';
    });
    ch = ch.replace(/<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi, (_, href: string, text: string) => {
      const fullUrl = resolveUrl(href, baseUrl);
      return `<a href="${fullUrl}" target="_blank" rel="noopener noreferrer">${text}</a>`;
    });

    // Convert strong / b
    md = md.replace(/<(?:strong|b)\b[^>]*>([\s\S]*?)<\/(?:strong|b)>/gi, '**$1**');
    // Convert em / i
    md = md.replace(/<(?:em|i)\b[^>]*>([\s\S]*?)<\/(?:em|i)>/gi, '*$1*');
    // Convert inline code
    md = md.replace(/<code\b[^>]*>([\s\S]*?)<\/code>/gi, '`$1`');

    // Strip remaining tags for MD
    const cleanMd = decodeEntities(md.replace(/<[^>]+>/g, '')).replace(/\s+/g, ' ').trim();
    // Strip tags for clean text
    const cleanText = decodeEntities(inlineHtml.replace(/<[^>]+>/g, '')).replace(/\s+/g, ' ').trim();
    // Sanitize ch
    const sanitizedHtml = decodeEntities(ch.replace(/<(?!a\b|strong\b|em\b|code\b|\/a|\/strong|\/em|\/code)[^>]+>/gi, '')).trim();

    return { md: cleanMd, cleanHtml: sanitizedHtml, text: cleanText };
  };

  while ((blockMatch = blockRegex.exec(root)) !== null) {
    const fullMatch = blockMatch[0];
    const tag = (blockMatch[1] || (fullMatch.startsWith('<img') ? 'img' : 'hr')).toLowerCase();
    const inner = blockMatch[3] || '';
    const imgAttrs = blockMatch[4] || '';

    if (tag === 'img') {
      const srcMatch = (fullMatch || imgAttrs).match(/src=["']([^"']+)["']/i);
      const altMatch = (fullMatch || imgAttrs).match(/alt=["']([^"']*)["']/i);
      if (srcMatch?.[1]) {
        const src = resolveUrl(srcMatch[1], baseUrl);
        const alt = altMatch?.[1] ? decodeEntities(altMatch[1]).trim() : 'Image';
        if (!seenImages.has(src) && !src.includes('data:image/svg') && !src.includes('1x1')) {
          seenImages.add(src);
          markdownBlocks.push(`![${alt}](${src})`);
          htmlBlocks.push(`<figure><img src="${src}" alt="${alt}" loading="lazy" /><figcaption>${alt}</figcaption></figure>`);
        }
      }
      continue;
    }

    if (tag === 'hr') {
      markdownBlocks.push('---');
      htmlBlocks.push('<hr />');
      continue;
    }

    if (/^h[1-6]$/.test(tag)) {
      const level = parseInt(tag[1], 10);
      const { md, cleanHtml, text } = convertInline(inner);
      if (text.length > 0) {
        markdownBlocks.push(`${'#'.repeat(level)} ${md}`);
        htmlBlocks.push(`<${tag}>${cleanHtml}</${tag}>`);
        textBlocks.push(text);
      }
      continue;
    }

    if (tag === 'p') {
      const { md, cleanHtml, text } = convertInline(inner);
      if (text.length > 5) {
        markdownBlocks.push(md);
        htmlBlocks.push(`<p>${cleanHtml}</p>`);
        textBlocks.push(text);
      }
      continue;
    }

    if (tag === 'blockquote') {
      const { md, cleanHtml, text } = convertInline(inner);
      if (text.length > 0) {
        markdownBlocks.push(`> ${md}`);
        htmlBlocks.push(`<blockquote><p>${cleanHtml}</p></blockquote>`);
        textBlocks.push(`"${text}"`);
      }
      continue;
    }

    if (tag === 'pre') {
      const codeMatch = inner.match(/<code\b[^>]*>([\s\S]*?)<\/code>/i);
      const rawCode = decodeEntities(codeMatch ? codeMatch[1] : inner).replace(/<[^>]+>/g, '').trim();
      if (rawCode.length > 0) {
        markdownBlocks.push(`\`\`\`\n${rawCode}\n\`\`\``);
        htmlBlocks.push(`<pre><code>${rawCode.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</code></pre>`);
        textBlocks.push(rawCode);
      }
      continue;
    }

    if (tag === 'ul' || tag === 'ol') {
      const isOrdered = tag === 'ol';
      const items: { md: string; html: string; text: string }[] = [];
      const itemRegex = /<li\b[^>]*>([\s\S]*?)<\/li>/gi;
      let im: RegExpExecArray | null;
      let counter = 1;

      while ((im = itemRegex.exec(inner)) !== null) {
        const { md, cleanHtml, text } = convertInline(im[1]);
        if (text.length > 0) {
          items.push({
            md: isOrdered ? `${counter++}. ${md}` : `- ${md}`,
            html: `<li>${cleanHtml}</li>`,
            text,
          });
        }
      }

      if (items.length > 0) {
        markdownBlocks.push(items.map((i) => i.md).join('\n'));
        htmlBlocks.push(`<${tag}>${items.map((i) => i.html).join('')}</${tag}>`);
        textBlocks.push(items.map((i) => i.text).join(' '));
      }
      continue;
    }
  }

  // If no block elements were extracted, fall back to simple paragraph splitting
  if (textBlocks.length === 0) {
    const fallbackText = decodeEntities(root.replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();
    if (fallbackText.length > 20) {
      const paras = fallbackText.split(/(?:\r?\n){2,}|(?<=[.!?])\s{2,}/).map((p) => p.trim()).filter((p) => p.length > 20);
      for (const p of paras) {
        markdownBlocks.push(p);
        htmlBlocks.push(`<p>${p}</p>`);
        textBlocks.push(p);
      }
    }
  }

  const markdown = markdownBlocks.join('\n\n');
  const htmlContent = htmlBlocks.join('\n');
  const textContent = textBlocks.join('\n\n');

  // Word count & reading time estimation (~200 wpm)
  const wordCount = textContent.trim().length > 0 ? textContent.trim().split(/\s+/).length : 0;
  const readingTimeMinutes = Math.max(1, Math.ceil(wordCount / 200));

  return {
    title: jsonLd.title || null,
    description: jsonLd.description || null,
    author: jsonLd.author || null,
    publishedTime: jsonLd.publishedTime || null,
    previewImageUrl: jsonLd.previewImageUrl ? resolveUrl(jsonLd.previewImageUrl, baseUrl) : null,
    markdown,
    htmlContent,
    textContent,
    readingTimeMinutes,
  };
}
