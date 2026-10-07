export interface LinkedInProfile {root:Element;insertionPoint:HTMLElement;url:string;name:string;company?:boolean}
const excluded='[hidden],[aria-hidden="true"],nav,[role="navigation"],[aria-label="Sidebar"],[aria-label="Aside"],[data-laterbox-control]';
function visible(doc:Document,element:Element){
  if(element.closest(excluded))return false;
  for(let node:Element|null=element;node;node=node.parentElement){const style=doc.defaultView?.getComputedStyle(node);if(style?.display==='none' || style?.visibility==='hidden')return false;}
  return true;
}
function profileUrl(raw:string,page:URL){
  try{const url=new URL(raw,page);const match=url.pathname.match(/^\/(in|company)\/([^/]+)(?:\/(?:about|life|people|posts))?\/?$/);if(url.protocol==='https:' && /^(www\.)?linkedin\.com$/.test(url.hostname) && match)return {url:url.origin+'/'+match[1]+'/'+match[2]+'/',company:match[1]==='company'};}catch{}
}
function nameOf(element:Element){return element.textContent?.trim().replace(/\s+View .*verifications.*$/i,'').slice(0,500) || '';}
function action(intro:Element,doc:Document){
  const actions=Array.from(intro.querySelectorAll<HTMLElement>('button,a,[role="button"]')).filter(element=>visible(doc,element) && /^(message|connect|follow|following|open to|more|visit website)(\s|$)/i.test((element.getAttribute('aria-label') || element.textContent || '').trim()));
  return actions.find(element=>/^more(\s|$)/i.test((element.getAttribute('aria-label') || element.textContent || '').trim())) || actions.at(-1);
}
export function findLinkedInProfile(doc:Document,pageUrl:string):LinkedInProfile|undefined{
  const page=new URL(pageUrl);const identity=profileUrl(page.href,page);if(!identity)return;
  const primary=Array.from(doc.querySelectorAll('main,[role="main"],[aria-label="Primary content"]')).find(element=>visible(doc,element));
  const scope=primary || doc.body;
  const candidates=Array.from(scope.querySelectorAll('h1,h2,a[href*="/in/"],a[href*="/company/"]')).filter(element=>{
    if(!visible(doc,element) || !nameOf(element))return false;
    if(element.tagName==='H1')return true;
    return element.matches('a') && profileUrl(element.getAttribute('href')!,page)?.url===identity.url;
  }).sort((a,b)=>Number(b.tagName==='H1')-Number(a.tagName==='H1'));
  for(const nameElement of candidates){
    for(let intro=nameElement.parentElement;intro && intro!==doc.body && intro!==primary;intro=intro.parentElement){
      const insertionPoint=action(intro,doc);
      if(insertionPoint)return {root:primary || intro,insertionPoint,...identity,name:nameOf(nameElement)};
    }
  }
  // A stable name is sufficient even when LinkedIn omits all intro actions.
  const nameElement=candidates[0] as HTMLElement|undefined;
  if(nameElement)return {root:primary || nameElement.closest('section,article') || nameElement.parentElement!,insertionPoint:nameElement,...identity,name:nameOf(nameElement)};
}
export function findLinkedInProfiles(doc:Document,pageUrl:string):LinkedInProfile[]{
  const page=new URL(pageUrl);if(!/^(www\.)?linkedin\.com$/.test(page.hostname))return [];
  const pageProfile=findLinkedInProfile(doc,pageUrl);const profiles:LinkedInProfile[]=pageProfile ? [pageProfile]:[];
  const seen=new Set<Element>();
  for(const link of doc.querySelectorAll<HTMLAnchorElement>('a[href*="/in/"],a[href*="/company/"]')){
    if(!visible(doc,link) || link.closest('.feed-shared-update-v2,[componentkey^="update-card-focus"],form,[contenteditable="true"]'))continue;
    const identity=profileUrl(link.getAttribute('href')!,page);const name=nameOf(link);if(!identity || !name || identity.url===pageProfile?.url)continue;
    let root:Element|undefined;
    for(let node=link.parentElement;node && node!==doc.body;node=node.parentElement){
      const identities=new Set(Array.from(node.querySelectorAll<HTMLAnchorElement>('a[href*="/in/"],a[href*="/company/"]')).map(anchor=>profileUrl(anchor.getAttribute('href')!,page)?.url).filter(Boolean));
      if(identities.size>1)break;
      if(node.matches('li,article,section,[role="listitem"],.entity-result,.artdeco-card') || action(node,doc)){root=node;break;}
    }
    if(!root || seen.has(root) || profiles.some(profile=>profile.insertionPoint===link || profile.root===root))continue;
    seen.add(root);profiles.push({root,insertionPoint:action(root,doc) || link,...identity,name});
  }
  return profiles;
}
export function createLinkedInProfileControls(doc:Document,create:(profile:LinkedInProfile,resolve:()=>LinkedInProfile|undefined)=>HTMLElement){
  const controls=new Map<Element,{profile:LinkedInProfile;container:HTMLElement}>();
  return (enabled:boolean,pageUrl:string)=>{
    const profiles=enabled ? findLinkedInProfiles(doc,pageUrl):[];
    for(const [root,current] of controls){const profile=profiles.find(profile=>profile.root===root);if(!profile || profile.url!==current.profile.url || profile.insertionPoint!==current.profile.insertionPoint || !current.container.isConnected){current.container.remove();controls.delete(root);}}
    for(const profile of profiles){
      let current=controls.get(profile.root);
      if(!current){current={profile,container:create(profile,()=>findLinkedInProfiles(doc,doc.location.href).find(latest=>latest.root===profile.root && latest.url===profile.url))};controls.set(profile.root,current);}
      const color=doc.defaultView?.getComputedStyle(profile.insertionPoint).color;
      if(color && current.container.style.color!==color)current.container.style.color=color;
      if(profile.insertionPoint.nextElementSibling!==current.container)profile.insertionPoint.after(current.container);
    }
  };
}
