# macOS App Store release checklist

Complete this checklist for each macOS submission. Record the build number, hardware, macOS version, tester, and result beside each item in the release issue.

## Build and signing

- [ ] Configure and verify a native macOS Xcode target; the current Apple release scheme targets iOS.
- [ ] Run native Swift tests and archive the macOS target using Xcode with App Store signing.
- [ ] Archive Apple Silicon and Intel-compatible output, then verify the main app and embedded Share/Safari extensions have the expected App Sandbox, App Group, network, file-access, and APNs entitlements.
- [ ] Validate the signed package with App Store Connect before upload.
- [ ] Confirm the build version is new and release notes match `CHANGELOG.md`.

## Clean-device acceptance

- [ ] On a clean macOS 12.3+ Apple Silicon Mac and Intel Mac: install, sign in, and finish onboarding.
- [ ] Save URL, selected text, note, file, clipboard candidate, Service input, Share Extension input, and Safari extension input; verify each can be scheduled, returned, opened, archived, and retried after an offline save.
- [ ] Verify tray/menu-bar actions, global hotkey, launch-at-login, window restoration, notifications, Screen Recording/Watch Mode permission recovery, and notch/no-notch behavior.
- [ ] Purchase monthly and annual subscriptions in StoreKit sandbox, cancel, restore, refresh entitlement, and open subscription management. Verify the free tier retains local data.

## App Store Connect

- [ ] StoreKit products `com.laterbox.pro.monthly` and `com.laterbox.pro.annual` are approved in the LaterBox Pro subscription group with a 14-day introductory trial.
- [ ] Privacy nutrition labels match production data collection; privacy policy, terms, support URL, age rating, and encryption declaration are complete.
- [ ] Screenshots and app preview reflect the current macOS build; review notes explain sign-in, permission-dependent integrations, and StoreKit sandbox access.
- [ ] Test account access, support contact, and escalation owner are current and kept outside the repository.
