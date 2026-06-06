# Agent Skills

A multi-domain Claude Code skill library. Install once, use the skills relevant to your work.

```
/plugin install OlixIgnacious/agent-skills
```

---

## Domains

### Kaggle — Competitive Machine Learning

**Agents** (auto-delegated role workers):

| Agent | Role |
|-------|------|
| `kaggle-grandmaster` | Orchestrates the full competition workflow, decides phase and delegates |
| `kaggle-feature-engineer` | Deep feature engineering with CV-delta tracking per batch |
| `kaggle-ensemble-builder` | Hill climbing, stacking, Optuna weights, final blend |

**Skills** (slash commands you invoke explicitly):

| Command | When |
|---------|------|
| `/kaggle-grandmaster` | Always first — persona, judgment filters, shake-up avoidance |
| `/kaggle-adversarial-validation` | Day 1 — detect train/test distribution shift |
| `/kaggle-validation` | Day 1 — lock fold strategy before any modeling |
| `/kaggle-eda` | Day 1–2 — distribution analysis, leakage scan, temporal patterns |
| `/kaggle-baselines` | Day 2–3 — Ridge + XGBoost + LGB + CatBoost simultaneously |
| `/kaggle-target-transform` | Day 2–3 — log/sqrt transforms, winsorization, calibration |
| `/kaggle-optuna` | Day 3+ — Bayesian hyperparameter search + ensemble weight optimization |
| `/kaggle-feature-engineering` | Day 3→N-5 — groupby aggs, interactions, CV-safe target encoding |
| `/kaggle-hill-climbing` | Final week — greedy ensemble forward selection |
| `/kaggle-stacking` | Final week — OOF meta-features → meta-learner |
| `/kaggle-pseudo-labeling` | Final 3 days — soft labels on unlabeled test data |
| `/kaggle-extra-training` | Final 24h — seed ensemble + full-data retrain + checklist |

→ [Kaggle domain guide](domains/kaggle/README.md) · [Competition orchestration](domains/kaggle/ORCHESTRATION.md)

---

### Finance Research *(coming soon)*

**Agents:** `finance-researcher` — quantitative research, factor analysis, portfolio construction

→ [Finance domain guide](domains/finance/README.md)

---

## Adding a New Domain

1. Create `domains/<domain>/README.md` — describe the use case and skill chain
2. Create skills in `skills/<domain>-<name>/SKILL.md` — follow the skill format
3. PR to this repo

Each skill is a markdown file with YAML frontmatter. Invoke with `/<domain>-<skill-name>`.

## Adding a Domain

1. `agents/<domain>/<domain>-<role>.md` — agent persona with `prompt:` frontmatter
2. `skills/<domain>-<name>/SKILL.md` — slash-command skills
3. `domains/<domain>/README.md` + `ORCHESTRATION.md` — workflow guide

## Structure

```
agents/              ← role-based AI workers (auto-delegated)
  kaggle/
  finance/
skills/              ← slash-command skills, domain-prefixed
  kaggle-*/
domains/             ← per-domain workflow guides
  kaggle/
  finance/
.claude-plugin/      ← plugin manifest
.claude/skills/      ← local dev copy
```
