interface ImportMetaEnv {
  readonly VITE_CAPTURE_API_URL?: string;
  readonly VITE_EXTENSION_CONNECT_URL?: string;
  readonly VITE_LATERBOX_WEB_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
