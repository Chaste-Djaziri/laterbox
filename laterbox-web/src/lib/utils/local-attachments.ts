import type { Attachment } from '../supabase/types';

function openFiles(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('laterbox-files', 1);
    request.onupgradeneeded = () => request.result.createObjectStore('files', { keyPath: 'id' });
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(new Error('Could not store this file locally. Check browser storage space.'));
  });
}
export async function storeLocalAttachment(file: File, itemId: string, userId: string | null): Promise<Attachment> {
  const now = new Date().toISOString();
  const record: Attachment = { id: crypto.randomUUID(), item_id: itemId, user_id: userId,
    original_file_name: file.name, file_extension: file.name.includes('.') ? file.name.split('.').pop()!.toLowerCase() : 'bin',
    mime_type: file.type || 'application/octet-stream', byte_size: file.size, created_at: now, updated_at: now };
  const db = await openFiles();
  try {
    await new Promise<void>((resolve, reject) => {
      const transaction = db.transaction('files', 'readwrite');
      transaction.objectStore('files').put({ id: record.id, userId, file });
      transaction.oncomplete = () => resolve();
      transaction.onerror = () => reject(new Error('Could not store this file locally. Check browser storage space.'));
      transaction.onabort = () => reject(new Error('Local file storage was interrupted. Try again.'));
    });
  } finally { db.close(); }
  return record;
}
export async function localAttachmentUrl(id: string, ownerId: string | null): Promise<string | null> {
  const db = await openFiles();
  try {
    return await new Promise((resolve, reject) => {
      const request = db.transaction('files').objectStore('files').get(id);
      request.onsuccess = () => {
        const record = request.result as { userId: string | null; file: File } | undefined;
        resolve(record && record.userId === ownerId ? URL.createObjectURL(record.file) : null);
      };
      request.onerror = () => reject(request.error);
    });
  } finally { db.close(); }
}

export async function readLocalAttachment(id: string, ownerId: string | null): Promise<File | null> {
  const db = await openFiles();
  try {
    return await new Promise((resolve, reject) => {
      const request = db.transaction('files').objectStore('files').get(id);
      request.onsuccess = () => { const record = request.result as { userId: string | null; file: File } | undefined;
        resolve(record && record.userId === ownerId ? record.file : null); };
      request.onerror = () => reject(request.error);
    });
  } finally { db.close(); }
}
