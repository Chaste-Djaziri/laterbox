export interface BrowserCapabilities {
  supportsSidePanel: boolean;
  openSidePanel(tabId: number): Promise<void>;
  isRestrictedUrl(url?: string): boolean;
}
