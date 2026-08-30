# Feature Specification: Local AI Stack + GDPR Compatibility

**Feature Branch**: `feat/002-local-ai-gdpr-compat`
**Created**: 2026-08-30
**Status**: Draft (pending CLARIFY)
**Rigor Level**: Spec-Anchored
**Milestone**: `local-ai-gdpr-compat`

## Context

Today the canvas-agent runtime is served exclusively by AI CLI providers
(Claude Code, Codex CLI, Kimi). These providers send prompt and canvas content
to their respective vendor cloud APIs by design. In device-link mode, canvas
content additionally transits the penecho.ai relay.

For GDPR-relevant data (EU business documents, client names, internal
diagrams) neither path is acceptable: the user must be able to run PenEcho
fully on their own infrastructure (local or EU-hosted LLM server) so that
canvas content and all model I/O stay inside a trusted boundary.

The target test environment is an OpenAI-compatible inference server
(Lemonade) exposed at `https://api.satware.ai` with Bearer API key auth.

**Existing coverage (verified in code, 2026-08-30)**: the fork already ships
a first-class `api` provider (`AI_PROVIDER=api`) speaking the OpenAI and
Anthropic HTTP APIs, with known-provider presets, per-connection configs,
`penecho configure` (interactive) and `penecho doctor --api` (validation),
and key/config storage in `~/.penecho/config.env` (mode 0600; process
environment overrides file values, CLI flags override both). The
canvas-agent loop is a prompt-embedded JSON command protocol (`write_text`,
`draw_formula`, `plot_function`, `draw`, `erase`, HTML) executed client-side,
not native `tools[]` function calling. This feature is therefore a
compatibility verification + gap-closure + GDPR effort, not a from-scratch
provider build.

## User Scenarios & BDD Scenarios

### User Story 1 - Run the canvas agent on a local LLM endpoint (Priority: P1)
**Why this priority**: This is the core GDPR unlock - without a local
provider the feature does not exist.

**Acceptance Scenarios (Gherkin)**:
- **Given** a running OpenAI-compatible server (e.g. `https://api.satware.ai`)
  **When** the user configures base URL, API key, and model in PenEcho
  **Then** the canvas agent serves conversations from that endpoint
- **Given** a configured local endpoint
  **When** the user sends a prompt
  **Then** the response streams into the conversation UI incrementally
- **Given** two providers are configured (local + a CLI provider)
  **When** the user opens a conversation
  **Then** they can select which provider serves it without reinstalling or
  reconfiguring

### User Story 2 - Verifiable data isolation in local mode (Priority: P1)
**Why this priority**: GDPR compliance is only meaningful if it is
demonstrable, not just claimed.

**Acceptance Scenarios (Gherkin)**:
- **Given** PenEcho running in local mode with a local provider
  **When** a full canvas-agent conversation (prompt + tools + canvas edits)
    is executed
  **Then** no outbound network traffic carries canvas content, prompts, or
    user metadata to any non-local endpoint
- **Given** a user asks where their data goes
  **When** they open the privacy documentation
  **Then** they find a per-mode data flow table (mode, data categories,
    recipients, purpose, retention)

### User Story 3 - Tool calling through the local endpoint (Priority: P2)
**Why this priority**: The canvas agent's usefulness depends on its tool loop
(canvas reads/writes, widget generation), not just chat.

**Acceptance Scenarios (Gherkin)**:
- **Given** a model capable of the JSON command schema is selected
  **When** the user asks for a canvas edit (text, formula, drawing)
  **Then** the model returns structured commands, they execute on the canvas,
    and the conversation continues
- **Given** a model that cannot reliably produce the command schema is
  selected
  **When** the user starts a conversation
  **Then** they get an explicit capability warning and plain chat still works

### User Story 4 - Configuration validation and health (Priority: P2)
**Why this priority**: Local endpoints have many failure modes (server down,
model not downloaded, wrong key); silent failures destroy trust.

