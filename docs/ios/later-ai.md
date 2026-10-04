# Later AI on native iOS

Later AI uses Apple's Foundation Models on-device provider. Text and links can be captured through chat, with original content stored separately from generated formatting, summaries, categories, and tags. Simple conversation does not create library items. Clear capture requests save locally and display Edit and Undo; ambiguous requests display capture/chat choices. Missing reminder timing is asked after saving.

Home's Add item opens Later AI when a model is available. Otherwise it opens the four-step guided form. The plus button inside Later AI opens guided capture at any time. The guided form uses dedicated content, title, category, format, tag, and date controls rather than a conversational composer. Model failures expose Retry and Continue manually, preserving the submitted content.

## Access

| Feature | Access |
| --- | --- |
| On-device Later AI and local search | Free and Pro |
| Guided capture and local storage | Free and Pro |
| AI Inbox Organizer | Verified Pro |
| Cloud sync | Signed-in verified Pro |
| Gemini fallback | Signed-in verified Pro, only when explicitly enabled |

StoreKit recognizes only active verified LaterBox subscription products. Account entitlements are checked through the existing Supabase entitlement RPC. Signed StoreKit transactions are registered through the existing Apple verification endpoint; cloud access requires a purchase linked to the signed-in account. No cached Boolean grants Pro access.

## Disabled Gemini fallback

Fallback is deliberately disabled by `GeminiLaterAIProvider.enabled = false` and by the server's absent `IOS_GEMINI_FALLBACK_ENABLED` flag. Local-model errors are not hidden by remote responses. Free users never invoke Gemini, and the server separately checks Pro entitlement.

For a future explicit rollout, both sides must be enabled. The server also requires `GEMINI_API_KEY` and `IOS_GEMINI_MODEL`. Keys remain server-side. The endpoint uses Gemini's Interactions API with a JSON schema, a bounded output, and request storage disabled. No live Gemini calls were needed for implementation tests.

## Search and sync

Local search covers original content, notes, titles, domains, URLs, tags, categories, summaries, and formatted text. Exact and lexical matches rank first; typo tolerance and available Apple Natural Language word embeddings broaden matching. Longer queries can be interpreted on-device for content-type and return-date filters. Search is debounced, stale interpretations are discarded, and lexical results remain available when AI fails.

Pro sync paginates remote records, uploads pending changes with stable IDs, retains newer local revisions, and persists notes, classification, link metadata, and return dates using the existing database schema. Unknown web structured metadata is retained during upload. Failed uploads stay pending. Permanent cloud deletions are queued for an online retry.

## Validation

Run native behavior and UI tests with Xcode's `laterbox-ios` scheme. Server boundary tests are in `laterbox-web/src/app/api/ai/ios/route.test.ts` and use mocked network responses.

Before release, use a compatible physical iPhone to check model availability, generation latency, content/instruction separation, explicit tags and dates, refusal recovery, offline capture, and ambiguous search. Simulator tests and mocked providers verify app actions but do not establish real-device model accuracy. Verify signed-in Pro sync against a staging account, including an offline edit, retry, and purchase registration.
