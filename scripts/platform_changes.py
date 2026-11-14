#!/usr/bin/env python3
"""Route LaterBox source changes to the platform builds that own them.

Only true shared Apple sources/project settings trigger both native targets.
GitHub Release publishing reuses checksum-verified artifacts for other targets.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path

REQUIRED_ASSETS = {
    "ios": ("LaterBox.ipa",),
    "web": ("laterbox-web.tar.gz",),
    "extensions": (
        "laterbox-chrome-extension.zip",
        "laterbox-firefox-extension.zip",
        "laterbox-safari-extension.zip",
    ),
}

APPLE_SHARED = (
    "laterbox-ios/Shared/",
    "laterbox-ios/laterbox-ios.xcodeproj/",
    "laterbox-ios/version.json",
)

IOS_OWNED = (
    "laterbox-ios/laterbox-ios/",
    "laterbox-ios/laterbox-iosTests/",
    "laterbox-ios/laterbox-iosUITests/",
    "laterbox-ios/LaterBoxShare/",
    "laterbox-ios/LaterBoxWidgets/",
    "laterbox-ios/laterbox-ios.entitlements",
    "laterbox-ios/LaterBoxShare.entitlements",
    "laterbox-ios/LaterBoxWidgets.entitlements",
    "laterbox-ios/ci/",
    "ci_scripts/",
    "scripts/apple-review-metadata.py",
    ".github/workflows/ios.yml",
)

MAC_OWNED = (
    "laterbox-ios/LaterBoxMac/",
    "scripts/upload_macos_appstore.sh",
    "scripts/package_macos.sh",
    "scripts/build-laterbox-macos-icons.sh",
    ".github/workflows/macos.yml",
)

WEB_OWNED = (
    "laterbox-web/",
    "supabase/",
    ".github/workflows/release.yml",
    "version.json",
)

EXTENSION_OWNED = (
    "laterbox-extension/",
    "safari_app/",
    ".github/workflows/extensions.yml",
)

RELEASE_METADATA = (
    "CHANGELOG.md",
    "scripts/assemble_release.py",
    "scripts/platform_changes.py",
    ".github/workflows/complete-release.yml",
)


def matches(path: str, rules: tuple[str, ...]) -> bool:
    return any(path == rule or (rule.endswith("/") and path.startswith(rule))
               for rule in rules)


def affected_platforms(paths: list[str]) -> set[str]:
    changed: set[str] = set()
    for path in paths:
        if matches(path, APPLE_SHARED):
            changed.update(("ios", "macos"))
        if matches(path, IOS_OWNED):
            changed.add("ios")
        if matches(path, MAC_OWNED):
            changed.add("macos")
        if matches(path, WEB_OWNED):
            changed.add("web")
        if matches(path, EXTENSION_OWNED):
            changed.add("extensions")
    return changed


def release_plan(
    paths: list[str], previous_assets: set[str], has_previous_release: bool
) -> dict[str, bool]:
    changed = affected_platforms(paths)
    results = {
        f"build_{platform}": (
            platform in changed
            or not has_previous_release
            or any(asset not in previous_assets for asset in assets)
        )
        for platform, assets in REQUIRED_ASSETS.items()
    }
    # macOS is delivered by its own App Store Connect workflow, not as an IPA.
    results["publish"] = (
        any(results.values()) or any(matches(path, RELEASE_METADATA) for path in paths)
    )
    return results


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--paths", type=Path, required=True,
                        help="NUL-separated git diff --name-only -z paths")
    parser.add_argument("--assets", type=Path, required=True,
                        help="Previous managed release asset names, one per line")
    parser.add_argument("--previous-tag", default="")
    parser.add_argument("--github-output", type=Path, required=True)
    args = parser.parse_args()

    changed_paths = [
        os.fsdecode(item) for item in args.paths.read_bytes().split(b"\0") if item
    ]
    previous_assets = set(args.assets.read_text().splitlines())
    plan = release_plan(changed_paths, previous_assets, bool(args.previous_tag))
    with args.github_output.open("a") as output:
        for name, enabled in plan.items():
            output.write(f"{name}={'true' if enabled else 'false'}\n")

    print("Changed platforms:", ", ".join(sorted(affected_platforms(changed_paths))) or "(none)")
    print("Build plan:", plan)


if __name__ == "__main__":
    main()
