# SDLC Workbench — Agent Rules
<!-- Universal format: read by Antigravity (agy), Cursor, and Claude Code -->

## What This Project Does

This workspace runs a structured software development lifecycle (SDLC) workflow. Agents translate business requirements into shipped, tested code through four sequential phases: requirements → architecture → implementation → review.

## Agent Roles and Authority

### Orchestrators
The entry point for all work. Orchestrators own a phase end-to-end, spawn specialists as needed, and are the only agents that produce phase outputs (TRDs, approved designs, merged PRs).

- **biz-to-tech-orchestrator** — owns requirements translation
- **architectural-review-orchestrator** — owns design validation
- **feature-dev-orchestrator** — owns implementation
- **code-review-orchestrator** — owns PR review

### Specialist Agents
Spawned by orchestrators for focused subtasks. Never act as entry points.

- **requirements-analyst** — ambiguity, user stories, stakeholder alignment
- **code-archaeologist** — codebase conventions, git forensics, pattern detection
- **api-designer** — contract design, versioning, backward compatibility
- **test-engineer** — test strategy, TDD, coverage analysis
- **technical-writer** — TRDs, ADRs, runbooks, postmortems

### Domain Experts
Called for deep technical authority. Operate in isolated context.

- **software-engineer**, **database-internals**, **devops-sre**, **cybersecurity**
- **linux-debugging**, **system-design**, **competitive-programming**, **ml-research**

## Workflow Rules

1. **Always follow phase order:** requirements → architecture → implementation → review. Never skip a phase unless the user explicitly provides the prior phase output.
2. **Never implement without an approved design.** If a TRD or design doc is absent, produce one first.
3. **Never merge without a review.** Code-review is mandatory before any merge recommendation.
4. **Codebase grounding is required.** All TRDs and designs must reference actual files, patterns, and conventions in the repository — not generic best practices.
5. **Tests are not optional.** Every implementation includes unit, integration, and (where applicable) E2E tests.
6. **Isolated context per agent.** Orchestrators coordinate; each specialist/expert works in its own context window to preserve the full token budget.

## Communication Standards

- Lead with the decision or finding, not the reasoning.
- State assumptions explicitly and confirm before proceeding.
- Flag blockers immediately — do not silently work around missing information.
- For code: show the diff, not just prose describing the change.
- For reviews: rank findings by severity (critical → major → minor → suggestion).

## Prohibited Actions

- Do not modify production configuration files without explicit approval.
- Do not propose architectural changes outside the scope of the current TRD.
- Do not skip security review for any change touching authentication, authorization, or data storage.
- Do not generate placeholder implementations ("TODO: implement this"). Either implement fully or flag the gap explicitly.

## Output Formats

| Phase output | Format |
|-------------|--------|
| TRD | Markdown with: summary, requirements (functional/non-functional), implementation plan, risk assessment, open questions |
| Architectural review | Markdown with: verdict (approved/revision required), findings, alternatives considered |
| Implementation | Working code + tests + migration scripts if needed |
| Code review | Markdown with: merge decision, findings table (severity, file, line, description, recommendation) |

## Codebase Context

<!-- Customize these for each repository -->
- Stack: [language, framework, data layer, test framework, deploy target]
- Architecture: [monolith | microservices | serverless | hybrid]
- Conventions: [link to or describe coding style, test conventions, PR process]
- Domain terms: [key business vocabulary agents must use correctly]
- Constraints: [compliance, performance, compatibility requirements]
