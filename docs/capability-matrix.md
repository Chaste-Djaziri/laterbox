# LaterBox capability matrix

This is the release contract for product parity. A platform may advertise a capability only when its entry is marked **Ready** and its required verification is recorded in the release checklist.

| Capability | macOS MVP | iOS | Android | Windows | Web | Extension | Access | Data contract |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Save URL, text, note, and file | Ready | Parity target | Parity target | Parity target | Parity target | Ready | Free | Local SQLite write succeeds offline; sync is idempotent when Pro returns online. |
| Schedule and return | Ready | Parity target | Parity target | Parity target | Parity target | N/A | Free | One canonical return timestamp and item lifecycle across clients. |
| Search, reader, collections, export | Ready | Parity target | Parity target | Parity target | Parity target | N/A | Free | Local data remains available without an account. |
| Account sync and cloud attachments | Ready | Parity target | Parity target | Parity target | Ready | Ready | Pro | Authenticated data is account-scoped and conflict-safe. |
| Paid access | StoreKit | StoreKit | Play Billing | Deferred | Paddle | N/A | Pro | Entitlement is account-bound; restore and refresh never create duplicate access. |
| Global quick capture | Ready | N/A | N/A | Parity target | In-app only | N/A | Free | Failed launches retain the capture draft. |
| Menu bar / system tray | Ready | N/A | N/A | Parity target | N/A | N/A | Free | Open and Quick Capture are always recoverable actions. |
| Native sharing / Services | Ready | Parity target | Parity target | Parity target | N/A | Browser share | Free | Failed deliveries stay queued until retried or discarded. |
| Safari / browser capture | Ready | Safari target | Chrome target | Browser target | N/A | Ready | Pro for connected sync | Browser sends only explicit user-selected content. |
| Clipboard monitoring | Ready | Opt-in target | Opt-in target | Parity target | N/A | N/A | Pro automation | Candidates are never persisted or uploaded before confirmation. |
| Watch Mode / screen context | Ready | N/A | N/A | Deferred | N/A | N/A | Pro automation | Requires explicit Screen Recording permission and an obvious active state. |
| Notch companion | Ready on supported Macs | Dynamic Island target | N/A | N/A | N/A | N/A | Pro automation | No-op on hardware without a notch; captures still work. |
| Return notifications | Ready | Parity target | Parity target | Parity target | Web target | N/A | Free local; Pro remote | Permission denial leaves in-app return queues usable. |

## Platform rules

- **Ready** means a release test exists and the capability passed on a clean supported device.
- **Parity target** means its behavior must match the data contract before it is promoted or marketed.
- A platform-specific permission must be disclosed in onboarding and System Status before the feature is enabled.
- Changes to a capability update this file, `CHANGELOG.md`, and the applicable release checklist in the same logical change.
