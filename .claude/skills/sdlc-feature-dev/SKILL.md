---
name: sdlc-feature-dev
description: Implement an approved TRD — architecture, code, and full test coverage. Requires an approved TRD as input. Spawns api-designer, test-engineer, software-engineer, devops-sre, and technical-writer in sequence. Never starts coding without an approved design.
allowed-tools: Read Bash Write Edit
effort: xhigh
---

# Skill: Feature Development

**Entry point for Phase 3 of the SDLC workflow.**

## What This Does

Takes an approved TRD and produces working, tested, documented code ready for review. Tests are written first (TDD). Implementation follows the patterns found by `code-archaeologist` in the TRD phase. No placeholders, no TODOs, no untested paths.

## Input

Provide one of:
- An approved TRD (from `docs/trd/`)
- An approved architectural review + TRD pair
- A TRD number: "Implement TRD-042"

## What Gets Produced

- Implemented feature code on a feature branch
- Unit tests (one behavior per test, 80% coverage minimum)
- Integration tests (real dependencies, no mocks at this layer)
- E2E tests for the happy path and critical error path
- API contract spec (if endpoints are added or modified)
- Deployment plan and runbook (if infrastructure is affected)
- Updated docs: API docs, ADRs, runbooks

## Orchestration

```
feature-dev-orchestrator
    ├── api-designer       ← contract spec (if API changes in TRD)
    ├── test-engineer      ← failing tests from TRD acceptance criteria
    ├── software-engineer  ← implements against failing tests
    ├── devops-sre         ← deployment plan (if infra changes in TRD)
    └── technical-writer   ← docs, ADRs, runbooks
```

## Next Phase

Implemented + passing tests → `/sdlc-code-review`

## Rules

- No implementation without a TRD that passed architectural review. If absent, request one.
- Tests first. Implementation against failing tests only.
- If a gap is found in the TRD during implementation: stop, document it, return to `/sdlc-architectural-review`.
- No `// TODO` in shipped code.
