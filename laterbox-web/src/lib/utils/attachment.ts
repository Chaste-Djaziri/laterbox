import { getSupabaseClient } from '../supabase/client';

const urlCache = new Map<string, { url: string; expiresAt: number }>();

export async function fetchAttachmentDownloadUrl(attachmentId: string): Promise<string | null> {
  const cached = urlCache.get(attachmentId);
  if (cached && cached.expiresAt > Date.now() + 60000) {
    return cached.url;
  }

  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.functions.invoke('attachment-storage', {
      body: {
        action: 'prepare-download',
        attachmentId,
      },
    });

    if (error || !data?.downloadUrl) {
      return null;
    }

    const url = data.downloadUrl as string;
    const expiresIn = ((data.expiresIn as number) || 300) * 1000;
    urlCache.set(attachmentId, {
      url,
      expiresAt: Date.now() + expiresIn,
    });
    return url;
  } catch (err) {
    console.error('[LaterBox] Failed to fetch attachment download URL:', err);
    return null;
  }
}
