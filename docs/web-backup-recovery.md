# LaterBox Web backup and restore — Phase 4

**Status:** Implemented in the repository; needs real-browser and multi-device acceptance testing before release.

## Formats

- **Item records JSON** (Settings): unencrypted, readable export of currently active cached item records. It is **not** a complete library archive, contains no recoverable attachment bytes and has no corresponding automatic import. Treat it as sensitive personal data.
- **Encrypted Web backup** (`.laterboxweb`): versioned `laterbox-web-backup-v1` payload, encrypted with PBKDF2-HMAC-SHA256 (250,000 rounds, random 16-byte salt) and AES-256-GCM (random 12-byte IV). Includes active and deleted cached item records, collection records, notes and locally available attachment bytes. It never transmits the password.
- **iOS `.laterbox`**: encrypted using a related algorithm, but with a different inner data model. Neither Web-import-of-iOS nor iOS-import-of-Web is supported or advertised.

The browser's item/collection cache is **localStorage**, with local attachment bytes in **IndexedDB**; Supabase and object storage handle optional cloud synchronization. Clearing browser site data can erase local-only records.

## Restore policy

1. Select a `.laterboxweb` file and enter its password.
2. Decrypt locally and validate archive format and item records. Preview existing-ID conflicts, new items, collection counts, available local file bytes and unavailable cloud-only attachments.
3. Confirm additive restore. Existing IDs are **skipped**, not overwritten. Collection names are merged case-insensitively; new browser collection IDs are generated. Imported item ownership is assigned to the active browser account. Local file references receive new IDs.
4. Write local files, then item and collection state. On a failure, restore the previous localStorage snapshot and try to clean up written attachments.
5. Keep the original backup and verify results before relying on another device.

### Current limitations / release gates

- Only **locally available** attachment files are bundled; cloud-only remote object bytes are not fetched. They are reported as missing, and broken attachment references are not restored.
- Web export and import are capped at roughly **60 MB of decrypted JSON** (ciphertext is larger). Large libraries need a future streaming format.
- Items imported into signed-in Pro accounts enter the normal pending cloud item queue. **Restored collection membership and deleted history do not yet have a complete cloud-replay path.** Do not claim full cross-device restore. A separate cloud restoration workflow should be implemented and tested before promising that.
- iOS backup interoperability is pending a separately versioned mapping and cross-platform fixtures. Never label the Web format as native iOS compatible.
- Existing-ID conflicts are skipped rather than merged. No automatic destructive replacement is offered.
- The module has unit tests, but **real browser restore with attachments and signed-in cloud sync has not yet been verified**.

## Release acceptance checklist

- [ ] Export and decrypt a guest library containing links, notes, attachments, and collections.
- [ ] Test files absent from IndexedDB and confirm the export warns exactly which count was omitted.
- [ ] Test wrong password, tampered ciphertext, corrupt JSON, unsupported iOS archive and too-large files.
- [ ] Restore into empty browser data; verify file bytes and item fields, and that all statuses survive.
- [ ] Restore twice; verify duplicate IDs are skipped and existing items unchanged.
- [ ] Force an IndexedDB/localStorage failure midway; ensure the original library is intact.
- [ ] Restore with both guest and signed-in accounts; ensure no cross-user file disclosure.
- [ ] Verify signed-in cloud reconciliation, collision handling, collections, memberships, and deleted history separately.
- [ ] Confirm UI on Safari/iOS Safari, Chrome, Firefox and smaller displays.
- [ ] Keep production cloud migration/deployment separate from this UI work.
