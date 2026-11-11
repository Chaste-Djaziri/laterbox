#!/bin/bash
# scripts/build-laterbox-macos-icons.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source_icon="laterbox-ios/laterbox-ios/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
destination="laterbox-ios/LaterBoxMac/Assets.xcassets/AppIcon.appiconset"
test -f "$source_icon"
mkdir -p "$destination"
for size in 16 32 128 256 512; do
  for scale in 1 2; do
    pixels=$((size * scale))
    sips -s format png -z "$pixels" "$pixels" "$source_icon" --out "$destination/mac-${size}@${scale}x.png" >/dev/null
  done
done
echo "Created native macOS Dock icons from LaterBox's official 1024px icon."
