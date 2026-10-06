#!/bin/sh
set -e

echo "=== Xcode Cloud: ci_post_clone starting ==="

# Xcode Cloud supplies the checkout root; local invocations find it from this script.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")" && pwd)}"
while [ ! -f "$REPO_ROOT/extension/package.json" ]; do
  if [ "$REPO_ROOT" = / ]; then
    echo "Could not locate the LaterBox repository" >&2
    exit 1
  fi
  REPO_ROOT="$(dirname "$REPO_ROOT")"
done

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
