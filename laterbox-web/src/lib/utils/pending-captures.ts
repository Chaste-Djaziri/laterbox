import type { LaterBoxItem } from '../supabase/types';
import { getSupabaseClient } from '../supabase/client';
import { readLocalAttachment } from './local-attachments';
import { uploadAttachmentFile } from './attachment';

export function itemRow(item: LaterBoxItem) {
  return { id: item.id, user_id: item.user_id, url: item.url, title: item.title,
    text_content: item.text_content, text_selector: item.text_selector, type: item.type,
    favorite: item.favorite, status: item.status, return_at: item.return_at ?? null,
    created_at: item.created_at, updated_at: item.updated_at, deleted_at: item.deleted_at ?? null };
}
const queueKey = (userId: string) => `laterbox_pending_captures_${userId}`;
export function queueCapture(item: LaterBoxItem) {
  if (!item.user_id) return;
  const queue = JSON.parse(localStorage.getItem(queueKey(item.user_id)) || '{}');
  queue[item.id] = item; localStorage.setItem(queueKey(item.user_id), JSON.stringify(queue));
}
export async function syncPendingCaptures(userId: string) {
  const client = getSupabaseClient();
  const queue = JSON.parse(localStorage.getItem(queueKey(userId)) || '{}') as Record<string, LaterBoxItem>;
  for (const item of Object.values(queue)) {
    const { data: remote, error: readError } = await client.from('items').select('updated_at,deleted_at').eq('id', item.id).eq('user_id', userId).maybeSingle();
    if (readError) throw readError;
    if (!remote || new Date(remote.updated_at) <= new Date(item.updated_at)) {
      const { error } = await client.from('items').upsert(itemRow(item));
      if (error) throw error;
    }
    if (!item.deleted_at && !remote?.deleted_at) {
      for (const attachment of item.attachments || []) {
        if (attachment.r2_object_key) continue;
        const file = await readLocalAttachment(attachment.id, userId);
        if (file) await uploadAttachmentFile(file, item.id, userId, attachment.id);
      }
    }
    // Read the latest queue so a concurrent reschedule is never removed by an older sync.
    const latest = JSON.parse(localStorage.getItem(queueKey(userId)) || '{}');
    if (latest[item.id]?.updated_at === item.updated_at) delete latest[item.id];
    localStorage.setItem(queueKey(userId), JSON.stringify(latest));
  }
}
