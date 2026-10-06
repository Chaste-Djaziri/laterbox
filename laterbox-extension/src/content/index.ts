import { browser } from '../platform/api';
import { captureFromPage, extractRenderedPage } from '../lib/page';
import { findSocialPosts } from './social';
import type { Capture, CaptureResult } from '../types/capture';

const host = document.createElement('div');
host.setAttribute('data-laterbox-control','');
const shadow = host.attachShadow({ mode:'closed' });
const style = document.createElement('style');
style.textContent = `
:host{all:initial;font-family:system-ui,sans-serif;color:#171711;color-scheme:light}
*{box-sizing:border-box}[hidden]{display:none!important}
button{display:inline-flex;align-items:center;justify-content:center;gap:7px;min-height:34px;font:650 12px/1.2 system-ui;padding:8px 12px;background:#171711;color:#fff;border:1px solid #171711;border-radius:9px;cursor:pointer;transition:background .15s,box-shadow .15s}
button:hover{background:#34342b}button:focus-visible{outline:3px solid #9cb550;outline-offset:3px}button:disabled{cursor:wait;opacity:.75}
button svg{width:15px;height:15px;flex-shrink:0}
.quote-toolbar{position:fixed;z-index:2147483647;display:flex;align-items:center;gap:6px;padding:5px;background:#fff;border:1px solid #deded4;border-radius:13px;box-shadow:0 6px 24px #0002;max-width:calc(100vw - 16px)}
.dismiss{min-width:28px;min-height:28px;padding:6px;border:0;background:transparent;color:#77766b;border-radius:7px}.dismiss:hover{background:#f1f0e8;color:#171711}
.social-row{display:flex;justify-content:flex-end;padding:8px 12px;margin:4px 0;border-top:1px solid #7772}
.social-row button{background:#fff;color:#171711;border-color:#dcdcd3;box-shadow:0 1px 3px #0001}.social-row button:hover{background:#f0f3df;border-color:#b1c483}
button[data-state=saved]{background:#edf5ee;color:#25653c;border-color:#c3ddc6}button[data-state=queued]{background:#fff6de;color:#805b12;border-color:#ebd6a3}
.notice{position:fixed;bottom:24px;right:24px;display:flex;align-items:flex-start;gap:12px;max-width:min(360px,calc(100vw - 32px));font:13px/1.5 system-ui;background:#fff;color:#171711;padding:14px 14px 14px 17px;border:1px solid #deded4;border-left:4px solid #26734d;border-radius:12px;box-shadow:0 6px 28px #0002;z-index:2147483647}
.notice[data-state=queued]{border-left-color:#b7791f}.notice[data-state=error]{border-left-color:#a33a32}.notice strong{display:block;font-size:13px}.notice p{margin:3px 0 0;color:#6c6b63;font-size:12px}.notice .dismiss{flex-shrink:0}
@media(prefers-reduced-motion:reduce){button{transition:none}}
`;
shadow.append(style);document.documentElement.append(host);
function decorate(button:HTMLButtonElement,label:string) {
  button.replaceChildren();
  const icon=document.createElementNS('http://www.w3.org/2000/svg','svg');icon.setAttribute('viewBox','0 0 24 24');icon.setAttribute('fill','none');icon.setAttribute('stroke','currentColor');icon.setAttribute('stroke-width','1.8');icon.setAttribute('aria-hidden','true');
  const path=document.createElementNS(icon.namespaceURI,'path');path.setAttribute('d','M6 4h12v17l-6-4-6 4V4Z');icon.append(path);
  const text=document.createElement('span');text.textContent=label;button.append(icon,text);
}
const quoteToolbar=document.createElement('div');quoteToolbar.className='quote-toolbar';quoteToolbar.setAttribute('role','group');quoteToolbar.setAttribute('aria-label','Save selected text');quoteToolbar.hidden=true;shadow.append(quoteToolbar);
const quoteButton=document.createElement('button');quoteButton.type='button';decorate(quoteButton,'Save quote');quoteButton.title='Save this selection with its source to LaterBox';quoteToolbar.append(quoteButton);
const dismissQuote=document.createElement('button');dismissQuote.type='button';dismissQuote.className='dismiss';dismissQuote.textContent='×';dismissQuote.setAttribute('aria-label','Dismiss selection controls');quoteToolbar.append(dismissQuote);
dismissQuote.addEventListener('pointerdown',event=>event.preventDefault());dismissQuote.addEventListener('click',()=>{quoteToolbar.hidden=true;});
const notice=document.createElement('div');notice.className='notice';notice.hidden=true;shadow.append(notice);
const noticeCopy=document.createElement('div');noticeCopy.setAttribute('role','status');noticeCopy.setAttribute('aria-live','polite');noticeCopy.setAttribute('aria-atomic','true');notice.append(noticeCopy);
const dismissNotice=document.createElement('button');dismissNotice.type='button';dismissNotice.className='dismiss';dismissNotice.textContent='×';dismissNotice.setAttribute('aria-label','Dismiss save message');notice.append(dismissNotice);dismissNotice.addEventListener('click',()=>{notice.hidden=true;});
let enabled = true; let quote = ''; let context = extractRenderedPage(); let timer: ReturnType<typeof setTimeout> | undefined;
const socialHosts = new Set<Element>();
const socialSeen = new WeakSet<Element>();
let scheduled = false;
function show(message:string,state='error',title='Could not save') {
  const heading=document.createElement('strong');heading.textContent=title;const detail=document.createElement('p');detail.textContent=message;
  noticeCopy.replaceChildren(heading,detail);notice.dataset.state=state;notice.hidden=false;clearTimeout(timer);timer=setTimeout(()=>{notice.hidden=true;},8000);
}
async function submit(capture:Capture,button:HTMLButtonElement) {
  const label=button===quoteButton ? 'Save quote' : 'Save post';button.disabled=true;button.setAttribute('aria-busy','true');decorate(button,'Saving…');
  try {
    const result:CaptureResult=await browser.runtime.sendMessage({type:'capture',capture});
    button.dataset.state=result.status;
    if(result.status==='saved'){decorate(button,'Saved');show('Available in your LaterBox account.','saved','Saved to LaterBox');}
    else if(result.status==='queued'){decorate(button,'Pending');show('Your capture is queued and will sync when the connection returns.','queued','Pending save');}
    else if(result.status==='proRequired'){decorate(button,label);show('Open the LaterBox extension to upgrade your account.','error','LaterBox Pro required');}
    else if(result.status==='needsAuth'){decorate(button,label);show('Open the LaterBox extension to connect your account.','error','Connect to LaterBox');}
    else {decorate(button,label);show('Try again, or save using the extension popup.');}
  } catch {decorate(button,label);show('Reload this page and try again.','error','Extension unavailable');}
  finally {button.removeAttribute('aria-busy');setTimeout(()=>{button.disabled=false;delete button.dataset.state;decorate(button,label);},2000);}
}
quoteButton.addEventListener('pointerdown',event=>event.preventDefault());
quoteButton.addEventListener('click',event=>{ if (event.isTrusted && quote) void submit(captureFromPage(context,'highlight',quote),quoteButton); });
document.addEventListener('selectionchange',()=>{
  if (!enabled) return;
  const selection=window.getSelection(); const parent=selection?.anchorNode?.parentElement;
  quote=selection?.toString().trim() || '';
  if (!quote || !selection?.rangeCount || parent?.closest('input,textarea,select,form,[contenteditable="true"]') || shadow.activeElement) { quoteToolbar.hidden=true;return; }
  const rect=selection.getRangeAt(0).getBoundingClientRect();
  // Preserve the quote before clicking the isolated button changes focus.
  context=extractRenderedPage();quote=context.selection;
  quoteToolbar.style.left=Math.max(8,Math.min(rect.left,innerWidth-190))+'px';
  quoteToolbar.style.top=Math.max(8,Math.min(rect.bottom+8,innerHeight-58))+'px';quoteToolbar.hidden=!quote;
});
document.addEventListener('keydown',event=>{if(event.key==='Escape')quoteToolbar.hidden=true;});
window.addEventListener('scroll',()=>{quoteToolbar.hidden=true;},{passive:true});
function addSocialControls() {
  if (!enabled) return;
  for (const post of findSocialPosts(document,location.href)) {
    if (socialSeen.has(post.root)) continue;socialSeen.add(post.root);
    const container=document.createElement('div');container.setAttribute('data-laterbox-control','');
    const local=container.attachShadow({mode:'closed'});local.append(style.cloneNode(true));
    const row=document.createElement('div');row.className='social-row';local.append(row);
    const button=document.createElement('button');button.type='button';decorate(button,'Save post');button.title=`Save this ${post.site} post to LaterBox`;button.setAttribute('aria-label',`Save ${post.author ? post.author+'’s ' : ''}${post.site} post to LaterBox`);row.append(button);
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
  host.hidden=!enabled;if(!enabled)quoteToolbar.hidden=true;for(const container of socialHosts)(container as HTMLElement).hidden=!enabled;
  if(enabled)addSocialControls();
}
browser.storage.onChanged.addListener((changes,area)=>{if(area==='local' && changes.injectedControls)void refreshSettings();});
window.addEventListener('online',()=>{void browser.runtime.sendMessage({type:'flush-captures'}).catch(()=>{});});
void refreshSettings();

// Browsers without native text directives still reopen saved highlight links.
async function reopenFragment() {
  if (Reflect.has(document,'fragmentDirective')) return;
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
