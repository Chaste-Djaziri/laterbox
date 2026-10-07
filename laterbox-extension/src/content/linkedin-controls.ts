import type {InstagramPost} from './social';

/** Only post-local actions and verified LinkedIn post URLs qualify. */
export function findLinkedInPosts(doc:Document,pageUrl:string):InstagramPost[]{
  const page=new URL(pageUrl);
  if(!/^(www\.)?linkedin\.com$/.test(page.hostname))return [];
  const rootSelector='.feed-shared-update-v2,[data-urn*="urn:li:activity:"],[data-urn*="urn:li:ugcPost:"],[data-id*="urn:li:activity:"],[data-id*="urn:li:ugcPost:"],[data-view-name="feed-full-update"],article,[role="article"],[role="dialog"]';
  const roots=Array.from(doc.querySelectorAll(rootSelector));
  const posts:InstagramPost[]=[];
  const permalink=(raw:string|null):string|undefined=>{
    if(!raw)return;
    try{const target=new URL(raw,page);if(!/^(www\.)?linkedin\.com$/.test(target.hostname) || target.protocol!=='https:' || !(/^\/feed\/update\/urn:li:(activity|ugcPost):\d+\/?$/.test(target.pathname) || /^\/posts\/[^/]+\/?$/.test(target.pathname)))return;target.search='';target.hash='';return target.href;}catch{return;}
  };
  for(const root of roots){
    if(root.closest('[hidden],[aria-hidden="true"]'))continue;
    const actions=Array.from(root.querySelectorAll<HTMLElement>('button,[role="button"],a[aria-label]')).filter(button=>!button.closest('[data-laterbox-control]') && !button.closest('[hidden],[aria-hidden="true"]'));
    const share=actions.find(button=>{
      const label=[button.getAttribute('aria-label'),button.getAttribute('title'),button.textContent].filter(Boolean).join(' ').trim();
      return /^(send|share)(\b|$)/i.test(label) || button.matches('[data-view-name*="send"],[data-control-name*="send"]') || !!button.querySelector('[data-test-icon*="send"],[data-test-icon*="paper-plane"],use[href*="send"],use[href*="paper-plane"]');
    }) || actions.find(button=>/^repost(\b|$)/i.test((button.getAttribute('aria-label') || button.textContent || '').trim()));
    if(!share)continue;
    // Prefer the smallest recognized post containing this action. This also
    // keeps a photo dialog independent from its underlying feed card.
    if(roots.some(other=>other!==root && root.contains(other) && other.contains(share)))continue;
    const identity=(element:Element)=>['data-urn','data-id','data-entity-urn'].map(name=>element.getAttribute(name)?.match(/urn:li:(activity|ugcPost):\d+/)?.[0]).find(Boolean);
    const urn=identity(root);
    let url=urn ? 'https://www.linkedin.com/feed/update/'+urn+'/':undefined;
    if(!url){
      const candidates=new Set<string>();
      for(const link of root.querySelectorAll<HTMLAnchorElement>('a[href*="/feed/update/"],a[href*="/posts/"]')){const target=permalink(link.getAttribute('href'));if(target)candidates.add(target);}
      for(const element of root.querySelectorAll('[data-urn],[data-id],[data-entity-urn]')){const id=identity(element);if(id)candidates.add('https://www.linkedin.com/feed/update/'+id+'/');}
      if(candidates.size===1)url=[...candidates][0];
      if(!url && candidates.size===0 && (root.matches('[role="dialog"]') || roots.filter(candidate=>!candidate.matches('[role="dialog"]')).length===1))url=permalink(page.href);
    }
    if(!url)continue;
    let insertionPoint=share;
    const wrapper=share.parentElement;
    if(wrapper && wrapper!==root && wrapper.querySelectorAll('button,[role="button"]').length===1 && (wrapper.parentElement?.querySelectorAll('button,[role="button"]').length || 0)>1)insertionPoint=wrapper;
    posts.push({root,url,site:'LinkedIn',share,insertionPoint,
      author:root.querySelector('.update-components-actor__title,.feed-shared-actor__name,[data-view-name*="actor"] a,a[href*="/in/"],a[href*="/company/"]')?.textContent?.trim().slice(0,500),
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
