import { browser } from '../platform/api';
import { captureFromPage, extractRenderedPage } from '../lib/page';
import { findSocialPosts } from './social';
import type { Capture, CaptureResult } from '../types/capture';

const host = document.createElement('div');
host.setAttribute('data-laterbox-control','');
const shadow = host.attachShadow({ mode:'closed' });
const style = document.createElement('style');
style.textContent = `button{font:600 12px system-ui;padding:8px 12px;background:#171711;color:#fff;border:1px solid #e6edb0;border-radius:12px;cursor:pointer;box-shadow:0 2px 8px #0003}button:focus-visible{outline:3px solid #26734d}button:disabled{opacity:.6}.quote{position:fixed;z-index:2147483647}.notice{position:fixed;bottom:24px;right:24px;max-width:320px;font:14px system-ui;background:#171711;color:white;padding:12px;border-radius:12px;z-index:2147483647}`;
shadow.append(style);document.documentElement.append(host);
const quoteButton = document.createElement('button');quoteButton.className='quote';quoteButton.textContent='Save to LaterBox';quoteButton.hidden=true;shadow.append(quoteButton);
const notice = document.createElement('div');notice.className='notice';notice.setAttribute('role','status');notice.hidden=true;shadow.append(notice);
let enabled = true; let quote = ''; let context = extractRenderedPage(); let timer: ReturnType<typeof setTimeout> | undefined;
const socialHosts = new Set<Element>();
const socialSeen = new WeakSet<Element>();
let scheduled = false;
function show(message:string) { notice.textContent=message;notice.hidden=false;clearTimeout(timer);timer=setTimeout(()=>{notice.hidden=true;},6000); }
async function submit(capture:Capture,button:HTMLButtonElement) {
  button.disabled=true;
  try {
    const result:CaptureResult = await browser.runtime.sendMessage({ type:'capture',capture });
    show(result.status==='saved' ? 'Saved to LaterBox.' : result.status==='queued' ? 'Offline or service unavailable. Pending save will sync to your account when online.' : result.status==='proRequired' ? 'LaterBox Pro is required. Open the extension to upgrade.' : result.status==='needsAuth' ? 'Connect your paid LaterBox account in the extension.' : 'Could not save this content.');
  } catch { show('The extension is unavailable. Reload this page and retry.'); }
  finally { button.disabled=false; }
}
quoteButton.addEventListener('pointerdown',event=>event.preventDefault());
quoteButton.addEventListener('click',event=>{ if (event.isTrusted && quote) void submit(captureFromPage(context,'highlight',quote),quoteButton); });
document.addEventListener('selectionchange',()=>{
  if (!enabled) return;
  const selection=window.getSelection(); const parent=selection?.anchorNode?.parentElement;
  quote=selection?.toString().trim() || '';
  if (!quote || !selection?.rangeCount || parent?.closest('input,textarea,select,form,[contenteditable="true"]') || shadow.activeElement) { quoteButton.hidden=true;return; }
  const rect=selection.getRangeAt(0).getBoundingClientRect();
  // Preserve the quote before clicking the isolated button changes focus.
  context=extractRenderedPage();quote=context.selection;
  quoteButton.style.left=Math.max(8,Math.min(rect.left,innerWidth-170))+'px';
  quoteButton.style.top=Math.max(8,Math.min(rect.bottom+8,innerHeight-50))+'px';quoteButton.hidden=!quote;
});
document.addEventListener('keydown',event=>{if(event.key==='Escape')quoteButton.hidden=true;});
window.addEventListener('scroll',()=>{quoteButton.hidden=true;},{passive:true});
function addSocialControls() {
  if (!enabled) return;
  for (const post of findSocialPosts(document,location.href)) {
    if (socialSeen.has(post.root)) continue;socialSeen.add(post.root);
    const container=document.createElement('div');container.setAttribute('data-laterbox-control','');
    const local=container.attachShadow({mode:'closed'});local.append(style.cloneNode(true));
    const button=document.createElement('button');button.textContent='Save to LaterBox';local.append(button);
    post.root.append(container);socialHosts.add(container);
    button.addEventListener('click',event=>{
      if (!event.isTrusted) return;event.stopPropagation();
      // Resolve again: virtualized feeds can reuse an element for a different post.
      const current=findSocialPosts(document,location.href).find(p=>p.root===post.root);
      if(!current){show('Post link unavailable. Select its text or use Save Page.');return;}
      const marker='lb-'+crypto.randomUUID();current.root.setAttribute('data-laterbox-post',marker);
      const page=extractRenderedPage(`[data-laterbox-post="${marker}"]`);current.root.removeAttribute('data-laterbox-post');
      page.url=current.url;page.canonicalUrl=current.url;page.siteName=current.site;page.author=current.author;page.publishedAt=current.publishedAt;
      page.title=(current.author ? current.author+' on ' : 'Post on ')+current.site;
      // Feed-wide descriptions/previews must not be mistaken for this specific post.
      page.description=(current.root as HTMLElement).innerText?.trim().slice(0,500);page.previewImageUrl=current.root.querySelector<HTMLImageElement>('img')?.src || '';
      void submit(captureFromPage(page,'social'),button);
    });
  }
}
const observer=new MutationObserver(()=>{
  if(scheduled || !enabled)return;scheduled=true;setTimeout(()=>{scheduled=false;addSocialControls();},500);
});
observer.observe(document.body,{childList:true,subtree:true});
async function refreshSettings() {
  const values=await browser.storage.local.get('injectedControls');enabled=values.injectedControls!==false;
  host.hidden=!enabled;for(const container of socialHosts)(container as HTMLElement).hidden=!enabled;
  if(enabled)addSocialControls();
}
browser.storage.onChanged.addListener((changes,area)=>{if(area==='local' && changes.injectedControls)void refreshSettings();});
window.addEventListener('online',()=>{void browser.runtime.sendMessage({type:'flush-captures'}).catch(()=>{});});
void refreshSettings();

// Browsers without native text directives still reopen saved highlight links.
async function reopenFragment() {
  if ('fragmentDirective' in document) return;
  const raw=location.hash.split(':~:text=')[1]?.split('&')[0];if(!raw)return;
  try {
    const parts=raw.split(',');let prefix='',suffix='';
    if(parts[0]?.endsWith('-'))prefix=decodeURIComponent(parts.shift()!.slice(0,-1));
    if(parts.at(-1)?.startsWith('-'))suffix=decodeURIComponent(parts.pop()!.slice(1));
    let exact=decodeURIComponent(parts[0] || '');
    if(parts.length>1){
      const end=decodeURIComponent(parts[1]);const text=document.body.textContent || '';const start=text.indexOf(exact);const finish=text.indexOf(end,start+exact.length);
      if(start<0 || finish<0)return;exact=text.slice(start,finish+end.length);
    }
    const {locateAndSelect}=await import('../lib/highlight');
    locateAndSelect({exact,prefix,suffix});
  } catch { /* malformed or changed source: retain the normal page */ }
}
void reopenFragment();
