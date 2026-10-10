# Clerk rollout and existing accounts

The repository implementation is disabled by default. Production activation requires configuration in Clerk, Supabase, and Cloudflare. Setting the flag alone does not migrate users or make Supabase trust Clerk.

## Production configuration

1. Configure the production Clerk instance for `laterbox.dev`, with its Frontend API at `clerk.laterbox.dev`. Install and verify the DNS records provided by Clerk. Use this same instance and publishable key on `laterbox.dev`, `www.laterbox.dev`, and `app.laterbox.dev`. Configure email-code login, password login, and the existing Google/GitHub providers, including their production OAuth callbacks. Enable account registration only through Clerk once the web flag is active.
2. Enable Clerk's Supabase compatibility integration. Session tokens must include `"role": "authenticated"`. In the Supabase production dashboard, add the Clerk third-party integration with domain `clerk.laterbox.dev` (the issuer is `https://clerk.laterbox.dev`). This is the native third-party integration, not the deprecated Supabase JWT template.
3. Apply migrations `202610100002` through `202610100004` in order. Existing UUIDs and data are retained. New provider mappings are private and writable only with the service role. Policies and public SQL functions are updated from their current definitions, including Storage policies; their Pro checks remain intact. For a different Supabase project or local Clerk development instance, add its exact trusted issuer to `auth_provider_issuers` and adapt server verification configuration before testing.
4. Deploy `attachment-storage`, `delete-account`, `capture`, and `extension-connect` with the updated configuration. `verify_jwt=false` allows Clerk JWTs through the function gateway; each function verifies identities internally. Retain existing R2 secrets. Attachment cleanup requires `R2_BUCKET`, `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, and `R2_SECRET_ACCESS_KEY`.
5. Set Cloudflare secrets `CLERK_SECRET_KEY`, `CLERK_WEBHOOK_SIGNING_SECRET`, and `SUPABASE_SERVICE_ROLE_KEY`. Set build variables `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `NEXT_PUBLIC_CLERK_AUTH_ENABLED=true`. These `NEXT_PUBLIC_*` variables must be present during the build, not just worker runtime. Configure `CLERK_AUTHORIZED_PARTIES=https://laterbox.dev,https://www.laterbox.dev,https://app.laterbox.dev`; explicitly add trusted localhost origins only for local testing. Never commit secrets.
6. Configure Clerk webhooks at `https://app.laterbox.dev/api/auth/clerk/webhook` for `user.created`, `user.updated`, and `user.deleted`, with the matching signing secret. Webhooks work before the UI flag is enabled. Identity conflicts remain unlinked and require both-account login proof in the app.
7. Build and deploy the web app after verifying configuration. Test login on the app, visit the landing page in the same browser, and confirm **Open app**. Confirm sign-out across both origins, OAuth, email codes, password login, guest mode, and extension connection.

## Local development

Production `pk_live_`/`sk_live_` keys cannot authenticate on `localhost`: Clerk restricts them to the configured production domain. Use development `pk_test_`/`sk_test_` keys with an isolated development Supabase project, its matching Clerk integration, and its exact Clerk/Supabase issuers in `auth_provider_issuers`. Do not migrate production Supabase users into a development Clerk instance: the account has one Clerk identity, and development/production user stores are separate.

Set `NEXT_PUBLIC_CLERK_AUTH_ENABLED=true`, `NEXT_PUBLIC_APP_ORIGIN=http://localhost:3000`, `CLERK_JWT_ISSUER=https://your-instance.clerk.accounts.dev`, and `CLERK_AUTHORIZED_PARTIES=http://localhost:3000,http://app.localhost:3000` in the untracked environment file, along with the development keys and development Supabase credentials. Restart Next.js after changing keys or the rollout flag. Forward webhooks through a supported tunnel and configure its signing secret for local webhook tests.

