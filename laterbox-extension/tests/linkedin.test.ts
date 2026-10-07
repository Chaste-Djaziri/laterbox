import {test} from 'node:test';
import assert from 'node:assert/strict';
import {JSDOM} from 'jsdom';
import {findLinkedInPosts,createLinkedInControls} from '../src/content/linkedin-controls';
const post=(id:string)=>`<article class="feed-shared-update-v2" data-urn="urn:li:activity:${id}"><a class="update-components-actor__title">Author ${id}</a><p>Post ${id}</p><div><span><button>Like</button></span><span><button>Comment</button></span><span><button>Repost</button></span><span><button aria-label="Send">Send</button></span></div></article>`;
test('LinkedIn feed and details resolve separate canonical posts and action slots',()=>{
  for(const url of ['https://www.linkedin.com/feed/','https://www.linkedin.com/feed/update/urn:li:activity:123/']){
    const doc=new JSDOM(post('123')+post('456'),{url}).window.document;
    const posts=findLinkedInPosts(doc,url);assert.equal(posts.length,2);
    assert.equal(posts[0].url,'https://www.linkedin.com/feed/update/urn:li:activity:123/');assert.equal(posts[1].author,'Author 456');
    assert.equal(posts[0].insertionPoint.tagName,'SPAN');assert.equal(posts[0].share.textContent,'Send');
  }
});
test('LinkedIn controls reconcile recycled posts, disable, and never resolve stale targets',()=>{
  const doc=new JSDOM(post('123'),{url:'https://www.linkedin.com/feed/'}).window.document;
  let resolve:(()=>unknown)|undefined;
  const sync=createLinkedInControls(doc,(_,current)=>{resolve=current;const node=doc.createElement('span');node.dataset.laterboxControl='';return node;});
  sync(true,doc.location.href);const first=doc.querySelector('[data-laterbox-control]');const stale=resolve!;
  sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,1);
  doc.querySelector('article')!.setAttribute('data-urn','urn:li:activity:456');assert.equal(stale(),undefined);
  sync(true,doc.location.href);assert.equal(first!.isConnected,false);assert.equal((resolve!() as {url:string}).url,'https://www.linkedin.com/feed/update/urn:li:activity:456/');
  sync(false,doc.location.href);assert.equal(doc.querySelector('[data-laterbox-control]'),null);
});
test('LinkedIn skips missing actions, ambiguous links, unrelated domains and hidden posts',()=>{
  const doc=new JSDOM(post('123'),{url:'https://www.linkedin.com/feed/'}).window.document;
  assert.equal(findLinkedInPosts(doc,'https://example.com/').length,0);
  doc.querySelector('article')!.setAttribute('hidden','');assert.equal(findLinkedInPosts(doc,doc.location.href).length,0);
  doc.querySelector('article')!.removeAttribute('hidden');doc.querySelector('article')!.removeAttribute('data-urn');
  doc.querySelector('article')!.insertAdjacentHTML('afterbegin','<a href="/posts/author_activity-123">Post</a>');assert.equal(findLinkedInPosts(doc,doc.location.href).length,1);
  doc.querySelector('article')!.insertAdjacentHTML('afterbegin','<a href="/posts/other_activity-456">Other</a>');assert.equal(findLinkedInPosts(doc,doc.location.href).length,0);
  doc.querySelectorAll('button').forEach(button=>button.remove());assert.equal(findLinkedInPosts(doc,doc.location.href).length,0);
});
