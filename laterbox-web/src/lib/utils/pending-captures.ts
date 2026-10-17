import { getAccessToken, refreshAccessToken } from '../auth/tokens';
import { installationId, uploadWithNotificationHandoff } from '../notifications/client';
import type { LaterBoxItem, Attachment, Collection, ItemMetadata, ItemContent } from '../supabase/types';
import { getSupabaseClient } from '../supabase/client';
import { readLocalAttachment } from './local-attachments';
import { uploadAttachmentFile } from './attachment';
import { migrateSchedule } from './schedule';
import { createQueryRecovery } from './query-recovery';

export function itemRow(item: LaterBoxItem) {
  return {
    ...(typeof window !== 'undefined' ? { origin_installation_id: installationId() } : {}),
    id: item.id,
    user_id: item.user_id,
    url: item.url,
    title: item.title,
    text_content: item.text_content,
    text_selector: item.text_selector,
    type: item.type,
    favorite: item.favorite,
    status: item.status,
    return_at: item.return_at ?? null,
    created_at: item.created_at,
    updated_at: item.updated_at,
    deleted_at: item.deleted_at ?? null,
  };
}

export const queueKey = (userId: string) => `laterbox_pending_captures_${userId}`;

export function getPendingQueue(userId: string): Record<string, LaterBoxItem> {
  if (typeof localStorage === 'undefined' || !userId) return {};
  try {
    return JSON.parse(localStorage.getItem(queueKey(userId)) || '{}');
  } catch {
    return {};
  }
}

export function queueCapture(item: LaterBoxItem) {
  if (!item.user_id || typeof localStorage === 'undefined') return;
  const queue = getPendingQueue(item.user_id);
  queue[item.id] = item;
  localStorage.setItem(queueKey(item.user_id), JSON.stringify(queue));
}

export function queueHardDelete(userId: string, itemId: string) {
  if (!userId || typeof localStorage === 'undefined') return;
  const queue = getPendingQueue(userId);
  const now = new Date().toISOString();
  queue[itemId] = {
    id: itemId,
    user_id: userId,
    title: 'Deleted',
    url: null,
    text_content: null,
    text_selector: null,
    type: 'link',
    favorite: false,
    status: 'inbox',
    return_at: null,
    created_at: now,
    updated_at: now,
    deleted_at: now,
    _action: 'hard_delete',
  } as any;
  localStorage.setItem(queueKey(userId), JSON.stringify(queue));
}

export function clearPendingItem(userId: string, itemId: string, expectedUpdatedAt?: string) {
  if (!userId || typeof localStorage === 'undefined') return;
  const queue = getPendingQueue(userId);
  if (!queue[itemId]) return;
  if (expectedUpdatedAt && queue[itemId].updated_at !== expectedUpdatedAt) return;
  delete queue[itemId];
  localStorage.setItem(queueKey(userId), JSON.stringify(queue));
}

export function getItemActionTimestamp(item?: { updated_at?: string | null; deleted_at?: string | null; created_at?: string | null } | null): number {
  if (!item) return 0;
  const tDel = item.deleted_at ? new Date(item.deleted_at).getTime() : 0;
  const tUpd = item.updated_at ? new Date(item.updated_at).getTime() : 0;
  const tCre = item.created_at ? new Date(item.created_at).getTime() : 0;
  return Math.max(isNaN(tDel) ? 0 : tDel, isNaN(tUpd) ? 0 : tUpd, isNaN(tCre) ? 0 : tCre);
}

export interface ConflictResolution<T extends LaterBoxItem> {
  winner: 'remote' | 'local' | 'same';
  item: T;
  shouldPush: boolean;
}

