# iOS share capture

LaterBoxShare is an embedded Share Extension, not a redirect to the app. It accepts the text, URL and file representations offered by the source app. Files are copied before their temporary provider URLs expire. Captures are atomically persisted in `group.pro.micorp.laterbox`, imported idempotently into SwiftData at launch/activation and every 30 seconds while the app is running. Failed saves keep the sheet open. Shared attachments stay local; existing Pro metadata sync does not upload attachment binaries.

The light sheet uses LaterBox pastel green choice cards, editable fields, Save, Undo and Done. Available Apple Foundation Models prepare titles/tags/categories and support capture questions. AI sees text and filenames, not audiovisual or document contents. Model errors leave manual saving available. No Gemini or paid inference is used. The in-app Later AI drawer retains black styling and uses a green submit button, light guided cards and custom date controls.

Scheduled captures request local notification permission and install a reminder without launching LaterBox. Permission denial or scheduling failure is disclosed after the capture is saved. Due scheduled items move to Inbox when the app next runs; iOS does not launch the app merely to mutate SwiftData at the reminder timestamp. Notification taps open refreshed Inbox. Rescheduling replaces reminders; deleting, marking done and undoing cancel them.

## Device setup and verification

Register App Group `group.pro.micorp.laterbox` for both `pro.micorp.laterbox` and `pro.micorp.laterbox.Share` in the Apple developer account and refresh provisioning profiles. Both targets declare the entitlement. An unsigned simulator build cannot validate distribution provisioning.

From Safari, Photos, Files and a media app, share a link, selected text, image, video, audio, PDF and arbitrary file. Select LaterBox (enable it in the system share sheet if hidden). Verify attachments appear, Save/Undo/Edit works without launching LaterBox, and files still preview after reopening the host. Schedule a near-future return with alerts allowed and denied; verify notification, Inbox and original content. Repeat offline and on a device without Apple Intelligence. Test actual local-model latency on a compatible iPhone.

Automated coverage includes legacy store migration, capture round trips, due/future/deleted return states, existing capture/search/sync tests and guided Save/Undo UI. The physical iPhone was unavailable during implementation; actual cross-app provider and local-model validation remains a device check.
