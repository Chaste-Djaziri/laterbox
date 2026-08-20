# 0001. Local attachments import

**Date**: 2026-08-20
**Status**: Accepted

## Summary

LaterBox will import supported files into storage it owns and create one local item with multiple attachment records. Imports work without a network connection, survive source file changes after import, and never wait for cloud upload. Phase 14.5A and 14.5B provide the data model, safe copy pipeline, basic multi file picker, and capture sheet integration. R2 upload remains deferred.

## Context

LaterBox currently captures URLs and text into Drift. Attachments add binary ownership, filesystem failure, guest ownership, deletion, and future cloud storage concerns that do not fit the existing string capture path.

The local copy must remain valid if the source moves, is deleted, or lives on a disconnected volume. Filesystem changes and SQLite transactions cannot commit atomically together, so the import service needs an explicit order and rollback boundary. Remote metadata must not claim a binary exists before R2 has accepted it.

This feature assumes the existing Supabase authentication, per user item ownership, Drift tombstones, and local first sync architecture remain authoritative.

## Requirements

**User stories**:

1. As a LaterBox user, I want to choose several files with optional text so they appear immediately as one saved item.
2. As an offline user, I want imported files to survive restart without depending on their original paths or any network service.
3. As a guest, I want attachments to remain local and become owned by my account when I sign in.

**Acceptance criteria**:

1. **AC-1**: The existing Save to LaterBox sheet allows native multi file selection and permits optional text and files on the same item.
2. **AC-2**: One save creates exactly one item with zero or more text content and one attachment row for every successfully imported file.
3. **AC-3**: The item title is the first successfully imported file name without its extension. Phase 14.5A adds `file` to the item type taxonomy. Items with attachments use `type = file`, and every relevant Drift model, Supabase serialization path, filter, and display fallback must preserve that value without coercing it to an existing type.
4. **AC-4**: JPEG, PNG, WebP, HEIC, PDF, TXT, Markdown, DOC, and DOCX files from 1 byte through 100 MB are eligible. Every other type receives `unsupportedType`; files over 100 MB receive `tooLarge`.
5. **AC-5**: Every successful import is copied to `attachments/<attachmentId>/original.<ext>` below Application Support using a temporary file, streamed SHA 256, copied file verification, and atomic rename.
6. **AC-6**: Import never modifies or deletes a source file. Symlinks resolve to their target, and only readable regular files are eligible.
7. **AC-7**: Extension and MIME checks use one centralized policy. Unknown or `application/octet-stream` detection is allowed when no contradiction exists. DOC, DOCX, HEIC, and text formats receive explicit validation.
8. **AC-8**: DOCX validation performs bounded ZIP structure inspection without blindly extracting archive contents. It confirms clean container parsing plus `[Content_Types].xml` and `word/document.xml`, and rejects malformed, encrypted, path traversal, or otherwise problematic containers. DOC validation confirms the legacy Compound File signature.
9. **AC-9**: Repeated normalized source paths in one attempt import once. Different paths with identical SHA 256 values remain separate attachments.
10. **AC-10**: A source whose size or modification time changes during copying is rejected with `sourceChanged`, its temporary or final copy is removed, and other files continue.
11. **AC-11**: Valid files commit despite invalid peers. The result contains the item ID, successful attachment IDs, and typed per file failures. If no file succeeds after files were selected, no item is created and entered text remains in the sheet.
12. **AC-12**: Files are finalized before one Drift transaction inserts the item and every attachment row. A database failure rolls back rows and removes only copies created by that attempt.
13. **AC-13**: A successful partial import closes the sheet, updates the Inbox from Drift immediately, and shows a non blocking summary with the saved count and each failed filename and reason.
14. **AC-14**: Guest item and attachment ownership is nullable. On account claim, the item and all attachment rows, including tombstones, receive the authenticated user ID in one Drift transaction.
15. **AC-15**: Deleting an item tombstones it and every active attachment in one Drift transaction, marks their sync states pending, hides them immediately, and retains their binaries for future garbage collection.
16. **AC-16**: New attachments start with `uploadStatus = local`, `syncStatus = pending`, and no R2 key. A live attachment is not eligible for Supabase metadata push until it has an R2 key. This pending state is intentionally deferred and must not increment sync retries, record a sync error, or transition to `failed` while `deletedAt` and `r2ObjectKey` are both null.
17. **AC-17**: The Supabase attachments table enforces authenticated ownership and confirms the referenced item belongs to the same user. Guest attachments never leave the device.
18. **AC-18**: Imported attachment rows and LaterBox owned files remain resolvable after database and application restart.
19. **AC-19**: Each import uses an attempt scoped staging marker on the same filesystem as final attachment storage. After the database is ready, startup cleanup removes stale staged attempts and finalized UUID attachment directories that have no attachment row. It never removes a source path, a directory referenced by Drift, or an unrecognized directory.

