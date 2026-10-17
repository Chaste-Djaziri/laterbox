import test from 'node:test';
import assert from 'node:assert/strict';
import {
  SyncQueueManager,
  getItemActionTimestamp,
  resolveActionConflict,
  reconcileItemsWithRemote,
  queueCapture,
  queueHardDelete,
  clearPendingItem,
  getPendingQueue,
} from './pending-captures';
import type { LaterBoxItem } from '../supabase/types';

function createMockItem(overrides: Partial<LaterBoxItem>): LaterBoxItem {
  const id = overrides.id || 'item-1';
  return {
    id,
    user_id: overrides.user_id !== undefined ? overrides.user_id : 'user-123',
    url: overrides.url !== undefined ? overrides.url : `https://example.com/${id}`,
    title: overrides.title || 'Example Title',
    text_content: overrides.text_content || null,
    text_selector: overrides.text_selector || null,
    type: overrides.type || 'link',
    favorite: overrides.favorite || false,
    seen: overrides.seen ?? false,
    status: overrides.status || 'inbox',
    return_at: overrides.return_at !== undefined ? overrides.return_at : null,
    created_at: overrides.created_at || '2026-10-11T01:00:00.000Z',
    updated_at: overrides.updated_at || '2026-10-11T01:00:00.000Z',
    deleted_at: overrides.deleted_at !== undefined ? overrides.deleted_at : null,
    attachments: overrides.attachments || [],
    metadata: overrides.metadata || null,
  };
}

test('pull retains a pending attachment even when the remote text-only item is newer', () => {
  const local = createMockItem({ attachments: [{
    id: 'photo', item_id: 'item-1', user_id: 'user-123', original_file_name: 'photo.jpg',
    file_extension: 'jpg', mime_type: 'image/jpeg', byte_size: 10,
    created_at: '2026-10-11T01:00:00.000Z', updated_at: '2026-10-11T01:00:00.000Z',
  }] });
  const remote = createMockItem({ updated_at: '2026-10-12T01:00:00.000Z' });
  const result = reconcileItemsWithRemote({ remoteActive: [remote], remoteDeleted: [],
    localCached: [local], localDeleted: [], pendingQueue: { [local.id]: local } });
  assert.deepEqual(result.queueIdsToRemove, []);
  assert.deepEqual(result.itemsToPush, [local]);
  assert.equal(result.reconciledActive[0].attachments?.[0].id, 'photo');
});

test('SyncQueueManager executes tasks strictly in serial queue order', async () => {
  const queue = new SyncQueueManager();
  const order: number[] = [];
  let concurrent = 0;
  let maxConcurrent = 0;

  const makeTask = (id: number, delayMs: number) => async () => {
    concurrent++;
    maxConcurrent = Math.max(maxConcurrent, concurrent);
    await new Promise(resolve => setTimeout(resolve, delayMs));
    order.push(id);
    concurrent--;
    return id;
  };

  const p1 = queue.enqueue('user-1', makeTask(1, 25));
  const p2 = queue.enqueue('user-1', makeTask(2, 10));
  const p3 = queue.enqueue('user-1', makeTask(3, 5));

  const results = await Promise.all([p1, p2, p3]);

  assert.deepEqual(results, [1, 2, 3]);
  assert.deepEqual(order, [1, 2, 3]);
  assert.equal(maxConcurrent, 1, 'Tasks must run one at a time');
  assert.equal(queue.isBusy('user-1'), false);
});

test('SyncQueueManager isolates errors and continues processing queued tasks', async () => {
  const queue = new SyncQueueManager();
  const executed: string[] = [];

  const p1 = queue.enqueue('user-1', async () => {
    executed.push('task1');
    throw new Error('Task 1 failed');
  });

  const p2 = queue.enqueue('user-1', async () => {
    executed.push('task2');
    return 'ok';
  });

  await assert.rejects(p1, /Task 1 failed/);
  const result2 = await p2;

  assert.equal(result2, 'ok');
  assert.deepEqual(executed, ['task1', 'task2']);
});

