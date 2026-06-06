---
name: sdlc-architectural-review
description: Stress-test a TRD or design document before any code is written. Spawns system-design, cybersecurity, database-internals, and devops-sre in parallel for a multi-dimensional review. Produces an APPROVED or REVISION REQUIRED verdict with specific findings.
allowed-tools: Read Bash Write Edit
effort: xhigh
---

# Skill: Architectural Review

**Entry point for Phase 2 of the SDLC workflow.**

## What This Does

Catches design problems before they become code problems. Runs parallel expert reviews across scalability, security, data integrity, and operational readiness. Every finding is specific: what the risk is, where in the design it lives, and what the fix is.

## Input

Provide one of:
- A TRD from `/sdlc-biz-to-tech`
- A design document or architecture proposal
- A link to a `docs/trd/` file in the repo

## What Gets Produced

```
docs/reviews/REVIEW-[TRD-number]-[date].md
```

Containing:
- **Verdict:** APPROVED or REVISION REQUIRED
- Findings table by severity (Critical / Major / Minor)
- Alternatives considered
- Conditions for approval (if revision required)

## Orchestration

```
architectural-review-orchestrator
    ├── system-design        (parallel) ← scalability, coupling, failure modes
    ├── cybersecurity        (parallel) ← threat model, auth/authz, attack surface
    ├── database-internals   (parallel) ← schema, migration safety, transactions
    └── devops-sre           (parallel) ← deployment, rollback, observability
```

## Next Phase

APPROVED → `/sdlc-feature-dev`
REVISION REQUIRED → back to `/sdlc-biz-to-tech` with findings attached

## Rules

- REVISION REQUIRED if any Critical finding exists. No exceptions.
- Security findings are never waived, even if Minor.
- If the design is genuinely good, the verdict is APPROVED — "no findings" is a valid outcome.
