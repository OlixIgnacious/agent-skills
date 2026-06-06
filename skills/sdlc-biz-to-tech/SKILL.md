---
name: sdlc-biz-to-tech
description: Translate a business requirement, PRD, stakeholder ask, or vague goal into a grounded Technical Requirements Document (TRD). Delegates to biz-to-tech-orchestrator, which spawns requirements-analyst and code-archaeologist in parallel before drafting the TRD.
allowed-tools: Read Bash Write Edit
effort: xhigh
---

# Skill: Business → Technical Requirements

**Entry point for Phase 1 of the SDLC workflow.**

## What This Does

Takes any business input — a PRD, a stakeholder ask, a compliance mandate, a vague feature idea — and produces a Technical Requirements Document (TRD) that is grounded in the actual codebase and ready for architectural review.

## Input

Paste or describe any of:
- A product requirements document (PRD)
- A stakeholder request ("we need parental controls")
- A compliance mandate ("GDPR requires we add data deletion")
- A bug report that has grown into a feature request
- A vague goal ("make the checkout flow faster")

## What Gets Produced

```
docs/trd/TRD-[number]-[feature-slug].md
```

Containing:
- Business requirements (non-technical)
- Functional and non-functional requirements
- Implementation plan with actual files from the codebase
- Risk assessment
- Open questions with owners

## Orchestration

```
biz-to-tech-orchestrator
    ├── requirements-analyst    (parallel) ← resolves ambiguity, extracts user stories
    ├── code-archaeologist      (parallel) ← maps existing codebase, finds integration points
    └── technical-writer                  ← formats the final TRD
```

## Next Phase

After TRD is approved by stakeholders → `/sdlc-architectural-review`

## Rules

- Every TRD requirement references real files found in the codebase — not generic best practices.
- Ambiguities are surfaced and owned before implementation begins.
- Out-of-scope items are listed explicitly so they don't creep in later.
