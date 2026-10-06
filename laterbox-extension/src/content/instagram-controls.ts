import {findInstagramPosts,type InstagramPost} from './social';
export function createInstagramControls(doc:Document, create:(post:InstagramPost,resolve:()=>InstagramPost|undefined)=>HTMLElement) {
  const controls=new Map<Element,{post:InstagramPost;container:HTMLElement;observer?:ResizeObserver}>();
  return (enabled:boolean,pageUrl:string)=>{
    const posts=enabled ? findInstagramPosts(doc,pageUrl):[];
    for(const [root,record] of controls){
      const current=posts.find(post=>post.root===root);
      if(!current || current.url!==record.post.url || current.share!==record.post.share || current.insertionPoint!==record.post.insertionPoint || current.compact!==record.post.compact || !record.container.isConnected){record.observer?.disconnect();record.container.remove();controls.delete(root);}
    }
    const matchIcon=(post:InstagramPost,container:HTMLElement)=>{
      const icon=post.share.querySelector('svg') || post.share;
      const appearance=doc.defaultView?.getComputedStyle(icon);
      const color=appearance?.fill && !['none','currentColor',''].includes(appearance.fill) ? appearance.fill : appearance?.color;
      const size=Math.max(16,Math.min(32,parseFloat(appearance?.width || '') || 24))+'px';
      for(const [name,value] of [['--lb-instagram-color',color],['--lb-instagram-size',size]]){
        if(value && container.style.getPropertyValue(name)!==value)container.style.setProperty(name,value);
      }
    };
    for(const post of posts){
      let record=controls.get(post.root);
      if(!record){
        const container=create(post,()=>findInstagramPosts(doc,doc.location.href).find(current=>current.root===post.root && current.url===post.url));
        record={post,container};controls.set(post.root,record);
        const adapt=()=>{
          matchIcon(post,container);
          const row=container.parentElement;if(!row)return;
          const direction=doc.defaultView?.getComputedStyle(row).flexDirection;
          const width=row.getBoundingClientRect().width;
          const occupied=Array.from(row.children).filter(child=>child!==container).reduce((sum,child)=>sum+child.getBoundingClientRect().width,0);
          container.dataset.compact=String(!!post.compact || direction==='column' || direction==='column-reverse' || (width>0 && width-occupied<160));
        };
        container.dataset.compact=String(!!post.compact);
        if(typeof ResizeObserver!=='undefined'){record.observer=new ResizeObserver(adapt);record.observer.observe(post.insertionPoint.parentElement!);}
        post.insertionPoint.after(container);adapt();
      }
      matchIcon(post,record.container);
      if(post.insertionPoint.nextElementSibling!==record.container)post.insertionPoint.after(record.container);
    }
  };
}
