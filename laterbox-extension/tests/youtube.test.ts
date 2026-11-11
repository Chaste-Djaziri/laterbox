import { test } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import {
  isYouTube,
  findYouTubeVideos,
  findYouTubeProfile,
  createYouTubeVideoControls,
  createYouTubeProfileControls,
} from '../src/content/youtube-controls';

const watchPageHtml = `
<ytd-watch-flexy>
  <div id="primary-inner">
    <div id="above-the-fold">
      <div id="title" class="ytd-watch-metadata">
        <h1>Microsoft FINALLY Fixed the Right Click Menu</h1>
      </div>
      <div id="owner">
        <div id="channel-name">
          <a href="/@Britec09">Britec09</a>
        </div>
      </div>
      <div id="actions">
        <div id="top-level-buttons-computed">
          <button aria-label="like this video">Like</button>
          <button aria-label="Share">Share</button>
          <button aria-label="Download">Download</button>
        </div>
      </div>
    </div>
  </div>
</ytd-watch-flexy>`;

const channelPageHtml = `
<ytd-app>
  <yt-page-header-renderer>
    <div class="page-header-view-model-wiz">
      <h1>Marques Brownlee</h1>
      <div id="channel-handle" role="text">@mkbhd</div>
      <div id="subscribe-button">
        <button aria-label="Subscribe to Marques Brownlee">Subscribe</button>
      </div>
    </div>
  </yt-page-header-renderer>
</ytd-app>`;

const feedCardsHtml = `
<ytd-browse>
  <ytd-rich-item-renderer>
    <div id="content">
      <a id="video-title-link" href="/watch?v=vid123" title="Building an AI Agent">
        Building an AI Agent
      </a>
      <div id="channel-name">
        <a href="/@tech">Tech Channel</a>
      </div>
      <div id="menu">
        <button aria-label="Action menu">⋮</button>
      </div>
    </div>
  </ytd-rich-item-renderer>
</ytd-browse>`;

test('isYouTube accurately validates YouTube domains', () => {
  assert.equal(isYouTube('https://www.youtube.com/watch?v=123'), true);
  assert.equal(isYouTube('https://youtube.com/@mkbhd'), true);
  assert.equal(isYouTube('https://m.youtube.com/watch?v=123'), true);
  assert.equal(isYouTube('https://youtu.be/123'), true);
  assert.equal(isYouTube('https://google.com'), false);
  assert.equal(isYouTube('https://vimeo.com/123'), false);
});

test('findYouTubeVideos extracts watch page video with title, author, and actions row insertion', () => {
  const pageUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s';
  const doc = new JSDOM(watchPageHtml, { url: pageUrl }).window.document;
  const videos = findYouTubeVideos(doc, pageUrl);

  assert.equal(videos.length, 1);
  assert.equal(videos[0].url, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  assert.equal(videos[0].title, 'Microsoft FINALLY Fixed the Right Click Menu');
  assert.equal(videos[0].author, 'Britec09');
  assert.equal(videos[0].thumbnailUrl, 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
  assert.equal(videos[0].compact, false);
  assert.equal(videos[0].insertionPoint.getAttribute('aria-label'), 'Share');
});

test('findYouTubeVideos extracts feed video cards', () => {
  const pageUrl = 'https://www.youtube.com/';
  const doc = new JSDOM(feedCardsHtml, { url: pageUrl }).window.document;
  const videos = findYouTubeVideos(doc, pageUrl);

  assert.equal(videos.length, 1);
  assert.equal(videos[0].url, 'https://www.youtube.com/watch?v=vid123');
  assert.equal(videos[0].title, 'Building an AI Agent');
  assert.equal(videos[0].author, 'Tech Channel');
  assert.equal(videos[0].compact, true);
});

test('findYouTubeProfile extracts channel URL, display name, and subscribe button insertion', () => {
  const pageUrl = 'https://www.youtube.com/@mkbhd/videos';
  const doc = new JSDOM(channelPageHtml, { url: pageUrl }).window.document;
  const profile = findYouTubeProfile(doc, pageUrl);

  assert.ok(profile);
  assert.equal(profile.url, 'https://www.youtube.com/@mkbhd');
  assert.equal(profile.name, 'Marques Brownlee');
  assert.equal(profile.insertionPoint.id, 'subscribe-button');
});

test('findYouTubeProfile rejects non-profile routes', () => {
  const doc = new JSDOM(channelPageHtml, { url: 'https://www.youtube.com/watch?v=123' }).window.document;
  assert.equal(findYouTubeProfile(doc, 'https://www.youtube.com/watch?v=123'), undefined);
  assert.equal(findYouTubeProfile(doc, 'https://www.youtube.com/feed/subscriptions'), undefined);
});

test('createYouTubeVideoControls reconciles and toggles with enabled state', () => {
  const pageUrl = 'https://www.youtube.com/watch?v=abc12345';
  const doc = new JSDOM(watchPageHtml, { url: pageUrl }).window.document;

  let resolve: (() => unknown) | undefined;
  const sync = createYouTubeVideoControls(doc, (_, get) => {
    resolve = get;
    const host = doc.createElement('span');
    host.dataset.laterboxControl = '';
    return host;
  });

  sync(true, pageUrl);
  sync(true, pageUrl);
  assert.equal(doc.querySelectorAll('[data-laterbox-control]').length, 1);

  const found = resolve!() as { url: string; title: string };
  assert.equal(found.url, 'https://www.youtube.com/watch?v=abc12345');

  // Disable controls
  sync(false, pageUrl);
  assert.equal(doc.querySelectorAll('[data-laterbox-control]').length, 0);
});

test('createYouTubeProfileControls reconciles and toggles with enabled state', () => {
  const pageUrl = 'https://www.youtube.com/@mkbhd';
  const doc = new JSDOM(channelPageHtml, { url: pageUrl }).window.document;

  let resolve: (() => unknown) | undefined;
  const sync = createYouTubeProfileControls(doc, (_, get) => {
    resolve = get;
    const host = doc.createElement('span');
    host.dataset.laterboxControl = '';
    return host;
  });

  sync(true, pageUrl);
  sync(true, pageUrl);
  assert.equal(doc.querySelectorAll('[data-laterbox-control]').length, 1);

  const found = resolve!() as { url: string; name: string };
  assert.equal(found.url, 'https://www.youtube.com/@mkbhd');

  // Disable controls
  sync(false, pageUrl);
  assert.equal(doc.querySelectorAll('[data-laterbox-control]').length, 0);
});

