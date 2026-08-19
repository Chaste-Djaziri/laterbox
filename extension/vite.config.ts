import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";

const rootDir = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  publicDir: "public",
  plugins: [
    {
      name: "copy-extension-manifest",
      generateBundle() {
        this.emitFile({
          type: "asset",
          fileName: "manifest.json",
          source: readFileSync(resolve(rootDir, "manifest.json"), "utf8"),
        });
      },
    },
  ],
  build: {
    outDir: "dist",
    emptyOutDir: true,
    modulePreload: false,
    rollupOptions: {
      input: {
        popup: resolve(rootDir, "src/popup/popup.html"),
        background: resolve(rootDir, "src/background/service-worker.ts"),
        socialSave: resolve(rootDir, "src/content/social-save.ts"),
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "assets/[name].js",
        assetFileNames: "assets/[name][extname]",
      },
    },
  },
});
