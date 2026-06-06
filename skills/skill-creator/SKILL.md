---
name: skill-creator
description: Creates new skills and agents for any tool in this library — Claude Code (SKILL.md + agents), Google Antigravity (AGENTS.md + GEMINI.md), and GitHub Copilot (.github/copilot-instructions.md). Gathers requirements, inspects existing examples, writes correctly structured files, places them in the right directories, and updates the README.
allowed-tools: Read Bash Write Edit
effort: high
---

# Skill: Skill Creator

A meta-skill that builds new skills and agents for the agent-skills library across all supported tools.

## Supported Tools

| Tool | File format | Invocation |
|------|-------------|------------|
| **Claude Code** | `SKILL.md` (slash commands) + `agents/<domain>/<name>.md` | `/skill-name` or auto-delegated |
| **Google Antigravity** | `AGENTS.md` (universal rules) + `GEMINI.md` (agy-specific) | `agy --agent <name> "..."` |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Inline suggestion context |
| **All tools** | `AGENTS.md` | Universal — read by Antigravity, Cursor, and Claude Code |

---

## Step 0 — Gather Requirements

Before writing anything, establish:

1. **Target tool(s):** Claude Code only? Antigravity? Copilot? All tools?
2. **Type:** Skill (slash command) / Agent (auto-delegated) / Universal rule / Copilot instruction block?
3. **Domain:** `kaggle`, `sdlc`, `finance`, or a new domain?
4. **Name:** kebab-case, domain-prefixed for skills (`kaggle-*`, `sdlc-*`)
5. **Purpose:** What problem does it solve? One sentence.
6. **Tools needed:** `Read`, `Bash`, `Write`, `Edit` — include only what is actually used
7. **Effort level:** `low` | `medium` | `high` | `xhigh`

If any are unclear, ask before proceeding.

---

## Step 1 — Study Existing Examples

Read the closest existing example before writing anything new:

```bash
# Claude Code skill — procedural (disable-model-invocation: true)
cat .claude/skills/kaggle-validation/SKILL.md

# Claude Code skill — orchestrator/persona (no disable-model-invocation)
cat .claude/skills/sdlc-biz-to-tech/SKILL.md

# Claude Code agent — orchestrator
cat agents/sdlc/biz-to-tech-orchestrator.md

# Claude Code agent — domain expert
cat agents/sdlc/software-engineer.md

# Antigravity config
cat domains/sdlc/GEMINI.md

# Universal cross-tool rules
cat domains/sdlc/AGENTS.md

# GitHub Copilot instructions
cat domains/sdlc/copilot-instructions.md
```

---

## Step 2 — Write the Output

### A. Claude Code Skill (SKILL.md)

**Frontmatter:**
```yaml
---
name: <domain>-<name>
description: <one clear sentence — shown in /skills list>
disable-model-invocation: true   # ONLY for procedural/code-template skills
                                 # OMIT for persona, orchestrator, agentic skills
allowed-tools: Read Bash Write Edit
effort: high
---
```

**`disable-model-invocation: true` when:**
- Skill is a library of code templates, checklists, step-by-step procedures the user runs directly
- Examples: `kaggle-validation`, `kaggle-baselines`, `kaggle-hill-climbing`

**Omit `disable-model-invocation` when:**
- Skill activates a persona, sets thinking mode, or delegates to agents
- Examples: `kaggle-grandmaster`, `sdlc-biz-to-tech`, `sdlc-code-review`

**Content structure — procedural skill:**
```markdown
# Skill: <Name>
**One-line context — when and why to use this**

## When to Use
## Step 1 — <Action>
[copy-paste ready code blocks]
## Step 2 — <Next action>
## Checklist
- [ ] item
## Output
## Pitfalls
Next skill: `/<next-skill>`
```

**Content structure — persona/orchestrator skill:**
```markdown
# Skill: <Name>
**Entry point for Phase N / Activates <persona> mode**

## What This Does
## Input
## What Gets Produced
## Orchestration
[agent tree]
## Next Phase
## Rules
```

---

### B. Claude Code Agent (agents/<domain>/<name>.md)

**Frontmatter:**
```yaml
---
name: <name>
description: <"Delegate to this agent when..." or "Spawned by <orchestrator>. ...">
model: opus
tools: ["Read", "Bash", "Write", "Edit"]
---
```

**Description convention:**
- Orchestrators: `"Delegate to this agent when [trigger condition]"`
- Specialists spawned by orchestrators: `"Spawned by <orchestrator>. [what it does]"`

**Content structure:**
```markdown
You are a <role> with expertise in <domain>. <One sentence mandate>.

## Mandate / Core Principles
[What success looks like for this agent]

## <Primary analytical framework>
[The main thing this agent does — decision trees, review criteria, etc.]

## <Secondary section>
[Techniques, standards, or specific rules]

## Rules
- Non-negotiable constraints, bullet list
```

---

### C. Google Antigravity — GEMINI.md Addition

When adding a new domain or agent pattern to Antigravity, append to the domain's `GEMINI.md`:

