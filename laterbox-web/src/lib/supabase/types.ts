export type ContentType = 'link' | 'article' | 'video' | 'music' | 'document' | 'note';

export type ItemStatus = 'inbox' | 'saved' | 'archived';

export interface TextSelector {
  before?: string | null;
  after?: string | null;
}

export interface ItemClassification {
  type: ContentType;
  source?: string | null;
  confidence: number;
  structuredData?: Record<string, unknown> | null;
}

export interface ItemMetadata {
  item_id: string;
  user_id?: string | null;
  domain?: string | null;
  site_name?: string | null;
  title?: string | null;
  description?: string | null;
  favicon_url?: string | null;
  preview_image_url?: string | null;
  status: 'pending' | 'enriching' | 'enriched' | 'failed' | 'unsupported';
  attempt_count: number;
  last_error?: string | null;
  metadata_version?: number;
  enriched_at?: string | null;
  content_type?: string | null;
  classification_source?: string | null;
  classification_confidence?: number | null;
  structured_data?: string | null;
  created_at: string;
  updated_at: string;
}

export interface ItemNote {
  item_id: string;
  user_id?: string | null;
  content: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface Attachment {
  id: string;
  item_id: string;
  user_id?: string | null;
  original_file_name: string;
  file_extension: string;
  mime_type: string;
  byte_size: number;
  sha256?: string;
  local_path?: string | null;
  r2_object_key?: string | null;
  preview_object_key?: string | null;
  thumbnail_object_key?: string | null;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface Collection {
  id: string;
  user_id?: string | null;
  name: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface CollectionItem {
  collection_id: string;
  item_id: string;
  user_id?: string | null;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
}

export interface LaterBoxItem {
  id: string;
  user_id?: string | null;
  url?: string | null;
  title?: string | null;
  text_content?: string | null;
  text_selector?: string | null;
  type: string;
  favorite: boolean;
  status: ItemStatus;
  created_at: string;
  updated_at: string;
  deleted_at?: string | null;
  metadata?: ItemMetadata | null;
  note?: ItemNote | null;
  attachments?: Attachment[];
  collections?: Collection[];
}

export type InboxFilterType = 'all' | 'articles' | 'videos' | 'music' | 'notes' | 'starred';
