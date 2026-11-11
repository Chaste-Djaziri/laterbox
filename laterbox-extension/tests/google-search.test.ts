import { test } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import {
  isGoogleSearch,
  extractGoogleTargetUrl,
  findGoogleSearchResults,
  createGoogleSearchControls,
} from '../src/content/google-search-controls';

const searchResultHtml = (id: string, url: string, title: string, snippet: string) => `
<div class="MjjYud" id="res-${id}">
  <div class="g">
    <div class="yuRUbf">
      <a href="${url}">
        <br>
        <h3 class="LC20lb">${title}</h3>
        <div><span>cite info</span></div>
      </a>
      <div class="B6fmyf"><button aria-haspopup="menu">⋮</button></div>
    </div>
    <div class="VwiC3b">${snippet}</div>
  </div>
</div>`;

const searchResultWithSitelinks = `
<div class="MjjYud" id="res-main">
  <div class="g">
    <div class="yuRUbf">
      <a href="https://www.microsoft.com/en-us">
        <h3 class="LC20lb">Microsoft – AI, Cloud, Productivity</h3>
      </a>
    </div>
    <div class="VwiC3b">Main Microsoft snippet text.</div>
    <div class="StTG7b">
      <table class="mslg">
        <tr>
          <td class="usJj9c">
            <h3><a href="https://support.microsoft.com">Support</a></h3>
            <div>Help with products</div>
          </td>
          <td class="usJj9c">
            <h3><a href="https://www.microsoft.com/microsoft-365">Microsoft 365</a></h3>
            <div>Office apps</div>
          </td>
        </tr>
      </table>
    </div>
  </div>
</div>`;

const videoSearchResultHtml = `
<div class="MjjYud" id="res-video">
  <div class="g">
    <div class="yuRUbf">
      <div class="B6fmyf"><button>⋮</button></div>
      <div class="TbwUpd">www.youtube.com › watch</div>
    </div>
    <div class="n0jPhd">
      <a href="https://www.youtube.com/watch?v=12345" id="video-anchor">
        <h3 class="LC20lb">Microsoft FINALLY Fixed the Right Click Menu</h3>
      </a>
    </div>
    <div class="video-body">
      <div class="thumbnail">12:46</div>
      <div class="VwiC3b">Video description snippet...</div>
    </div>
  </div>
</div>`;

test('isGoogleSearch accurately validates Google Search URLs', () => {
  assert.equal(isGoogleSearch('https://www.google.com/search?q=laterbox'), true);
  assert.equal(isGoogleSearch('https://google.com/search?q=test'), true);
  assert.equal(isGoogleSearch('https://www.google.co.uk/search?q=react'), true);
  assert.equal(isGoogleSearch('https://www.google.de/search?q=news'), true);
  assert.equal(isGoogleSearch('https://www.google.com/?q=hello'), true);
  assert.equal(isGoogleSearch('https://example.com/search?q=test'), false);
  assert.equal(isGoogleSearch('https://www.google.com/about'), false);
  assert.equal(isGoogleSearch('https://maps.google.com/'), false);
});

test('extractGoogleTargetUrl extracts direct and redirect URLs, rejecting internal Google links', () => {
  const base = 'https://www.google.com/search?q=test';
  assert.equal(
    extractGoogleTargetUrl('https://example.com/article', base),
    'https://example.com/article',
  );
  assert.equal(
    extractGoogleTargetUrl('/url?q=https%3A%2F%2Fgithub.com%2Flaterbox&sa=U', base),
    'https://github.com/laterbox',
  );
  assert.equal(
    extractGoogleTargetUrl('https://www.google.com/search?q=more', base),
    null,
  );
  assert.equal(
    extractGoogleTargetUrl('https://accounts.google.com/signin', base),
    null,
  );
  assert.equal(extractGoogleTargetUrl('javascript:void(0)', base), null);
  assert.equal(extractGoogleTargetUrl('#', base), null);
});

