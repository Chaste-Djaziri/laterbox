#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

require_plist_value() {
  local file="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(/usr/libexec/PlistBuddy -c "Print :$key" "$file" 2>/dev/null || true)"
  if [[ "$actual" != *"$expected"* ]]; then
    echo "Missing expected $key in $file" >&2
    exit 1
  fi
}

require_plist_value macos/Runner/Release.entitlements com.apple.security.app-sandbox true
require_plist_value macos/Runner/Release.entitlements com.apple.security.application-groups group.pro.micorp.laterbox
require_plist_value macos/Runner/Release.entitlements com.apple.developer.aps-environment production
require_plist_value macos/ShareExtension/ShareExtension.entitlements com.apple.security.app-sandbox true
require_plist_value macos/ShareExtension/ShareExtension.entitlements com.apple.security.application-groups group.pro.micorp.laterbox
require_plist_value macos/SafariExtension/SafariExtension.entitlements com.apple.security.app-sandbox true
require_plist_value macos/Runner/Info.plist LSApplicationCategoryType public.app-category.productivity
require_plist_value macos/Runner/Info.plist ITSAppUsesNonExemptEncryption false

rg -q "com.laterbox.pro.monthly" lib/core/billing/apple_purchase_service.dart
rg -q "com.laterbox.pro.annual" lib/core/billing/apple_purchase_service.dart
rg -q "LATERBOX_DISTRIBUTION=app-store" docs/macos-release-checklist.md

echo "macOS release metadata and entitlement contract verified"
