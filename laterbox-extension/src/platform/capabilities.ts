export interface BrowserCapabilities {
  supportsSidePanel: boolean;
  openSidePanel(): Promise<void>;
  isRestrictedUrl(url?: string): boolean;
}
