export interface YouTubeVideo {
  root: Element;
  url: string;
  title: string;
  author?: string;
  thumbnailUrl?: string;
  insertionPoint: HTMLElement;
  compact?: boolean;
}

export interface YouTubeProfile {
  root: Element;
  url: string;
  name: string;
  insertionPoint: HTMLElement;
}

export function isYouTube(pageUrl: string): boolean {
  try {
    const url = new URL(pageUrl);
    const host = url.hostname.toLowerCase().replace(/^www\./, "");
    return host === "youtube.com" || host === "m.youtube.com" || host === "youtu.be";
  } catch {
    return false;
  }
}

export function findYouTubeVideos(doc: Document, pageUrl: string): YouTubeVideo[] {
  if (!isYouTube(pageUrl)) return [];

  const videos: YouTubeVideo[] = [];
  const seenRoots = new Set<Element>();
  const seenUrls = new Set<string>();

  const url = new URL(pageUrl);

  // 1. Primary Watch Page video
  const videoId = url.searchParams.get("v");
  if (videoId && (url.pathname === "/watch" || url.pathname.startsWith("/watch/"))) {
    const canonicalUrl = `https://www.youtube.com/watch?v=${videoId}`;
    const primaryRoot =
      doc.querySelector("ytd-watch-metadata, #above-the-fold, #primary-inner, ytd-watch-flexy") ||
      doc.body;

    const titleEl = doc.querySelector(
      "ytd-watch-metadata #title h1, #above-the-fold #title h1, h1.ytd-watch-metadata, #title.ytd-watch-metadata",
    );
    const title =
      titleEl?.textContent?.trim() ||
      doc.title.replace(/ - YouTube$/, "").trim() ||
      "YouTube Video";

    const ownerEl = doc.querySelector(
      "#owner #channel-name a, ytd-video-owner-renderer #channel-name a, #upload-info #channel-name a, ytd-channel-name a",
    );
    const author = ownerEl?.textContent?.trim() || undefined;

    // Insertion point in watch action buttons bar (Like, Share, Download)
    const actionRow = doc.querySelector<HTMLElement>(
      "#actions #top-level-buttons-computed, ytd-menu-renderer #top-level-buttons-computed, #actions-inner, #actions",
    );

    if (actionRow) {
      const share =
        actionRow.querySelector<HTMLElement>(
          'button[aria-label*="Share" i], ytd-button-renderer:has(button[aria-label*="Share" i])',
        ) ||
        (actionRow.lastElementChild as HTMLElement) ||
        actionRow;

      seenRoots.add(primaryRoot);
      seenUrls.add(canonicalUrl);
      videos.push({
        root: primaryRoot,
        url: canonicalUrl,
        title,
        author,
        thumbnailUrl: `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`,
        insertionPoint: share,
        compact: false,
      });
    }
  }

  // 2. YouTube Shorts
  const shortsMatch = url.pathname.match(/^\/shorts\/([a-zA-Z0-9_-]+)/);
  if (shortsMatch) {
    const shortId = shortsMatch[1];
    const canonicalUrl = `https://www.youtube.com/shorts/${shortId}`;
    const shortRoot =
      doc.querySelector("ytd-reel-video-renderer[is-active], ytd-reel-video-renderer") ||
      doc.body;

    const actionRail = shortRoot.querySelector<HTMLElement>(
      "#actions, ytd-like-button-renderer, #like-button",
    );
    if (actionRail && !seenUrls.has(canonicalUrl)) {
      const titleEl = shortRoot.querySelector(
        "h2.title, #overlay h2, ytd-reel-player-header-renderer h2",
      );
      const title = titleEl?.textContent?.trim() || doc.title.replace(/ - YouTube$/, "").trim();
      const author =
        shortRoot.querySelector("#channel-name, .ytd-channel-name")?.textContent?.trim() ||
        undefined;

      seenRoots.add(shortRoot);
      seenUrls.add(canonicalUrl);
      videos.push({
        root: shortRoot,
        url: canonicalUrl,
        title: title || "YouTube Short",
        author,
        thumbnailUrl: `https://i.ytimg.com/vi/${shortId}/hqdefault.jpg`,
        insertionPoint: actionRail,
        compact: true,
      });
    }
  }

  // 3. Video cards on feeds, search results, or channel tabs
  const cards = Array.from(
    doc.querySelectorAll(
      "ytd-video-renderer, ytd-rich-item-renderer, ytd-grid-video-renderer, ytd-compact-video-renderer",
    ),
  );

  for (const card of cards) {
    if (card.closest("[data-laterbox-control],[hidden],[aria-hidden=\"true\"]")) {
      continue;
    }

    const titleAnchor = card.querySelector<HTMLAnchorElement>(
      "a#video-title-link, a#video-title, a[href*=\"/watch?v=\"]",
    );
    if (!titleAnchor) continue;

    const href = titleAnchor.getAttribute("href");
    const vMatch = href?.match(/[?&]v=([a-zA-Z0-9_-]+)/);
    if (!vMatch) continue;

    const cardVideoId = vMatch[1];
    const cardUrl = `https://www.youtube.com/watch?v=${cardVideoId}`;
    if (seenUrls.has(cardUrl) || seenRoots.has(card)) continue;

    const cardTitle =
      titleAnchor.textContent?.trim() || titleAnchor.getAttribute("title")?.trim() || "";
    if (!cardTitle) continue;

    const cardAuthor =
      card.querySelector("#channel-name a, ytd-channel-name a, #text.ytd-channel-name")
        ?.textContent?.trim() || undefined;

    // Insertion point near card actions / menu
    const menu = card.querySelector<HTMLElement>("#menu, ytd-menu-renderer, #metadata-line");
    const insertionPoint = menu || titleAnchor;

    seenRoots.add(card);
    seenUrls.add(cardUrl);
    videos.push({
      root: card,
      url: cardUrl,
      title: cardTitle,
      author: cardAuthor,
      thumbnailUrl: `https://i.ytimg.com/vi/${cardVideoId}/hqdefault.jpg`,
      insertionPoint,
      compact: true,
    });
  }

  return videos;
}