export function resolveActionConflict<T extends LaterBoxItem>(
  localItem: T | undefined,
  remoteItem: T | undefined
): ConflictResolution<T> {
  if (!remoteItem && localItem) {
    return { winner: 'local', item: localItem, shouldPush: true };
  }
  if (remoteItem && !localItem) {
    return { winner: 'remote', item: remoteItem, shouldPush: false };
  }
  if (!remoteItem && !localItem) {
    throw new Error('Both local and remote items are undefined');
  }

  const localTime = getItemActionTimestamp(localItem);
  const remoteTime = getItemActionTimestamp(remoteItem);

  if (remoteTime > localTime) {
    // Remote is newer (another device acted later)
    return { winner: 'remote', item: remoteItem!, shouldPush: false };
  } else if (localTime > remoteTime) {
    // Local is newer (this device acted later)
    return { winner: 'local', item: localItem!, shouldPush: true };
  } else {
    // Equal timestamp
    if (localItem!.deleted_at && !remoteItem!.deleted_at) {
      return { winner: 'local', item: localItem!, shouldPush: true };
    }
    if (remoteItem!.deleted_at && !localItem!.deleted_at) {
      return { winner: 'remote', item: remoteItem!, shouldPush: false };
    }
    return { winner: 'same', item: remoteItem!, shouldPush: false };
  }
}

export interface ReconcileParams {
  remoteActive: LaterBoxItem[];
  remoteDeleted: LaterBoxItem[];
  localCached: LaterBoxItem[];
  localDeleted: LaterBoxItem[];
  pendingQueue: Record<string, LaterBoxItem>;
}

export interface ReconcileResult {
  reconciledActive: LaterBoxItem[];
  reconciledDeleted: LaterBoxItem[];
  itemsToPush: LaterBoxItem[];
  hardDeletesToPush: string[];
  queueIdsToRemove: string[];
}

export function reconcileItemsWithRemote(params: ReconcileParams): ReconcileResult {
  const { remoteActive, remoteDeleted, localCached, localDeleted, pendingQueue } = params;

  const remoteActiveMap = new Map(remoteActive.map(i => [i.id, i]));
  const remoteDeletedMap = new Map(remoteDeleted.map(i => [i.id, i]));
  const localCachedMap = new Map(localCached.map(i => [i.id, i]));
  const localDeletedMap = new Map(localDeleted.map(i => [i.id, i]));

  const allIds = new Set<string>([
    ...remoteActiveMap.keys(),
    ...remoteDeletedMap.keys(),
    ...localCachedMap.keys(),
    ...localDeletedMap.keys(),
    ...Object.keys(pendingQueue),
  ]);

  const reconciledActive: LaterBoxItem[] = [];
  const reconciledDeleted: LaterBoxItem[] = [];
  const itemsToPush: LaterBoxItem[] = [];
  const hardDeletesToPush: string[] = [];
  const queueIdsToRemove: string[] = [];

  for (const id of allIds) {
    const remote = remoteDeletedMap.get(id) || remoteActiveMap.get(id);
    const local = pendingQueue[id] || localDeletedMap.get(id) || localCachedMap.get(id);

    const isPending = Boolean(pendingQueue[id]);

    const hasUnpublishedAssets = isPending && !local?.deleted_at && local?.attachments?.some(asset =>
      !remote?.attachments?.some(remoteAsset => remoteAsset.id === asset.id && Boolean(remoteAsset.r2_object_key))
    );
    const resolution = hasUnpublishedAssets && local
      ? { winner: 'local' as const, item: local, shouldPush: true }
      : resolveActionConflict(local, remote);

    if (resolution.winner === 'remote') {
      // Remote wins
      if (isPending) {
        queueIdsToRemove.push(id);
      }
      if (resolution.item.deleted_at) {
        reconciledDeleted.push(resolution.item);
      } else {
        reconciledActive.push(resolution.item);
      }
    } else if (resolution.winner === 'local') {
      // Local wins
      const localItem = resolution.item;
      if ((localItem as any)._action === 'hard_delete') {
        hardDeletesToPush.push(id);
      } else if (localItem.deleted_at) {
        reconciledDeleted.push(localItem);
        if (isPending || !remote || getItemActionTimestamp(localItem) > getItemActionTimestamp(remote)) {
          itemsToPush.push(localItem);
        }
      } else {
        reconciledActive.push(localItem);
        if (isPending || !remote || getItemActionTimestamp(localItem) > getItemActionTimestamp(remote)) {
          itemsToPush.push(localItem);
        }
      }
    } else {
      // Equal timestamp (already in sync)
      if (isPending) {
        queueIdsToRemove.push(id);
      }
      if (resolution.item.deleted_at) {
        reconciledDeleted.push(resolution.item);
      } else {
        reconciledActive.push(resolution.item);
      }
    }
  }

  return {
    reconciledActive: deduplicateItems(reconciledActive),
    reconciledDeleted: deduplicateItems(reconciledDeleted),
    itemsToPush,
    hardDeletesToPush,
    queueIdsToRemove,
  };
}