## Options considered

### Option 1: LaterBox owned copies with a dedicated import service

The picker returns paths only. A shared service validates, hashes, copies, verifies, and records attachments.

**Pros**:

1. Source moves and deletions cannot break attachments.
2. Future drag, clipboard, Finder, and mobile capture can reuse one pipeline.
3. Failure behavior is testable without picker UI.

**Cons**:

1. Imports consume additional disk space.
2. Filesystem and database rollback require explicit cleanup code.

### Option 2: Reference source paths

Store the chosen absolute source paths without copying bytes.

**Pros**:

1. Fast imports and no duplicated disk use.

**Cons**:

1. Renames, cleanup, removable volumes, and sandbox changes create broken attachments.
2. Absolute paths are machine specific and unsuitable for durable ownership.

### Option 3: Upload first, cache second

Send files to cloud storage before creating local records.

**Pros**:

1. Remote bytes exist before metadata becomes visible.

**Cons**:

1. Offline capture fails.
2. Save latency and cloud failures enter the foreground capture path.
3. It contradicts LaterBox local first behavior.

## Decision

**Chosen option**: Option 1, LaterBox owned copies with a dedicated import service.

Use `file_picker` behind `AttachmentFilePicker`, streamed SHA 256 through `crypto`, MIME header detection through `mime`, and DOCX structure validation through `archive`. The picker performs no validation or import work.

## Rationale

LaterBox promises immediate local capture. Owning a verified copy is the only option that makes an attachment independent of the original path and the network. A separate import service provides one failure and integrity contract for every future capture surface.

The filesystem first order ensures database rows never point at a file that was not finalized. Compensating cleanup after a failed Drift transaction is small and bounded because every copied path belongs to the current attempt and contains a new UUID.

## Feature design

**Data model sketch**:

| Entity | Fields | Relationships and constraints |
|---|---|---|
| Local `items` | Existing fields, with `file` added to the item type taxonomy | An attachment save sets `type = file`, optional `textContent`, and title from the first successful filename. Drift and Supabase item serialization preserve the new value |
| Local `attachments` | `id` text required, `itemId` text required, `userId` text nullable, `originalFileName` text required, `fileExtension` text required, `mimeType` text required, `byteSize` integer required, `sha256` text required, `localPath` text required, `r2ObjectKey` text nullable, `width` integer nullable, `height` integer nullable, `uploadStatus` text required, `uploadAttempts` integer required, `uploadLastError` text nullable, `syncStatus` text required, `createdAt` datetime required, `updatedAt` datetime required, `deletedAt` datetime nullable, `lastSyncedAt` datetime nullable | UUID primary key. `itemId` references `items.id` without physical delete cascade. `localPath` unique. `r2ObjectKey` nullable and unique. Index item, user, SHA 256, upload status, sync status, and deletion time |
| Remote `attachments` | `id` uuid, `item_id` uuid, `user_id` uuid, original filename, extension, MIME type, byte size, SHA 256, R2 object key, nullable dimensions, created time, updated time, deleted time | Portable metadata only. R2 key required and unique for a live remote row. Foreign key to items. RLS requires attachment and item ownership |
| Local binary | Relative path `attachments/<attachmentId>/original.<ext>` | Resolved below the current Application Support directory. The original filename is metadata only |

The local Drift schema and remote Supabase schema are intentionally different. Device state such as `localPath`, `uploadStatus`, `uploadAttempts`, `uploadLastError`, `syncStatus`, and `lastSyncedAt` remains local. It is never serialized to Supabase. Remote rows contain only portable binary metadata, ownership, the R2 object key, and shared timestamps or tombstones.

Local constraints:

1. `userId` is nullable for guest rows.
2. `byteSize` is from 1 through `104857600` bytes.
3. `sha256` contains 64 lowercase hexadecimal characters.
4. `fileExtension` is lowercase without a leading dot.
5. `localPath` is relative and remains below the LaterBox attachment root.
6. `uploadAttempts >= 0`.
7. `width` and `height` are null or positive.
8. `uploadStatus` is `local`, `pending`, `uploading`, `uploaded`, or `failed`.
9. `syncStatus` is `pending`, `synced`, or `failed`.
10. SHA 256 is indexed but not unique.

**State transitions**:

```text
local → pending → uploading → uploaded
                        ↘ failed
```