**Acceptance Scenarios (Gherkin)**:
- **Given** the user saves an unreachable base URL or a rejected API key
  **When** the configuration is saved
  **Then** validation reports the exact failure with an actionable hint
- **Given** a configured endpoint
  **When** the user opens the provider status
  **Then** they see ready / degraded / offline plus the selected model and,
    when the server lists models, the available model set
- **Given** a saved configuration
  **When** the provider status is shown
  **Then** the API key is never displayed or logged in full

## Requirements

### Functional Requirements

- **FR-001**: System MUST serve the full canvas-agent loop through the
  OpenAI-compatible path of the `api` provider against a user-configured
  endpoint (base URL, API key, model). Existing coverage MUST be diffed
  FR-by-FR in the plan phase; gaps are closed there.
- **FR-002**: System MUST stream (SSE) model responses into the
  canvas-agent conversation UI with parity to existing CLI providers.
- **FR-003**: The canvas-agent command protocol (structured JSON commands in
  model output, executed client-side) MUST work reliably with local endpoint
  models. When the selected model cannot reliably produce the command schema,
  System MUST surface a capability warning. Native OpenAI `tools[]` calling
  is OPTIONAL and out of scope for the canvas loop.
- **FR-004**: System MUST operate against plain-HTTP local and LAN
  endpoints (no TLS requirement for 127.0.0.1 / RFC 1918 addresses) and
  against HTTPS public endpoints.
- **FR-005**: In local mode with a local provider, System MUST NOT transmit
  canvas content, prompts, or user metadata to any endpoint other than the
  configured local endpoint. This MUST be verifiable by a documented egress
  audit.
- **FR-006**: System MUST validate provider configuration
  (reachability, auth, model existence) with precise, actionable errors.
  Existing `penecho doctor --api` covers reachability/auth; the delta MUST
  include a configured-model existence check against `GET /v1/models`.
- **FR-007**: System MUST expose provider health state (ready / degraded /
  offline, selected model, model list when available).
- **FR-008**: System MUST ship a GDPR transparency data-flow document
  (per mode: local, device-link, CLI providers) covering data categories,
  recipients, purposes, and retention, published in the repository and
  referenced from the app.
- **FR-009**: System MUST allow per-conversation provider selection without
  reinstalling or reconfiguring.
- **FR-010**: The provider API key MUST be stored only on-device in the
  existing secret storage (`~/.penecho/config.env`, mode 0600; process env
  overrides) and MUST NOT appear in logs, error messages, or the UI in full.

### Constraints & TDD Targets

- **TC-001**: Coverage target >= 80% for the new provider module.
- **TC-002**: Contract tests run against a local in-process OpenAI mock
  server (streaming round trip, canvas JSON command round trip including
  markdown-fence tolerance, `reasoning_content` handling) with no external
  network access.
- **TC-003**: Live smoke matrix against the public Lemonade endpoint with the
  starting model set (below); results recorded in the issue, not the repo.
- **TC-004**: Egress audit for FR-005: scripted network capture during a full
  local-mode conversation asserting zero non-local egress of content.

## Key Entities & Data Model

- **ProviderConfig**: type (`cli` | `api`, both existing - no new provider
  type in current scope), base URL, API key reference (on-device secret),
  default model, fetched model list (cached), enabled flag.
- **Conversation routing**: each conversation references an active provider
  (FR-009); fallback behavior when the provider is offline is unspecified
  here (CLARIFY item).
- **DataFlowDocument**: mode, data categories, recipients, purposes,
  retention, legal basis (GDPR Art. 13/14 transparency).

## Model Test Matrix (live-verified 2026-08-30)

Grounded in the live catalog of the test-fleet OpenAI-compatible server
(same server family as `api.satware.ai`). Live matrix = flagship row only
(narrowed 2026-08-30, see notes); other rows are deferred candidates:

