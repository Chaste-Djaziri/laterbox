export type CaptureSource =
  | "manual"
  | "androidShare"
  | "iosShare"
  | "browserExtension"
  | "desktopQuickCapture"
  | "api";

export type Capture = {
  url?: string;
  text?: string;
  title?: string;
  description?: string;
  previewImageUrl?: string;
  faviconUrl?: string;
  siteName?: string;
  os?: string;
  selector?: { before?: string; after?: string };
  source: CaptureSource;
  createdAt: string;
};

export type CaptureResult = {
  id?: string;
  status: "saved" | "queued" | "needsAuth";
  reason?: "network" | "server";
};
