import type {XProfile} from './x-profile';
const reserved=/^(accounts|about|developer|direct|explore|legal|p|reel|reels|stories|web|challenge|emails|privacy|settings)$/i;
export function findInstagramProfile(doc:Document,pageUrl:string):XProfile|undefined{
  const page=new URL(pageUrl);const match=page.pathname.match(/^\/([A-Za-z0-9._]{1,30})\/?$/);
  if(!/^(www\.)?instagram\.com$/.test(page.hostname) || !match || reserved.test(match[1]))return;
  const primary=doc.querySelector('main,[role="main"]');if(!primary)return;
  const headings=Array.from(primary.querySelectorAll<HTMLElement>('h1,h2,header a')).filter(element=>!element.closest('[hidden],[aria-hidden="true"],[role="dialog"],article,[data-laterbox-control]') && element.textContent?.trim());
  const username=headings.find(element=>element.textContent?.trim().replace(/^@/,'').toLowerCase()===match[1].toLowerCase());
  const header=primary.querySelector('header');
  const name=username || (header ? headings.find(element=>header.contains(element)):undefined);
  if(!name)return;
  let root:Element=header || name.parentElement!;
  if(!header){
    for(let node=name.parentElement;node && node!==primary;node=node.parentElement){
      if(node.querySelector('article,a[href*="/p/"],a[href*="/reel/"]'))break;
      root=node;
      if(node.querySelector('a[href$="/followers/"],a[href$="/following/"]'))break;
    }
  }
  const actions=Array.from(root.querySelectorAll<HTMLElement>('button,[role="button"],a')).filter(element=>!element.closest('[hidden],[aria-hidden="true"],[data-laterbox-control]') && /^(follow|following|message|edit profile|options|more|share profile)(\b|$)/i.test((element.getAttribute('aria-label') || element.textContent || '').trim()));
  return {root,insertionPoint:actions.at(-1) || name,url:page.origin+'/'+match[1]+'/',name:match[1]};
}
export function createInstagramProfileControls(doc:Document,create:(profile:XProfile,resolve:()=>XProfile|undefined)=>HTMLElement){
  let control:{profile:XProfile;container:HTMLElement}|undefined;
  return (enabled:boolean,pageUrl:string)=>{
    const profile=enabled ? findInstagramProfile(doc,pageUrl):undefined;
    if(control && (!profile || profile.url!==control.profile.url || profile.insertionPoint!==control.profile.insertionPoint || !control.container.isConnected)){control.container.remove();control=undefined;}
    if(!profile)return;
    if(!control)control={profile,container:create(profile,()=>{const current=findInstagramProfile(doc,doc.location.href);return current?.url===profile.url ? current:undefined;})};
    const color=doc.defaultView?.getComputedStyle(profile.insertionPoint).color;if(color && control.container.style.color!==color)control.container.style.color=color;
    if(profile.insertionPoint.nextElementSibling!==control.container)profile.insertionPoint.after(control.container);
  };
}