To test actual production users locally, Clerk documents an alternative: map a hostname under `laterbox.dev` to your machine and run HTTPS on port 443. Set the app origin and authorized parties to that hostname and keep the production issuer. Ordinary `localhost:3000` does not support production keys. See [Clerk's production-key local testing guide](https://clerk.com/docs/guides/development/troubleshooting/using-production-keys-in-development).

## Gradual migration

On the app origin, an existing Supabase session is refreshed, then verified by the migration API. Confirmed email users receive a single-use Clerk ticket with a 60-second lifetime. The ticket stays in the response body and never appears in a URL. The legacy local session is removed only after Clerk accepts it.

Existing users can also open `/login?legacy=1` and use their existing Supabase password or email code. If a Clerk account with the same email already exists, sign into Clerk first and use legacy login to prove ownership of both identities. Email equality never authorizes merging. The server links identities transactionally; repeat requests reuse the same account and Clerk external ID.

An active Supabase session is not inherently a Clerk session. A login outside the app origin cannot inspect the app's local storage; visiting the app performs the handoff. Supabase MFA users require reviewed MFA migration and are not automatically migrated. Clerk accounts with MFA must complete Clerk login rather than use a legacy ticket. Phone-only users also need a separate migration workflow.

New Clerk users receive a linked Supabase identity with the same UUID so the mobile apps can continue using verified Supabase email-code login. Clerk passwords are not mirrored into Supabase. Existing legacy passwords remain valid during the transition; changes made to a Clerk password do not update a legacy password. Migrate native clients before retiring Supabase Auth.

## Import remaining accounts

Use a privileged SQL connection to export a JSON array from Supabase. Keep the export outside the repository with restricted permissions: it contains password hashes.

```sql
select coalesce(json_agg(json_build_object(
  'id', u.id,
  'email', u.email,
  'email_confirmed_at', u.email_confirmed_at,
  'encrypted_password', u.encrypted_password,
  'raw_user_meta_data', u.raw_user_meta_data,
  'mfa_enabled', exists(select 1 from auth.mfa_factors f where f.user_id=u.id and f.status='verified')
)), '[]'::json)
from auth.users u;
```

From `laterbox-web`, with secrets available in an untracked environment file:

```sh
npx tsx --env-file=.env scripts/import-clerk-users.ts /secure/path/users.json
npx tsx --env-file=.env scripts/import-clerk-users.ts /secure/path/users.json --execute
```

The default is dry-run. Re-running resumes from durable account mappings and Clerk external IDs, including partially completed user creation. Supported bcrypt hashes preserve passwords; users without hashes use email-code login. Unconfirmed addresses are imported as reserved, not verified. MFA, phone-only accounts, unsupported hashes, and conflicts are reported as requiring manual work. Only counts and failing account UUIDs are logged. Dry-run validates the export/database state; only execution can detect Clerk-side email conflicts and API limits. Delete the export securely after reconciliation.

## Account deletion and retries

Deletion marks the application account unavailable, removes its R2 prefix, revokes Clerk and Supabase identities, then cascades database data. Failure returns an error rather than falsely confirming deletion. A deletion tombstone survives cleanup, and signed `user.deleted` webhooks retry interrupted work. No public RPC can bypass provider revocation.

If a webhook or provider outage leaves jobs pending, inspect and retry them with service credentials:

```sh
npx tsx --env-file=.env scripts/retry-account-deletions.ts
npx tsx --env-file=.env scripts/retry-account-deletions.ts --execute
```

Monitor failed migration/webhook log messages and counts of unlinked accounts and incomplete deletion jobs. Do not log session tokens, email codes, hashes, SDK errors, or webhook bodies. Configure operational retries for pending cleanup jobs; this repository does not install a scheduled production job automatically.

## Rollback

Rebuild and redeploy with `NEXT_PUBLIC_CLERK_AUTH_ENABLED=false`. Preserve Clerk keys, webhooks, the dual-provider APIs, identity mappings, and database migrations. Keep Supabase Auth enabled so existing mobile and legacy web sessions continue working. Imported/new Clerk users can use their linked Supabase email-code identity during rollback. Do not revert application foreign keys or delete identities.

References: [Supabase third-party Clerk integration](https://supabase.com/docs/guides/auth/third-party/clerk), [Clerk migration strategies](https://clerk.com/docs/guides/development/migrating/overview), [Clerk production deployment](https://clerk.com/docs/guides/development/deployment/production).
