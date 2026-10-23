import type { Attachment, Collection, LaterBoxItem } from '../supabase/types';

const FORMAT = 'laterbox-web-encrypted-v1';
const PAYLOAD = 'laterbox-web-backup-v1';
const MAX_BYTES = 60 * 1024 * 1024;
const ROUNDS = 250_000;

export interface WebBackup {
  format: typeof PAYLOAD;
  exportedAt: string;
  items: LaterBoxItem[];
  deletedItems: LaterBoxItem[];
  collections: Collection[];
  attachmentFiles: Record<string, { name: string; type: string; data: string }>;
  unavailableAttachments: string[];
}
interface Envelope { format: typeof FORMAT; salt: string; rounds: number; sealed: string }
const encoder = new TextEncoder();
const decoder = new TextDecoder('utf-8', { fatal: true });

function base64(bytes: Uint8Array): string {
  let raw = '';
  for (let i = 0; i < bytes.length; i += 8192) {
    raw += String.fromCharCode(...bytes.subarray(i, i + 8192));
  }
  return btoa(raw);
}
function unbase64(value: string): Uint8Array {
  if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(value)) {
    throw new Error('The backup contains invalid file data.');
  }
  const raw = atob(value);
  return Uint8Array.from(raw, c => c.charCodeAt(0));
}
function assertSize(length: number) {
  if (length > MAX_BYTES) throw new Error('This backup exceeds the 60 MB browser safety limit.');
}
function asBuffer(bytes: Uint8Array): ArrayBuffer {
  return Uint8Array.from(bytes).buffer;
}

async function derive(password: string, salt: Uint8Array, rounds: number): Promise<CryptoKey> {
  const key = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveKey']);
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt: asBuffer(salt), iterations: rounds, hash: 'SHA-256' },
    key, { name: 'AES-GCM', length: 256 }, false, ['encrypt', 'decrypt'],
  );
}

export async function createWebBackup(
  items: LaterBoxItem[], deletedItems: LaterBoxItem[], collections: Collection[],
  readAttachment: (attachment: Attachment) => Promise<File | null>,
): Promise<WebBackup> {
  const attachmentFiles: WebBackup['attachmentFiles'] = {};
  const unavailableAttachments: string[] = [];
  let bytes = 0;
  for (const item of [...items, ...deletedItems]) {
    for (const att of item.attachments ?? []) {
      if (att.deleted_at || attachmentFiles[att.id] || unavailableAttachments.includes(att.id)) continue;
      const file = await readAttachment(att);
      if (!file) { unavailableAttachments.push(att.id); continue; }
      bytes += file.size;
      assertSize(bytes);
      attachmentFiles[att.id] = {
        name: file.name || att.original_file_name,
        type: file.type || att.mime_type || 'application/octet-stream',
        data: base64(new Uint8Array(await file.arrayBuffer())),
      };
    }
  }
  const archive: WebBackup = {
    format: PAYLOAD, exportedAt: new Date().toISOString(),
    items, deletedItems, collections, attachmentFiles, unavailableAttachments,
  };
  assertSize(encoder.encode(JSON.stringify(archive)).length);
  return archive;
}

export async function encryptWebBackup(archive: WebBackup, password: string): Promise<Uint8Array> {
  if (password.length < 8) throw new Error('Use a password of at least 8 characters.');
  const plain = encoder.encode(JSON.stringify(archive));
  assertSize(plain.byteLength);
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await derive(password, salt, ROUNDS);
  const sealed = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, asBuffer(plain)));
  const combined = new Uint8Array(iv.length + sealed.length);
  combined.set(iv); combined.set(sealed, iv.length);
  return encoder.encode(JSON.stringify({ format: FORMAT, salt: base64(salt), rounds: ROUNDS, sealed: base64(combined) } satisfies Envelope));
}

export async function decryptWebBackup(data: ArrayBuffer, password: string): Promise<WebBackup> {
  assertSize(data.byteLength);
  let envelope: Envelope;
  try {
    envelope = JSON.parse(decoder.decode(data)) as Envelope;
  } catch { throw new Error('This is not a supported encrypted LaterBox Web backup.'); }
  if (envelope.format !== FORMAT || typeof envelope.salt !== 'string' ||
      typeof envelope.sealed !== 'string' || envelope.rounds !== ROUNDS) {
    throw new Error('Unsupported backup format. iOS .laterbox archives cannot yet be restored on web.');
  }
  let plain: ArrayBuffer;
  try {
    const combined = unbase64(envelope.sealed);
    if (combined.length < 29) throw new Error('Invalid archive');
    const key = await derive(password, unbase64(envelope.salt), envelope.rounds);
    plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: asBuffer(combined.slice(0, 12)) }, key, asBuffer(combined.slice(12)));
  } catch { throw new Error('Incorrect password or damaged backup.'); }
  assertSize(plain.byteLength);
  let payload: unknown;
  try { payload = JSON.parse(decoder.decode(plain)); } catch { throw new Error('The decrypted backup is invalid.'); }
  if (!isWebBackup(payload)) throw new Error('The backup has an unsupported or invalid schema.');
  return payload;
}
function isItem(item: unknown): item is LaterBoxItem {
  if (!item || typeof item !== 'object') return false;
  const o = item as Record<string, unknown>;
  return typeof o.id === 'string' && o.id.length > 0 && o.id.length < 256 &&
    typeof o.title === 'string' && typeof o.created_at === 'string' &&
    typeof o.updated_at === 'string' && typeof o.type === 'string' &&
    ['inbox', 'deferred', 'saved', 'archived'].includes(String(o.status)) &&
    (!o.attachments || (Array.isArray(o.attachments) && o.attachments.every(a =>
      a && typeof a.id === 'string' && typeof a.original_file_name === 'string')));
}
export function isWebBackup(x: unknown): x is WebBackup {
  if (!x || typeof x !== 'object') return false;
  const v = x as Record<string, unknown>;
  if (v.format !== PAYLOAD || !Array.isArray(v.items) ||
      !Array.isArray(v.deletedItems) || !Array.isArray(v.collections) ||
      !v.attachmentFiles || typeof v.attachmentFiles !== 'object' ||
      !Array.isArray(v.unavailableAttachments)) return false;
  if (!v.items.every(isItem) || !v.deletedItems.every(isItem)) return false;
  if (!v.collections.every(c => c && typeof c.id === 'string' && typeof c.name === 'string')) return false;
  const ids = [...v.items, ...v.deletedItems].map((i: LaterBoxItem) => i.id);
  if (new Set(ids).size !== ids.length) return false;
  return Object.values(v.attachmentFiles).every(f => {
    if (!f || typeof f !== 'object') return false;
    const record = f as Record<string, unknown>;
    return typeof record.name === 'string' && typeof record.type === 'string' &&
      typeof record.data === 'string' && record.data.length <= MAX_BYTES * 2;
  });
}

export function backupPreview(backup: WebBackup, existingIds: Set<string>) {
  const incoming = [...backup.items, ...backup.deletedItems];
  const conflicts = incoming.filter(item => existingIds.has(item.id));
  const available = incoming.length - conflicts.length;
  return { total: incoming.length, newItems: available, conflicts: conflicts.map(item => item.title || 'Untitled'), unavailableAttachments: backup.unavailableAttachments.length };
}

export function restoredAttachmentFile(archive: WebBackup, id: string): File | null {
  const encoded = archive.attachmentFiles[id];
  if (!encoded) return null;
  const bytes = unbase64(encoded.data);
  return new File([asBuffer(bytes)], encoded.name.replace(/[/\\]/g, '_'), { type: encoded.type });
}
