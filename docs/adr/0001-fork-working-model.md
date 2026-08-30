# ADR 0001: Fork Working Model - pull upstream, work in fork

Status: accepted (2026-08-30)
Supersedes: initial "pure mirror + file findings upstream" plan (same day, SOD)

## Context

This fork exists for independent security/supply-chain verification and
evaluation of PenEcho (first run: 2026-08-30, filed as issue #1). The initial
plan was to keep the fork a bit-exact mirror and file findings upstream as
issues. Upstream maintainers are actively shipping (three releases in three
days), and interrupting them with third-party evaluation work is not desired.

## Decision

1. `main` tracks `penecho/penecho:main` - pull-only sync (fast-forward).
2. All fork work (verification action items, evaluation, future features)
   happens on branches of this repo, merged to `main` via PR.
3. No upstream communication about evaluation work: no issues, no PRs, no
   direct contact.
4. The fork's own issue tracker holds the evaluation records
   (public-safe content only).

## Consequences

- `main` is no longer bit-identical to upstream: fork-specific files
  (`AGENTS.md`, `specs/`, `docs/adr/`, `SECURITY.md`, `CHANGELOG.md`,
  `CODEOWNERS`, `.github/dependabot.yml`) persist across syncs.
- Every upstream sync invalidates the verification snapshot: re-run the
  verification (spec 001) against the new HEAD.
- Findings stay on the fork until (if ever) the upstream team reaches out or
  asks for them independently.
- Branches carrying fork-specific changes must be re-based against a fresh
  upstream sync before merging, to keep `main` mergeable.
