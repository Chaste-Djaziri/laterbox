#!/bin/sh
set -e

echo "=== Xcode Cloud: ci_post_clone starting ==="

# CI_PRIMARY_REPOSITORY_PATH is provided by Xcode Cloud; fallback to current directory or parent
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
if [ ! -f "$REPO_ROOT/extension/package.json" ] && [ -f "$REPO_ROOT/../../extension/package.json" ]; then
  REPO_ROOT="$(cd "$REPO_ROOT/../.." && pwd)"
fi

echo "Repository Root: $REPO_ROOT"

# 1. Build Safari Web Extension assets
if [ -d "$REPO_ROOT/extension" ]; then
  echo "--- Building Safari Web Extension ---"
  cd "$REPO_ROOT/extension"
  npm ci
  npm run build:safari
  
  if [ -d "$REPO_ROOT/safari_app/laterbox/Shared (Extension)" ]; then
    echo "--- Copying Safari Extension assets into Xcode Project Resources ---"
    cp -R dist/safari/* "$REPO_ROOT/safari_app/laterbox/Shared (Extension)/"
  fi
fi

echo "=== Xcode Cloud: ci_post_clone finished successfully ==="
