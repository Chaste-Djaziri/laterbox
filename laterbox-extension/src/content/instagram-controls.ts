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
      const isModal=Boolean(post.root.closest('[role="dialog"]') || post.share.closest('[role="dialog"]') || doc.querySelector('[role="dialog"]'));
      const actionRoot=post.share.closest('section,aside,[role="group"]') || post.share.parentElement || post.share;
      const candidateSvgs=[
        post.share.querySelector('svg'),
        actionRoot.querySelector('svg[aria-label*="Share"],svg[aria-label*="Like"],svg[aria-label*="Comment"],svg[aria-label*="Save"]'),
        actionRoot.querySelector('svg'),
      ].filter((s):s is SVGElement=>Boolean(s));

      let explicitColor:string|undefined;
      for(const svg of candidateSvgs){
        for(const attr of ['color','fill','stroke'] as const){
          const val=svg.getAttribute(attr);
          if(val && !['none','currentColor','transparent',''].includes(val)){explicitColor=val;break;}
        }
        if(explicitColor)break;
        for(const prop of ['color','fill'] as const){
          const val=svg.style[prop];
          if(val && !['none','currentColor','transparent',''].includes(val)){explicitColor=val;break;}
        }
        if(explicitColor)break;
      }

      const icon=post.share.querySelector('svg') || post.share;
      const appearance=doc.defaultView?.getComputedStyle(icon);
      let color=explicitColor || (appearance?.fill && !['none','currentColor',''].includes(appearance.fill) ? appearance.fill : appearance?.color);

      // Detect dark background surface or dark theme
      let isDarkSurface=isModal;
      if(!isDarkSurface){
        for(let el:HTMLElement|null=post.share;el && el!==doc.body;el=el.parentElement){
          const bg=doc.defaultView?.getComputedStyle(el)?.backgroundColor;
          if(bg && bg!=='transparent' && !bg.startsWith('rgba(0, 0, 0, 0)')){
            const rgb=bg.match(/\d+(\.\d+)?/g)?.map(Number);
            if(rgb && rgb.length>=3 && (rgb[3]===undefined || rgb[3]>0.1)){
              const lum=0.299*rgb[0]+0.587*rgb[1]+0.114*rgb[2];
              isDarkSurface=lum<140;
              break;
            }
          }
        }
      }
      if(!isDarkSurface){
        const htmlClass=doc.documentElement.className || '';
        const bodyClass=doc.body?.className || '';
        const scheme=doc.defaultView?.getComputedStyle(doc.documentElement)?.colorScheme;
        if(htmlClass.includes('dark') || htmlClass.includes('_a9--') || bodyClass.includes('dark') || scheme==='dark'){
          isDarkSurface=true;
        }
      }

      // In post modal or on dark surface, action icons must be bright white (rgb(245, 245, 245))
      // If color was computed as secondary text (sum < 650 e.g. #a8b3bf rgb(168,179,191) or #737373), elevate to bright white.
      if(isDarkSurface){
        if(color){
          const rgb=color.match(/\d+/g)?.map(Number);
          if(rgb && rgb.length>=3){
            const sum=rgb[0]+rgb[1]+rgb[2];
            if(sum<650)color='rgb(245, 245, 245)';
          }
        } else {
          color='rgb(245, 245, 245)';
        }
      }

      const size=Math.max(16,Math.min(32,parseFloat(appearance?.width || '') || 24))+'px';
      for(const [name,value] of [['--lb-instagram-color',color],['--lb-instagram-size',size]] as const){
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