function deduplicateItems(items: LaterBoxItem[]): LaterBoxItem[] {
  const seenIds = new Set<string>();
  const seenKeys = new Set<string>();
  const deduplicated: LaterBoxItem[] = [];

  for (const item of items) {
    if (seenIds.has(item.id)) continue;
    seenIds.add(item.id);

    const key = item.content?.capture_id
      ? `capture:${item.content.capture_id}`
      : item.url
        ? `url:${item.url}`
        : item.text_content
          ? `text:${item.text_content}`
          : null;

    if (key && seenKeys.has(key)) continue;
    if (key) seenKeys.add(key);

    deduplicated.push(item);
  }
  return deduplicated;
}

export function isAuthError(error: any): boolean {
  if (!error) return false;
  const status = error.status || error.statusCode || (error as any).response?.status;
  const code = String(error.code || '');
  const msg = typeof error.message === 'string' ? error.message.toLowerCase() : '';
  return (
    status === 401 ||
    status === 403 ||
    code === 'PGRST301' ||
    code === '401' ||
    code === '403' ||
    msg.includes('jwt') ||
    msg.includes('token') ||
    msg.includes('unauthorized') ||
    msg.includes('permission denied') ||
    msg.includes('session') ||
    msg.includes('auth') ||
    msg.includes('pgrst301')
  );
}

export class SyncQueueManager {
  private queues = new Map<string, Promise<any>>();
  private activeCount = new Map<string, number>();

  async enqueue<T>(userId: string, task: () => Promise<T>): Promise<T> {
    const current = this.queues.get(userId) || Promise.resolve();

    const next = current.then(async () => {
      this.activeCount.set(userId, (this.activeCount.get(userId) || 0) + 1);
      try {
        if (typeof navigator !== 'undefined' && navigator.locks && navigator.locks.request) {
          return await navigator.locks.request(`laterbox_sync_${userId}`, async () => {
            return await task();
          });
        }
        return await task();
      } finally {
        const count = (this.activeCount.get(userId) || 1) - 1;
        if (count <= 0) {
          this.activeCount.delete(userId);
        } else {
          this.activeCount.set(userId, count);
        }
      }
    });

    this.queues.set(userId, next.catch(() => {}));
    return next;
  }

  isBusy(userId: string): boolean {
    return (this.activeCount.get(userId) || 0) > 0;
  }
}

export const syncQueue = new SyncQueueManager();

