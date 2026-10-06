# Contributing

Read [README.md](README.md) for the maintained native, web, extension, and backend projects. Follow [AGENTS.md](AGENTS.md): work on `main`, record user-facing changes in `CHANGELOG.md` before implementation, and commit each logical edit immediately using conventional commits.

## Verification

Run checks for the subsystem you change:

- Web: `cd laterbox-web && npx tsc --noEmit --incremental false && npm test`.
- Apple: `python -m unittest discover -s laterbox-ios/ci -p 'test_*.py'`; run Swift and UI tests through Xcode as described in [Apple CI](laterbox-ios/ci/README.md).
- Android: open `laterbox-android/` in Android Studio and run the app's Gradle unit tests and build with JDK 17 and SDK 36.
- Extensions: `cd laterbox-extension && npm run typecheck && npm run build:all`.
- Backend: use the Deno checks and tests listed in `.github/workflows/release.yml`.

Never commit secrets, signing keys, generated builds, or local SDK configuration. Describe the problem, behavior, and verification in reviews using the [review template](.github/PULL_REQUEST_TEMPLATE.md).

See [SUPPORT.md](SUPPORT.md) for help, [SECURITY.md](SECURITY.md) to report vulnerabilities, and [LICENSE](LICENSE) for licensing terms.
