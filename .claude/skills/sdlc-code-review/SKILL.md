---
name: sdlc-code-review
description: Multi-dimensional PR review before merging — correctness, security, test coverage, and database safety. Spawns software-engineer, cybersecurity, test-engineer, and database-internals in parallel. Produces an APPROVE, REQUEST CHANGES, or BLOCK decision with findings ranked by severity.
allowed-tools: Read Bash Write Edit
effort: xhigh
---

# Skill: Code Review

**Entry point for Phase 4 of the SDLC workflow.**

## What This Does

Protects the codebase from regressions, security holes, test gaps, and bad patterns before they reach main. Runs parallel expert reviews and synthesizes them into a single, actionable merge decision with every finding ranked by severity and mapped to a specific file and line.

## Input

Provide one of:
- A branch name: "Review branch feature/parental-controls"
- A PR number: "Review PR #142"
- A diff pasted inline

## What Gets Produced

A review document containing:
- **Decision:** APPROVE / REQUEST CHANGES / BLOCK
- Findings table: Severity | File | Line | Finding | Recommendation
- Positive observations (what was done well)
- Conditions to approve (if not approved)

## Orchestration

```
code-review-orchestrator
    ├── software-engineer    (parallel) ← correctness, patterns, performance
    ├── cybersecurity        (parallel) ← security implications of every change
    ├── test-engineer        (parallel) ← coverage, quality, missing edge cases
    └── database-internals   (parallel) ← migrations, queries, schema (if DB changes)
```

## Decision Rules

| Finding severity | Decision |
|---|---|
| BLOCK or CRITICAL | BLOCK — fix before review continues |
| MAJOR | REQUEST CHANGES — must address before merge |
| MINOR / NIT | APPROVE — safe to merge, fix optional |

## Next Phase

APPROVE → merge to main
REQUEST CHANGES / BLOCK → back to `/sdlc-feature-dev` with findings attached

## Rules

- Every finding has a file, a line, and a concrete recommendation — no vague suggestions.
- Never approve a BLOCK or CRITICAL finding. Never block on NIT preferences.
- If the code is genuinely clean, APPROVE — "no findings" is the right outcome.