function buildRemoteItem(
  row: any,
  metaMap: Map<string, any>,
  noteMap: Map<string, any>,
  attachmentMap: Map<string, Attachment[]>,
  itemColsMap: Map<string, Collection[]>,
  contentMap: Map<string, ItemContent>,
  localCached?: LaterBoxItem
): LaterBoxItem {
  const remoteMeta = metaMap.get(row.id);
  const localMeta = localCached?.metadata;
  const mergedMeta: ItemMetadata | null = remoteMeta || localMeta
    ? ({
        ...(localMeta || {}),
        ...(remoteMeta || {}),
        preview_image_url: remoteMeta?.preview_image_url || localMeta?.preview_image_url || null,
        title: remoteMeta?.title || localMeta?.title || null,
        structured_data: remoteMeta?.structured_data || localMeta?.structured_data || null,
        description: remoteMeta?.description || localMeta?.description || null,
        favicon_url: remoteMeta?.favicon_url || localMeta?.favicon_url || null,
      } as ItemMetadata)
    : null;

  const resolvedTitle =
    row.title && row.title !== 'New Capture' && !row.title.startsWith('http')
      ? row.title
      : (localCached?.title || row.title);

  const resolvedTextContent = row.text_content || localCached?.text_content || null;

  let remoteSeen = false;
  if (mergedMeta?.structured_data) {
    try {
      const parsed = typeof mergedMeta.structured_data === 'string'
        ? JSON.parse(mergedMeta.structured_data)
        : mergedMeta.structured_data;
      if (typeof parsed?.seen === 'boolean') {
        remoteSeen = parsed.seen;
      }
    } catch {}
  }
  const resolvedSeen = remoteSeen || (localCached?.seen ?? false);

  return {
    ...migrateSchedule(row),
    title: resolvedTitle,
    text_content: resolvedTextContent,
    metadata: mergedMeta,
    seen: resolvedSeen,
    content: contentMap.get(row.id) || localCached?.content || null,
    note: noteMap.get(row.id) || localCached?.note || null,
    collections: itemColsMap.get(row.id) || localCached?.collections || [],
    attachments: [
      ...new Map(
        [...(localCached?.attachments || []), ...(attachmentMap.get(row.id) || [])]
          .filter(att => !att.deleted_at)
          .map(att => [att.id, att])
      ).values(),
    ],
  };
}

export interface SyncCloudResult {
  items: LaterBoxItem[];
  deletedItems: LaterBoxItem[];
  collections: Collection[];
}

export async function checkRemoteChangesWeb(userId: string): Promise<{ pendingPullCount: number; pendingPushCount: number }> {
  if (!userId || typeof localStorage === 'undefined') {
    return { pendingPullCount: 0, pendingPushCount: 0 };
  }

  const pendingQueue = getPendingQueue(userId);
  const pendingPushCount = Object.keys(pendingQueue).length;

  try {
    const session = await getAccessToken();
    if (!session) {
      return { pendingPullCount: 0, pendingPushCount };
    }

    const client = getSupabaseClient();
    const { data: remoteRows, error } = await client
      .from('items')
      .select('id, updated_at, deleted_at, created_at')
      .eq('user_id', userId);

    if (error || !remoteRows) {
      return { pendingPullCount: 0, pendingPushCount };
    }

    const localCached = JSON.parse(localStorage.getItem(`laterbox_local_items_${userId}`) || '[]') as LaterBoxItem[];
    const localDeleted = JSON.parse(localStorage.getItem(`laterbox_local_deleted_items_${userId}`) || '[]') as LaterBoxItem[];
    const localMap = new Map<string, LaterBoxItem>();
    for (const item of localCached) localMap.set(item.id, item);
    for (const item of localDeleted) localMap.set(item.id, item);

    let pendingPullCount = 0;
    for (const row of remoteRows) {
      const local = localMap.get(row.id);
      if (!local) {
        pendingPullCount++;
      } else {
        const remoteTime = getItemActionTimestamp(row);
        const localTime = getItemActionTimestamp(local);
        if (remoteTime > localTime) {
          pendingPullCount++;
        }
      }
    }

    return { pendingPullCount, pendingPushCount };
  } catch (err) {
    console.warn('[checkRemoteChangesWeb] error checking remote changes:', err);
    return { pendingPullCount: 0, pendingPushCount };
  }
}

