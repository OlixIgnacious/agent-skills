# Kaggle Grandmaster Skills

Claude Code skills for competitive machine learning, based on the [NVIDIA Kaggle Grandmasters Playbook](https://developer.nvidia.com/blog/the-kaggle-grandmasters-playbook-7-battle-tested-modeling-techniques-for-tabular-data/).

## Install

```
/plugin install ashwini-sharma/agent-skills
```

## Skills (12 total)

| Command | When to use |
|---------|-------------|
| `/kaggle-grandmaster` | Start every session — persona, judgment filters, shake-up avoidance |
| `/kaggle-adversarial-validation` | Detect train/test distribution shift before locking folds |
| `/kaggle-validation` | Lock fold strategy (KFold / TimeSeries / GroupKFold / MultilabelStratified) |
| `/kaggle-eda` | Distribution analysis, leakage scan, temporal pattern detection |
| `/kaggle-baselines` | Diverse model families simultaneously (Ridge + XGBoost + LGB + CatBoost + MLP) |
| `/kaggle-target-transform` | Log/sqrt transforms, winsorization, probability calibration, beta sharpening |
| `/kaggle-optuna` | Bayesian hyperparameter search (TPE) + Optuna ensemble weight optimization |
| `/kaggle-feature-engineering` | Groupby aggs, interactions, CV-safe target encoding, lag/rolling features |
| `/kaggle-hill-climbing` | Greedy ensemble selection + scipy/Optuna weight optimization |
| `/kaggle-stacking` | Stage 1 OOF → Stage 2 meta-learner + residual stacking |
| `/kaggle-pseudo-labeling` | Semi-supervised boost with fold-aware soft labels |
| `/kaggle-extra-training` | Seed ensemble (50–100 seeds) + full-data retrain + submission checklist |

## Competition Workflow

```
/kaggle-grandmaster              ← always first
/kaggle-adversarial-validation   ← check shift
/kaggle-validation               ← lock folds
/kaggle-eda                      ← understand data
/kaggle-baselines                ← CV floor
/kaggle-target-transform         ← if skewed/calibration needed
/kaggle-optuna                   ← tune models
/kaggle-feature-engineering      ← iterate until CV plateaus
/kaggle-hill-climbing            ← final week
/kaggle-stacking                 ← final week
/kaggle-pseudo-labeling          ← final 3 days
/kaggle-extra-training           ← final 24h
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