| Tier | Model | Labels | Rationale |
|------|-------|--------|-----------|
| Primary | Qwen3.6-35B-A3B-MTP-GGUF | chat, tool-calling, vision, MoE | Flagship local coding model; highest capability in class |
| Primary | Qwen3.6-27B-MTP-GGUF | chat, tool-calling, vision, dense | Dense alternative, MTP decode |
| Secondary | Gemma-4-31B-it-GGUF | chat, tool-calling, vision | Cross-vendor (Google) tool-calling check |
| Fast | qwen3.5-9b-FLM | chat, tool-calling, reasoning, vision | Low-VRAM fast iteration path |
| Edge | Qwen-AgentWorld-35B-A3B-GGUF-Q8_0 | chat, tool-calling | Agent-oriented fine-tune, upper VRAM bound |

Notes:

- The public endpoint `api.satware.ai` requires its own Bearer key (the LAN
  key is rejected); the key was provided and verified on 2026-08-30 (never
  stored in repo or issues).
- **Live state + decision (2026-08-30)**: only
  `Qwen3.6-35B-A3B-MTP-GGUF` (chat, 256k ctx) is downloaded on the public
  instance (plus embedding/reranker/transcription). The instance is at
  memory capacity, so **the live matrix is narrowed to the flagship**
  (decision: mw, 2026-08-30); the remaining models stay as deferred
  candidates for a later, larger instance.
- Capability gates: any matrix model MUST reliably produce the canvas JSON
  command schema (FR-003); streaming is expected for all (SSE on
  `/v1/chat/completions` with `stream: true`).

**Live verification findings (2026-08-30, Qwen3.6-35B-A3B-MTP-GGUF):**

| Check | Result |
|-------|--------|
| Chat round trip | PASS (~2.5s, 138 completion tokens) |
| Thinking mode | ON by default - responses carry a separate `reasoning_content` field; `max_tokens` budgets MUST account for reasoning, empty `content` at tiny budgets is expected, not an error |
| Canvas JSON command | PASS - valid `write_text` schema, but wrapped in a markdown ```json fence despite an explicit "no markdown" instruction; client-side fence tolerance MUST be verified and covered by a contract test (TC-002) |

## Assumptions & Handoffs

- **Assumption 1**: The OpenAI Chat Completions surface (messages, tools,
  tool results, SSE streaming, `GET /v1/models`) is sufficient for the
  canvas-agent loop; the Anthropic-compatible surface is NOT required.
- **Assumption 2**: Key/config storage is the existing `config.env`
  mechanism (the project has no dotenv dependency); precedence is CLI flags
  > process env > `config.env` > defaults.
- **Assumption 3**: The plan phase MUST diff the existing `api` provider
  coverage FR-by-FR and keep only the delta in plan/tasks (contracts in
  `contracts/`: `config.env` keys, canvas command protocol for local models).
- **Next Step**: `/spec.clarify` (open items below), then `/spec.plan`.

## Open Clarification Items

1. Offline conversation fallback: when the active provider is offline,
   should the conversation error out (recommended) or fall back to another
   provider? (Recommended: explicit error, no silent fallback - GDPR
   predictability.)
2. Key storage format: reuse the existing on-device secret file pattern
   (recommended) vs. new env-var-only support.
3. Model list refresh: fetch `/v1/models` on save + manual refresh
   (recommended) vs. periodic polling.
4. Scope guard: does "full local AI stack" include non-chat modalities
   (TTS/STT/image) in this spec? (Recommended: NO - chat + tool calling only;
   separate spec if wanted.)

## Success Criteria

- **SC-001**: A user completes a full canvas-agent conversation (prompt,
  tool calls, canvas edits) against a local endpoint with zero non-local
  content egress (egress audit green).
- **SC-002**: `npm test` green including new provider contract tests;
  coverage >= 80% on the new module (TC-001, TC-002).
- **SC-003**: Live matrix (TC-003): the flagship model
  (`Qwen3.6-35B-A3B-MTP-GGUF`, sole provisioned chat model - matrix narrowed
  2026-08-30 due to instance memory capacity) passes the full smoke test
  (conversation + streaming + canvas JSON command round trip + degraded
  paths) against `api.satware.ai`.
- **SC-004**: Data-flow document (FR-008) reviewed and published; in-app
  reference present.
