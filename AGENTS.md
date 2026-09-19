# AGENTS.md

## Git workflow

- Commit each edit as its own independent commit, never batch unrelated changes into a single commit. An atomic commit style: make a change, commit it immediately, then move to the next change. Do not group multiple logical changes into one commit.
- Follow the existing conventional-commit style (e.g., `docs:`, `chore:`, `feat:`).
- work directly on the main branch; do not create or use separate branches.
- before making any user-facing change, you must make an entry in CHANGELOG.md, even if it's just "Minor UI tweaks."