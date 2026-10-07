import type {InstagramPost} from './social';

/** Only post-local actions and verified LinkedIn post URLs qualify. */
export function findLinkedInPosts(doc:Document,pageUrl:string):InstagramPost[]{
  const page=new URL(pageUrl);
  if(!/^(www\.)?linkedin\.com$/.test(page.hostname))return [];
  const roots=Array.from(doc.querySelectorAll('.feed-shared-update-v2,[data-urn*="urn:li:activity:"],[data-urn*="urn:li:ugcPost:"]'));
  const posts:InstagramPost[]=[];
  for(const root of roots){
    if(root.parentElement?.closest('.feed-shared-update-v2,[data-urn*="urn:li:activity:"],[data-urn*="urn:li:ugcPost:"]') || root.closest('[hidden],[aria-hidden="true"]'))continue;
    const actions=Array.from(root.querySelectorAll<HTMLElement>('button,[role="button"]')).filter(button=>!button.closest('[data-laterbox-control]'));
    const share=actions.find(button=>/^(send|share|send post|share post)(\b|$)/i.test((button.getAttribute('aria-label') || button.textContent || '').trim())) || actions.find(button=>/^repost(\b|$)/i.test((button.getAttribute('aria-label') || button.textContent || '').trim()));
    if(!share)continue;
    const urn=root.getAttribute('data-urn')?.match(/^urn:li:(activity|ugcPost):\d+$/)?.[0];
    let url=urn ? 'https://www.linkedin.com/feed/update/'+urn+'/':undefined;
    if(!url){
      const candidates=new Set<string>();
      for(const link of root.querySelectorAll<HTMLAnchorElement>('a[href*="/feed/update/"],a[href*="/posts/"]')){
        try{const target=new URL(link.getAttribute('href')!,page);if(/^(www\.)?linkedin\.com$/.test(target.hostname) && target.protocol==='https:' && (/^\/feed\/update\/urn:li:(activity|ugcPost):\d+\/?$/.test(target.pathname) || /^\/posts\/[^/]+\/?$/.test(target.pathname))){target.search='';target.hash='';candidates.add(target.href);}}catch{/* Invalid links do not qualify. */}
      }
      if(candidates.size===1)url=[...candidates][0];
    }
    if(!url)continue;
    let insertionPoint=share;
    const wrapper=share.parentElement;
    if(wrapper && wrapper!==root && wrapper.querySelectorAll('button,[role="button"]').length===1 && wrapper.parentElement?.querySelectorAll('button,[role="button"]').length!>1)insertionPoint=wrapper;
    posts.push({root,url,site:'LinkedIn',share,insertionPoint,
      author:root.querySelector('.update-components-actor__title,.feed-shared-actor__name')?.textContent?.trim().slice(0,500),
      publishedAt:root.querySelector('time')?.getAttribute('datetime') || undefined});
  }
  return posts;
}

export function createLinkedInControls(doc:Document,create:(post:InstagramPost,resolve:()=>InstagramPost|undefined)=>HTMLElement){
  const controls=new Map<Element,{post:InstagramPost;container:HTMLElement}>();
  return (enabled:boolean,pageUrl:string)=>{
    const posts=enabled ? findLinkedInPosts(doc,pageUrl):[];
    for(const [root,record] of controls){
      const post=posts.find(post=>post.root===root);
      if(!post || post.url!==record.post.url || post.insertionPoint!==record.post.insertionPoint || !record.container.isConnected){record.container.remove();controls.delete(root);}
    }
    for(const post of posts){
      let record=controls.get(post.root);
      if(!record){const container=create(post,()=>findLinkedInPosts(doc,doc.location.href).find(current=>current.root===post.root && current.url===post.url));record={post,container};controls.set(post.root,record);}
      const color=doc.defaultView?.getComputedStyle(post.share).color;
      if(color && record.container.style.getPropertyValue('--lb-instagram-color')!==color)record.container.style.setProperty('--lb-instagram-color',color);
      if(post.insertionPoint.nextElementSibling!==record.container)post.insertionPoint.after(record.container);
    }
  };
}
