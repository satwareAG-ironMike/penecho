# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.1.x (latest) | Yes |
| < 1.1.0 | No - update to the latest release |

## Reporting a vulnerability

Please do **not** report security vulnerabilities through public GitHub issues.

| Channel | How |
|---------|-----|
| Preferred | GitHub private vulnerability reporting: **Security tab** of this repository -> "Report a vulnerability" |
| Alternative | `security@satware.com` (include the repository name and a reproduction) |

Include: a description of the issue, steps to reproduce, affected versions, and
the impact you believe it has.

## What we do with reports

- Acknowledgement within **7 days**.
- Triage and fix target within **30 days** for critical issues.
- We will not publish or discuss a report until a fix is available.
- Credit is offered to reporters who ask for it.

## Scope

**In scope:** the PenEcho application (server, CLI, canvas client, cloud
connector), its npm dependencies as shipped in this repository, and the
GitHub workflows in this repository.

**Out of scope:** the PenEcho Cloud backend infrastructure (penecho.ai),
third-party AI CLI tools installed on user machines, and issues in upstream
[penecho/penecho](https://github.com/penecho/penecho) that this fork did not
introduce.

## General guidelines

Standard OWASP guidance applies: input validation at trust boundaries, no
secrets in code or configuration, least-privilege process and network access.
