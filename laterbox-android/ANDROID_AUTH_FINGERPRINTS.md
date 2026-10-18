# Android authentication fingerprints

These fingerprints are for the local Android debug signing key (`~/.android/debug.keystore`, alias `androiddebugkey`). Use them for Google OAuth while running the debug build.

## SHA-1 certificate fingerprint

`37:9A:F7:22:BA:02:C7:9F:55:C0:B4:9C:C6:44:6F:2D:F4:18:00:27`

## SHA-256 certificate fingerprint

`49:CA:1F:F0:24:D1:83:DB:08:77:46:75:DB:58:D7:4A:85:9D:15:18:CA:DB:A0:37:D3:D1:1B:41:75:E6:D4:85`

The release/upload keystore is not present in this checkout, so these are not the Play Store release fingerprints. Add the release SHA-1 separately in Google Cloud when the production signing certificate is available.
