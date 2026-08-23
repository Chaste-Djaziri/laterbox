#!/bin/sh
set -e

echo "=== Xcode Cloud: ci_post_clone starting ==="

# CI_PRIMARY_REPOSITORY_PATH is provided by Xcode Cloud; fallback to current directory or parent
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
if [ ! -f "$REPO_ROOT/pubspec.yaml" ] && [ -f "$REPO_ROOT/../../pubspec.yaml" ]; then
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

# 2. Setup Flutter if building iOS or macOS schemes
if [ -f "$REPO_ROOT/pubspec.yaml" ]; then
  echo "--- Setting up Flutter SDK for Xcode Cloud ---"
  if ! command -v flutter >/dev/null 2>&1; then
    FLUTTER_HOME="$HOME/flutter"
    if [ ! -d "$FLUTTER_HOME" ]; then
      git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
    fi
    export PATH="$FLUTTER_HOME/bin:$PATH"
  fi

  cd "$REPO_ROOT"
  flutter precache --ios --macos
  flutter pub get
fi

echo "=== Xcode Cloud: ci_post_clone finished successfully ==="
