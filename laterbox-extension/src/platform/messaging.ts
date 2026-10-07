import {browser} from './api';

/** An async boundary also turns missing APIs and stale-context throws into rejections. */
export async function sendRuntimeMessage<T=unknown>(message:unknown):Promise<T>{
  if(typeof browser.runtime?.sendMessage!=='function')throw new Error('Extension unavailable. Reload this page and try again.');
  return await browser.runtime.sendMessage(message) as T;
}
