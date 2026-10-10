import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  parseItemThread,
  serializeItemThread,
  toggleRootReaction,
  toggleThreadReaction,
  addThreadEntry,
} from './itemThread';

test('parseItemThread handles empty and plain-text fallback', () => {
  assert.deepEqual(parseItemThread(''), {
    entries: [],
    rootReactions: {},
    rootUserReactions: [],
  });

  const fallback = parseItemThread('Just a quick note');
  assert.equal(fallback.entries.length, 1);
  assert.equal(fallback.entries[0].content, 'Just a quick note');
  assert.deepEqual(fallback.rootReactions, {});
});

test('serializeItemThread and parseItemThread preserve entries and rootReactions', () => {
  const entries = addThreadEntry([], {
    type: 'message',
    authorName: 'Alex',
    content: 'First followup',
  });

  const serialized = serializeItemThread(entries, { '🔥': 2 }, ['🔥']);
  const parsed = parseItemThread(serialized);

  assert.equal(parsed.entries.length, 1);
  assert.equal(parsed.entries[0].content, 'First followup');
  assert.equal(parsed.rootReactions['🔥'], 2);
  assert.deepEqual(parsed.rootUserReactions, ['🔥']);
});

test('toggleRootReaction increments and removes emoji reaction', () => {
  // 1. Add reaction
  const first = toggleRootReaction({}, [], '❤️');
  assert.equal(first.reactions['❤️'], 1);
  assert.deepEqual(first.userReactions, ['❤️']);

  // 2. Remove reaction
  const second = toggleRootReaction(first.reactions, first.userReactions, '❤️');
  assert.equal(second.reactions['❤️'], undefined);
  assert.deepEqual(second.userReactions, []);
});