Only `local` is used for new files in Phase 14.5A and 14.5B. Phase 14.5C activates the remaining upload transitions. Metadata sync remains independently pending while a live row has no R2 key. The sync engine treats that state as deferred work rather than a failed attempt.

Deletion sets `deletedAt` and hides the row. It does not remove the binary in this phase. A later garbage collector will use a grace period and sync state before physical removal.

**API surface**:

| Interface | Method | Key inputs | Key outputs | Auth | Key errors |
|---|---|---|---|---|---|
| `AttachmentFilePicker` | `pickFiles` | allowed extensions, multi select true | selected source paths | local session | cancelled picker returns empty selection |
| `AttachmentImportService` | `importFiles` | source paths, optional text | `AttachmentImportResult` | active user or guest | typed per file failures, batch database failure |
| `AttachmentRepository` | `watchForItem` | item ID | active non deleted attachments | active user or guest | ownership mismatch yields no rows |
| `AttachmentRepository` | `tombstone` | attachment ID | updated local row | active user or guest owner | missing or foreign attachment |
| `AppDatabase` | `claimGuestItemWithAttachments` | item ID, authenticated user ID | claimed item and attachment rows | authenticated session | transaction rollback |
| `AppDatabase` | `softDeleteItemWithAttachments` | item ID, deletion time | item and attachment tombstones | active user or guest owner | transaction rollback |
| Supabase `attachments` | select, insert, update | authenticated metadata with R2 key | owned remote metadata | authenticated user | RLS denial, parent ownership mismatch |

`AttachmentImportResult` contains nullable `itemId`, successful `attachmentIds`, and `failures`. Each `AttachmentImportFailure` contains a display filename, source path for the current UI session only, a failure code, and optional technical details. Source paths are never persisted or logged.

A batch database failure returns no item ID or attachment IDs and one `databaseFailed` result for each otherwise valid file after its owned copy has been removed.

Failure codes are `unsupportedType`, `tooLarge`, `emptyFile`, `unreadable`, `mimeMismatch`, `sourceChanged`, `copyFailed`, `verificationFailed`, and `databaseFailed`.

**Value sourcing**:

| Action | Value produced or displayed | Source |
|---|---|---|
| Pick files | Selected paths | Native `file_picker` result |
| Validate | Normalized source identity | Resolved canonical source path |
| Validate | Original filename | Basename of resolved source path, preserved as user metadata |
| Validate | Extension | Lowercase suffix of original filename without the dot |
| Validate | MIME type | Central policy using extension, header bytes, and explicit format checks |
| Validate | Byte size and modification time | Source `FileStat` before and after copy |
| Import | Attachment ID | UUID generated before the copy starts |
| Import | Local path | Attachment ID plus validated normalized extension |
| Import | SHA 256 | Bytes streamed from source, then independently verified from the temporary copy |
| Import | Item title | Original filename without extension of the first successfully finalized file |
| Import | Item and attachment owner | Current active user ID, or null in guest mode |
| Import | Timestamps | One application clock value per transaction, stored consistently with existing Drift rows |
| Import | Image dimensions | Null in Phase 14.5A and 14.5B. Phase 14.5E may derive positive values from decoded image metadata |
| Result UI | Saved count | Length of successful attachment IDs |
| Result UI | Failure summary | Typed failures mapped to UI copy |
| Restart | Absolute owned file path | Application Support root plus persisted relative local path |

**Key invariants**:

1. An item's attachment rows always have the same nullable user ID as the item after import or claim.
2. An attachment row is inserted only after its owned binary is finalized and verified.
3. A committed import contains one item and every successful attachment row in one Drift transaction.
4. Import cleanup can delete only UUID paths created by that attempt and never a source path.
5. Live attachment metadata without an R2 key is not eligible for remote push.
6. Guest rows are never sent to Supabase.
7. Logical deletion never physically cascades attachment rows or binaries.
8. Different source paths may produce identical hashes and remain separate rows.
9. Device local paths, upload errors, and queue state are never included in remote attachment payloads.
10. Startup orphan cleanup runs only after Drift is available and deletes only recognized import staging entries or UUID attachment directories that have no database row.

**Security model**:

Local queries scope attachments to the active user's ID, or to null in guest mode. Import resolves symlinks and accepts only readable regular files. Paths persisted in Drift are relative and must remain below the LaterBox attachment root. Absolute source paths exist only for the active picker and import call and are not persisted or logged.

Supabase RLS requires `auth.uid() = attachments.user_id` for reads and writes. Insert and update policies also require an `items` row whose ID and user ID match the attachment and authenticated user. Guest rows never reach Supabase.

