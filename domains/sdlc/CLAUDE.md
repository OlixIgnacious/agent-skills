# SDLC Workbench

A drop-in project template that turns any codebase into a structured software development lifecycle workflow. Copy `.claude/` into any repository and immediately get:

- Business requirements → Technical requirements (codebase-grounded)
- Architectural review of technical plans
- Feature implementation with full test coverage
- Multi-dimensional code review

> **Cross-tool:** Also see `AGENTS.md` (universal — works with Antigravity and Cursor too) and `.github/copilot-instructions.md` (GitHub Copilot).

---

## Agents (17 total)

### Orchestrators — start here

| Agent | Trigger |
|-------|---------|
| `biz-to-tech-orchestrator` | PRD, stakeholder ask, compliance requirement, vague business goal |
| `architectural-review-orchestrator` | TRD/design doc needing stress-test before build |
| `feature-dev-orchestrator` | Approved TRD ready to implement |
| `code-review-orchestrator` | PR ready for multi-dimensional review |

### Specialist Agents — spawned by orchestrators

| Agent | Domain |
|-------|--------|
| `requirements-analyst` | Ambiguity resolution, user stories, stakeholder translation |
| `code-archaeologist` | Codebase forensics, git history analysis, convention detection |
| `api-designer` | REST/GraphQL/gRPC contract design, versioning, error handling |
| `test-engineer` | Unit/integration/E2E design, TDD, property-based testing |
| `technical-writer` | TRDs, ADRs, API docs, runbooks, postmortems |

### Domain Experts — deep technical authority

| Agent | Expertise |
|-------|-----------|
| `software-engineer` | Architecture, code review, implementation |
| `database-internals` | Schema, queries, transactions, storage engines |
| `devops-sre` | Deployment, monitoring, reliability, incident response |
| `cybersecurity` | Threat modeling, vulnerability assessment, compliance |
| `linux-debugging` | Performance profiling, system-level debugging |
| `system-design` | System architecture, scalability, architecture evaluation |
| `competitive-programming` | Algorithms, complexity analysis, optimization |
| `ml-research` | ML system design, training pipelines, model evaluation, research-to-production |

---

## Skills (4 workflows)

### `biz-to-tech`
Translates business requirements into a Technical Requirements Document (TRD) grounded in the actual codebase.

**Trigger:** "We need parental controls", "compliance requires X", "stakeholders want Y"
**Output:** Validated TRD with implementation path, risk assessment, open questions

### `architectural-review`
Stress-tests a design before anyone writes code. Catches scalability, security, and coupling issues early.

**Trigger:** "Review this design", "will this scale", "is this the right approach"
**Output:** Approved design or revision requests with specific concerns and alternatives

### `feature-dev`
Implements from an approved TRD — architecture, code, and full test coverage.

**Trigger:** "Implement TRD-042", "build this feature", "code up the design"
**Output:** Working implementation with unit, integration, and E2E tests

### `code-review`
Multi-dimensional PR review: correctness, security, performance, maintainability, test quality.

**Trigger:** "Review this PR", "is this ready to merge"
**Output:** Merge decision with specific findings ranked by severity

---

## Canonical Workflow

```
Stakeholder ask
    ↓
biz-to-tech      → validated TRD
    ↓
architectural-review  → approved design  (loops until approved)
    ↓
feature-dev      → implemented feature with tests
    ↓
code-review      → merge decision
    ↓
Merged code
```

Each skill also works standalone for the subset of the workflow you need.

---

## Invocation Examples

```
# Full pipeline from a single requirement
> Take this requirement all the way to a merged PR: [paste requirement]

# Start from a business ask
> We need to add parental controls so parents can restrict what their kids see.
> Use biz-to-tech to produce a TRD.

# Review a design
> Here's the TRD: [link]. Use architectural-review to stress-test it.

# Implement from approved TRD
> Implement TRD-042 using feature-dev. Ensure full test coverage.

# Review a PR
> Review the diff on branch feature/parental-controls with code-review.
```

---

## Configuration

**Model:** `claude-opus-4-8` at `effort: xhigh`
Each orchestrator and domain expert runs in an isolated context window (no cross-persona interference, full 1M token budget per agent).

### PRISM Intent Modes

Agents select mode automatically based on task type:

| Mode | When | Behaviour |
|------|------|-----------|
| **A — Knowledge** | Code, math, debugging | Suppress personality, pure precision |
| **B — Coaching** | Stakeholder comms, teaching | Full persona voice |
| **C — Hybrid** | Design reviews, architecture workshops | Persona voice + Mode A precision |

---

## Codebase Context (customize per repo)

### Stack
- Language: [fill in]
- Framework: [fill in]
- Data layer: [fill in]
- Test framework: [fill in]
- Deploy: [fill in]

### Architecture Pattern
[Monolith | Microservices | Serverless | Hybrid]

### Conventions
- Code style: [fill in]
- Test conventions: [fill in]
- PR conventions: [fill in]
- Migration conventions: [fill in]

### Business Context
- Domain terms: [fill in]
- Compliance requirements: [fill in]
- Performance constraints: [fill in]
- Constraints affecting every feature: [fill in]
