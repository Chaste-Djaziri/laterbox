// laterbox-web/src/lib/utils/itemDetailPresentation.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import type { LaterBoxItem } from '@/lib/supabase/types';
import { isTaskComplete, safeExternalItemUrl, shouldShowArticleReader } from './itemDetailPresentation';

const base = {
  id: '1', type: 'link', status: 'inbox', title: 'Sample',
  url: 'https://example.com/article', favorite: false,
  created_at: '2026-11-08T00:00:00Z', updated_at: '2026-11-08T00:00:00Z',
} satisfies LaterBoxItem;
const item = (changes: Partial<LaterBoxItem> = {}): LaterBoxItem => ({ ...base, ...changes });

test('task checkbox follows the existing archived/active lifecycle', () => {
  assert.equal(isTaskComplete(item({ type: 'task', status: 'inbox' })), false);
  assert.equal(isTaskComplete(item({ type: 'task', status: 'saved' })), false);
  assert.equal(isTaskComplete(item({ type: 'task', status: 'archived' })), true);
  assert.equal(isTaskComplete(item({ type: 'task', status: 'archived', deleted_at: '2026-11-08T01:00:00Z' })), false);
  assert.equal(isTaskComplete(item({ type: 'note', status: 'archived' })), false);
});

test('reader needs actual article content, not plain text or an OG preview', () => {
  assert.equal(shouldShowArticleReader(item({type:'note',text_content:'My note'}), 'My note', null), false);
  assert.equal(shouldShowArticleReader(item({type:'task',text_content:'Finish homework'}), 'Finish homework', null), false);
  assert.equal(shouldShowArticleReader(item({type:'link',text_content:'Saved snippet'}), 'Saved snippet', null), false);
  assert.equal(shouldShowArticleReader(item({type:'article'}), null, null), false);
  assert.equal(shouldShowArticleReader(item({type:'article'}), '# Article body', null), true);
  assert.equal(shouldShowArticleReader(item({type:'link',metadata: { content_type:'article' } as LaterBoxItem['metadata']}), '# Reader', null), true);
  assert.equal(shouldShowArticleReader(item({type:'file',attachments:[]}), '# Long text', null), false);
});

test('reader supports long captured pages but blocks media, task and file content', () => {
  const snapshot = {kind:'page',markdown:'Paragraph. '.repeat(36)} as LaterBoxItem['content'];
  assert.equal(shouldShowArticleReader(item({content:snapshot}), snapshot!.markdown, null), true);
  assert.equal(shouldShowArticleReader(item({content:snapshot,url:'https://youtube.com/watch?v=x'}),snapshot!.markdown,null),false);
  assert.equal(shouldShowArticleReader(item({content:snapshot,type:'task'}),snapshot!.markdown,null),false);
  assert.equal(shouldShowArticleReader(item({content:snapshot,attachments:[{id:'a'}] as LaterBoxItem['attachments']}),snapshot!.markdown,null),false);
});

test('only HTTP and HTTPS URLs are eligible external-image destinations', () => {
  assert.equal(safeExternalItemUrl('https://example.com/path'), 'https://example.com/path');
  assert.equal(safeExternalItemUrl('http://example.com/'), 'http://example.com/');
  assert.equal(safeExternalItemUrl('javascript:alert(1)'),null);
  assert.equal(safeExternalItemUrl('data:text/html,hello'),null);
  assert.equal(safeExternalItemUrl('file:///etc/passwd'),null);
  assert.equal(safeExternalItemUrl('not-a-url'),null);
  assert.equal(safeExternalItemUrl(null),null);
});
