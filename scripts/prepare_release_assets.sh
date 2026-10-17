#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <release-tag> <staging-directory> [current-asset ...]" >&2
  exit 2
fi

tag="$1"
staging_dir="$2"
shift 2

mkdir -p "$staging_dir"
download_dir="${RUNNER_TEMP:-/tmp}/laterbox-release-assets-$RANDOM"
mkdir -p "$download_dir"
trap 'rm -rf "$download_dir"' EXIT

copy_assets() {
  local source_dir="$1"
  [ -d "$source_dir" ] || return 0
  find "$source_dir" -maxdepth 1 -type f -print0 |
    while IFS= read -r -d '' file; do
      cp -n "$file" "$staging_dir/$(basename "$file")"
    done
}

download_release() {
  local release_tag="$1"
  local destination="$download_dir/$release_tag"
  mkdir -p "$destination"
  if gh release download "$release_tag" --dir "$destination" --clobber >/dev/null 2>&1; then
    copy_assets "$destination"
  fi
}

# Preserve assets already uploaded by another platform workflow for this release.
download_release "$tag"

previous_tag="$(
  gh release list --limit 100 --json tagName,publishedAt,isDraft,isPrerelease \
    --jq 'sort_by(.publishedAt) | reverse | map(select(.isDraft == false and .isPrerelease == false and .tagName != "'"$tag"'")) | .[0].tagName // empty'
)"
if [ -n "$previous_tag" ]; then
  download_release "$previous_tag"
fi

for asset in "$@"; do
  [ -f "$asset" ] || { echo "Missing release asset: $asset" >&2; exit 1; }
  cp "$asset" "$staging_dir/$(basename "$asset")"
done

cp CHANGELOG.md "$staging_dir/LaterBox-CHANGELOG.md"
