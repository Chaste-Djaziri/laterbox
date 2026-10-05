"""Validate imported CI signing profiles and write temporary signing configuration."""
import datetime
import os
from pathlib import Path
import plistlib
import subprocess

TEAM = "LS42X27YFY"
GROUP = "group.pro.micorp.laterbox"
TARGETS = {"main": "pro.micorp.laterbox", "share": "pro.micorp.laterbox.ShareExtension"}

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
    profiles = {}
    for name, bundle in TARGETS.items():
        raw = subprocess.check_output(["security", "cms", "-D", "-i", str(root / (name + ".mobileprovision"))])
        profile = plistlib.loads(raw)
        profiles[bundle] = validate(profile, bundle)
        subprocess.run(["openssl", "x509", "-inform", "DER", "-checkend", "0", "-noout"], input=profile["DeveloperCertificates"][0], check=True)
        destination = Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles" / (profile["UUID"] + ".mobileprovision")
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes((root / (name + ".mobileprovision")).read_bytes())
    # Per-target profile settings avoid assigning the app profile to the extension.
    import re
    project = Path("laterbox-ios/laterbox-ios.xcodeproj/project.pbxproj")
    text = project.read_text()
    for bundle, name in profiles.items():
        pattern = r"(PRODUCT_BUNDLE_IDENTIFIER = " + re.escape(bundle) + r";)"
        escaped = name.replace("\\", "\\\\").replace('"', '\\"')
        text, count = re.subn(pattern, lambda m: m[0] + '\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "' + escaped + '";', text)
        if count != 2: raise ValueError("Expected Debug and Release signing configurations for " + bundle)
    project.write_text(text)
    options = {"method": "app-store-connect", "signingStyle": "manual", "signingCertificate": "Apple Distribution",
               "teamID": TEAM, "provisioningProfiles": profiles, "uploadSymbols": True, "manageAppVersionAndBuildNumber": False}
    (root / "ExportOptions.plist").write_bytes(plistlib.dumps(options))

if __name__ == "__main__": main()
