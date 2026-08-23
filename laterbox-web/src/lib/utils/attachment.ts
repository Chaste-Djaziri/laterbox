import { getSupabaseClient } from '../supabase/client';
import { Attachment } from '../supabase/types';

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

async function computeSha256(file: File): Promise<string> {
  const buffer = await file.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function uploadAttachmentFile(
  file: File,
  itemId: string,
  userId: string
): Promise<Attachment> {
  const attachmentId = crypto.randomUUID();
  const extension = file.name.split('.').pop()?.toLowerCase() || '';
  const sha256 = await computeSha256(file);
  const byteSize = file.size;
  const mimeType = file.type || 'application/octet-stream';
  const supabase = getSupabaseClient();

  let r2ObjectKey: string | null = null;

  try {
    // 1. Request presigned upload URL from edge function
    const { data: prepData, error: prepError } = await supabase.functions.invoke('attachment-storage', {
      body: {
        action: 'prepare-upload',
        attachmentId,
        itemId,
        originalFileName: file.name,
        extension,
        mimeType,
        byteSize,
        sha256,
      },
    });

    if (!prepError && prepData?.uploadUrl) {
      // 2. Direct upload to R2
      const uploadRes = await fetch(prepData.uploadUrl, {
        method: 'PUT',
        headers: {
          'Content-Type': mimeType,
          'x-amz-meta-sha256': sha256,
          'x-amz-meta-attachment-id': attachmentId,
          'x-amz-meta-user-id': userId,
        },
        body: file,
      });

      if (uploadRes.ok) {
        // 3. Complete and verify upload
        const { data: compData } = await supabase.functions.invoke('attachment-storage', {
          body: {
            action: 'complete-upload',
            attachmentId,
            itemId,
            originalFileName: file.name,
            extension,
            mimeType,
            byteSize,
            sha256,
          },
        });
        r2ObjectKey = compData?.objectKey || prepData.objectKey;
      }
    }
  } catch (err) {
    console.warn('[LaterBox] Edge upload failed, saving local reference:', err);
  }

  const now = new Date().toISOString();

  const record: Attachment = {
    id: attachmentId,
    item_id: itemId,
    user_id: userId,
    original_file_name: file.name,
    file_extension: extension,
    mime_type: mimeType,
    byte_size: byteSize,
    sha256,
    r2_object_key: r2ObjectKey,
    created_at: now,
    updated_at: now,
  };

  // Insert into attachments table in Supabase
  try {
    await supabase.from('attachments').insert({
      id: attachmentId,
      item_id: itemId,
      user_id: userId,
      original_file_name: file.name,
      file_extension: extension,
      mime_type: mimeType,
      byte_size: byteSize,
      sha256,
      r2_object_key: r2ObjectKey,
      created_at: now,
      updated_at: now,
    });
  } catch (err) {
    console.error('[LaterBox] Failed to insert attachment row in Supabase:', err);
  }

  return record;
}