test('findGoogleSearchResults extracts organic results with titles, URLs, and snippets', () => {
  const pageUrl = 'https://www.google.com/search?q=testing';
  const html =
    searchResultHtml('1', 'https://laterbox.dev/guide', 'LaterBox Guide', 'Everything you need.') +
    searchResultHtml('2', '/url?q=https%3A%2F%2Fgithub.com%2Ftest', 'GitHub Repo', 'Open source repo.');

  const doc = new JSDOM(html, { url: pageUrl }).window.document;
  const results = findGoogleSearchResults(doc, pageUrl);

  assert.equal(results.length, 2);
  assert.equal(results[0].title, 'LaterBox Guide');
  assert.equal(results[0].url, 'https://laterbox.dev/guide');
  assert.equal(results[0].snippet, 'Everything you need.');
  assert.equal(results[0].insertionPoint.tagName, 'DIV');

  assert.equal(results[1].title, 'GitHub Repo');
  assert.equal(results[1].url, 'https://github.com/test');
  assert.equal(results[1].snippet, 'Open source repo.');
});

test('findGoogleSearchResults excludes sitelinks and sub-pages, keeping only the main link', () => {
  const pageUrl = 'https://www.google.com/search?q=microsoft';
  const doc = new JSDOM(searchResultWithSitelinks, { url: pageUrl }).window.document;
  const results = findGoogleSearchResults(doc, pageUrl);

  // Must only extract the primary search result, NOT sub-pages like Support or Microsoft 365
  assert.equal(results.length, 1);
  assert.equal(results[0].title, 'Microsoft – AI, Cloud, Productivity');
  assert.equal(results[0].url, 'https://www.microsoft.com/en-us');
});

test('findGoogleSearchResults aligns correctly on Video tab results directly beneath the title', () => {
  const pageUrl = 'https://www.google.com/search?q=microsoft&tbm=vid';
  const doc = new JSDOM(videoSearchResultHtml, { url: pageUrl }).window.document;
  const results = findGoogleSearchResults(doc, pageUrl);

  assert.equal(results.length, 1);
  assert.equal(results[0].title, 'Microsoft FINALLY Fixed the Right Click Menu');
  assert.equal(results[0].url, 'https://www.youtube.com/watch?v=12345');
  // Insertion point must be the title anchor (id="video-anchor"), NOT the breadcrumb (.yuRUbf)
  assert.equal(results[0].insertionPoint.id, 'video-anchor');
});

test('createGoogleSearchControls reconciles controls, avoids duplicates, and responds to enabled state', () => {
  const pageUrl = 'https://www.google.com/search?q=testing';
  const html = searchResultHtml('1', 'https://laterbox.dev', 'LaterBox App', 'Capture anything.');
  const doc = new JSDOM(html, { url: pageUrl }).window.document;

  let resolve: (() => unknown) | undefined;
  const sync = createGoogleSearchControls(doc, (_, get) => {
    resolve = get;
    const host = doc.createElement('span');
    host.dataset.laterboxControl = '';
    return host;
  });

  sync(true, pageUrl);
  sync(true, pageUrl);
  assert.equal(doc.querySelectorAll('[data-laterbox-control]').length, 1);

  const found = resolve!() as { url: string; title: string };
  assert.equal(found.url, 'https://laterbox.dev/');
  assert.equal(found.title, 'LaterBox App');

  // Disable controls
  sync(false, pageUrl);
  assert.equal(doc.querySelectorAll('[data-laterbox-control]').length, 0);
});

test('non-Google pages yield zero search results', () => {
  const html = searchResultHtml('1', 'https://laterbox.dev', 'LaterBox', 'Snippet');
  const doc = new JSDOM(html, { url: 'https://bing.com/search?q=test' }).window.document;
  assert.equal(findGoogleSearchResults(doc, 'https://bing.com/search?q=test').length, 0);
});
