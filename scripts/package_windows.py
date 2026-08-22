#!/usr/bin/env python3
"""
Package Laterbox for Windows:
1. Optionally builds Flutter Windows release (`flutter build windows --release`)
2. Compiles the standalone installer using Inno Setup (`dist/laterbox-windows-setup.exe`)
3. Packages a portable zip archive (`dist/laterbox-windows-x64.zip`)
4. Copies installer & zip to `web/downloads/` and `build/web/downloads/` for web distribution
"""

import argparse
import os
import shutil
import subprocess
import sys
import zipfile


def find_iscc() -> str:
    """Find the Inno Setup Compiler executable."""
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    program_files = os.environ.get("ProgramFiles", r"C:\Program Files")
    program_files_x86 = os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")

    candidates = [
        os.path.join(local_app_data, "Programs", "Inno Setup 6", "ISCC.exe"),
        os.path.join(program_files, "Inno Setup 6", "ISCC.exe"),
        os.path.join(program_files_x86, "Inno Setup 6", "ISCC.exe"),
        "ISCC.exe",
    ]

    for path in candidates:
        if shutil.which(path) or os.path.exists(path):
            return path

    return ""


def main():
    parser = argparse.ArgumentParser(description="Package Laterbox Windows release and installer.")
    parser.add_argument(
        "--build-flutter",
        action="store_true",
        help="Force building Flutter Windows release before packaging",
    )
    parser.add_argument(
        "--skip-flutter-build",
        action="store_true",
        help="Skip Flutter build even if output seems missing",
    )
    args = parser.parse_args()

    repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(repo_dir)

    release_dir = os.path.join(repo_dir, "build", "windows", "x64", "runner", "Release")
    exe_file = os.path.join(release_dir, "laterbox.exe")

    # Step 1: Build Flutter Windows release if needed
    should_build = args.build_flutter or (not os.path.exists(exe_file) and not args.skip_flutter_build)
    if should_build:
        print("🔨 Building Flutter Windows release...")
        flutter_cmd = ["flutter", "build", "windows", "--release"]
        if sys.platform == "win32":
            flutter_bat = shutil.which("flutter.bat") or shutil.which("flutter")
            if flutter_bat:
                flutter_cmd[0] = flutter_bat
        subprocess.check_call(flutter_cmd)
    else:
        print(f"✅ Found existing Windows build at {release_dir}")

    if not os.path.exists(exe_file):
        print(f"❌ Error: {exe_file} not found. Please run with --build-flutter.")
        sys.exit(1)

    # Step 2: Compile Inno Setup Installer
    iscc_path = find_iscc()
    if not iscc_path:
        print("❌ Error: Inno Setup 6 (ISCC.exe) not found. Please install Inno Setup 6.")
        sys.exit(1)

    dist_dir = os.path.join(repo_dir, "dist")
    os.makedirs(dist_dir, exist_ok=True)

    iss_file = os.path.join(repo_dir, "scripts", "laterbox.iss")
    print(f"📦 Compiling Windows installer with {iscc_path}...")
    subprocess.check_call([iscc_path, iss_file])

    installer_path = os.path.join(dist_dir, "laterbox-windows-setup.exe")
    if os.path.exists(installer_path):
        size_mb = os.path.getsize(installer_path) / (1024 * 1024)
        print(f"🎉 Installer ready: {installer_path} ({size_mb:.2f} MB)")
    else:
        print(f"⚠️ Warning: Expected installer not found at {installer_path}")

    # Step 3: Create portable zip archive
    zip_path = os.path.join(dist_dir, "laterbox-windows-x64.zip")
    print(f"🗜️ Creating portable zip bundle: {zip_path}...")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for root, dirs, files in os.walk(release_dir):
            for file in files:
                file_full = os.path.join(root, file)
                rel_path = os.path.relpath(file_full, release_dir)
                zf.write(file_full, arcname=rel_path)

    zip_size_mb = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"🎉 Portable zip ready: {zip_path} ({zip_size_mb:.2f} MB)")

    # Step 4: Copy to web distribution directories
    dest_dirs = [
        os.path.join(repo_dir, "web", "downloads"),
    ]
    build_web_dir = os.path.join(repo_dir, "build", "web", "downloads")
    if os.path.exists(os.path.join(repo_dir, "build", "web")):
        dest_dirs.append(build_web_dir)

    for dest in dest_dirs:
        os.makedirs(dest, exist_ok=True)
        if os.path.exists(installer_path):
            shutil.copy2(installer_path, os.path.join(dest, "laterbox-windows-setup.exe"))
        if os.path.exists(zip_path):
            shutil.copy2(zip_path, os.path.join(dest, "laterbox-windows-x64.zip"))
        print(f"🚀 Synced download artifacts to {dest}")

    print("\n✅ All packaging tasks completed successfully!")


if __name__ == "__main__":
    main()
