# PenEcho (satwareAG-ironMike fork)

Fork of [penecho/penecho](https://github.com/penecho/penecho) for independent
security/supply-chain verification and evaluation. Upstream stays untouched:
no issues, PRs, or contact about our evaluation work.

## Working Model (binding)

| Rule | Value |
|------|-------|
| Upstream | `penecho/penecho`, remote `upstream` - pull-only, never pushed to |
| `main` | upstream sync target: accepts upstream syncs + branch merges via PR only |
| Fork work | all work happens on branches of this repo (`origin`), merged to `main` via PR |
| Upstream communication | none (decision 2026-08-30) |
| Evaluation records | this repo's issue tracker; published content must be public-safe (no internal org names or URLs) |

Rationale: [docs/adr/0001-fork-working-model.md](docs/adr/0001-fork-working-model.md)

## Sync with upstream

```bash
git fetch upstream
git switch main
git merge --ff-only upstream/main   # fast-forward sync (pull-only)
```

After each sync: re-run the verification against the new upstream HEAD
(spec: `specs/001-security-verification/spec.md`).

## Forge (GitHub)

- CLI: `gh`. **Always pass `--repo satwareAG-ironMike/penecho`** for issue/PR
  operations: in a fork checkout, bare `gh issue list` / `gh issue create`
  resolves to the UPSTREAM repo (verified 2026-08-30).
- The fork has its own issue tracker; upstream issues appear in the GitHub UI
  Issues view but live on `penecho/penecho`.
- Daily ops: issue `Daily Ops YYYY-MM-DD` (label `daily-ops`, milestone `YYYY-Www`).

## Commands

| Task | Command |
|------|---------|
| Install | `npm ci` (Node >= 22, enforced by `preinstall`) |
| Test | `npm test` (`node --test`) |
| Static checks + tests | `npm run check` |
| Dev server | `npm run dev` |
| CLI | `npm start` |

## Layout

| Path | Scope |
|------|-------|
| `src/cli/` | CLI entry, configure, update, node-version gate |
| `src/server/` | local server, cloud connector, canvas-agent runtime |
| `src/providers/` | AI providers: Claude/Codex/Kimi CLI + `api` (OpenAI/Anthropic-compatible HTTP) |
| `public/` | canvas client |
| `desktop/`, `tools/` | Electron + mobile packaging |
| `test/` | `node:test` suite |
| `specs/` | SDD specs (active feature: `002-local-ai-gdpr-compat`, milestone `local-ai-gdpr-compat`); IPADP metadata in `specs/metadata.json` |
| `docs/adr/` | decision records |

## License & Compliance

- AGPL-3.0-only with commercial dual license (`COMMERCIAL-LICENSE.md`);
  trademarks separate (`TRADEMARKS.md`).
- EU/GDPR: device-linked mode routes canvas content through the `penecho.ai`
  relay; for EU data use local/self-hosted mode.

## DOX framework

- DOX is highly performant AGENTS.md hierarchy installed here
- Agent must follow DOX instructions across any edits

## Core Contract

- AGENTS.md files are binding work contracts for their subtrees
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it

## Read Before Editing

1. Read the root AGENTS.md
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules
7. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX

Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.

## Update After Editing

Every meaningful change requires a DOX pass before the task is done.

Update the closest owning AGENTS.md when a change affects:

- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- AGENTS.md creation, deletion, move, rename, or index contents

Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen.

## Hierarchy

- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index
- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific and practical it must be

## Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty
- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists

Default section order:
- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

## Style

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

## Closeout

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## User Preferences

- All work happens in this fork. Never create issues, PRs, or any other
  contact with upstream about evaluation work (decision 2026-08-30).
- `main` tracks upstream; fork-specific files (this file, `specs/`,
  `docs/adr/`, `SECURITY.md`, ...) are expected to persist across syncs.
- Everything published in this repo (issues, PRs, docs) must be public-safe:
  no internal org names, no internal URLs, no internal project references.

## Child DOX Index

- No child AGENTS.md files are needed for the current repository structure.
- Root-owned files: `README.md`, `LICENSE`, `COMMERCIAL-LICENSE.md`,
  `TRADEMARKS.md`, `CONTRIBUTING.md`, `CONTRIBUTOR-LICENSE-AGREEMENT.md`,
  `NOTICE`, and root-level project documentation.
