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

# Explicit macOS bundle icon for Dock/Launch Services, independent of asset catalog behavior.
iconset_dir="$(mktemp -d)/LaterBoxMac.iconset"
mkdir -p "$iconset_dir"
for size in 16 32 128 256 512; do
  cp "$destination/mac-${size}@1x.png" "$iconset_dir/icon_${size}x${size}.png"
  cp "$destination/mac-${size}@2x.png" "$iconset_dir/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$iconset_dir" -o "laterbox-ios/LaterBoxMac/LaterBoxMac.icns"
rm -rf "$(dirname "$iconset_dir")"
echo "Created LaterBoxMac.icns for the native app bundle."
