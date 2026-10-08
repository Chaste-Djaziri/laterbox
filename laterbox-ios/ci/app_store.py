"""Query release identity and verify TestFlight processing without logging credentials."""
import argparse
import json
import os
from pathlib import Path
import time
import urllib.request
import urllib.error
import jwt

BASE = "https://api.appstoreconnect.apple.com"
BUNDLE = "pro.micorp.laterbox"
APP_ID = "6804139119"

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
    # Marketing versions change only when explicitly edited in version.json.
    # TestFlight uploads advance CFBundleVersion independently.
    baseline = max([int(metadata["buildNumber"])] + [version(b["attributes"]["version"])[0] for b in builds])
    if baseline >= 9999: raise ValueError("Build number requires a new numbering scheme")
    return ".".join(map(str, selected)), str(baseline + 1)

def existing_app():
    try:
        app = request(f"/v1/apps/{APP_ID}")["data"]
    except urllib.error.HTTPError as error:
        raise RuntimeError(
            f"App Store Connect HTTP {error.code} for existing LaterBox app {APP_ID}. "
            "Check that the GitHub API key and issuer belong to the account shown in App Store Connect "
            "and have access to this app. No upload was attempted."
        ) from None
    if app["id"] != APP_ID or app["attributes"]["bundleId"] != BUNDLE:
        raise RuntimeError("Existing App Store Connect app identity does not match pro.micorp.laterbox")
    return app["id"]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["prepare", "verify"])
    parser.add_argument("--metadata", default="version.json")
    args = parser.parse_args()
    app = existing_app()
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
