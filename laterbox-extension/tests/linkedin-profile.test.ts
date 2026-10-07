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
  dom.reconfigure({url:'https://www.linkedin.com/in/another/'});assert.equal(resolve!(),undefined);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,1); // The still-rendered old person is now a card with its original URL.
  assert.equal((resolve!() as {url:string}).url,'https://www.linkedin.com/in/person/');
  dom.reconfigure({url:'https://www.linkedin.com/in/person/'});sync(true,doc.location.href);sync(false,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
});
test('legacy h1 profiles and SDUI primary-content regions qualify; hidden profiles do not',()=>{
  const doc=new JSDOM('<div aria-label="Primary content"><section><h1>Person</h1><button>Connect</button></section></div>',{url:'https://www.linkedin.com/in/person/'}).window.document;
  assert.equal(findLinkedInProfile(doc,doc.location.href)?.name,'Person');doc.querySelector('section')!.setAttribute('hidden','');assert.equal(findLinkedInProfile(doc,doc.location.href),undefined);
});

test('profile name fallback appears without More or connection actions',()=>{
  const doc=new JSDOM('<main><section><h1>Person</h1><p>Designer</p></section></main>',{url:'https://www.linkedin.com/in/person/'}).window.document;
  const profile=findLinkedInProfile(doc,doc.location.href)!;assert.equal(profile.insertionPoint.tagName,'H1');assert.equal(profile.name,'Person');
});
test('company pages and company tabs canonicalize to the company profile',()=>{
  const doc=new JSDOM('<main><section><h1>Example Company</h1><button>Follow</button></section><section><h2>About</h2><p>Company description</p></section></main>',{url:'https://www.linkedin.com/company/example/about/?tracking=1'}).window.document;
  const profile=findLinkedInProfile(doc,doc.location.href)!;assert.equal(profile.url,'https://www.linkedin.com/company/example/');assert.equal(profile.company,true);assert.equal(profile.name,'Example Company');
});
test('person and company cards get distinct buttons and never capture a whole results list',async()=>{
  const {findLinkedInProfiles}=await import('../src/content/linkedin-profile');
  const doc=new JSDOM('<main><ul><li><a href="/in/person/"><img></a><a href="/in/person/">Person</a><p>Designer</p><button>Connect</button></li><li><a href="/company/example/">Example</a><p>Company description</p><button>Follow</button></li></ul></main>',{url:'https://www.linkedin.com/search/results/all/'}).window.document;
  const profiles=findLinkedInProfiles(doc,doc.location.href);assert.equal(profiles.length,2);assert.ok(profiles.every(profile=>profile.root.tagName==='LI'));assert.equal(profiles[1].company,true);
  const sync=createLinkedInProfileControls(doc,()=>{const host=doc.createElement('span');host.dataset.laterboxControl='';return host;});sync(true,doc.location.href);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,2);sync(false,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
});