test('getItemActionTimestamp resolves the latest timestamp across deletion, update, and creation', () => {
  const item1 = createMockItem({
    created_at: '2026-10-11T01:00:00.000Z',
    updated_at: '2026-10-11T01:05:00.000Z',
    deleted_at: null,
  });
  assert.equal(getItemActionTimestamp(item1), new Date('2026-10-11T01:05:00.000Z').getTime());

  const item2 = createMockItem({
    created_at: '2026-10-11T01:00:00.000Z',
    updated_at: '2026-10-11T01:05:00.000Z',
    deleted_at: '2026-10-11T01:10:00.000Z',
  });
  assert.equal(getItemActionTimestamp(item2), new Date('2026-10-11T01:10:00.000Z').getTime());

  assert.equal(getItemActionTimestamp(null), 0);
  assert.equal(getItemActionTimestamp(undefined), 0);
});

test('resolveActionConflict: remote newer edit wins over local older edit', () => {
  const local = createMockItem({
    id: 'item-1',
    title: 'Local Older Title',
    updated_at: '2026-10-11T01:00:00.000Z',
  });
  const remote = createMockItem({
    id: 'item-1',
    title: 'Remote Newer Title',
    updated_at: '2026-10-11T01:05:00.000Z',
  });

  const resolution = resolveActionConflict(local, remote);
  assert.equal(resolution.winner, 'remote');
  assert.equal(resolution.shouldPush, false);
  assert.equal(resolution.item.title, 'Remote Newer Title');
});

test('resolveActionConflict: local newer edit wins over remote older state and marks for push', () => {
  const local = createMockItem({
    id: 'item-1',
    title: 'Local Newer Title',
    updated_at: '2026-10-11T01:10:00.000Z',
  });
  const remote = createMockItem({
    id: 'item-1',
    title: 'Remote Older Title',
    updated_at: '2026-10-11T01:05:00.000Z',
  });

  const resolution = resolveActionConflict(local, remote);
  assert.equal(resolution.winner, 'local');
  assert.equal(resolution.shouldPush, true);
  assert.equal(resolution.item.title, 'Local Newer Title');
});

test('resolveActionConflict: remote newer deletion beats local older edit', () => {
  const local = createMockItem({
    id: 'item-1',
    updated_at: '2026-10-11T01:00:00.000Z',
    deleted_at: null,
  });
  const remote = createMockItem({
    id: 'item-1',
    updated_at: '2026-10-11T01:05:00.000Z',
    deleted_at: '2026-10-11T01:05:00.000Z',
  });

  const resolution = resolveActionConflict(local, remote);
  assert.equal(resolution.winner, 'remote');
  assert.equal(resolution.shouldPush, false);
  assert.equal(resolution.item.deleted_at, '2026-10-11T01:05:00.000Z');
});

test('resolveActionConflict: local newer deletion beats remote older edit', () => {
  const local = createMockItem({
    id: 'item-1',
    updated_at: '2026-10-11T01:10:00.000Z',
    deleted_at: '2026-10-11T01:10:00.000Z',
  });
  const remote = createMockItem({
    id: 'item-1',
    updated_at: '2026-10-11T01:05:00.000Z',
    deleted_at: null,
  });

  const resolution = resolveActionConflict(local, remote);
  assert.equal(resolution.winner, 'local');
  assert.equal(resolution.shouldPush, true);
  assert.equal(resolution.item.deleted_at, '2026-10-11T01:10:00.000Z');
});

test('resolveActionConflict: local newer restoration beats remote older deletion', () => {
  const remote = createMockItem({
    id: 'item-1',
    updated_at: '2026-10-11T01:00:00.000Z',
    deleted_at: '2026-10-11T01:00:00.000Z',
  });
  const local = createMockItem({
    id: 'item-1',
    status: 'inbox',
    updated_at: '2026-10-11T01:15:00.000Z',
    deleted_at: null,
  });

  const resolution = resolveActionConflict(local, remote);
  assert.equal(resolution.winner, 'local');
  assert.equal(resolution.shouldPush, true);
  assert.equal(resolution.item.deleted_at, null);
});

test('reconcileItemsWithRemote pulls remote first and drops outdated local queue entry', () => {
  const remoteItem = createMockItem({
    id: 'synced-item',
    title: 'Cloud Winning Title',
    updated_at: '2026-10-11T01:30:00.000Z',
  });

  const localStalePending = createMockItem({
    id: 'synced-item',
    title: 'Offline Stale Title',
    updated_at: '2026-10-11T01:10:00.000Z',
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [remoteItem],
    remoteDeleted: [],
    localCached: [localStalePending],
    localDeleted: [],
    pendingQueue: {
      'synced-item': localStalePending,
    },
  });

  // Remote wins
  assert.equal(result.reconciledActive.length, 1);
  assert.equal(result.reconciledActive[0].title, 'Cloud Winning Title');
  assert.deepEqual(result.itemsToPush, []);
  assert.deepEqual(result.queueIdsToRemove, ['synced-item']);
});

