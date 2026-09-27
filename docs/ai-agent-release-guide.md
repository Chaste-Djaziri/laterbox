# LaterBox AI agent release guide

Use this guide for any LaterBox change that can reach customers.

## Preflight

1. Check `git status` and do not overwrite unrelated user changes.
2. Read `docs/capability-matrix.md`, the applicable platform config, and the current `CHANGELOG.md` entry.
3. Add the customer-visible changelog entry before changing product behavior.
4. Never put credentials, StoreKit keys, App Store Connect access, Supabase service keys, or test-account passwords in source control or logs.

## Implementation contract

- Keep a change to one independently releasable behavior.
- Maintain offline capture durability; never discard queued data after a failed integration or sync attempt.
- Make permission-dependent features explain their unavailable state and offer a retry or System Settings route.
- Update the capability matrix whenever a capability, platform, entitlement, permission, or parity target changes.
- Add or update an automated test. Native-only behavior also needs a repeatable clean-device manual test.

## Commit and release contract

1. Verify the smallest relevant test set, then the full suite for release-critical changes.
2. Commit immediately on `main` using a conventional commit. One commit represents one logical change, even when it spans several files.
3. Do not combine unrelated fixes, generated files, or user work with the current commit.
4. Before a Mac App Store release, complete `docs/macos-release-checklist.md`; a claim is not shippable because a screen exists.
