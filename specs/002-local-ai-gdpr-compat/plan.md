# Implementation Plan: Local AI Stack + GDPR Compatibility

**Spec**: [spec.md](spec.md) - Clarified (2026-08-31)
**Branch**: `feat/002-local-ai-gdpr-compat`
**Date**: 2026-08-31

## Input: FR-by-FR Coverage Audit (2026-08-31)

Read-only audit of the existing `api` provider (branch ef3a56f):

| Item | Verdict | Evidence / note |
|------|---------|-----------------|
| FR-001 canvas loop via OpenAI path | covered | E2E-verified (smoke 8/8 + human session) |
| FR-002 SSE streaming | covered | C4 PASS; minor: legacy `/api/ai/command` sends phases, not token deltas |
| FR-003 command protocol + capability warning | partial | protocol works (C5/C7); no capability warning for weak models |
| FR-004 plain-HTTP local/LAN | covered | no TLS requirement for local/RFC1918 in code |
| FR-005 no non-local egress | partial | outbound: npm update check + opt-in search endpoints; egress audit (TC-004) not yet scripted |
| FR-006 config validation + model existence | partial | `doctor --api` checks reachability/auth (static); no configured-model check vs `GET /v1/models`; wizard probe gap = issue #12 |
| FR-007 provider health state | missing | no ready/degraded/offline surface, no model list display |
| FR-008 GDPR data-flow document | missing | no per-mode document, no in-app reference |
| FR-009 per-conversation provider | covered | existing |
| FR-010 key never logged in full | covered | redaction verified in audit |
| TC-002 contract tests (OpenAI mock) | partial | provider unit tests exist; missing: streaming round trip, canvas JSON round trip incl. markdown-fence tolerance, `reasoning_content` handling |

**Scope conclusion**: this is a gap-closure plan. Six work items (W1-W6);
everything else in the spec is already covered and stays covered.

## Work Items

### W1 - TC-002 contract tests (test-first, no network)

In-process OpenAI-compatible mock server (Node `http`, no dependency) in
`test/`:

- streaming round trip: `stream: true` -> SSE `data:` chunks -> assembled
  content matches non-stream response
- canvas JSON command round trip: model output wrapped in a ```json fence is
  parsed and executed (fence tolerance), bare JSON also parses
- `reasoning_content`: response with a separate `reasoning_content` field and
  empty/small `content` is handled (no crash, no error surfaced to user at
  tiny `max_tokens` budgets)

Acceptance: `npm test` green; mock tests run with no external network.

### W2 - FR-006 model-existence check + wizard probe (closes issue #12)

- `penecho doctor --api`: after reachability+auth, call `GET {base}/models`
  and verify the configured model is listed; precise error when absent
  (list available models in the hint).
- Configure wizard: on save, probe the resolved endpoint (`GET {base}/models`
  for openai format) and show the result before saving; warn on bare-host
  base URLs (missing version path).
- Base-URL contract documented: openai format expects the version path in
  the base URL (`https://host/v1`).

### W3 - FR-007 provider health state

Expose provider status: `ready` / `degraded` (reachable, model missing or
last call failed) / `offline` (unreachable or auth failed), selected model,
and the model list when the server provides one. Surface in `doctor` output
and in the app's provider status UI (read-only; no polling - on open +
manual refresh, per clarification decision 3).

### W4 - FR-003 capability warning

When the selected model is not in the capability-verified set (spec Model
Test Matrix, verified rows), show an explicit one-time warning in the
conversation that canvas commands may be unreliable; plain chat remains
available. Verified models suppress the warning. No model download/install
logic - information surface only.

### W5 - TC-004 egress audit (FR-005)

- `docs/egress-audit.md`: complete table of every outbound endpoint the app
  can call (mode, endpoint, data sent, trigger, opt-in?), including the npm
  update check and opt-in search endpoints, with the assertion that in local
  mode no canvas content / prompts / user metadata leave for any non-local
  endpoint.
- `scripts/egress-audit.sh`: scripted capture - run the app in local mode
  against the in-process mock (W1) through a full canvas conversation with
  egress interception (transparent proxy or DNS-level capture of non-local
  attempts); exit nonzero on any content-bearing non-local egress.

### W6 - FR-008 GDPR data-flow document

- `docs/data-flow.md`: per mode (local, device-link, CLI providers): data
  categories, recipients, purposes, retention, legal basis (Art. 13/14).
  Sourced from code paths audited in W5; public-safe (no internal hosts -
  use placeholders like `https://<your-local-server>`).
- In-app reference: link from the privacy/settings surface.

## FR-002 Note (no work)

Legacy `/api/ai/command` phase-vs-token-delta difference is cosmetic on a
legacy endpoint; the live canvas path streams properly. Documented, not
changed (YAGNI).

## Phase Ordering

| Phase | Items | Why this order |
|-------|-------|----------------|
| A | W1 | tests first (TDD); the mock doubles as the W5 test double |
| B | W2, W3 | validation + health are one config surface; closes #12 |
| C | W4 | small, depends on W3 status surface |
| D | W5, W6 | egress evidence + the document that cites it (SC-001, SC-004) |

Each phase: RED -> GREEN -> REFACTOR, atomic commits (<200 LOC),
`npm run check` green per commit.

## Contracts

- **config.env keys** (unchanged): `AI_PROVIDER`, `AI_API_URL`,
  `AI_API_KEY`, `AI_API_MODEL`, `AI_API_FORMAT` - see spec Assumption 2.
- **Canvas command protocol** (unchanged): prompt-embedded JSON commands
  (`write_text`, `draw_formula`, `plot_function`, `draw`, `erase`, HTML),
  client-side execution; markdown-fence tolerance is now a tested contract
  (W1), not an accident.
- **Health states**: `ready | degraded | offline` with machine-readable
  fields (state, selected model, model list, last error).

## Success Criteria Mapping

| SC | Closed by |
|----|-----------|
| SC-001 (egress green) | W5 |
| SC-002 (tests green, coverage) | W1 (plus existing suite) |
| SC-003 (live matrix) | already met (2026-08-31) |
| SC-004 (data-flow doc) | W6 |
