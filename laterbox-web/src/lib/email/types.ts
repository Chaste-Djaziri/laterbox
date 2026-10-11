export interface UnseenDigestItemMetadata {
  domain?: string | null;
  site_name?: string | null;
  title?: string | null;
  description?: string | null;
  favicon_url?: string | null;
  preview_image_url?: string | null;
  content_type?: string | null;
}

export interface UnseenDigestItem {
  id: string;
  title?: string | null;
  url?: string | null;
  text_content?: string | null;
  type?: string | null;
  favorite?: boolean;
  seen?: boolean;
  status: string;
  created_at: string;
  return_at?: string | null;
  metadata?: UnseenDigestItemMetadata | null;
  note?: { content?: string } | null;
}

export interface UnseenDigestEmailOptions {
  to: string;
  recipientName?: string | null;
  items: UnseenDigestItem[];
  totalUnseenCount?: number;
  subject?: string;
  from?: string;
  replyTo?: string;
  appBaseUrl?: string;
  customScheme?: string;
  minAgeDays?: number;
}

export interface SendDigestEmailResult {
  success: boolean;
  id?: string;
  error?: string;
}
