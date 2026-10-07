import type {InstagramPost} from './social';

export function findXPosts(doc:Document,pageUrl:string):InstagramPost[]{
  const page=new URL(pageUrl);if(!/^(www\.)?(x|twitter)\.com$/.test(page.hostname))return [];
  const posts:InstagramPost[]=[];
  for(const root of doc.querySelectorAll('article[data-testid="tweet"]')){
    if(root.closest('[hidden],[aria-hidden="true"]') || root.parentElement?.closest('article[data-testid="tweet"]'))continue;
    const links=Array.from(root.querySelectorAll<HTMLAnchorElement>('a[href*="/status/"]')).filter(link=>!link.closest('[data-testid="quoteTweet"]'));
    const link=links.find(link=>link.querySelector('time'));if(!link)continue;
    let url:string;
    try{const target=new URL(link.getAttribute('href')!,page);const match=target.pathname.match(/^\/(?:[^/]+|i\/web)\/status\/(\d+)\/?$/);if(target.protocol!=='https:' || !/^(www\.)?(x|twitter)\.com$/.test(target.hostname) || !match)continue;target.search='';target.hash='';url=target.href;}catch{continue;}
    const group=Array.from(root.querySelectorAll<HTMLElement>('[role="group"]')).find(group=>group.querySelector('[data-testid="reply"]') && group.querySelector('[data-testid="like"],[data-testid="unlike"]'));
    if(!group)continue;
    const buttons=Array.from(group.querySelectorAll<HTMLElement>('button,[role="button"]')).filter(button=>!button.closest('[data-laterbox-control]'));
    const share=buttons.find(button=>/^share(\b|$)/i.test(button.getAttribute('aria-label') || button.getAttribute('title') || '') || button.matches('[data-testid="share"]')) || buttons.at(-1);
    if(!share)continue;
    let insertionPoint=share;
    for(let slot=share.parentElement;slot && slot!==group;slot=slot.parentElement){if(slot.parentElement===group){insertionPoint=slot;break;}}
    posts.push({root,url,share,insertionPoint,site:'X',compact:true,
      author:root.querySelector('[data-testid="User-Name"]')?.textContent?.trim().slice(0,500),
      publishedAt:link.querySelector('time')?.getAttribute('datetime') || undefined});
  }
  return posts;
}
export function createXControls(doc:Document,create:(post:InstagramPost,resolve:()=>InstagramPost|undefined)=>HTMLElement){
  const controls=new Map<Element,{post:InstagramPost;container:HTMLElement}>();
  return (enabled:boolean,pageUrl:string)=>{
    const posts=enabled ? findXPosts(doc,pageUrl):[];
    for(const [root,record] of controls){const post=posts.find(post=>post.root===root);if(!post || post.url!==record.post.url || post.insertionPoint!==record.post.insertionPoint || !record.container.isConnected){record.container.remove();controls.delete(root);}}
    for(const post of posts){
      let record=controls.get(post.root);
      if(!record){const container=create(post,()=>findXPosts(doc,doc.location.href).find(current=>current.root===post.root && current.url===post.url));container.removeAttribute('data-reel-action');container.style.cssText='display:inline-flex;align-items:center;justify-content:center;flex:0 0 auto;margin:0 2px;vertical-align:middle';container.style.setProperty('--lb-instagram-size','20px');record={post,container};controls.set(post.root,record);}
      const color=doc.defaultView?.getComputedStyle(post.share).color;
      if(color && record.container.style.getPropertyValue('--lb-instagram-color')!==color)record.container.style.setProperty('--lb-instagram-color',color);
      if(post.insertionPoint.nextElementSibling!==record.container)post.insertionPoint.after(record.container);
    }
  };
}
