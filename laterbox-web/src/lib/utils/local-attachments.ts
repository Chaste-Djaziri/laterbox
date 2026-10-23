import type { Attachment } from '../supabase/types';

interface StoredLocalAttachment {
  id: string;
  userId: string | null;
  file: Blob;
  // File.name is not reliably preserved by every structured-clone runtime
  // (including Node 22's IndexedDB test environment).
  fileName?: string;
  fileType?: string;
}

function restoreFile(record: StoredLocalAttachment): File {
  const file = record.file as File;
  if (!record.fileName) return file; // Keep older IndexedDB records readable.
  if (file.name === record.fileName && file instanceof File) return file;
  return new File([record.file], record.fileName, {
    type: record.fileType || record.file.type || 'application/octet-stream',
  });
}

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
      transaction.objectStore('files').put({ id: record.id, userId, file, fileName: file.name, fileType: file.type });
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
        const record = request.result as StoredLocalAttachment | undefined;
        const matches = record && (record.userId === ownerId || (ownerId !== null && record.userId === null));
        resolve(matches && record ? URL.createObjectURL(record.file) : null);
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
      request.onsuccess = () => {
        const record = request.result as StoredLocalAttachment | undefined;
        const matches = record && (record.userId === ownerId || (ownerId !== null && record.userId === null));
        resolve(matches && record ? restoreFile(record) : null);
      };
      request.onerror = () => reject(request.error);
    });
  } finally { db.close(); }
}

/** Used to undo a partially restored encrypted backup. */
export async function deleteLocalAttachment(id: string): Promise<void> {
  const db = await openFiles();
  try {
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction('files', 'readwrite');
      tx.objectStore('files').delete(id);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(new Error('Could not clean up an incomplete attachment restore.'));
      tx.onabort = () => reject(new Error('Attachment cleanup was interrupted.'));
    });
  } finally { db.close(); }
}
