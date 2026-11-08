// laterbox-web/src/components/marketing/dashboard-preview-model.test.ts
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { changeDemoItem, DEMO_ITEMS, demoCount, demoVisibleItems, makeDemoItem } from './dashboard-preview-model';

describe('Marketing dashboard preview', () => {
  it('separates sample inbox, scheduled items, collections, and completed items', () => {
    assert.equal(demoCount(DEMO_ITEMS, 'inbox'), 3);
    assert.equal(demoCount(DEMO_ITEMS, 'today'), 2);
    assert.equal(demoCount(DEMO_ITEMS, 'upcoming'), 1);
    assert.equal(demoCount(DEMO_ITEMS, 'someday'), 2);
    assert.equal(demoCount(DEMO_ITEMS, 'done'), 1);
    assert.equal(demoCount(DEMO_ITEMS, 'home'), DEMO_ITEMS.length - 1);
  });

  it('filters by search query, collection, and starred section', () => {
    assert.equal(demoVisibleItems(DEMO_ITEMS, 'home', 'WORKSPACE').length, 1);
    assert.equal(demoVisibleItems(DEMO_ITEMS, 'collections', '', 'Design').length, 3);
    assert.equal(demoVisibleItems(DEMO_ITEMS, 'starred').length, 2);
    assert.equal(demoVisibleItems(DEMO_ITEMS, 'home', 'not-present').length, 0);
  });

  it('updates only the targeted sample item without mutating original fixtures', () => {
    const before = structuredClone(DEMO_ITEMS);
    let items = changeDemoItem(DEMO_ITEMS, { type: 'star', id: 'idea-02' });
    assert.equal(items.find(item => item.id === 'idea-02')?.starred, true);
    items = changeDemoItem(items, { type: 'move', id: 'idea-02', bucket: 'someday' });
    assert.equal(items.find(item => item.id === 'idea-02')?.bucket, 'someday');
    items = changeDemoItem(items, { type: 'complete', id: 'idea-02' });
    assert.equal(demoVisibleItems(items, 'done').some(item => item.id === 'idea-02'), true);
    items = changeDemoItem(items, { type: 'complete', id: 'idea-02' });
    assert.equal(items.find(item => item.id === 'idea-02')?.bucket, 'inbox');
    items = changeDemoItem(items, { type: 'delete', id: 'idea-02' });
    assert.equal(items.some(item => item.id === 'idea-02'), false);
    assert.deepEqual(DEMO_ITEMS, before);
  });

  it('creates local-only sample links and rejects invalid inputs', () => {
    const item = makeDemoItem('test-id', 'https://example.com/a', 'New design idea', 'today');
    assert.equal(item?.source, 'example.com');
    assert.equal(item?.bucket, 'today');
    assert.equal(makeDemoItem('bad', 'javascript:alert(1)', 'Unsafe', 'inbox'), null);
    assert.equal(makeDemoItem('bad', 'file:///private/a.txt', 'Unsafe', 'inbox'), null);
    assert.equal(makeDemoItem('bad', 'https://example.com', '', 'inbox'), null);
  });
});
