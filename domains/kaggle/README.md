# Domain: Kaggle — Competitive Machine Learning

12 Claude Code skills covering the full Grandmaster competition workflow, based on the [NVIDIA Kaggle Grandmasters Playbook](https://developer.nvidia.com/blog/the-kaggle-grandmasters-playbook-7-battle-tested-modeling-techniques-for-tabular-data/) and GM-level competition research.

## Competition Phases

```
Phase 1 — Understand (Day 1–2)
  /kaggle-grandmaster              activate persona
  /kaggle-adversarial-validation   is train/test shift a problem?
  /kaggle-validation               lock folds — never change after this
  /kaggle-eda                      target, leakage, temporal patterns

Phase 2 — Build (Day 3 → deadline minus 5)
  /kaggle-baselines                CV floor across model families
  /kaggle-target-transform         skewed target? calibration needed?
  /kaggle-optuna                   tune the best 1–2 families
  /kaggle-feature-engineering      iterate until CV plateaus 2 rounds

Phase 3 — Ensemble (Final week)
  /kaggle-hill-climbing            greedy combination of OOF predictions
  /kaggle-stacking                 learned meta-combination

Phase 4 — Final Push (Final 24–48h)
  /kaggle-pseudo-labeling          soft labels if test >> train
  /kaggle-extra-training           seeds + full retrain + submission
```

## Competition Type Adaptations

| Type | Key adjustments |
|------|----------------|
| **PlaygroundSeries** | Skip heavy stacking; focus on feature engineering + hill climbing |
| **Time Series** | Always `TimeSeriesSplit`; lag/rolling features dominant |
| **Grouped data** | `GroupKFold`; set `GROUP_COL` in config |
| **Multi-label** | `MultilabelStratifiedKFold`; binary cross-entropy per label |
| **Featured (2–3 months)** | Full workflow; tabular transformers viable |

## Key Files

- [ORCHESTRATION.md](ORCHESTRATION.md) — detailed phase-by-phase guide with data contracts between skills
- [personas/kaggle-grandmaster.md](personas/kaggle-grandmaster.md) — persona quick reference

## Techniques Covered

- Adversarial validation (train/test shift detection)
- KS-test distribution profiling
- Fold locking + CV–LB correlation tracking + shake-up avoidance
- Diverse baselines (linear + GBDT trifecta + MLP)
- Target transforms: log1p, winsorization, isotonic calibration, beta sharpening
- Optuna TPE for hyperparameters + ensemble weights
- Feature engineering at scale: groupby aggs, interactions, CV-safe target encoding, lag/rolling
- Hill climbing with Caruana greedy selection (CuPy-accelerated)
- Two-level stacking + residual stacking
- Fold-aware pseudo-labeling with confidence thresholding
- Seed ensembling (50–100 seeds) + full-data retrain
