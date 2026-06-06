# Kaggle Grandmaster Skills

Claude Code skills for competitive machine learning, based on the [NVIDIA Kaggle Grandmasters Playbook](https://developer.nvidia.com/blog/the-kaggle-grandmasters-playbook-7-battle-tested-modeling-techniques-for-tabular-data/).

## Install

```
/plugin install ashwini-sharma/agent-skills
```

## Skills

| Command | When to use |
|---------|-------------|
| `/kaggle-grandmaster` | Start every session — loads judgment filters and decision heuristics |
| `/kaggle-validation` | Lock your fold strategy before any modeling |
| `/kaggle-eda` | Detect distribution shift, leakage, and temporal patterns |
| `/kaggle-baselines` | Train diverse model families simultaneously (Ridge + XGBoost + LGB + CatBoost) |
| `/kaggle-feature-engineering` | Groupby aggregations, interactions, CV-safe target encoding, lag features |
| `/kaggle-hill-climbing` | Greedy ensemble selection with weight optimization |
| `/kaggle-stacking` | Stage 1 OOF → Stage 2 meta-learner |
| `/kaggle-pseudo-labeling` | Semi-supervised boost with soft labels on unlabeled test data |
| `/kaggle-extra-training` | Seed ensemble + full-data retrain + final submission checklist |

## Competition Workflow

```
/kaggle-grandmaster        ← always first
/kaggle-validation         ← lock folds
/kaggle-eda                ← understand data
/kaggle-baselines          ← CV floor
/kaggle-feature-engineering  ← iterate until CV plateaus
/kaggle-hill-climbing      ← final week
/kaggle-stacking           ← final week
/kaggle-pseudo-labeling    ← final 3 days
/kaggle-extra-training     ← final 24h
```

See [orchestration/ORCHESTRATION.md](orchestration/ORCHESTRATION.md) for the full phase-by-phase guide and competition-type adaptations (PlaygroundSeries, time series, featured competitions).

## GPU Support

All skills support GPU acceleration via cuDF, cuML, and CuPy with automatic CPU fallbacks. No GPU required — skills work on any machine.

## Requirements

Skills include ready-to-run Python templates. Recommended libraries:

```
pandas numpy scipy scikit-learn matplotlib seaborn
xgboost lightgbm catboost
cudf cuml cupy          # optional, for GPU acceleration
torch                   # optional, for MLP baseline
```
