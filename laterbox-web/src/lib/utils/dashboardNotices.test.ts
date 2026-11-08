// laterbox-web/src/lib/utils/dashboardNotices.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { nextNoticeId, visibleNotices } from './dashboardNotices';

const notices = [
  { id: 'guest', title: 'Sign in' },
  { id: 'extension', title: 'Connect' },
  { id: 'sync', title: 'Sync warning' },
];

test('dismissing one notice does not dismiss other notices', () => {
  const dismissed = new Set(['extension']);
  assert.deepEqual(visibleNotices(notices, dismissed).map(n => n.id), ['guest', 'sync']);
  assert.deepEqual(visibleNotices(notices, new Set()).map(n => n.id), ['guest', 'extension', 'sync']);
});

test('closing the current notice advances safely to a still-visible notice', () => {
  const next = nextNoticeId(notices.map(n => n.id), 'guest');
  assert.equal(next, 'extension');
  const rest = visibleNotices(notices, new Set(['guest']));
  assert.equal(nextNoticeId(rest.map(n => n.id), next), 'sync');
  assert.equal(nextNoticeId(['extension'], 'guest'), 'extension');
  assert.equal(nextNoticeId([], 'guest'), null);
});

test('manual previous and next navigation wrap without losing items', () => {
  const ids = notices.map(n => n.id);
  assert.equal(nextNoticeId(ids, 'sync'), 'guest');
  assert.equal(nextNoticeId(ids, 'guest', -1), 'sync');
  assert.equal(nextNoticeId(ids, 'extension', -1), 'guest');
});

test('duplicate and empty IDs are not rendered as separate notices', () => {
  assert.deepEqual(
    visibleNotices([...notices, notices[0], { id: '', title: 'Invalid' }], new Set()).map(n => n.id),
    ['guest', 'extension', 'sync'],
  );
});
