import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";

const rootDir = dirname(fileURLToPath(import.meta.url));
const browserTarget = process.env.BROWSER ?? "chromium";

export default defineConfig({
  publicDir: "public",
  plugins: [
    {
      name: "copy-extension-manifest",
      generateBundle() {
        this.emitFile({
          type: "asset",
          fileName: "manifest.json",
          source: readFileSync(
            resolve(rootDir, `manifests/${browserTarget}.json`),
            "utf8",
          ),
        });
      },
    },
  ],
  build: {
    outDir: `dist/${browserTarget}`,
    emptyOutDir: true,
    modulePreload: false,
    rollupOptions: {
      input: {
        popup: resolve(rootDir, "src/popup/popup.html"),
        background: resolve(rootDir, "src/background/service-worker.ts"),
        sidepanel: resolve(rootDir, "src/sidepanel/sidepanel.html"),
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "assets/[name].js",
        assetFileNames: "assets/[name][extname]",
      },
    },
  },
});