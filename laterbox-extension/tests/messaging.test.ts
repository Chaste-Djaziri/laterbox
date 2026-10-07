import {test} from 'node:test';
import assert from 'node:assert/strict';

test('messaging rejects missing and invalidated runtimes and forwards acknowledgements',async()=>{
  const api:{}={};
  Object.assign(globalThis,{chrome:api});
  const {sendRuntimeMessage}=await import('../src/platform/messaging');
  await assert.rejects(sendRuntimeMessage({type:'flush-captures'}),/Extension unavailable/);
  Object.assign(api,{runtime:{sendMessage:()=>{throw new Error('Extension context invalidated');}}});
  await assert.rejects(sendRuntimeMessage({type:'capture'}),/context invalidated/);
  const message={type:'capture'};
  Object.assign(api,{runtime:{sendMessage:async(received:unknown)=>{assert.equal(received,message);return {status:'saved',itemId:'123'};}}});
  assert.deepEqual(await sendRuntimeMessage(message),{status:'saved',itemId:'123'});
});
