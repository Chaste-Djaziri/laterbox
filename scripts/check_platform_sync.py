#!/usr/bin/env python3
"""Read-only source audit: compare item-cloud field support across platforms.

This is a repository parity check, NOT a database migration runner and NOT
proof that the hosted Supabase database has been upgraded.
"""
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "docs/platform-sync-contract.json").read_text())
migration = ROOT / manifest["database"]["migration"]
read_write = {
    "ios": (ROOT / "laterbox-ios/laterbox-ios/Services/IOSCloudSync.swift", None),
    "web": (ROOT / "laterbox-web/src/lib/utils/pending-captures.ts", None),
    "android": (ROOT / "laterbox-android/app/src/main/java/com/example/laterbox/data/sync/SyncCoordinator.kt", None),
}
errors = []
observed_versions = {platform: 1 for platform in read_write}
if not migration.is_file():
    errors.append(f"Missing migration: {migration}")
else:
    sql = migration.read_text()
    for required in ("ADD COLUMN IF NOT EXISTS inbox_entered_at", "BEFORE INSERT OR UPDATE"):
        if required not in sql:
            errors.append(f"Migration missing safety contract: {required}")
print(f"Cloud contract v{manifest['cloud_contract_version']} / hosted DB deployment: NOT VERIFIED")
print("Field                     iOS             Web             Android")
for entry in manifest["shared_fields"]:
    field = entry["name"]
    statuses = []
    for platform, (source, _) in read_write.items():
        code = source.read_text()
        if platform == "ios":
            read = "var " + field in code and ("snapshot." + field) in code
            write = '"' + field + '":' in code
        elif platform == "web":
            read = field in (ROOT / "laterbox-web/src/lib/supabase/types.ts").read_text() or field == "return_at"
            write = field + ":" in code
        else:
            read = '"' + field + '"' in code
            write = '.put("' + field + '"' in code
        actual = "read/write" if read and write else "read-only" if read else "write-only" if write else "not yet"
        expected = {"read_write": "read/write", "read_only": "read-only",
                    "not_implemented": "not yet"}[entry[platform]]
        statuses.append(actual)
        if actual != expected:
            errors.append(f"{platform}: {field} is {actual}, but contract declares {expected}; update source or manifest")
        if field == "inbox_entered_at" and read and write:
            observed_versions[platform] = 2
    print(f"{field:25} {statuses[0]:15} {statuses[1]:15} {statuses[2]}")
for platform, p in manifest["platform_contracts"].items():
    print(f"{platform}: declared contract v{p['version']} / detected v{observed_versions[platform]} ({p['status']})")
    if p["version"] != observed_versions[platform]:
        errors.append(f"{platform}: detected contract v{observed_versions[platform]} differs from declared v{p['version']}")
print("Database migration deployment is intentionally not inferred from local files.")
if errors:
    print("\nERRORS:")
    for message in errors: print("- " + message)
    sys.exit(1)
print("\nRepository compatibility check passed (legacy gaps listed above).")