**Critical test scenarios**:

1. Happy path: select PDF plus images with optional text, restart, observe one Inbox item and resolvable owned copies, verifies **AC-1**, **AC-2**, **AC-3**, **AC-5**, and **AC-18**.
2. Partial failure: import valid files with unsupported and oversized peers, commit valid files, close the sheet, and show typed failures, verifies **AC-4**, **AC-11**, and **AC-13**.
3. Integrity: change a source during copy or corrupt the temporary copy, reject it and remove only the attempt copy, verifies **AC-5**, **AC-10**, and **AC-12**.
4. Type security: inspect DOCX entries without extraction and reject a renamed ZIP, encrypted or malformed DOCX, malformed DOC, directory, and broken link, verifies **AC-6**, **AC-7**, and **AC-8**.
5. Ownership: import as guest, sign in, and confirm item plus live and tombstoned attachments are claimed atomically, verifies **AC-14** and **AC-17**.
6. Deletion: delete an item and observe immediate item and attachment tombstones while the owned binary remains, verifies **AC-15**.
7. Cloud boundary: import offline and confirm no attachment metadata push occurs without an R2 key, verifies **AC-16** and **AC-17**.
8. Crash recovery: leave stale staging data and an unreferenced finalized UUID directory, restart after Drift opens, and confirm only those orphaned paths are removed, verifies **AC-19**.

## Build plan

The project has no recorded build approach. Use a thin end to end local slice first, then add remote schema preparation. Each step leaves the local path usable.

1. Add attachment dependencies, extend item type handling with `file`, and add the Drift attachments table, indexes, constraints, schema migration, generated code, database transactions, and database tests, satisfies **AC-2**, **AC-3**, **AC-12**, **AC-14**, **AC-15**, **AC-16**, and **AC-18**.
2. Add the Supabase attachments migration and RLS policies without enabling live metadata push before R2, satisfies **AC-16** and **AC-17**.
3. Add attachment models, typed failures, repository, active user scoping, and provider wiring, satisfies **AC-2**, **AC-11**, **AC-14**, and **AC-15**.
4. Add the centralized file policy with size, extension, MIME, DOC, DOCX, HEIC, regular file, symlink, and duplicate path validation tests, satisfies **AC-4**, **AC-6**, **AC-7**, **AC-8**, **AC-9**, and **AC-10**.
5. Add LaterBox owned storage with attempt scoped staging, temporary copying, streamed hash, copied file verification, atomic rename, rollback cleanup, startup orphan cleanup, and restart tests, satisfies **AC-5**, **AC-6**, **AC-10**, **AC-12**, **AC-18**, and **AC-19**.
6. Add `AttachmentImportService` to finalize valid files and insert one item plus all rows transactionally with optional text and partial results, satisfies **AC-2**, **AC-3**, **AC-9**, **AC-11**, **AC-12**, **AC-14**, and **AC-16**.
7. Add `AttachmentFilePicker` backed by `file_picker` and integrate multi selection, removable file rows, mixed text, saving state, preserved zero success text, and partial failure summary into the existing capture sheet, satisfies **AC-1**, **AC-11**, and **AC-13**.
8. Run the complete Flutter suite, changed area analysis, migration tests, offline restart test, and macOS build. Confirm no R2 or network dependency enters import, satisfies **AC-5**, **AC-16**, and **AC-18**.

## Consequences

**Positive**:

1. Imported files remain durable when their sources change or disappear.
2. Every future capture surface can reuse one import and validation contract.
3. Remote metadata remains truthful because a live row requires a remote object key.
4. Guest ownership, account claim, and deletion follow existing LaterBox patterns.

**Negative and tradeoffs**:

1. Every import duplicates local bytes and consumes LaterBox managed disk space.
2. Filesystem and database consistency relies on tested compensating cleanup.
3. Strict type checks intentionally reject many otherwise readable formats.
4. Deleted binaries remain until a future garbage collector is implemented.

**Neutral**:

1. SHA 256 is recorded for integrity but does not deduplicate content.
2. Image dimensions are nullable and may be populated during import where supported.
3. Upload states beyond `local` exist in the model but activate in Phase 14.5C.

## Follow-up

1. Phase 14.5C adds signed R2 uploads and makes live metadata eligible for Supabase sync.
2. Phase 14.5D adds background upload retry and binary garbage collection with a grace period.
3. Phase 14.5E adds rich attachment previews, open, and save as actions.
4. Phase 14.5F adds drag, Finder, clipboard image, and screenshot capture surfaces.
