// laterbox-web/src/lib/utils/taskChecklist.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import type { LaterBoxItem } from '../supabase/types';
import {
  newTaskChecklistData, readTaskChecklist, readStructuredData, setTaskChecklistComplete,
  taskChecklistProgress, validateTaskChecklist, withTaskChecklist,
} from './taskChecklist';

const entries = [
  { id: 'one', title: 'Research the project', done: false },
  { id: 'two', title: 'Create a draft', done: false },
  { id: 'three', title: 'Review the result', done: false },
];
const original = (overrides: Partial<LaterBoxItem> = {}): LaterBoxItem => ({
  id: 'group-1', type: 'task', title: 'Launch the project',
  status: 'inbox', favorite: false, url: null,
  text_content: 'Group context', created_at: '2026-11-08T00:00:00Z',
  updated_at: '2026-11-08T00:00:00Z',
  return_at: '2026-11-09T11:00:00Z',
  metadata: {
    item_id: 'group-1', status: 'pending', attempt_count: 0,
    created_at: '2026-11-08T00:00:00Z', updated_at: '2026-11-08T00:00:00Z',
    structured_data: JSON.stringify({ source: 'web', tags: ['Study'], seen: true, taskChecklist: newTaskChecklistData(entries) }),
  },
  ...overrides,
});
const later = '2026-11-08T09:00:00Z';

test('task group validation requires at least two valid, unique entries', () => {
  assert.equal(validateTaskChecklist(entries.slice(0,1)), null);
  assert.equal(validateTaskChecklist([{...entries[0]}, {...entries[0]}]),null);
  assert.equal(validateTaskChecklist([{...entries[0], title:' '}, entries[1]]),null);
  assert.equal(validateTaskChecklist(entries.concat(Array.from({length:40},(_,i)=>({id:`extra-${i}`,title:'More',done:false})))),null);
  assert.deepEqual(newTaskChecklistData(entries).entries, entries);
  assert.deepEqual(taskChecklistProgress(entries), {done:0,total:3,allDone:false});
});

test('reading checklist preserves order, completion, and skips invalid data', () => {
  assert.deepEqual(readTaskChecklist(original()), entries);
  assert.equal(readTaskChecklist(original({type:'note'})),null);
  assert.equal(readTaskChecklist(original({metadata:null})),null);
  assert.equal(readTaskChecklist(original({metadata:{...original().metadata!,structured_data:'invalid-json'}})),null);
});

test('checking entries keeps unrelated metadata and schedule, then archives on final checkbox', () => {
  const item = original();
  const first = withTaskChecklist(item, entries.map((e,i)=>({...e,done:i===0})),later);
  assert.equal(first.status, 'inbox');
  assert.equal(first.return_at,item.return_at);
  assert.deepEqual(readTaskChecklist(first)?.map(e=>e.done),[true,false,false]);
  const data = readStructuredData(first.metadata);
  assert.deepEqual(data.tags,['Study']);
  assert.equal(data.seen,true);
  assert.equal(data.source,'web');
  assert.equal(item.status,'inbox');
  assert.equal(readTaskChecklist(item)?.[0].done,false);

  const complete = withTaskChecklist(first, entries.map(e=>({...e,done:true})),later);
  assert.equal(complete.status,'archived');
  assert.equal(taskChecklistProgress(readTaskChecklist(complete)!).allDone,true);
  const reopen = withTaskChecklist(complete, entries.map((e,i)=>({...e,done:i!==0})),later);
  assert.equal(reopen.status,'inbox');
  assert.equal(reopen.return_at,null);
  assert.equal(reopen.seen,false);
  assert.equal(readStructuredData(reopen.metadata).seen,false);
  assert.deepEqual(readTaskChecklist(reopen)?.map(e=>e.done),[false,true,true]);
});

test('group action marks all entries done or reopens them together', () => {
  const completed=setTaskChecklistComplete(original(),true,later);
  assert.equal(completed.status,'archived');
  assert.equal(readTaskChecklist(completed)?.every(e=>e.done),true);
  const reopened=setTaskChecklistComplete(completed,false,later);
  assert.equal(reopened.status,'inbox');
  assert.equal(readTaskChecklist(reopened)?.every(e=>!e.done),true);
});

test('single tasks remain unchanged and cannot gain a checklist accidentally', () => {
  const single=original({metadata:null});
  assert.equal(setTaskChecklistComplete(single,true,later),single);
  assert.throws(()=>withTaskChecklist(single,entries,later),/not a checklist/);
});
