export interface XProfile {root:Element;insertionPoint:HTMLElement;url:string;name:string}
export function findXProfile(doc:Document,pageUrl:string):XProfile|undefined{
  const page=new URL(pageUrl);if(!/^(www\.)?(x|twitter)\.com$/.test(page.hostname))return;
  const match=page.pathname.match(/^\/([A-Za-z0-9_]{1,15})(?:\/(?:with_replies|media|highlights|articles))?\/?$/);
  if(!match || /^(home|explore|notifications|messages|settings|search|compose|i|login|logout|signup|tos|privacy)$/i.test(match[1]))return;
  const primary=doc.querySelector('main [data-testid="primaryColumn"],[data-testid="primaryColumn"],main');if(!primary)return;
  // Profile-specific metadata prevents injecting on routes that are not profiles.
  const name=Array.from(primary.querySelectorAll<HTMLElement>('[data-testid="UserName"]')).find(element=>!element.closest('article,[hidden],[aria-hidden="true"]'));
  if(!name)return;
  const displayName=name.querySelector('span')?.textContent?.trim() || name.textContent?.trim() || '@'+match[1];
  const actions=Array.from(primary.querySelectorAll<HTMLElement>('button,[role="button"],a')).filter(element=>!element.closest('article,[hidden],[aria-hidden="true"],[data-laterbox-control]') && (/^(follow|following|edit profile|message|more)(\b|$)/i.test(element.getAttribute('aria-label') || element.textContent?.trim() || '') || element.matches('[data-testid="userActions"],[data-testid="sendDMFromProfile"]')));
  const anchor=actions.find(element=>element.matches('[data-testid="userActions"]')) || actions[0] || name;
  let insertionPoint=anchor;
  if(anchor!==name && anchor.parentElement?.closest('button,[role="button"],a'))insertionPoint=anchor.parentElement.closest<HTMLElement>('button,[role="button"],a')!;
  let root:Element=name;
  for(let node=name.parentElement;node && primary.contains(node);node=node.parentElement){if(node.querySelector('article[data-testid="tweet"]'))break;root=node;if(node===primary)break;}
  return {root,insertionPoint,url:page.origin+'/'+match[1],name:displayName.slice(0,500)};
}
export function createXProfileControls(doc:Document,create:(profile:XProfile,resolve:()=>XProfile|undefined)=>HTMLElement){
  let control:{profile:XProfile;container:HTMLElement}|undefined;
  return (enabled:boolean,pageUrl:string)=>{
    const profile=enabled ? findXProfile(doc,pageUrl):undefined;
    if(control && (!profile || profile.url!==control.profile.url || profile.insertionPoint!==control.profile.insertionPoint || !control.container.isConnected)){control.container.remove();control=undefined;}
    if(!profile)return;
    if(!control)control={profile,container:create(profile,()=>{const current=findXProfile(doc,doc.location.href);return current?.url===profile.url ? current:undefined;})};
    const color=doc.defaultView?.getComputedStyle(profile.insertionPoint).color;if(color && control.container.style.color!==color)control.container.style.color=color;
    if(profile.insertionPoint.nextElementSibling!==control.container)profile.insertionPoint.after(control.container);
  };
}