test('reconcileItemsWithRemote keeps and pushes newer local actions', () => {
  const remoteOlder = createMockItem({
    id: 'item-to-update',
    favorite: false,
    updated_at: '2026-10-11T01:00:00.000Z',
  });

  const localNewer = createMockItem({
    id: 'item-to-update',
    favorite: true,
    updated_at: '2026-10-11T01:45:00.000Z',
  });

  const brandNewOffline = createMockItem({
    id: 'brand-new-item',
    title: 'Created Offline',
    updated_at: '2026-10-11T01:40:00.000Z',
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [remoteOlder],
    remoteDeleted: [],
    localCached: [localNewer, brandNewOffline],
    localDeleted: [],
    pendingQueue: {
      'item-to-update': localNewer,
      'brand-new-item': brandNewOffline,
    },
  });

  assert.equal(result.reconciledActive.length, 2);
  assert.equal(result.itemsToPush.length, 2);
  assert.ok(result.itemsToPush.some(i => i.id === 'item-to-update' && i.favorite === true));
  assert.ok(result.itemsToPush.some(i => i.id === 'brand-new-item'));
  assert.deepEqual(result.queueIdsToRemove, []);
});

test('reconcileItemsWithRemote handles queued hard delete correctly', () => {
  const remoteItem = createMockItem({
    id: 'to-hard-delete',
    updated_at: '2026-10-11T01:00:00.000Z',
  });

  const hardDeleteEntry = {
    id: 'to-hard-delete',
    user_id: 'user-123',
    updated_at: '2026-10-11T01:20:00.000Z',
    deleted_at: '2026-10-11T01:20:00.000Z',
    _action: 'hard_delete',
  } as any;

  const result = reconcileItemsWithRemote({
    remoteActive: [remoteItem],
    remoteDeleted: [],
    localCached: [],
    localDeleted: [],
    pendingQueue: {
      'to-hard-delete': hardDeleteEntry,
    },
  });

  assert.deepEqual(result.hardDeletesToPush, ['to-hard-delete']);
  assert.equal(result.reconciledActive.length, 0);
  assert.equal(result.reconciledDeleted.length, 0);
});

test('queueCapture, queueHardDelete, and clearPendingItem operate on localStorage queue', () => {
  const store = new Map<string, string>();
  const original = Object.getOwnPropertyDescriptor(globalThis, 'localStorage');
  Object.defineProperty(globalThis, 'localStorage', {
    configurable: true,
    value: {
      getItem: (key: string) => store.get(key) ?? null,
      setItem: (key: string, value: string) => store.set(key, value),
    },
  });

  try {
    const itemA = createMockItem({ id: 'item-a', user_id: 'user-xyz', updated_at: '2026-10-11T01:00:00.000Z' });
    queueCapture(itemA);

    let queue = getPendingQueue('user-xyz');
    assert.ok(queue['item-a']);
    assert.equal(queue['item-a'].id, 'item-a');

    queueHardDelete('user-xyz', 'item-b');
    queue = getPendingQueue('user-xyz');
    assert.ok(queue['item-b']);
    assert.equal((queue['item-b'] as any)._action, 'hard_delete');

    // clearPendingItem with matching timestamp clears it
    clearPendingItem('user-xyz', 'item-a', '2026-10-11T01:00:00.000Z');
    queue = getPendingQueue('user-xyz');
    assert.equal(queue['item-a'], undefined);
    assert.ok(queue['item-b']);

    // clearPendingItem with mismatched timestamp does not remove it (avoids racing new updates)
    clearPendingItem('user-xyz', 'item-b', 'wrong-timestamp');
    queue = getPendingQueue('user-xyz');
    assert.ok(queue['item-b']);

    // unconditional clear removes it
    clearPendingItem('user-xyz', 'item-b');
    queue = getPendingQueue('user-xyz');
    assert.equal(queue['item-b'], undefined);
  } finally {
    if (original) Object.defineProperty(globalThis, 'localStorage', original);
    else Reflect.deleteProperty(globalThis, 'localStorage');
  }
});

