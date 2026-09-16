# AGENTS.md

## Git workflow

- Commit each edit as its own independent commit, never batch unrelated changes into a single commit. an atomic commit style.
- Follow the existing conventional-commit style (e.g., `docs:`, `chore:`, `feat:`).
- each feature should be its own branch, and each bug fix should be its own branch.
- every user-facing change must have an entry in CHANGELOG.md, even if it's just "Minor UI tweaks."