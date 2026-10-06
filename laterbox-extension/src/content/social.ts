export interface SocialPost { root: Element; url: string; site: string; author?: string; publishedAt?: string }
export function findSocialPosts(doc: Document, pageUrl: string): SocialPost[] {
  const page = new URL(pageUrl); const host = page.hostname.replace(/^www\./,'');
  const configs: Record<string,{ roots: string; links: string; site: string; author: string }> = {
    'x.com': { roots:'article[data-testid="tweet"]',links:'a[href*="/status/"]',site:'X',author:'[data-testid="User-Name"]' },
    'twitter.com': { roots:'article[data-testid="tweet"]',links:'a[href*="/status/"]',site:'X',author:'[data-testid="User-Name"]' },
    'reddit.com': { roots:'shreddit-post,article',links:'a[href*="/comments/"]',site:'Reddit',author:'[data-testid="post_author_link"],a[href*="/user/"]' },
    'old.reddit.com': { roots:'.thing.link',links:'a.comments',site:'Reddit',author:'a.author' },
    'linkedin.com': { roots:'.feed-shared-update-v2,[data-urn*="urn:li:activity:"]',links:'a[href*="/feed/update/"],a[href*="/posts/"]',site:'LinkedIn',author:'.update-components-actor__title,.feed-shared-actor__name' },
    'instagram.com': { roots:'article',links:'a[href*="/p/"],a[href*="/reel/"],a[href*="/reels/"]',site:'Instagram',author:'header a,h2 a' },
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

export interface InstagramPost extends SocialPost { share: HTMLElement; insertionPoint: HTMLElement; compact?: boolean }
/** Semantic controls are deliberately conservative: ambiguous layouts get no button. */
export function findInstagramPosts(doc: Document, pageUrl: string): InstagramPost[] {
  const page=new URL(pageUrl);
  if (!/^(www\.)?instagram\.com$/.test(page.hostname) || page.pathname.startsWith('/stories/')) return [];
  const posts:InstagramPost[]=[];const seen=new Set<Element>();
  const currentPostUrl=page.pathname.match(/^\/reels\/([^/]+)\/?$/) ? new URL(page.href.replace('/reels/','/reel/')).href : page.href;
  const permalink=(raw:string|null):string|null=>{
    if(!raw)return null;
    try{const url=new URL(raw,page);if(!/^(www\.)?instagram\.com$/.test(url.hostname) || !/^https?:$/.test(url.protocol) || !/^\/(p|reels?)\/[^/]+\/?$/.test(url.pathname))return null;return url.origin+url.pathname.replace(/^\/reels\//,'/reel/');}catch{return null;}
  };
  for(const icon of doc.querySelectorAll('[aria-label],svg title')) {
    const label=(icon.getAttribute('aria-label') || icon.textContent || '').trim();
    if(!/^(share|share post|share reel|send|send post|send reel|send to|share to)$/i.test(label))continue;
    if(icon.closest('[data-laterbox-control],[hidden]') || icon.parentElement?.closest('[aria-hidden="true"]'))continue;
    const share=icon.closest<HTMLElement>('button,[role="button"],[tabindex="0"]');if(!share)continue;
    let root:Element|null=share.closest('article');
    // Reels and modal layouts sometimes omit article. Find the smallest content
    // ancestor enclosing this action and exactly one media/post source.
    if(!root){
      for(let node=share.parentElement;node && node!==doc.body;node=node.parentElement){
        if(node.querySelector('video,img') && (node.querySelector('a[href*="/reel/"],a[href*="/reels/"],a[href*="/p/"]') || node.matches('[role="dialog"]') || /^\/(p|reels?)\//.test(page.pathname) || node.hasAttribute('data-permalink') || node.hasAttribute('data-shortcode'))){root=node;break;}
      }
    }
    if(!root || seen.has(root))continue;
    const links=Array.from(root.querySelectorAll<HTMLAnchorElement>('a[href*="/p/"],a[href*="/reel/"],a[href*="/reels/"]'));
    const timed=links.find(link=>link.querySelector('time'));
    const urls=[...new Set(links.map(link=>permalink(link.getAttribute('href'))).filter((url):url is string=>!!url))];
    let url=permalink(root.getAttribute('data-permalink')) || permalink(root.getAttribute('data-shortcode') ? '/p/'+root.getAttribute('data-shortcode')+'/' : null) || permalink(timed?.getAttribute('href') || null) || (urls.length===1 ? urls[0] : null);
    const dialog=root.closest('[role="dialog"]');
    if(!url && urls.length===0 && ((dialog && dialog.querySelectorAll('article').length<=1) || doc.querySelectorAll('article,video').length===1))url=permalink(currentPostUrl);
    if(!url)continue;
    const row=share.parentElement;if(!row || !root.contains(row))continue;
    // An icon's button can be wrapped by a single action slot. Insert after that
    // slot, not inside the clickable Share control.
    const insertionPoint=/^(SPAN|DIV)$/.test(row.tagName) && row.childElementCount===1 && row.parentElement && root.contains(row.parentElement) && row.parentElement.querySelectorAll('button,[role="button"]').length>1 ? row : share;
    seen.add(root);posts.push({root,share,insertionPoint,url,site:'Instagram',compact:page.pathname.startsWith('/reels/') && !root.closest('[role="dialog"]'),
      author:root.querySelector('header a,h2 a,a[role="link"]')?.textContent?.trim().slice(0,500),
      publishedAt:root.querySelector('time')?.getAttribute('datetime') || undefined});
  }
  return posts;
}
