import assert from 'node:assert/strict';
import test from 'node:test';
import { collectionNameKey, planCollectionMerge, remapItemCollections } from './collection-dedup';
import type { Collection, LaterBoxItem } from '../supabase/types';

const at = '2026-11-07T10:00:00Z';
const collection = (id: string, name: string, created_at = at, owner = 'account'): Collection => ({
  id, user_id: owner, name, created_at, updated_at: at,
});
const item = (id: string, cols: Collection[]): LaterBoxItem => ({
  id, user_id: 'account', title: id, type: 'note', favorite: false, status: 'inbox',
  created_at: at, updated_at: at, collections: cols,
});

test('case and whitespace variants use the oldest stable collection id', () => {
  const oldest = collection('old-reading', 'Reading', '2026-10-01T00:00:00Z');
  const recent = collection('recent-reading', ' reading ', '2026-11-01T00:00:00Z');
  const inbox = collection('inbox', 'Inbox');
  const plan = planCollectionMerge([recent, inbox, oldest]);
  assert.equal(collectionNameKey(' INBOX '), 'inbox');
  assert.deepEqual(plan.collections.map(c => c.id), ['inbox', 'old-reading']);
  assert.deepEqual(plan.duplicates.map(d => [d.duplicate.id, d.canonical.id]), [['recent-reading', 'old-reading']]);
});

test('all memberships are united, with no duplicate items or references', () => {
  const original = collection('old', 'Inbox', '2026-10-01T00:00:00Z');
  const aliases = Array.from({ length: 14 }, (_, index) =>
    collection(`alias-${index}`, 'inbox ', '2026-11-01T00:00:00Z')
  );
  const plan = planCollectionMerge([original, ...aliases]);
  const items = [item('one', [original]), ...aliases.map((c, i) => item(`item-${i}`, [c]))];
  items.push(item('both', [aliases[0], original, aliases[1]]));

  const normalized = remapItemCollections(items, plan.canonicalById);
  assert.equal(plan.collections.length, 1);
  assert.equal(normalized.length, 16);
  assert.equal(normalized.filter(i => i.collections?.some(c => c.id === 'old')).length, 16);
  assert.deepEqual(normalized.find(i => i.id === 'both')?.collections?.map(c => c.id), ['old']);
});

test('different accounts and distinct names never merge; tombstones do not return', () => {
  const first = collection('a', 'Work');
  const otherOwner = collection('b', 'work', at, 'second-account');
  const different = collection('c', 'Personal');
  const deleted = { ...collection('d', 'Work'), deleted_at: '2026-11-07T15:00:00Z' };
  const plan = planCollectionMerge([first, otherOwner, different, deleted]);
  assert.deepEqual(plan.collections.map(c => c.id), ['a', 'b', 'c']);
  assert.equal(plan.duplicates.length, 0);
});

test('normalizing already normalized data is idempotent', () => {
  const one = collection('one', 'Reading');
  const another = collection('two', ' reading ');
  const original = [item('same', [one, another])];
  const first = planCollectionMerge([another, one]);
  const once = remapItemCollections(original, first.canonicalById);
  const second = planCollectionMerge(first.collections);
  const twice = remapItemCollections(once, second.canonicalById);
  assert.deepEqual(twice, once);
});
