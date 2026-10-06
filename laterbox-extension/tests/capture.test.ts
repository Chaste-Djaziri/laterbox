import { test } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
(globalThis as any).chrome={};
const {extractRenderedPage,buildScrollToTextFragment,captureFromPage}=await import('../src/lib/page');
const {findSocialPosts}=await import('../src/content/social');
function dom(html:string,url='https://example.com/read') {
 const w=new JSDOM(html,{url}).window;
 for(const key of ['document','window','location','Node','Element','NodeFilter','getComputedStyle']) Object.defineProperty(globalThis,key,{value:(w as any)[key],configurable:true});
 Object.defineProperty(globalThis,'navigator',{value:w.navigator,configurable:true});return w;
}
test('rendered extraction preserves structure and resolves relative metadata',()=>{dom('<title>Example</title><meta name="author" content="Writer"><meta property="og:image" content="/cover.jpg"><article><h1>Heading</h1><ul><li>One</li></ul><blockquote>Quote</blockquote><a href="../source">Link</a><img src="/image.jpg" alt="Photo"><pre>const a = 1;</pre><form>Secret<input value="private"></form><p hidden>Hidden</p></article>');const p=extractRenderedPage();assert.equal(p.author,'Writer');assert.equal(p.previewImageUrl,'https://example.com/cover.jpg');for(const text of ['# Heading','- One','> Quote','[Link](https://example.com/source)','![Photo](https://example.com/image.jpg)','```'])assert.ok(p.markdown?.includes(text),text);assert.ok(!p.markdown?.includes('Secret'));assert.ok(!p.markdown?.includes('Hidden'));});
test('missing metadata and unsupported root degrade safely; byte limit marked',()=>{dom('<article>'+ 'é'.repeat(120000)+'</article>');const p=extractRenderedPage();assert.ok(new TextEncoder().encode(p.markdown).length<=204800);assert.equal(p.truncated,true);assert.equal(extractRenderedPage('.missing').markdown,'');});
test('Apple fragment, anchors, punctuation, Unicode and long quotes',()=>{assert.equal(buildScrollToTextFragment('https://www.apple.com/','Endless entertainment.'),'https://www.apple.com/#:~:text=Endless%20entertainment.');assert.equal(buildScrollToTextFragment('https://example.com/#section:~:text=old','a-b, café!'),'https://example.com/#section:~:text=a%2Db%2C%20caf%C3%A9%21');assert.ok(buildScrollToTextFragment('https://example.com',Array(1000).fill('word').join(' ')).length<100);assert.throws(()=>captureFromPage({url:'https://example.com/'+ 'a'.repeat(8200),title:'',selection:''}));});
test('multi-element quotes retain exact text separate from Markdown',()=>{const w=dom('<article>Before <b>Hello</b> <i>world</i> after</article>');const r=w.document.createRange();r.setStart(w.document.querySelector('b')!.firstChild!,0);r.setEnd(w.document.querySelector('i')!.firstChild!,5);w.getSelection()!.addRange(r);const p=extractRenderedPage();assert.equal(p.selection,'Hello world');assert.equal(p.selector?.exact,'Hello world');const c=captureFromPage(p,'highlight');assert.equal(c.text,'Hello world');assert.ok(c.markdown?.includes('**Hello**'));});
for(const [site,url,html] of [
 ['X','https://x.com/home','<article data-testid="tweet"><a href="/person/status/123"><time datetime="2026-10-06"></time></a><p>Post</p></article>'],
 ['Reddit','https://www.reddit.com/','<shreddit-post permalink="/r/test/comments/abc/title" author="writer">Post</shreddit-post>'],
 ['LinkedIn','https://www.linkedin.com/feed/','<div class="feed-shared-update-v2" data-urn="urn:li:activity:123">Post</div>'],
 ['Instagram','https://www.instagram.com/','<article><a href="/p/abc/">Post</a></article>'],
 ['Facebook','https://www.facebook.com/','<div role="article"><a href="/person/posts/123">Post</a></div>'],
] as const) test(`${site}: targeted posts, dynamic additions, missing permalink fallback`,()=>{const w=dom(html+html,url);let posts=findSocialPosts(w.document,url);assert.equal(posts.length,2);assert.equal(posts[0].site,site);w.document.body.insertAdjacentHTML('beforeend',html);assert.equal(findSocialPosts(w.document,url).length,3);w.document.body.innerHTML='<article><p>Changed unsupported layout</p></article>';assert.equal(findSocialPosts(w.document,url).length,0);});

test('serialized DOM fallback distinguishes repeated quotes across elements',async()=>{const w=dom('<p>First Hello <b>world</b> wrong</p><p>Second Hello <b>world</b> correct</p><form>Private</form>');(w.HTMLElement.prototype as any).scrollIntoView=()=>{};const source=readFileSync(new URL('../src/lib/highlight.ts',import.meta.url),'utf8').replace(/^import.*;$/m,'').replace(/export /g,'');const js=ts.transpileModule(source,{compilerOptions:{target:ts.ScriptTarget.ES2022}}).outputText;const injected=new Function('selector',js+';return locateAndSelect(selector);');assert.equal(injected({exact:'Hello world',prefix:'Second ',suffix:' correct'}),true);assert.equal(w.getSelection()?.toString(),'Hello world');assert.equal(w.getSelection()?.anchorNode?.parentElement?.closest('p')?.textContent,'Second Hello world correct');});