export async function pullCloudChanges(userId: string): Promise<SyncCloudResult | null> {
  if (!userId) return null;

  return syncQueue.enqueue(userId, async () => {
    const session = await getAccessToken();
    if (!session) return null;

    const client = getSupabaseClient();
    const recoverQuery = createQueryRecovery(refreshAccessToken);
    const fetchWithRetry: typeof recoverQuery = async query => {
      const result = await recoverQuery(query);
      if (result.error) throw result.error;
      return result;
    };

    // Step 1: PULL remote state first
    const { data: itemRows } = await fetchWithRetry(() =>
      client
        .from('items')
        .select('*')
        .eq('user_id', userId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
    );

    const { data: deletedRows } = await fetchWithRetry(() =>
      client
        .from('items')
        .select('*')
        .eq('user_id', userId)
        .not('deleted_at', 'is', null)
        .order('deleted_at', { ascending: false })
        .limit(100)
    );

    const { data: metaRows } = await fetchWithRetry(() =>
      client.from('item_metadata').select('*').eq('user_id', userId)
    );

    const { data: contentRows } = await fetchWithRetry(() =>
      client.from('item_content').select('*').eq('user_id', userId)
    );

    const { data: noteRows } = await fetchWithRetry(() =>
      client.from('item_notes').select('*').eq('user_id', userId).is('deleted_at', null)
    );

    const { data: attachmentRows } = await fetchWithRetry(() =>
      client.from('attachments').select('*').eq('user_id', userId).is('deleted_at', null)
    );

    const { data: colRows } = await fetchWithRetry(() =>
      client.from('collections').select('*').eq('user_id', userId).is('deleted_at', null).order('created_at', { ascending: false })
    );

    const { data: colItemRows } = await fetchWithRetry(() =>
      client.from('collection_items').select('*').eq('user_id', userId).is('deleted_at', null)
    );

    // Build lookup maps
    const contentMap = new Map((contentRows || []).map(c => [c.item_id, c as ItemContent]));
    const metaMap = new Map((metaRows || []).map(m => [m.item_id, m]));
    const noteMap = new Map((noteRows || []).map(n => [n.item_id, n]));
    const colMap = new Map((colRows || []).map(c => [c.id, c]));

    const attachmentMap = new Map<string, Attachment[]>();
    (attachmentRows || []).forEach(att => {
      const list = attachmentMap.get(att.item_id) || [];
      list.push(att);
      attachmentMap.set(att.item_id, list);
    });

    const itemColsMap = new Map<string, Collection[]>();
    (colItemRows || []).forEach(ci => {
      const col = colMap.get(ci.collection_id);
      if (col) {
        const list = itemColsMap.get(ci.item_id) || [];
        if (!list.some(existing => existing.id === col.id)) {
          list.push(col);
        }
        itemColsMap.set(ci.item_id, list);
      }
    });

    // Read local cache and pending queue
    const localCached = typeof localStorage !== 'undefined'
      ? (JSON.parse(localStorage.getItem(`laterbox_local_items_${userId}`) || '[]') as LaterBoxItem[])
      : [];
    const localDeleted = typeof localStorage !== 'undefined'
      ? (JSON.parse(localStorage.getItem(`laterbox_local_deleted_items_${userId}`) || '[]') as LaterBoxItem[])
      : [];
    const pendingQueue = getPendingQueue(userId);

    const localCachedMap = new Map(localCached.map(i => [i.id, i]));

    // Build complete remote items
    const remoteActive = (itemRows || []).map(row =>
      buildRemoteItem(row, metaMap, noteMap, attachmentMap, itemColsMap, contentMap, localCachedMap.get(row.id))
    );
    const remoteDeleted = (deletedRows || []).map(row =>
      buildRemoteItem(row, metaMap, noteMap, attachmentMap, itemColsMap, contentMap, localCachedMap.get(row.id))
    );

    // Step 2: RECONCILE (Last-Write-Wins comparison of action timestamps)
    const {
      reconciledActive,
      reconciledDeleted,
      itemsToPush,
      hardDeletesToPush,
      queueIdsToRemove,
    } = reconcileItemsWithRemote({
      remoteActive,
      remoteDeleted,
      localCached,
      localDeleted,
      pendingQueue,
    });

    // Remove obsolete items from local pending queue
    for (const id of queueIdsToRemove) {
      clearPendingItem(userId, id);
    }

    // Ensure winning local actions are tracked in pending queue to be pushed
    for (const item of itemsToPush) {
      if (!pendingQueue[item.id]) {
        queueCapture(item);
      }
    }
    for (const id of hardDeletesToPush) {
      if (!pendingQueue[id]) {
        queueHardDelete(userId, id);
      }
    }

    // Step 3: PERSIST authoritative reconciled state locally
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(`laterbox_local_items_${userId}`, JSON.stringify(reconciledActive));
      localStorage.setItem(`laterbox_local_deleted_items_${userId}`, JSON.stringify(reconciledDeleted));
      if (colRows) {
        localStorage.setItem(`laterbox_local_collections_${userId}`, JSON.stringify(colRows));
      }
    }

    return {
      items: reconciledActive,
      deletedItems: reconciledDeleted,
      collections: colRows || [],
    };
  });
}

