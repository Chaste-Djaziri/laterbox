import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig, build } from "vite";

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
    {
      name: "build-background-script",
      async closeBundle() {
        await build({
          configFile: false,
          publicDir: false,
          build: {
            outDir: resolve(rootDir, `dist/${browserTarget}`),
            emptyOutDir: false,
            modulePreload: false,
            lib: {
              entry: resolve(rootDir, "src/background/service-worker.ts"),
              name: "LaterBoxBackground",
              formats: ["iife"],
              fileName: () => "background.js",
            },
          },
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