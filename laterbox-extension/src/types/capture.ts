export type CaptureSource = 'manual' | 'androidShare' | 'iosShare' | 'browserExtension' | 'desktopQuickCapture' | 'api';
export type CaptureKind = 'page' | 'link' | 'highlight' | 'social';
export type Capture = {
  captureId?: string;
  kind?: CaptureKind;
  url?: string;
  canonicalUrl?: string;
  text?: string;
  markdown?: string;
  author?: string;
  publishedAt?: string;
  truncated?: boolean;
  title?: string;
  description?: string;
  previewImageUrl?: string;
  faviconUrl?: string;
  siteName?: string;
  os?: string;
  selector?: { exact?: string; before?: string; after?: string };
  source: CaptureSource;
  createdAt: string;
};
export type CaptureResult = {
  id?: string;
  status: 'saved' | 'queued' | 'needsAuth' | 'proRequired' | 'error';
  reason?: 'network' | 'server' | 'proRequired' | 'invalid';
};
export type QueuedCapture = { userId: string; capture: Capture };
