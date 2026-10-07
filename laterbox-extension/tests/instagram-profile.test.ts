import {test} from 'node:test';
import assert from 'node:assert/strict';
import {JSDOM} from 'jsdom';
import {findInstagramProfile,createInstagramProfileControls} from '../src/content/instagram-profile';
const markup='<main><header><h2>profile.person</h2><div><button>Follow</button><button>Message</button></div><p>Visible biography</p><a href="/profile.person/followers/">100 followers</a></header><article><a href="/p/123/">Grid post</a></article></main>';
test('Instagram profile captures header and canonical URL without the post grid',()=>{
  const doc=new JSDOM(markup,{url:'https://www.instagram.com/profile.person/?tracking=1'}).window.document;
  const profile=findInstagramProfile(doc,doc.location.href)!;assert.equal(profile.name,'profile.person');assert.equal(profile.url,'https://www.instagram.com/profile.person/');assert.equal(profile.root.tagName,'HEADER');assert.equal(profile.root.querySelector('article'),null);assert.equal(profile.insertionPoint.textContent,'Message');
});
test('Instagram profile controls avoid duplicates and reject stale navigation',()=>{
  const dom=new JSDOM(markup,{url:'https://www.instagram.com/profile.person/'});const doc=dom.window.document;let resolve:(()=>unknown)|undefined;
  const sync=createInstagramProfileControls(doc,(_,get)=>{resolve=get;const host=doc.createElement('span');host.dataset.laterboxControl='';return host;});
  sync(true,doc.location.href);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,1);
  dom.reconfigure({url:'https://www.instagram.com/reels/'});assert.equal(resolve!(),undefined);sync(true,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
  dom.reconfigure({url:'https://www.instagram.com/profile.person/'});sync(true,doc.location.href);sync(false,doc.location.href);assert.equal(doc.querySelectorAll('[data-laterbox-control]').length,0);
});
test('actionless profiles use the name while non-profile routes and hidden headers are excluded',()=>{
  const doc=new JSDOM(markup,{url:'https://www.instagram.com/profile.person/'}).window.document;doc.querySelectorAll('button').forEach(button=>button.remove());assert.equal(findInstagramProfile(doc,doc.location.href)?.insertionPoint.tagName,'H2');
  for(const path of ['/explore/','/accounts/','/p/123/','/reels/'])assert.equal(findInstagramProfile(doc,'https://www.instagram.com'+path),undefined);
  doc.querySelector('header')!.setAttribute('hidden','');assert.equal(findInstagramProfile(doc,doc.location.href),undefined);
});
