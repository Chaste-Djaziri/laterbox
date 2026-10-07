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
  return {root,insertionPoint:name,url:page.origin+'/'+match[1]+'/',name:match[1]};
}
export function createInstagramProfileControls(doc:Document,create:(profile:XProfile,resolve:()=>XProfile|undefined)=>HTMLElement){
  let control:{profile:XProfile;container:HTMLElement}|undefined;
  return (enabled:boolean,pageUrl:string)=>{
    const profile=enabled ? findInstagramProfile(doc,pageUrl):undefined;
    if(control && (!profile || profile.url!==control.profile.url || profile.insertionPoint!==control.profile.insertionPoint || !control.container.isConnected)){control.container.remove();control=undefined;}
    if(!profile)return;
    if(!control)control={profile,container:create(profile,()=>{const current=findInstagramProfile(doc,doc.location.href);return current?.url===profile.url ? current:undefined;})};
    let dark=false;
    for(let node:Element|null=profile.insertionPoint;node;node=node.parentElement){
      const background=doc.defaultView?.getComputedStyle(node).backgroundColor;
      const rgba=background?.match(/[\d.]+/g)?.map(Number);
      if(rgba && rgba.length>=3 && (rgba[3]===undefined || rgba[3]>.5)){dark=(rgba[0]*.299+rgba[1]*.587+rgba[2]*.114)<140;break;}
      if(node===doc.documentElement){
        const text=doc.defaultView?.getComputedStyle(profile.insertionPoint).color.match(/\d+/g)?.map(Number);
        dark=!!text && text.length>=3 && text[0]+text[1]+text[2]>384;
      }
    }
    const color=dark ? '#ffffff':'#000000';
    if(control.container.style.getPropertyValue('--lb-profile-color')!==color)control.container.style.setProperty('--lb-profile-color',color);
    if(profile.insertionPoint.nextElementSibling!==control.container)profile.insertionPoint.after(control.container);
  };
}
