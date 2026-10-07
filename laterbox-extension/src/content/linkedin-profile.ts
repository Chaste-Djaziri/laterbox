export interface LinkedInProfile {root:Element;insertionPoint:HTMLElement;url:string;name:string}
export function findLinkedInProfile(doc:Document,pageUrl:string):LinkedInProfile|undefined{
  const page=new URL(pageUrl);
  if(!/^(www\.)?linkedin\.com$/.test(page.hostname) || !/^\/in\/[^/]+\/?$/.test(page.pathname))return;
  const url=page.origin+page.pathname.replace(/\/?$/,'/');
  const primary=doc.querySelector('main,[role="main"],[aria-label="Primary content"]');
  const scope=primary || doc.body;
  const visible=(element:Element)=>!element.closest('[hidden],[aria-hidden="true"],nav,aside,[role="dialog"],[data-laterbox-control]');
  const nameElement=Array.from(scope.querySelectorAll('h1,a[href*="/in/"]')).find(element=>{
    if(!visible(element) || !element.textContent?.trim())return false;
    if(element.tagName==='H1')return true;
    try{return new URL(element.getAttribute('href')!,page).pathname.replace(/\/$/,'')===page.pathname.replace(/\/$/,'');}catch{return false;}
  });
  if(!nameElement)return;
  const name=nameElement.textContent!.trim().replace(/\s+View .*verifications.*$/i,'').slice(0,500);
  for(let intro=nameElement.parentElement;intro && intro!==doc.body;intro=intro.parentElement){
    const actions=Array.from(intro.querySelectorAll<HTMLElement>('button,a,[role="button"]')).filter(element=>visible(element) && /^(message|connect|follow|open to|more)(\s|$)/i.test((element.getAttribute('aria-label') || element.textContent || '').trim()));
    if(actions.length){const insertionPoint=actions.find(element=>/^(more)(\s|$)/i.test((element.getAttribute('aria-label') || element.textContent || '').trim())) || actions.at(-1)!;return {root:primary || intro,insertionPoint,url,name};}
    if(intro===primary)break;
  }
}
export function createLinkedInProfileControls(doc:Document,create:(profile:LinkedInProfile,resolve:()=>LinkedInProfile|undefined)=>HTMLElement){
  let current:{profile:LinkedInProfile;container:HTMLElement}|undefined;
  return (enabled:boolean,pageUrl:string)=>{
    const profile=enabled ? findLinkedInProfile(doc,pageUrl):undefined;
    if(current && (!profile || profile.url!==current.profile.url || profile.insertionPoint!==current.profile.insertionPoint || !current.container.isConnected)){current.container.remove();current=undefined;}
    if(!profile)return;
    if(!current){current={profile,container:create(profile,()=>{const latest=findLinkedInProfile(doc,doc.location.href);return latest?.url===profile.url ? latest:undefined;})};}
    const color=doc.defaultView?.getComputedStyle(profile.insertionPoint).color;
    if(color && current.container.style.color!==color)current.container.style.color=color;
    if(profile.insertionPoint.nextElementSibling!==current.container)profile.insertionPoint.after(current.container);
  };
}
