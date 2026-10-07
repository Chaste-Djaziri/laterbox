import {test} from 'node:test';
import assert from 'node:assert/strict';
import {JSDOM} from 'jsdom';
import {findXProfile,createXProfileControls} from '../src/content/x-profile';
const markup='<main><div data-testid="primaryColumn"><section><button data-testid="userActions" aria-label="More"></button><div data-testid="UserName"><span>Profile Person</span><span>@person</span></div><div data-testid="UserDescription">Visible bio</div><button>Follow</button></section><article data-testid="tweet"><div data-testid="UserName">Other author</div><p>Timeline post</p></article></div></main>';
test('X and Twitter profile tabs use canonical sources and exclude timeline posts',()=>{
  for(const url of ['https://x.com/person','https://twitter.com/person/media?tracking=1']){
    const doc=new JSDOM(markup,{url}).window.document;const profile=findXProfile(doc,url)!;
    assert.equal(profile.name,'Profile Person');assert.equal(profile.url,new URL(url).origin+'/person');assert.equal(profile.root.tagName,'SECTION');assert.equal(profile.root.querySelector('article'),null);assert.equal(profile.insertionPoint.getAttribute('data-testid'),'userActions');
  }
});
test('X profile controls reconcile navigation, respect settings, and avoid duplicates',()=>{
  const dom=new JSDOM(markup,{url:'https://x.com/person'});const doc=dom.window.document;let resolve:(()=>unknown)|undefined;
  const sync=createXProfileControls(doc,(_,get)=>{resolve=get;const host=doc.createElement('span');host.dataset.laterboxControl='';return host;});
  sync(true,doc.location.href);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,1);
  dom.reconfigure({url:'https://x.com/home'});assert.equal(resolve!(),undefined);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
  dom.reconfigure({url:'https://x.com/person'});sync(true,doc.location.href);sync(false,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
});
test('missing actions fall back to profile name; unrelated routes and post authors are excluded',()=>{
  const doc=new JSDOM(markup,{url:'https://x.com/person'}).window.document;doc.querySelectorAll('button').forEach(button=>button.remove());assert.equal(findXProfile(doc,doc.location.href)?.insertionPoint.getAttribute('data-testid'),'UserName');
  assert.equal(findXProfile(doc,'https://x.com/person/status/123'),undefined);assert.equal(findXProfile(doc,'https://x.com/settings'),undefined);assert.equal(findXProfile(doc,'https://example.com/person'),undefined);
  doc.querySelector('section')!.remove();assert.equal(findXProfile(doc,doc.location.href),undefined);
});
