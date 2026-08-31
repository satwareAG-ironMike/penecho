# Tasks: Local AI Stack + GDPR Compatibility

**Plan**: [plan.md](plan.md) | **Branch**: `feat/002-local-ai-gdpr-compat`

## Phase A - Contract tests (W1, TC-002)

- [ ] A1: In-process OpenAI mock server fixture (`test/`, Node `http`, no
  deps): `/v1/chat/completions` (stream + non-stream), `/v1/models`
- [ ] A2: RED+GREEN streaming round trip test (SSE chunks -> assembled
  content)
- [ ] A3: RED+GREEN canvas JSON command round trip: bare JSON output and
  markdown-fenced JSON output (json code fence) both parse and execute
- [ ] A4: RED+GREEN `reasoning_content` handling (separate field, empty
  `content` at tiny budget is not an error)
- [ ] A5: `npm run check` green; no external network in the new tests

## Phase B - Validation + health (W2+W3, FR-006/007, issue #12)

- [ ] B1: `doctor --api` - configured-model existence check vs
  `GET {base}/models`; precise error lists available models
- [ ] B2: wizard - probe resolved endpoint on save (openai: `GET {base}/models`);
  warn on bare-host base URL (missing version path)
- [ ] B3: health states `ready | degraded | offline` + selected model +
  model list in doctor output (machine-readable fields)
- [ ] B4: provider status surface in the app UI (on open + manual refresh,
  no polling)
- [ ] B5: tests for B1-B4 (mock-backed)
- [ ] B6: close issue #12 with the probe commit

## Phase C - Capability warning (W4, FR-003)

- [ ] C1: capability-verified model set (spec Model Test Matrix verified
  rows); warning surface in conversation for unverified models
- [ ] C2: plain chat remains available under the warning; tests

## Phase D - Egress + transparency (W5+W6, FR-005/008, SC-001/SC-004)

- [ ] D1: `docs/egress-audit.md` - full outbound endpoint table (all modes,
  including npm update check + opt-in search), public-safe
- [ ] D2: `scripts/egress-audit.sh` - local-mode conversation through mock
  with egress interception; nonzero exit on content-bearing non-local egress
- [ ] D3: `docs/data-flow.md` - per-mode GDPR table (categories, recipients,
  purposes, retention, Art. 13/14), public-safe
- [ ] D4: in-app reference to `docs/data-flow.md` (privacy/settings surface)
- [ ] D5: final `npm run check` + full smoke matrix re-run + egress audit
  green (SC-001 + SC-002 + SC-004 evidence)

## Verification gates (per phase)

- `npm run check` green on every commit
- coverage >= 80% on touched modules (TC-001)
- public-safe review of D1/D3 before commit (no internal hosts)
