export interface SocialPost { root: Element; url: string; site: string; author?: string; publishedAt?: string }
export function findSocialPosts(doc: Document, pageUrl: string): SocialPost[] {
  const page = new URL(pageUrl); const host = page.hostname.replace(/^www\./,'');
  const configs: Record<string,{ roots: string; links: string; site: string; author: string }> = {
    'x.com': { roots:'article[data-testid="tweet"]',links:'a[href*="/status/"]',site:'X',author:'[data-testid="User-Name"]' },
    'twitter.com': { roots:'article[data-testid="tweet"]',links:'a[href*="/status/"]',site:'X',author:'[data-testid="User-Name"]' },
    'reddit.com': { roots:'shreddit-post,article',links:'a[href*="/comments/"]',site:'Reddit',author:'[data-testid="post_author_link"],a[href*="/user/"]' },
    'old.reddit.com': { roots:'.thing.link',links:'a.comments',site:'Reddit',author:'a.author' },
    'linkedin.com': { roots:'.feed-shared-update-v2,[data-urn*="urn:li:activity:"]',links:'a[href*="/feed/update/"],a[href*="/posts/"]',site:'LinkedIn',author:'.update-components-actor__title,.feed-shared-actor__name' },
    'instagram.com': { roots:'article',links:'a[href*="/p/"],a[href*="/reel/"]',site:'Instagram',author:'header a,h2 a' },
    'facebook.com': { roots:'[role="article"]',links:'a[href*="/posts/"],a[href*="/permalink/"],a[href*="story_fbid="],a[href*="/reel/"]',site:'Facebook',author:'h2 a,h3 a,strong a' },
  };
  const config = configs[host]; if (!config) return [];
  const seen = new Set<Element>(); const posts: SocialPost[] = [];
  for (const root of doc.querySelectorAll(config.roots)) {
    if (root.parentElement?.closest(config.roots) || seen.has(root)) continue;
    const timedLink = Array.from(root.querySelectorAll<HTMLAnchorElement>(config.links)).find(link=>link.querySelector('time'));
    let raw = timedLink?.getAttribute('href') || root.getAttribute('permalink') || root.querySelector(config.links)?.getAttribute('href');
    if (!raw && config.site==='LinkedIn') {
      const urn = root.getAttribute('data-urn')?.match(/urn:li:activity:\d+/)?.[0];
      if (urn) raw='/feed/update/'+urn+'/';
    }
    if (!raw && config.site==='Instagram' && /^\/(p|reel)\//.test(page.pathname)) raw=page.href;
    if (!raw) continue;
    try {
      const url=new URL(raw,page); if (!/^https?:$/.test(url.protocol) || url.hostname.replace(/^www\./,'')!==host) continue;
      if (config.site==='X' && !/\/status\/\d+/.test(url.pathname)) continue;
      url.hash='';
      seen.add(root); posts.push({ root, url:url.href,site:config.site,
        author:root.getAttribute('author') || root.querySelector(config.author)?.textContent?.trim().slice(0,500),
        publishedAt:root.querySelector('time')?.getAttribute('datetime') || undefined });
    } catch { /* malformed or unsupported permalink: generic capture remains available */ }
  }
  return posts;
}
