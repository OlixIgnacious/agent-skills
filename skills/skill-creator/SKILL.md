---
name: skill-creator
description: Creates new skills and agents for this repo. Gathers requirements, inspects existing examples, writes correctly structured SKILL.md or agent .md files, places them in the right directories, and updates the README. Use this whenever you want to add a new capability to the library.
allowed-tools: Read Bash Write Edit
effort: high
---

# Skill: Skill Creator

A meta-skill that builds new skills and agents for the agent-skills library, following the repo's own conventions and structure.

## Step 0 — Gather Requirements

Before writing anything, establish:

1. **Type:** Skill (slash command) or Agent (auto-delegated worker)?
2. **Domain:** Which domain does this belong to? (`kaggle`, `sdlc`, `finance`, or a new domain?)
3. **Name:** What is it called? Use kebab-case, domain-prefixed for skills (`kaggle-*`, `sdlc-*`).
4. **Purpose:** What problem does it solve? One clear sentence.
5. **Invocation model:** For skills — does the user invoke code directly (`disable-model-invocation: true`) or does the model think and act (`disable-model-invocation` omitted)?
6. **Tools needed:** Which tools does it use? (`Read`, `Bash`, `Write`, `Edit`)
7. **Effort level:** `low` | `medium` | `high` | `xhigh`

If any of these are unclear, ask before proceeding.

## Step 1 — Study Existing Examples

Before writing, read relevant examples from the repo:

```bash
# For a new skill — read two existing skills as reference
# Procedural/code skill:
cat .claude/skills/kaggle-validation/SKILL.md

# Persona/orchestrator skill:
cat .claude/skills/sdlc-biz-to-tech/SKILL.md

# For a new agent — read two existing agents as reference
# Orchestrator agent:
cat agents/sdlc/biz-to-tech-orchestrator.md

# Domain expert agent:
cat agents/sdlc/software-engineer.md
```

Match the voice, structure depth, and content style of whichever example is closest to the new capability.

## Step 2 — Write the Skill or Agent

### Skill Frontmatter (SKILL.md)

```yaml
---
name: <domain>-<name>              # kebab-case, domain-prefixed
description: <one clear sentence>  # shown in /skills list — make it specific
disable-model-invocation: true     # ONLY for procedural skills with code templates
                                   # OMIT for persona, orchestrator, or agentic skills
allowed-tools: Read Bash Write Edit  # include only what is actually needed
effort: high                       # low | medium | high | xhigh
---
```

**When to set `disable-model-invocation: true`:**
- The skill is a library of code templates, checklists, or procedures the user runs
- Examples: `kaggle-validation`, `kaggle-baselines`, `kaggle-hill-climbing`

**When to omit `disable-model-invocation`:**
- The skill sets a persona, activates a thinking mode, or delegates to agents
- Examples: `kaggle-grandmaster`, `sdlc-biz-to-tech`, `sdlc-code-review`

### Agent Frontmatter (agents/<domain>/<name>.md)

```yaml
---
name: <name>                       # kebab-case, no domain prefix
description: <one clear sentence starting with "Delegate to this agent" or "Spawned by...">
model: opus                        # always opus for domain experts and orchestrators
tools: ["Read", "Bash", "Write", "Edit"]  # only what this agent actually needs
---
```

**Description convention:**
- Orchestrators: `"Delegate to this agent when..."`
- Specialists/experts spawned by orchestrators: `"Spawned by <orchestrator>. ..."`

### Content Structure

**For a procedural skill** (disable-model-invocation: true):
```markdown
# Skill: <Name>
**One-line context — when and why to use this**

## When to Use
## Step 1 — <First action>
[code blocks with copy-paste ready templates]
## Step 2 — <Next action>
[code blocks]
## Checklist
- [ ] item
## Output
- file produced, metric logged, etc.
## Pitfalls
- common mistakes
Next skill: `/<next-skill-name>`
```

**For a persona/orchestrator skill** (no disable-model-invocation):
```markdown
# Skill: <Name>
**Entry point for Phase N / Activates <persona> mode**

## What This Does
## Input
## What Gets Produced
## Orchestration (if it delegates to agents)
[indented tree of agents spawned]
## Next Phase
## Rules
```

**For an agent**:
```markdown
You are a <role> with expertise in <domain>. <One sentence mandate>.

## Mandate / Core Principles
## <Main section — the agent's primary analytical framework>
## <Secondary section — specific techniques or rules>
## Rules
- Bullet list of non-negotiable constraints
```

## Step 3 — Place Files

### New Skill
```bash
# Primary (local dev use in this repo)
mkdir -p .claude/skills/<skill-name>/
# Write SKILL.md to .claude/skills/<skill-name>/SKILL.md

# Mirror (plugin distribution)
mkdir -p skills/<skill-name>/
cp .claude/skills/<skill-name>/SKILL.md skills/<skill-name>/SKILL.md
```

### New Agent
```bash
# Agents live only in agents/<domain>/
mkdir -p agents/<domain>/
# Write agent .md to agents/<domain>/<name>.md
```

### New Domain
If this is the first skill/agent in a new domain:
```bash
mkdir -p agents/<domain>/
mkdir -p domains/<domain>/
# Create domains/<domain>/README.md with: purpose, files, skill chain
```

## Step 4 — Update README.md

Add the new skill to the correct table in README.md:

- **Kaggle skill** → add a row to the Kaggle Skills table
- **SDLC skill** → add a row to the SDLC Skills table
- **New domain** → add a new domain section with agents and skills tables
- **New agent** → add a row to the correct Agents table in the domain section
- **Repo structure tree** → add the new file/directory to the tree

## Step 5 — Verify

```bash
# Confirm files exist in both locations (for skills)
ls .claude/skills/<skill-name>/
ls skills/<skill-name>/

# Confirm frontmatter is valid (no tabs, proper YAML)
head -10 .claude/skills/<skill-name>/SKILL.md

# Confirm agent file exists
ls agents/<domain>/<name>.md

# Check README was updated
grep "<skill-name>" README.md
```

## Step 6 — Report

After creating the file(s), report:

```
Created: .claude/skills/<name>/SKILL.md
Mirrored: skills/<name>/SKILL.md
Updated: README.md

Invoke with: /<name>
```

Or for an agent:
```
Created: agents/<domain>/<name>.md

The agent will be auto-delegated when: <describe trigger>
It can also be spawned explicitly by: <parent orchestrator if applicable>
```

## Common Mistakes to Avoid

- **Tabs in YAML frontmatter** — YAML requires spaces. Tabs silently break parsing.
- **`disable-model-invocation: true` on an orchestrator skill** — this prevents the model from acting, making the skill useless for delegation.
- **Missing the mirror copy** — if `.claude/skills/` is updated but `skills/` is not, plugin users won't get the new skill.
- **Agent description that doesn't start with "Delegate to" or "Spawned by"** — breaks discoverability in the AGENTS.md ecosystem.
- **Listing tools the agent doesn't actually need** — keep tool lists minimal; unnecessary tools are security surface area.
- **Creating an agent with no parent orchestrator and no skill entry point** — it will never be invoked. Either wire it into an orchestrator or create a matching skill.