export function findYouTubeProfile(doc: Document, pageUrl: string): YouTubeProfile | undefined {
  if (!isYouTube(pageUrl)) return undefined;

  const page = new URL(pageUrl);
  const path = page.pathname;

  // Exclude non-channel routes
  if (
    /^\/(watch|shorts|feed|results|live|gaming|playlist|premium|about|t\/|creators|ads|howyoutubeworks|new|browse|post)/i.test(
      path,
    )
  ) {
    return undefined;
  }

  // Matches /@handle, /channel/UC..., /c/name, /user/name
  const match = path.match(
    /^\/(@[A-Za-z0-9_.-]+|channel\/[A-Za-z0-9_-]+|c\/[A-Za-z0-9_.-]+|user\/[A-Za-z0-9_.-]+)(\/(?:videos|shorts|playlists|community|channels|about|featured))?\/?$/,
  );
  if (!match) return undefined;

  const canonicalUrl = `${page.origin}/${match[1]}`;

  // Channel header container in current & previous YouTube layouts
  const header = doc.querySelector(
    "yt-page-header-renderer, ytd-channel-header-renderer, ytd-c4-tabbed-header-renderer, #channel-header, .page-header-view-model-wiz",
  );
  if (!header) return undefined;

  const nameEl = header.querySelector(
    "yt-page-header-renderer h1, h1, ytd-channel-name yt-formatted-string, #channel-name yt-formatted-string, #channel-name, [role=\"text\"]",
  );
  const name = nameEl?.textContent?.trim() || match[1];

  const subscribeBtn = header.querySelector<HTMLElement>(
    "#subscribe-button, yt-subscribe-button-view-model, ytd-subscribe-button-renderer, .page-header-view-model-wiz__page-header-actions, #buttons",
  );
  const insertionPoint = subscribeBtn || (nameEl as HTMLElement) || (header as HTMLElement);

  return {
    root: header,
    url: canonicalUrl,
    name,
    insertionPoint,
  };
}

export function createYouTubeVideoControls(
  doc: Document,
  create: (video: YouTubeVideo, resolve: () => YouTubeVideo | undefined) => HTMLElement,
): (enabled: boolean, pageUrl: string) => void {
  const controls = new Map<Element, { video: YouTubeVideo; container: HTMLElement }>();

  return (enabled: boolean, pageUrl: string) => {
    const videos = enabled ? findYouTubeVideos(doc, pageUrl) : [];

    for (const [root, record] of controls) {
      const match = videos.find((v) => v.root === root);
      if (
        !match ||
        match.url !== record.video.url ||
        match.insertionPoint !== record.video.insertionPoint ||
        !record.container.isConnected
      ) {
        record.container.remove();
        controls.delete(root);
      }
    }

    for (const video of videos) {
      let record = controls.get(video.root);
      if (!record) {
        const container = create(video, () =>
          findYouTubeVideos(doc, doc.location.href).find(
            (current) => current.root === video.root && current.url === video.url,
          ),
        );
        record = { video, container };
        controls.set(video.root, record);
      }
      if (video.insertionPoint.nextElementSibling !== record.container) {
        video.insertionPoint.after(record.container);
      }
    }
  };
}

export function createYouTubeProfileControls(
  doc: Document,
  create: (profile: YouTubeProfile, resolve: () => YouTubeProfile | undefined) => HTMLElement,
): (enabled: boolean, pageUrl: string) => void {
  let control: { profile: YouTubeProfile; container: HTMLElement } | undefined;

  return (enabled: boolean, pageUrl: string) => {
    const profile = enabled ? findYouTubeProfile(doc, pageUrl) : undefined;

    if (
      control &&
      (!profile ||
        profile.url !== control.profile.url ||
        profile.insertionPoint !== control.profile.insertionPoint ||
        !control.container.isConnected)
    ) {
      control.container.remove();
      control = undefined;
    }

    if (!profile) return;

    if (!control) {
      control = {
        profile,
        container: create(profile, () => {
          const current = findYouTubeProfile(doc, doc.location.href);
          return current?.url === profile.url ? current : undefined;
        }),
      };
    }

    if (profile.insertionPoint.nextElementSibling !== control.container) {
      profile.insertionPoint.after(control.container);
    }
  };
}

