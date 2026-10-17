export interface PermanentAttachment {
  id: string;
  r2_object_key: string | null;
  preview_object_key?: string | null;
  thumbnail_object_key?: string | null;
}

export async function permanentlyDeleteCloudItem(itemId: string, userId: string, storage: {
  readItem: () => Promise<{ user_id: string } | null>;
  readAttachments: () => Promise<PermanentAttachment[]>;
  deleteFiles: (attachment: PermanentAttachment) => Promise<void>;
  deleteRecords: () => Promise<void>;
}): Promise<void> {
  const item = await storage.readItem();
  if (!item) return; // A retried successful deletion is already complete.
  if (item.user_id.toLowerCase() !== userId.toLowerCase()) throw new Error('Unauthorized item ownership');
  const attachments = await storage.readAttachments();
  for (const attachment of attachments) await storage.deleteFiles(attachment);
  // Keep records until every object is removed so failed cleanup can be retried.
  await storage.deleteRecords();
}
