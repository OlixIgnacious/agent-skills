# Agent Skills

A multi-domain Claude Code skill library — agents and skills organized by use case. Install once, use what's relevant.

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main/install.sh | bash
```

**Windows** (PowerShell)
```powershell
irm https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main/install.ps1 | iex
```

**Claude Code plugin**
```
/plugin install OlixIgnacious/agent-skills
```

The installer asks which domain (Kaggle / SDLC / Both) and which tool (Claude Code / Antigravity / Copilot / All), then downloads only the files you need.

---

## How It Works

**Agents** are role-based AI workers Claude delegates to automatically based on your task. They have a specific persona, judgment filters, and tool access.

**Skills** are slash commands you invoke explicitly for step-by-step procedures with code templates.

```
/kaggle-grandmaster          ← you invoke a skill
"help me engineer features"  ← Claude delegates to an agent
```

---

## Domains

### Kaggle — Competitive Machine Learning

> 3 agents · 12 skills · Full GM workflow from EDA to final submission

**Agents**

| Agent | Role |
|-------|------|
| `kaggle-grandmaster` | Competition orchestrator — decides phase, invokes skills, delegates to sub-agents |
| `kaggle-feature-engineer` | Feature engineering specialist — CV-delta tracked batches, GPU-accelerated |
| `kaggle-ensemble-builder` | Ensemble specialist — hill climbing, stacking, Optuna weight search, final blend |

**Skills**

| Command | Phase | What it does |
|---------|-------|-------------|
| `/kaggle-grandmaster` | Always | Persona, shake-up avoidance, problem reformulation heuristics |
| `/kaggle-adversarial-validation` | Day 1 | Detect train/test distribution shift before locking folds |
| `/kaggle-validation` | Day 1 | Lock fold strategy — KFold / TimeSeriesSplit / GroupKFold / Multilabel |
| `/kaggle-eda` | Day 1–2 | Distribution analysis, leakage scan, temporal pattern detection |
| `/kaggle-baselines` | Day 2–3 | Ridge + XGBoost + LightGBM + CatBoost with GPU backends |
| `/kaggle-target-transform` | Day 2–3 | Log/sqrt transforms, winsorization, isotonic calibration |
| `/kaggle-optuna` | Day 3+ | Bayesian hyperparameter search (TPE) + ensemble weight optimization |
| `/kaggle-feature-engineering` | Day 3→N-5 | Groupby aggs, interactions, CV-safe target encoding, lag/rolling |
| `/kaggle-hill-climbing` | Final week | Greedy ensemble selection + scipy/Optuna weight optimization |
| `/kaggle-stacking` | Final week | Stage 1 OOF → Stage 2 meta-learner + residual stacking |
| `/kaggle-pseudo-labeling` | Final 3 days | Fold-aware soft labels on unlabeled test data |
| `/kaggle-extra-training` | Final 24h | Seed ensemble + full-data retrain + submission checklist |

→ [Domain guide](domains/kaggle/README.md) · [Orchestration](domains/kaggle/ORCHESTRATION.md)

---

### SDLC Workbench — Software Development Lifecycle

> 17 agents · 4 skills · Requirements → Architecture → Implementation → Review

A drop-in workflow template for any codebase. Works across Claude Code, Antigravity, and GitHub Copilot.

| File | Tool |
|------|------|
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | Universal — Antigravity + Cursor + Claude Code |
| `GEMINI.md` | Antigravity (`agy`) |
| `.github/copilot-instructions.md` | GitHub Copilot |

→ [SDLC domain guide](domains/sdlc/README.md)

---

### Finance Research *(coming soon)*

> 1 agent · skills planned · Quant research, factor analysis, backtesting, portfolio construction

**Agents**

| Agent | Role |
|-------|------|
| `finance-researcher` | Quantitative research — factor IC analysis, walk-forward backtesting, risk |

→ [Domain guide](domains/finance/README.md)

---

## Repository Structure

```
agents/                  ← role-based AI workers (auto-delegated)
  kaggle/
    kaggle-grandmaster.md
    kaggle-feature-engineer.md
    kaggle-ensemble-builder.md
  sdlc/
    biz-to-tech-orchestrator.md
    architectural-review-orchestrator.md
    feature-dev-orchestrator.md
    code-review-orchestrator.md
    requirements-analyst.md
    code-archaeologist.md
    api-designer.md
    test-engineer.md
    technical-writer.md
    software-engineer.md
    database-internals.md
    devops-sre.md
    cybersecurity.md
    linux-debugging.md
    system-design.md
    competitive-programming.md
    ml-research.md
  finance/
    finance-researcher.md

skills/                  ← slash-command skills, domain-prefixed
  kaggle-grandmaster/
  kaggle-adversarial-validation/
  kaggle-validation/
  kaggle-eda/
  kaggle-baselines/
  kaggle-target-transform/
  kaggle-optuna/
  kaggle-feature-engineering/
  kaggle-hill-climbing/
  kaggle-stacking/
  kaggle-pseudo-labeling/
  kaggle-extra-training/

domains/                 ← per-domain workflow guides and orchestration
  kaggle/
  sdlc/
  finance/

.claude-plugin/          ← plugin manifest
  plugin.json
```

---

## Contributing a Domain

1. `agents/<domain>/<domain>-<role>.md` — agent with `name`, `description`, `model`, `tools` frontmatter
2. `skills/<domain>-<name>/SKILL.md` — skill with `description`, `disable-model-invocation`, `allowed-tools` frontmatter (omit `disable-model-invocation` for persona/orchestrator skills)
3. `domains/<domain>/README.md` — use case overview, file list, and skill chain
4. `domains/<domain>/ORCHESTRATION.md` — phase-by-phase workflow *(optional — see Kaggle for an example)*

See the Kaggle domain as the reference implementation for skills; the SDLC domain for agents.
