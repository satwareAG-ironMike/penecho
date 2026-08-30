# Spec 001: Security Verification Action Items

| Field | Value |
|-------|-------|
| Status | ACTIVE |
| Branch | `security/verification-action-items` |
| Source | independent verification run 2026-08-30 @ `986acce` (issue #1) |
| Working model | ADR 0001 (work in fork, no upstream contact) |

## Context

The 2026-08-30 verification (secrets, SAST, dependency audit, license audit,
container/CI review) found no exploitable issue. Two informational findings
and six maintenance action items were filed as issue #1. Per ADR 0001 they
are implemented in this fork instead of being filed upstream.

## Functional requirements

| ID | Requirement |
|----|-------------|
| FR-001 | `SECURITY.md` with a responsible-disclosure policy (how to report, expected response window) |
| FR-002 | `.github/dependabot.yml` for npm security + ecosystem updates |
| FR-003 | `CHANGELOG.md` back-filled for shipped releases (v0.7.1 .. v1.1.7) |
| FR-004 | `.github/CODEOWNERS` with explicit review ownership |
| FR-005 | Make the dummy pairing fixture unambiguously fake (`PEN-ABCD-2345` -> `PEN-XXXX-0000`) where the pairing-code format accepts it; otherwise add a scanner allowlist entry for the test file |
| FR-006 | semgrep suppression for the verified-safe `child_process` spawn sites (CLI provider launches) |

## Acceptance criteria

- [ ] `npm test` green (Node >= 22)
- [ ] `npm run check` green
- [ ] Secret scan (betterleaks/gitleaks) on the branch: the test fixture no longer matches a generic API-key shape (FR-005)
- [ ] semgrep on the branch: no `detect-child-process` hits on the suppressed sites (FR-006)
- [ ] All fork-specific files survive a simulated upstream sync (throwaway merge test)

## Out of scope

- Upstream communication (ADR 0001)
- Container scan (no Dockerfile) and CI-config lint: skipped in the original run, not passed
- Penetration testing
- Second maintainer / bus factor, legal entity publication (upstream business decisions)
