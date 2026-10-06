import {findInstagramPosts,type InstagramPost} from './social';
export function createInstagramControls(doc:Document, create:(post:InstagramPost,resolve:()=>InstagramPost|undefined)=>HTMLElement) {
  const controls=new Map<Element,{post:InstagramPost;container:HTMLElement}>();
  return (enabled:boolean,pageUrl:string)=>{
    const posts=enabled ? findInstagramPosts(doc,pageUrl):[];
    for(const [root,record] of controls){
      const current=posts.find(post=>post.root===root);
      if(!current || current.url!==record.post.url || current.share!==record.post.share || !record.container.isConnected){record.container.remove();controls.delete(root);}
    }
    for(const post of posts){
      let record=controls.get(post.root);
      if(!record){
        const container=create(post,()=>findInstagramPosts(doc,doc.location.href).find(current=>current.root===post.root && current.url===post.url));
        record={post,container};controls.set(post.root,record);
      }
      if(post.insertionPoint.nextElementSibling!==record.container)post.insertionPoint.after(record.container);
    }
  };
}
