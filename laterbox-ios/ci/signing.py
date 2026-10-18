"""Validate imported CI signing profiles and write temporary signing configuration."""
import datetime
import os
from pathlib import Path
import plistlib
import subprocess

TEAM = "LS42X27YFY"
GROUP = "group.pro.micorp.laterbox"
TARGETS = {
    "main": "pro.micorp.laterbox",
    "share": "pro.micorp.laterbox.ShareExtension",
    "widgets": "pro.micorp.laterbox.widgets"
}

def resolve_widgets_profile(root):
    widgets_path = root / "widgets.mobileprovision"
    if widgets_path.exists():
        return
    print("Attempting to resolve widgets provisioning profile via App Store Connect API...", flush=True)
    try:
        import app_store
        import base64
        # First check bundle ID and its associated profiles directly
        bundle_resp = app_store.request(f"/v1/bundleIds?filter[identifier]={TARGETS['widgets']}&include=profiles")
        bundles = bundle_resp.get("data", [])
        if bundles:
            bundle_resource_id = bundles[0]["id"]
            profiles = [p for p in bundle_resp.get("included", []) if p.get("type") == "profiles" and p.get("attributes", {}).get("profileType") == "IOS_APP_STORE"]
            if profiles:
                content = profiles[0]["attributes"]["profileContent"]
                widgets_path.write_bytes(base64.b64decode(content))
                print(f"Downloaded active widgets profile from App Store Connect: {profiles[0]['attributes'].get('name')}", flush=True)
                return
        else:
            print(f"Registering Bundle ID {TARGETS['widgets']}...", flush=True)
            new_bundle = app_store.request("/v1/bundleIds", method="POST", data={
                "data": {
                    "type": "bundleIds",
                    "attributes": {
                        "identifier": TARGETS["widgets"],
                        "name": "LaterBox Widgets",
                        "platform": "UNIVERSAL"
                    }
                }
            })
            bundle_resource_id = new_bundle["data"]["id"]
            try:
                app_store.request("/v1/bundleIdCapabilities", method="POST", data={
                    "data": {
                        "type": "bundleIdCapabilities",
                        "attributes": {
                            "capabilityType": "APP_GROUPS"
                        },
                        "relationships": {
                            "bundleId": {"data": {"type": "bundleIds", "id": bundle_resource_id}}
                        }
                    }
                })
            except Exception as cap_err:
                print(f"::warning::Could not register App Groups capability: {cap_err}", flush=True)

        print(f"No existing distribution profile found for {TARGETS['widgets']}. Attempting creation...", flush=True)
        certs_resp = app_store.request("/v1/certificates?filter[certificateType]=DISTRIBUTION")
        certs = certs_resp.get("data", [])
        if not certs:
            raise RuntimeError("No active DISTRIBUTION certificate found in App Store Connect")
        cert_resource_id = certs[0]["id"]

        payload = {
            "data": {
                "type": "profiles",
                "attributes": {
                    "name": "LaterBox Widgets AppStore",
                    "profileType": "IOS_APP_STORE"
                },
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundle_resource_id}},
                    "certificates": {"data": [{"type": "certificates", "id": cert_resource_id}]}
                }
            }
        }
        create_resp = app_store.request("/v1/profiles", method="POST", data=payload)
        content = create_resp["data"]["attributes"]["profileContent"]
        widgets_path.write_bytes(base64.b64decode(content))
        print("Created and saved widgets provisioning profile from App Store Connect", flush=True)
        return
    except Exception as err:
        import traceback
        traceback.print_exc()
        print(f"::warning::Could not resolve widgets profile from App Store Connect API: {err}", flush=True)
        raise RuntimeError(
            "Missing provisioning profile for 'pro.micorp.laterbox.widgets'. "
            "Please provide APPLE_WIDGETS_PROVISIONING_PROFILE_BASE64 in GitHub repository secrets "
            "or ensure the App Store Connect API key has Admin access to Certificates, Identifiers & Profiles."
        ) from err

def validate(profile, bundle, now=None):
    now = now or datetime.datetime.now(datetime.timezone.utc)
    expiry = profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc)
    entitlements = profile["Entitlements"]
    if expiry <= now: raise ValueError("Expired provisioning profile for " + bundle)
    if TEAM not in profile["TeamIdentifier"]: raise ValueError("Wrong signing team for " + bundle)
    if entitlements.get("application-identifier") != TEAM + "." + bundle: raise ValueError("Profile bundle identifier mismatch for " + bundle)
    if GROUP not in entitlements.get("com.apple.security.application-groups", []): raise ValueError("Profile lacks LaterBox App Group for " + bundle)
    if entitlements.get("get-task-allow") or profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices"):
        raise ValueError("An App Store distribution profile is required for " + bundle)
    return profile["Name"]

def main():
    if os.environ["APPLE_TEAM_ID"] != TEAM: raise ValueError("APPLE_TEAM_ID does not match the existing app")
    root = Path(os.environ["RUNNER_TEMP"])
    resolve_widgets_profile(root)
    profiles = {}
    for name, bundle in TARGETS.items():
        raw = subprocess.check_output(["security", "cms", "-D", "-i", str(root / (name + ".mobileprovision"))])
        profile = plistlib.loads(raw)
        profiles[bundle] = validate(profile, bundle)
        subprocess.run(["openssl", "x509", "-inform", "DER", "-checkend", "0", "-noout"], input=profile["DeveloperCertificates"][0], check=True)
        destination = Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles" / (profile["UUID"] + ".mobileprovision")
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes((root / (name + ".mobileprovision")).read_bytes())
        with (root / "installed-profiles.txt").open("a") as manifest: manifest.write(str(destination) + "\n")
    # Per-target profile settings avoid assigning the app profile to the extension.
    import re
    project = Path("laterbox-ios/laterbox-ios.xcodeproj/project.pbxproj")
    text = project.read_text()
    counts = {bundle: 0 for bundle in profiles}
    def configure(match):
        block = match[0]
        for bundle, name in profiles.items():
            if "PRODUCT_BUNDLE_IDENTIFIER = " + bundle + ";" not in block: continue
            escaped = name.replace("\\", "\\\\").replace('"', '\\"')
            setting = 'PROVISIONING_PROFILE_SPECIFIER = "' + escaped + '";'
            if "PROVISIONING_PROFILE_SPECIFIER =" in block:
                block = re.sub(r'PROVISIONING_PROFILE_SPECIFIER = [^;]*;', lambda _: setting, block)
            else:
                block = block.replace("PRODUCT_BUNDLE_IDENTIFIER = " + bundle + ";", "PRODUCT_BUNDLE_IDENTIFIER = " + bundle + ";\n\t\t\t\t" + setting)
            counts[bundle] += 1
        return block
    text = re.sub(r"buildSettings = \{.*?\n\t\t\t\};", configure, text, flags=re.DOTALL)
    if any(count != 2 for count in counts.values()): raise ValueError("Expected Debug and Release signing configurations")
    project.write_text(text)
    options = {"method": "app-store-connect", "signingStyle": "manual", "signingCertificate": "Apple Distribution",
               "teamID": TEAM, "provisioningProfiles": profiles, "uploadSymbols": True, "manageAppVersionAndBuildNumber": False}
    (root / "ExportOptions.plist").write_bytes(plistlib.dumps(options))

if __name__ == "__main__": main()
