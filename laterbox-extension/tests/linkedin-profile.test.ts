import {test} from 'node:test';
import assert from 'node:assert/strict';
import {JSDOM} from 'jsdom';
import {findLinkedInProfile,createLinkedInProfileControls} from '../src/content/linkedin-profile';
const markup='<aside><a href="/in/person/">Sidebar Person</a></aside><main><section><a href="/in/person/"><img></a><a href="/in/person/">Profile Person View Person’s verifications</a><p>Designer and developer</p><div><button>Message</button><button aria-label="More">…</button></div></section><section><h2>Experience</h2><p>Visible career details</p></section></main>';
test('profile button uses canonical profile, primary content, and intro actions',()=>{
  const doc=new JSDOM(markup,{url:'https://www.linkedin.com/in/person/?tracking=1'}).window.document;
  const profile=findLinkedInProfile(doc,doc.location.href)!;
  assert.equal(profile.name,'Profile Person');assert.equal(profile.url,'https://www.linkedin.com/in/person/');assert.equal(profile.root.tagName,'MAIN');assert.equal(profile.insertionPoint.getAttribute('aria-label'),'More');
  assert.equal(findLinkedInProfile(doc,'https://www.linkedin.com/feed/'),undefined);assert.equal(findLinkedInProfile(doc,'https://www.linkedin.com/in/person/edit/'),undefined);
});
test('profile controls avoid duplicates, respect settings and reject stale navigation',()=>{
  const dom=new JSDOM(markup,{url:'https://www.linkedin.com/in/person/'});const doc=dom.window.document;
  let resolve:(()=>unknown)|undefined;
  const sync=createLinkedInProfileControls(doc,(_,get)=>{resolve=get;const host=doc.createElement('span');host.dataset.laterboxControl='';return host;});
  sync(true,doc.location.href);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,1);
  dom.reconfigure({url:'https://www.linkedin.com/in/another/'});assert.equal(resolve!(),undefined);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
  dom.reconfigure({url:'https://www.linkedin.com/in/person/'});sync(true,doc.location.href);sync(false,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
});
test('legacy h1 profiles and SDUI primary-content regions qualify; hidden profiles do not',()=>{
  const doc=new JSDOM('<div aria-label="Primary content"><section><h1>Person</h1><button>Connect</button></section></div>',{url:'https://www.linkedin.com/in/person/'}).window.document;
  assert.equal(findLinkedInProfile(doc,doc.location.href)?.name,'Person');doc.querySelector('section')!.setAttribute('hidden','');assert.equal(findLinkedInProfile(doc,doc.location.href),undefined);
});
