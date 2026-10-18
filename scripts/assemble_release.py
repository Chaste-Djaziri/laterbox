#!/usr/bin/env python3
"""Assemble a complete release from this run and the preceding managed release."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path


ASSETS = {
    "laterbox.apk": ("laterbox.apk",),
    "laterbox-android-release.aab": ("laterbox-android-release.aab",),
    "LaterBox.ipa": ("*.ipa",),
    "laterbox-web.tar.gz": ("laterbox-web-*.tar.gz",),
    "laterbox-chrome-extension.zip": ("laterbox-chrome-extension.zip",),
    "laterbox-firefox-extension.zip": ("laterbox-firefox-extension.zip",),
    "laterbox-safari-extension.zip": ("laterbox-safari-extension.zip",),
}


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def find_asset(root: Path, patterns: tuple[str, ...]) -> Path | None:
    for pattern in patterns:
        matches = sorted(path for path in root.rglob(pattern) if path.is_file())
        if matches:
            return matches[0]
    return None


def assemble(current: Path, previous: Path, output: Path, commit: str, changelog: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    previous_manifest_path = previous / "release-manifest.json"
    previous_manifest = json.loads(previous_manifest_path.read_text()) if previous_manifest_path.exists() else None
    manifest = {"release_commit": commit, "assets": {}}

    for name, patterns in ASSETS.items():
        source = find_asset(current, patterns)
        if source:
            source_commit = commit
        else:
            source = previous / name
            if not source.is_file() or not previous_manifest:
                raise RuntimeError(f"Missing required release asset: {name}")
            previous_info = previous_manifest.get("assets", {}).get(name)
            if not previous_info or digest(source) != previous_info.get("sha256"):
                raise RuntimeError(f"Unverified previous release asset: {name}")
            source_commit = previous_info["source_commit"]
        destination = output / name
        shutil.copyfile(source, destination)
        manifest["assets"][name] = {
            "source_commit": source_commit,
            "sha256": digest(destination),
            "size": destination.stat().st_size,
        }

    shutil.copyfile(changelog, output / "LaterBox-CHANGELOG.md")
    (output / "release-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    notes = changelog.read_text().strip()
    (output.parent / "release-body.md").write_text(
        "## Changes\n\n" + notes[:12000] +
        ("\n\n[Download the full changelog from this release's assets.]" if len(notes) > 12000 else "") +
        "\n\nArtifact source commits and checksums are in `release-manifest.json`.\n"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--current", type=Path, required=True)
    parser.add_argument("--previous", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--changelog", type=Path, required=True)
    args = parser.parse_args()
    assemble(args.current, args.previous, args.output, args.commit, args.changelog)
