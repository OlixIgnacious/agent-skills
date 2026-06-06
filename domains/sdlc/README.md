# Domain: SDLC Workbench

A drop-in workflow template for any codebase. Copy the config files into a repository and get a structured software development lifecycle powered by 17 specialized agents.

## Files

| File | Tool | Purpose |
|------|------|---------|
| `CLAUDE.md` | Claude Code | Full agent roster, skills, invocation examples |
| `AGENTS.md` | Universal | Cross-tool rules — read by Antigravity, Cursor, and Claude Code |
| `GEMINI.md` | Antigravity (agy) | Antigravity-specific overrides: parallel agents, Mission Control, CLI usage |
| `copilot-instructions.md` | GitHub Copilot | Inline suggestion rules — place at `.github/copilot-instructions.md` |

## Setup Per Tool

**Claude Code:**
```bash
cp CLAUDE.md your-repo/CLAUDE.md
cp AGENTS.md your-repo/AGENTS.md
```

**Antigravity:**
```bash
cp AGENTS.md your-repo/AGENTS.md
cp GEMINI.md your-repo/GEMINI.md
```

**GitHub Copilot:**
```bash
mkdir -p your-repo/.github
cp copilot-instructions.md your-repo/.github/copilot-instructions.md
```

**All tools:**
```bash
cp AGENTS.md your-repo/AGENTS.md          # universal — all tools read this
cp CLAUDE.md your-repo/CLAUDE.md          # Claude Code
cp GEMINI.md your-repo/GEMINI.md          # Antigravity
mkdir -p your-repo/.github
cp copilot-instructions.md your-repo/.github/copilot-instructions.md
```

Then customize the **Codebase Context** section in each file for your stack.

## Workflow

```
Stakeholder ask
    ↓ biz-to-tech
Validated TRD
    ↓ architectural-review
Approved design
    ↓ feature-dev
Implemented + tested
    ↓ code-review
Merged code
```

## Agents (17)

- 4 orchestrators (one per phase)
- 5 specialists (requirements, codebase, API, testing, docs)
- 8 domain experts (engineering, database, devops, security, linux, system design, algorithms, ML)
