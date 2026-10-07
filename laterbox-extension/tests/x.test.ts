import {test} from 'node:test';
import assert from 'node:assert/strict';
import {JSDOM} from 'jsdom';
import {findXPosts,createXControls} from '../src/content/x-controls';
const card=(id:string)=>`<article data-testid="tweet"><div data-testid="User-Name">Author ${id}</div><a href="/author/status/${id}?s=20"><time datetime="2026-10-07T10:00:00Z">Now</time></a><div data-testid="tweetText">Post ${id}</div><div data-testid="quoteTweet"><a href="/other/status/999"><time>Quoted</time></a><p>Quoted author and text</p></div><div role="group"><span><button data-testid="reply">Reply</button></span><span><button data-testid="like">Like</button></span><span><button aria-label="Share post">Share</button></span></div></article>`;
test('X and Twitter feeds and details preserve each main post instead of quoted sources',()=>{
  for(const url of ['https://x.com/home','https://twitter.com/author/status/123']){
    const doc=new JSDOM(card('123')+card('456'),{url}).window.document;const posts=findXPosts(doc,url);
    assert.equal(posts.length,2);assert.equal(new URL(posts[0].url).pathname,'/author/status/123');assert.equal(new URL(posts[0].url).search,'');assert.equal(posts[1].author,'Author 456');assert.equal(posts[0].publishedAt,'2026-10-07T10:00:00Z');assert.equal(posts[0].insertionPoint.tagName,'SPAN');
  }
});
test('X controls reconcile navigation and recycled cards without duplicates',()=>{
  const doc=new JSDOM(card('123'),{url:'https://x.com/home'}).window.document;let resolve:(()=>unknown)|undefined;
  const sync=createXControls(doc,(_,get)=>{resolve=get;const host=doc.createElement('span');host.dataset.laterboxControl='';return host;});
  sync(true,doc.location.href);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,1);const stale=resolve!;
  doc.querySelector('a')!.setAttribute('href','/author/status/456');assert.equal(stale(),undefined);sync(true,doc.location.href);assert.match((resolve!() as {url:string}).url,/456$/);
  sync(false,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
});
test('unsupported domains, missing source timestamps and missing native action rows omit controls',()=>{
  const doc=new JSDOM(card('123'),{url:'https://x.com/home'}).window.document;
  assert.equal(findXPosts(doc,'https://example.com/').length,0);doc.querySelector('a')!.remove();assert.equal(findXPosts(doc,doc.location.href).length,0);
  doc.body.innerHTML=card('123');doc.querySelector('[role="group"]')!.remove();assert.equal(findXPosts(doc,doc.location.href).length,0);
});
