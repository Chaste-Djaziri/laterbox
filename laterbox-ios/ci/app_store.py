"""Query release identity and verify TestFlight processing without logging credentials."""
import argparse
import json
import os
from pathlib import Path
import time
import urllib.request
import jwt

BASE = "https://api.appstoreconnect.apple.com"
BUNDLE = "pro.micorp.laterbox"

def request(path):
    now = int(time.time())
    token = jwt.encode({"iss": os.environ["APP_STORE_CONNECT_ISSUER_ID"], "iat": now,
                        "exp": now + 600, "aud": "appstoreconnect-v1"},
                       Path(os.environ["ASC_KEY_PATH"]).read_text(), algorithm="ES256",
                       headers={"kid": os.environ["APP_STORE_CONNECT_KEY_ID"]})
    url = path if path.startswith(BASE + "/") else BASE + path
    if not url.startswith(BASE + "/"): raise ValueError("Unexpected pagination URL")
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
    with urllib.request.urlopen(req, timeout=60) as response: return json.load(response)

def records(path):
    result = []
    while path:
        page = request(path)
        result.extend(page["data"])
        path = page.get("links", {}).get("next")
    return result

def version(value):
    parts = tuple(int(p) for p in value.split("."))
    if not 1 <= len(parts) <= 3: raise ValueError("Invalid version")
    return parts + (0,) * (3 - len(parts))

def release_numbers(metadata, builds, store_versions):
    selected = version(metadata["version"])
    published = [version(v["attributes"]["versionString"]) for v in store_versions]
    if published and max(published) >= selected:
        major, minor, patch = max(published)
        selected = (major, minor, patch + 1)
    baseline = max([int(metadata["buildNumber"])] + [version(b["attributes"]["version"])[0] for b in builds])
    if baseline >= 9999: raise ValueError("Build number requires a new numbering scheme")
    return ".".join(map(str, selected)), str(baseline + 1)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["prepare", "verify"])
    parser.add_argument("--metadata", default="version.json")
    args = parser.parse_args()
    apps = records("/v1/apps?filter[bundleId]=" + BUNDLE)
    if len(apps) != 1: raise RuntimeError("Expected existing LaterBox App Store Connect app")
    app = apps[0]["id"]
    path = f"/v1/builds?filter[app]={app}&limit=200"
    if args.mode == "prepare":
        builds = records(path)
        store_versions = records(f"/v1/apps/{app}/appStoreVersions?filter[platform]=IOS&limit=200")
        marketing, build = release_numbers(json.loads(Path(args.metadata).read_text()), builds, store_versions)
        with open(os.environ["GITHUB_ENV"], "a") as out:
            out.write(f"IOS_VERSION={marketing}\nIOS_BUILD={build}\n")
        print(f"Existing app {BUNDLE}: version {marketing}, build {build}")
    else:
        deadline = time.monotonic() + 1200
        while time.monotonic() < deadline:
            matches = [b for b in records(path) if b["attributes"]["version"] == os.environ["IOS_BUILD"]]
            if matches:
                state = matches[0]["attributes"]["processingState"]
                if state == "VALID":
                    print("Native build processed successfully in the existing TestFlight app")
                    return
                if state in ("FAILED", "INVALID"): raise RuntimeError("Apple rejected build processing: " + state)
            time.sleep(30)
        raise TimeoutError("Build uploaded, but Apple processing was not confirmed within 20 minutes")

if __name__ == "__main__": main()
