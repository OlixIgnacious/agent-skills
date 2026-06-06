# SDLC Workbench — Antigravity Configuration
<!-- Antigravity (agy) reads this file. Rules here override AGENTS.md for Antigravity sessions. -->
<!-- For shared rules across all tools, edit AGENTS.md instead. -->

## Model and Effort

All agents: Gemini 3.5 Flash at maximum effort. Use Gemini 3.5 Pro for architectural-review and code-review orchestrators where deeper reasoning is critical.

## Subagent Orchestration

Antigravity supports parallel subagent execution. Use it:

- **biz-to-tech**: spawn `requirements-analyst` and `code-archaeologist` in parallel — requirements disambiguation and codebase grounding can proceed simultaneously.
- **architectural-review**: spawn `system-design` and `cybersecurity` in parallel — scalability and security reviews are independent.
- **feature-dev**: spawn `test-engineer` alongside implementation — tests can be drafted from the TRD while code is being written.
- **code-review**: spawn `cybersecurity` and `database-internals` in parallel for changes touching auth or schema.

## Agy CLI Invocation

```bash
# Full pipeline
agy "Take this requirement to a merged PR: [requirement]"

# Individual phases
agy --agent biz-to-tech-orchestrator "PRD: [paste PRD]"
agy --agent architectural-review-orchestrator "Review: [link or paste TRD]"
agy --agent feature-dev-orchestrator "Implement TRD-042"
agy --agent code-review-orchestrator "Review branch feature/parental-controls"
```

## Mission Control Setup

In Antigravity Mission Control, configure these agents as named tasks:

| Task name | Agent | Trigger |
|-----------|-------|---------|
| `requirements` | biz-to-tech-orchestrator | New feature request or PRD |
| `design-review` | architectural-review-orchestrator | TRD complete |
| `implement` | feature-dev-orchestrator | Design approved |
| `review` | code-review-orchestrator | PR opened |

## Background Task Scheduling

Use Antigravity's background scheduling for:
- Nightly code-review sweeps on open PRs
- Weekly architectural-review of any new TRDs merged to `docs/`
- Automated biz-to-tech translation of Jira/Linear tickets tagged `needs-trd`

## Codebase Context

<!-- Antigravity-specific overrides — for shared context, edit AGENTS.md -->
- Workspace root indexing: enabled
- Auto-read: `AGENTS.md`, `docs/architecture/`, `docs/trd/`
- Ignore: `node_modules/`, `dist/`, `*.lock`, `coverage/`
