import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  parseItemThread,
  serializeItemThread,
  toggleRootReaction,
  toggleThreadReaction,
  addThreadEntry,
  deleteThreadEntry,
  editThreadEntry,
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

test('serializeItemThread and parseItemThread preserve attachments', () => {
  const entries = addThreadEntry([], {
    type: 'document',
    authorName: 'Alex',
    content: 'Attached quarterly report',
    attachments: [
      {
        id: 'att-123',
        name: 'Report.pdf',
        size: 1048576,
        type: 'application/pdf',
        extension: 'pdf',
      },
    ],
  });

  const serialized = serializeItemThread(entries);
  const parsed = parseItemThread(serialized);

  assert.equal(parsed.entries.length, 1);
  assert.equal(parsed.entries[0].type, 'document');
  assert.equal(parsed.entries[0].attachments?.length, 1);
  assert.equal(parsed.entries[0].attachments?.[0].name, 'Report.pdf');
  assert.equal(parsed.entries[0].attachments?.[0].size, 1048576);
});

test('iOS chat JSON is rendered as entries and remains editable across clients', () => {
  const iosNote = JSON.stringify({
    rootReactions: {},
    rootUserReactions: [],
    version: 1,
    entries: [
      {
        reactions: {},
        type: 'message',
        userReactions: [],
        createdAt: '2026-11-08T22:17:01Z',
        id: 'entry-1794176221024-AF165',
        content: 'Anime vs movies',
        authorName: 'Me',
      },
    ],
  });

  const thread = parseItemThread(iosNote);
  assert.equal(thread.entries.length, 1);
  assert.equal(thread.entries[0].content, 'Anime vs movies');
  assert.equal(thread.entries[0].authorName, 'Me');
  assert.equal(thread.entries[0].type, 'message');

  const reply = addThreadEntry(thread.entries, {
    type: 'message',
    authorName: 'Me',
    content: 'I prefer anime for storytelling',
    attachedToId: thread.entries[0].id,
    attachedSnippet: thread.entries[0].content,
  });
  const serialized = serializeItemThread(reply, thread.rootReactions, thread.rootUserReactions);
  const parsed = parseItemThread(serialized);
  assert.equal(parsed.entries.length, 2);
  assert.equal(parsed.entries[1].attachedSnippet, 'Anime vs movies');
  assert.equal(parsed.entries[1].attachedToId, 'entry-1794176221024-AF165');

  const reacted = toggleThreadReaction(parsed.entries, parsed.entries[0].id, '❤️');
  const edited = editThreadEntry(reacted, parsed.entries[1].id, 'Updated');
  const afterDeletion = deleteThreadEntry(edited, parsed.entries[1].id);
  assert.equal(afterDeletion.length, 1);
  assert.equal(afterDeletion[0].content, 'Anime vs movies');
  assert.equal(afterDeletion[0].reactions?.['❤️'], 1);
});