```markdown
## <New Section Name>

[Antigravity-specific behavior for this agent/domain]

### Parallel Subagent Pattern
- **<orchestrator>**: spawn `<agent-a>` and `<agent-b>` in parallel — [reason they're independent]

### Agy CLI Invocation
```bash
agy --agent <agent-name> "<typical prompt>"
agy "<natural language trigger>"
```

### Mission Control Task
| Task name | Agent | Trigger |
|-----------|-------|---------|
| `<task>` | `<agent-name>` | <when to trigger> |
```

---

### D. Universal Cross-Tool Rules — AGENTS.md Addition

When adding a new agent role that all tools should know about, add it to the relevant `AGENTS.md`:

```markdown
### <Agent Role>
- **<agent-name>** — <one-line description of domain and authority>
```

If it's an orchestrator, add it to the orchestrators section and describe what it owns:
```markdown
- **<name>-orchestrator** — owns <phase name>; entry point for [trigger]
```

If it's a specialist or domain expert, add to the correct section.

---

### E. GitHub Copilot — copilot-instructions.md Addition

When adding a new domain or instruction block for Copilot:

```markdown
## <Domain or Topic Name>

- <Rule 1 — specific, actionable, no vague advice>
- <Rule 2>
- <Rule 3>

<!-- Customize per repository -->
- <Stack-specific context>: [fill in]
```

Copilot rules must be:
- **Specific** — "Prefer explicit column lists over SELECT *" not "write good SQL"
- **Actionable** — something Copilot can apply to a suggestion
- **Non-overlapping** — don't repeat what's in the Code Style section

---

## Step 3 — Place Files

### Claude Code skill:
```bash
mkdir -p .claude/skills/<skill-name>/
# Write SKILL.md to .claude/skills/<skill-name>/SKILL.md

# Mirror for plugin users
mkdir -p skills/<skill-name>/
cp .claude/skills/<skill-name>/SKILL.md skills/<skill-name>/SKILL.md
```

### Claude Code agent:
```bash
mkdir -p agents/<domain>/
# Write to agents/<domain>/<name>.md
```

### Antigravity addition:
```bash
# Append to the relevant domain's GEMINI.md
# Edit domains/<domain>/GEMINI.md
```

### Universal rules addition:
```bash
# Edit domains/<domain>/AGENTS.md
```

### Copilot addition:
```bash
# Edit domains/<domain>/copilot-instructions.md
```

### New domain (first skill/agent in that domain):
```bash
mkdir -p agents/<domain>/
mkdir -p domains/<domain>/
# Create domains/<domain>/README.md
# Create domains/<domain>/AGENTS.md
# Create domains/<domain>/CLAUDE.md
# Create domains/<domain>/GEMINI.md        # if Antigravity support wanted
# Create domains/<domain>/copilot-instructions.md  # if Copilot support wanted
```

---

## Step 4 — Update README.md

- **New Claude Code skill** → add row to the correct Skills table
- **New Claude Code agent** → add row to the correct Agents table
- **New domain** → add a full domain section (agents table + skills table + cross-tool files table)
- **Repo structure tree** → add the new file/directory

---

## Step 5 — Verify

```bash
# Skill: both copies exist
ls .claude/skills/<skill-name>/SKILL.md
ls skills/<skill-name>/SKILL.md

# Agent: file exists
ls agents/<domain>/<name>.md

# Frontmatter looks valid
head -10 .claude/skills/<skill-name>/SKILL.md

# README was updated
grep "<name>" README.md
```

---

## Step 6 — Report

**For a Claude Code skill:**
```
Created:  .claude/skills/<name>/SKILL.md
Mirrored: skills/<name>/SKILL.md
Updated:  README.md

Invoke with: /<name>
```

**For a Claude Code agent:**
```
Created: agents/<domain>/<name>.md

Auto-delegated when: <trigger description>
Spawned by: <parent orchestrator, if applicable>
```

**For an Antigravity addition:**
```
Updated: domains/<domain>/GEMINI.md

Invoke with: agy --agent <name> "<prompt>"
```

**For a Copilot addition:**
```
Updated: domains/<domain>/copilot-instructions.md

Users copy this to: .github/copilot-instructions.md
```

---

## Common Mistakes

- **Tabs in YAML frontmatter** — YAML requires spaces. Tabs silently break parsing.
- **`disable-model-invocation: true` on an orchestrator skill** — the model can't act; skill becomes a static doc.
- **Missing the `skills/` mirror** — plugin users won't get the new skill.
- **Agent description not starting with "Delegate to" or "Spawned by"** — breaks discoverability.
- **Listing tools the agent doesn't need** — keep tool lists minimal.
- **Agent with no entry point** — if there's no skill and no orchestrator that spawns it, it will never be invoked. Wire it in or create a matching skill.
- **Antigravity parallel pattern inconsistent with Claude orchestrator** — GEMINI.md and the orchestrator agent must agree on which agents run in parallel.
- **Copilot instruction that's too vague** — "write clean code" does nothing. "Prefer explicit column lists over SELECT *" is actionable.
