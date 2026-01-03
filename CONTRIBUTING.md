# Contributing

## Branch naming
- `feature/<directive>-<summary>`
- `fix/<summary>`
- `chore/<summary>`

## Before you commit
- Run module unit tests.
- Run contract tests against `specs/openapi.yaml`.
- Run the full-stack compose smoke test (when applicable).
- Verify no secrets, keys, tokens, or environment-specific paths are included.

## PR requirements
- Link relevant directive docs.
- Include test evidence (logs/coverage summaries/screenshots as appropriate).
- Keep changes scoped to the PR intent.
