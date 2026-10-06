import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createAccountQueue, type Connection } from '../src/lib/account-queue';
import type { Capture, CaptureResult, QueuedCapture } from '../src/types/capture';
const capture = (id:string):Capture => ({captureId:id,url:'https://example.com',title:'Page',source:'browserExtension',createdAt:new Date().toISOString()});
function fixture() {
 let account:Connection={userId:'a',token:'token-a',isPro:true}; let rows:QueuedCapture[]=[];
 let result:CaptureResult={status:'queued',reason:'network'}; const sends:{id:string|undefined,token:string}[]=[];
 const queue=createAccountQueue({connection:async()=>({...account}),read:async()=>structuredClone(rows),write:async next=>{rows=structuredClone(next)},send:async(c,token)=>{sends.push({id:c.captureId,token});return result},state:async()=>{}});
 return {queue,sends,get rows(){return rows},set account(a:Connection){account=a},set result(r:CaptureResult){result=r}};
}
test('offline captures survive restart and replay with stable IDs',async()=>{const f=fixture();assert.equal((await f.queue.save(capture('one'))).status,'queued');assert.equal(f.rows.length,1);f.result={status:'saved',itemId:'item'};assert.equal(await f.queue.flush(),1);assert.equal(f.rows.length,0);assert.deepEqual(f.sends.map(x=>x.id),['one','one']);});
test('disconnected and unpaid accounts have no guest queue',async()=>{const f=fixture();f.account={userId:'',token:'',isPro:null};assert.equal((await f.queue.save(capture('one'))).status,'needsAuth');f.account={userId:'a',token:'a',isPro:false};assert.equal((await f.queue.save(capture('two'))).status,'proRequired');assert.equal(f.rows.length,0);assert.equal(f.sends.length,0);});
test('account switching cannot upload another account queue',async()=>{const f=fixture();await f.queue.save(capture('one'));f.account={userId:'b',token:'token-b',isPro:true};f.result={status:'saved',itemId:'item'};assert.equal(await f.queue.flush(),0);await f.queue.save(capture('two'));assert.deepEqual(f.rows.map(x=>x.capture.captureId),['one']);assert.equal(f.sends[1].token,'token-b');f.account={userId:'a',token:'token-a',isPro:true};assert.equal(await f.queue.flush(),1);});
test('concurrent saves serialize without dropping pending rows',async()=>{const f=fixture();await Promise.all([f.queue.save(capture('one')),f.queue.save(capture('two')),f.queue.save(capture('three'))]);assert.deepEqual(f.rows.map(x=>x.capture.captureId),['one','two','three']);f.result={status:'needsAuth'};assert.equal(await f.queue.flush(),0);assert.equal(f.rows.length,3);f.result={status:'saved',itemId:'item'};assert.equal(await f.queue.flush(),3);});
test('server rejection differs from connectivity and stops replay',async()=>{const f=fixture();f.result={status:'proRequired'};await f.queue.save(capture('one'));assert.equal(f.rows.length,0);f.result={status:'queued',reason:'network'};await f.queue.save(capture('two'));f.result={status:'error',reason:'server'};assert.equal(await f.queue.flush(),0);assert.equal(f.rows.length,1);});
