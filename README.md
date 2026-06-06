# Agent Skills

A multi-domain Claude Code skill library. Install once, use the skills relevant to your work.

```
/plugin install OlixIgnacious/agent-skills
```

---

## Domains

### Kaggle — Competitive Machine Learning

12 skills encoding the full Grandmaster competition workflow.

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

Skills for quantitative research, factor analysis, backtesting, and financial modeling.

→ [Finance domain guide](domains/finance/README.md)

---

## Adding a New Domain

1. Create `domains/<domain>/README.md` — describe the use case and skill chain
2. Create skills in `skills/<domain>-<name>/SKILL.md` — follow the skill format
3. PR to this repo

Each skill is a markdown file with YAML frontmatter. Invoke with `/<domain>-<skill-name>`.

## Structure

```
skills/              ← all skills, flat, domain-prefixed
domains/             ← per-domain guides and orchestration
  kaggle/
  finance/
.claude-plugin/      ← plugin manifest
.claude/skills/      ← local dev copy (same as skills/)
```