export async function pushCloudChanges(userId: string): Promise<{ pushedCount: number } | null> {
  if (!userId) return null;

  return syncQueue.enqueue(userId, async () => {
    const session = await getAccessToken();
    if (!session) return null;

    const client = getSupabaseClient();
    const pendingQueue = getPendingQueue(userId);
    const itemIds = Object.keys(pendingQueue);
    if (itemIds.length === 0) {
      return { pushedCount: 0 };
    }

    let pushedCount = 0;

    for (const id of itemIds) {
      const item = pendingQueue[id];
      if (!item) continue;

      try {
        if ((item as any)._action === 'hard_delete') {
          await client.from('items').delete().eq('id', id).eq('user_id', userId);
          clearPendingItem(userId, id);
          pushedCount++;
        } else if (item.deleted_at) {
          // Soft-deleted item
          await uploadWithNotificationHandoff(item.id, null, async () => {
            const { error } = await client
              .from('items')
              .update(itemRow(item))
              .eq('id', item.id)
              .eq('user_id', userId)
              .lte('updated_at', item.updated_at);
            if (error) throw error;
          });
          clearPendingItem(userId, item.id, item.updated_at);
          pushedCount++;
        } else {
          // Active item upsert
          const assets: Attachment[] = [];
          for (const attachment of item.attachments || []) {
            if (attachment.r2_object_key) {
              assets.push(attachment);
              continue;
            }
            const file = await readLocalAttachment(attachment.id, userId);
            if (!file) throw new Error(`Attachment ${attachment.original_file_name} is missing; item remains pending.`);
            assets.push(await uploadAttachmentFile(file, item.id, userId, attachment.id, false));
          }
          await uploadWithNotificationHandoff(item.id, item.return_at, async () => {
            const { error } = assets.length
              ? await client.rpc('publish_item_attachments', { item: itemRow(item), assets: assets.map(({ local_path: _local, ...asset }) => asset) })
              : await client.from('items').upsert(itemRow(item));
            if (error) throw error;

            if (item.metadata) {
              const { error: metaErr } = await client.from('item_metadata').upsert({
                ...item.metadata,
                item_id: item.id,
                user_id: userId,
                updated_at: new Date().toISOString(),
              });
              if (metaErr) console.warn('[pending-captures] error upserting item_metadata:', metaErr);
            }

            if (item.note?.content) {
              const { error: noteErr } = await client.from('item_notes').upsert({
                item_id: item.id,
                user_id: userId,
                content: item.note.content,
                created_at: item.note.created_at || new Date().toISOString(),
                updated_at: new Date().toISOString(),
              });
              if (noteErr) console.warn('[pending-captures] error upserting item_notes:', noteErr);
            }
          });

          clearPendingItem(userId, item.id, item.updated_at);
          pushedCount++;
        }
      } catch (pushErr) {
        console.warn('[pending-captures] error pushing item:', id, pushErr);
      }
    }

    return { pushedCount };
  });
}

export async function syncCloudQueue(userId: string): Promise<SyncCloudResult | null> {
  if (!userId) return null;

  // Pull first to reconcile with latest remote state
  const pullResult = await pullCloudChanges(userId);
  if (!pullResult) return null;

  // Push local queued actions
  await pushCloudChanges(userId);

  return pullResult;
}

export async function syncPendingCaptures(userId: string): Promise<SyncCloudResult | null> {
  return syncCloudQueue(userId);
}
