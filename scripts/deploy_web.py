#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time

def main():
    repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(repo_dir)

    version_file = os.path.join(repo_dir, "web", "version.json")
    if os.path.exists(version_file):
        with open(version_file, "r") as f:
            data = json.load(f)
    else:
        data = {
            "app_name": "laterbox",
            "version": "1.0.0",
            "build_number": "1",
            "package_name": "laterbox"
        }

    # Increment build number
    current_build = int(data.get("build_number", "1"))
    next_build = current_build + 1
    data["build_number"] = str(next_build)
    data["built_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    try:
        commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).decode().strip()
        data["commit"] = commit
    except Exception:
        data["commit"] = "unknown"

    # Save incremented version.json in web/
    with open(version_file, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

    print(f"📦 Version auto-incremented to {data['version']}+{data['build_number']} (commit: {data['commit']}, built_at: {data['built_at']})")

    # Build web
    build_cmd = [
        "flutter",
        "build",
        "web",
        f"--build-name={data['version']}",
        f"--build-number={data['build_number']}"
    ]
    print(f"🚀 Running: {' '.join(build_cmd)}")
    subprocess.check_call(build_cmd)

    # Stamp build/web/version.json with the same metadata
    build_version_file = os.path.join(repo_dir, "build", "web", "version.json")
    with open(build_version_file, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

    # Deploy to Cloudflare Pages
    deploy_cmd = ["npx", "wrangler", "pages", "deploy", "build/web", "--project-name=laterbox"]
    print(f"🌐 Deploying to Cloudflare Pages: {' '.join(deploy_cmd)}")
    subprocess.check_call(deploy_cmd)
    print("✅ Web deployment complete!")

if __name__ == "__main__":
    main()
