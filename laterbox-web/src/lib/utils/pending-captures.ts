import { installationId, uploadWithNotificationHandoff } from '../notifications/client';
import type { LaterBoxItem } from '../supabase/types';
import { getSupabaseClient } from '../supabase/client';
import { readLocalAttachment } from './local-attachments';
import { uploadAttachmentFile } from './attachment';

export function itemRow(item: LaterBoxItem) {
  return { ...(typeof window !== 'undefined' ? { origin_installation_id: installationId() } : {}), id: item.id, user_id: item.user_id, url: item.url, title: item.title,
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

export async function syncPendingCaptures(userId: string) {
  const client = getSupabaseClient();
  const queue = JSON.parse(localStorage.getItem(queueKey(userId)) || '{}') as Record<string, LaterBoxItem>;
  const items = Object.values(queue);
  if (items.length === 0) return;

  // Proactively check and refresh expired session before triggering REST requests
  const { data: sessionData } = await client.auth.getSession();
  let session = sessionData?.session;
  if (!session) return;

  if (session.expires_at && session.expires_at * 1000 < Date.now() + 60000) {
    const { data: refreshed, error: refreshError } = await client.auth.refreshSession();
    if (!refreshError && refreshed?.session) {
      session = refreshed.session;
    } else {
      return;
    }
  }

  for (const item of items) {
    let { data: remote, error: readError } = await client
      .from('items')
      .select('updated_at,deleted_at')
      .eq('id', item.id)
      .eq('user_id', userId)
      .maybeSingle();

    if (readError && isAuthError(readError)) {
      const { data: refreshed, error: refreshError } = await client.auth.refreshSession();
      if (!refreshError && refreshed?.session) {
        const retry = await client
          .from('items')
          .select('updated_at,deleted_at')
          .eq('id', item.id)
          .eq('user_id', userId)
          .maybeSingle();
        remote = retry.data;
        readError = retry.error;
      } else {
        throw readError;
      }
    }
    if (readError) throw readError;

    if (!remote || new Date(remote.updated_at) <= new Date(item.updated_at)) {
      await uploadWithNotificationHandoff(item.id, item.return_at, async () => {
        let { error } = remote
          ? await client.from('items').update(itemRow(item)).eq('id', item.id).eq('user_id', userId).lte('updated_at', item.updated_at)
          : await client.from('items').upsert(itemRow(item));

        if (error && isAuthError(error)) {
          const { data: refreshed } = await client.auth.refreshSession();
          if (refreshed?.session) {
            const retry = remote
              ? await client.from('items').update(itemRow(item)).eq('id', item.id).eq('user_id', userId).lte('updated_at', item.updated_at)
              : await client.from('items').upsert(itemRow(item));
            error = retry.error;
          }
        }
        if (error) throw error;
      });
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
