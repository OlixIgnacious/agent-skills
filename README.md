# Agent Skills

A multi-domain Claude Code skill library — agents and skills organized by use case. Install once, use what's relevant.

```bash
# One-liner installer (interactive — picks domain + tool)
curl -fsSL https://raw.githubusercontent.com/OlixIgnacious/agent-skills/main/install.sh | bash
```

Or as a Claude Code plugin:
```
/plugin install OlixIgnacious/agent-skills
```

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
  finance/

.claude-plugin/          ← plugin manifest
  plugin.json
```

---

## Contributing a Domain

1. `agents/<domain>/<domain>-<role>.md` — agent with `name`, `description`, `prompt`, `tools` frontmatter
2. `skills/<domain>-<name>/SKILL.md` — skill with `description`, `disable-model-invocation`, `allowed-tools` frontmatter
3. `domains/<domain>/README.md` — use case overview and skill chain
4. `domains/<domain>/ORCHESTRATION.md` — phase-by-phase workflow

See the Kaggle domain as the reference implementation.