test('items preserve and propagate seen attribute across local queue and reconciliation', () => {
  const itemSeen = createMockItem({
    id: 'item-seen',
    status: 'inbox',
    seen: true,
    updated_at: '2026-10-11T02:00:00.000Z',
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [itemSeen],
    remoteDeleted: [],
    localCached: [],
    localDeleted: [],
    pendingQueue: {},
  });

  assert.equal(result.reconciledActive.length, 1);
  assert.equal(result.reconciledActive[0].seen, true);
});

test('conflict resolution: local recent delete beats remote older edit and marks for push', () => {
  const remoteItem = createMockItem({
    id: 'item-conflict-1',
    title: 'Remote Title',
    updated_at: '2026-10-11T01:00:00.000Z',
    deleted_at: null,
  });

  const localDeleted = createMockItem({
    id: 'item-conflict-1',
    title: 'Local Deleted',
    updated_at: '2026-10-11T02:00:00.000Z',
    deleted_at: '2026-10-11T02:00:00.000Z',
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [remoteItem],
    remoteDeleted: [],
    localCached: [],
    localDeleted: [localDeleted],
    pendingQueue: { 'item-conflict-1': localDeleted },
  });

  assert.equal(result.reconciledActive.length, 0);
  assert.equal(result.reconciledDeleted.length, 1);
  assert.equal(result.reconciledDeleted[0].id, 'item-conflict-1');
  assert.equal(result.itemsToPush.length, 1);
  assert.equal(result.itemsToPush[0].deleted_at, '2026-10-11T02:00:00.000Z');
  assert.equal(result.queueIdsToRemove.length, 0);
});

test('conflict resolution: remote recent delete beats local older edit and clears queue', () => {
  const remoteDeleted = createMockItem({
    id: 'item-conflict-2',
    title: 'Remote Deleted',
    updated_at: '2026-10-11T03:00:00.000Z',
    deleted_at: '2026-10-11T03:00:00.000Z',
  });

  const localEdited = createMockItem({
    id: 'item-conflict-2',
    title: 'Local Older Edit',
    updated_at: '2026-10-11T01:00:00.000Z',
    deleted_at: null,
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [],
    remoteDeleted: [remoteDeleted],
    localCached: [localEdited],
    localDeleted: [],
    pendingQueue: { 'item-conflict-2': localEdited },
  });

  assert.equal(result.reconciledActive.length, 0);
  assert.equal(result.reconciledDeleted.length, 1);
  assert.equal(result.reconciledDeleted[0].id, 'item-conflict-2');
  assert.equal(result.itemsToPush.length, 0);
  assert.deepEqual(result.queueIdsToRemove, ['item-conflict-2']);
});

test('conflict resolution: local recent create beats remote and marks for push', () => {
  const localNewItem = createMockItem({
    id: 'item-conflict-3',
    title: 'Local New Item',
    created_at: '2026-10-11T04:00:00.000Z',
    updated_at: '2026-10-11T04:00:00.000Z',
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [],
    remoteDeleted: [],
    localCached: [localNewItem],
    localDeleted: [],
    pendingQueue: { 'item-conflict-3': localNewItem },
  });

  assert.equal(result.reconciledActive.length, 1);
  assert.equal(result.reconciledActive[0].id, 'item-conflict-3');
  assert.equal(result.itemsToPush.length, 1);
  assert.equal(result.itemsToPush[0].id, 'item-conflict-3');
  assert.equal(result.queueIdsToRemove.length, 0);
});

test('conflict resolution: remote recent create pulls and updates active state without pushing', () => {
  const remoteNewItem = createMockItem({
    id: 'item-conflict-4',
    title: 'Remote New Item',
    created_at: '2026-10-11T05:00:00.000Z',
    updated_at: '2026-10-11T05:00:00.000Z',
  });

  const result = reconcileItemsWithRemote({
    remoteActive: [remoteNewItem],
    remoteDeleted: [],
    localCached: [],
    localDeleted: [],
    pendingQueue: {},
  });

  assert.equal(result.reconciledActive.length, 1);
  assert.equal(result.reconciledActive[0].id, 'item-conflict-4');
  assert.equal(result.itemsToPush.length, 0);
});

