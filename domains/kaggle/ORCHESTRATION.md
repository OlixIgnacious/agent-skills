# Kaggle Competition Orchestration

This document defines how to chain the Kaggle skills across a competition lifecycle.

## Layer Architecture

```
Objective (Win the competition metric)
  └── Persona (kaggle-grandmaster — who thinks)
        └── Skills (kaggle-* — how to execute)
              └── Your competition notebook (what to do)
```

## Quick Start

```
/kaggle-grandmaster              ← activate at session start, always
/kaggle-adversarial-validation   ← check train/test distribution shift
/kaggle-validation               ← lock folds before anything else
/kaggle-eda                      ← understand your data
/kaggle-baselines                ← establish CV floor
/kaggle-optuna                   ← tune top models
/kaggle-feature-engineering      ← iterate until CV plateaus
/kaggle-target-transform         ← if target is skewed / needs calibration
/kaggle-hill-climbing            ← combine models (final week)
/kaggle-stacking                 ← learned ensembling (final week)
/kaggle-pseudo-labeling          ← semi-supervised boost (final 3 days)
/kaggle-extra-training           ← seeds + full retrain (final 24h)
```

## Competition Phase Map

### Phase 1 — Understand (Day 1–2)

**Goal:** Know your data before touching a model.

| Skill | Output |
|-------|--------|
| `/kaggle-grandmaster` | Persona active, competition context logged |
| `/kaggle-adversarial-validation` | Distribution shift check; adversarial AUC; high-shift features identified |
| `/kaggle-eda` | Temporal signal, leakage scan, target analysis |
| `/kaggle-validation` | Fold type chosen, `train_folds.csv` saved |

**Decision gate:** Cannot proceed without `train_folds.csv` and a confirmed fold type. If adversarial AUC > 0.70, use adversarial-based validation set instead of random folds.

---

### Phase 2 — Build (Day 3 → deadline - 5 days)

**Goal:** Establish a strong CV baseline across diverse model families.

| Skill | Output |
|-------|--------|
| `/kaggle-baselines` | XGBoost + LGB + CatBoost OOF scores, OOF files |
| `/kaggle-target-transform` | Log/sqrt transform if target is skewed; winsorize outliers |
| `/kaggle-optuna` | Tuned hyperparameters for top 1–2 model families |
| `/kaggle-feature-engineering` | Feature batches measured by CV delta |

**Iteration loop:** Alternate between feature engineering and baseline retraining. Stop when 2 consecutive feature batches yield < +0.001 CV improvement.

**File structure to maintain:**
```
competition/
├── train_folds.csv          ← locked, never change fold column
├── oof/                     ← one file per model: xgb_oof.npy, lgb_oof.npy
├── test_preds/              ← one file per model: xgb_test.npy
├── experiments/             ← JSON logs: baselines.json, features.json
└── artifacts/               ← plots: feature_importance.png, cv_lb.png
```

---

### Phase 3 — Ensemble (Deadline - 5 days → deadline - 1 day)

**Goal:** Combine diverse models for maximum metric gain.

| Skill | Order | Notes |
|-------|-------|-------|
| `/kaggle-hill-climbing` | First | Greedy selection, weight optimization |
| `/kaggle-stacking` | Second | Meta-learner on OOF predictions |
| Blend | Manual | ~70% hill climb + 30% stack (tune by CV) |

**Rule:** Ensemble score must beat best individual model by > +0.002 to be worth the complexity overhead.

---

### Phase 4 — Final Push (Last 24–48 hours)

**Goal:** Maximize performance with no more feature/model changes.

| Skill | Order | Notes |
|-------|-------|-------|
| `/kaggle-pseudo-labeling` | First if applicable | Only when test >> train |
| `/kaggle-extra-training` | Last | Seed ensemble + full-data retrain |

**Submission strategy:**
- Slot 1: Best CV model (safe — hedges against ensemble failure)
- Slot 2: Full ensemble + pseudo-label + seeds (aggressive)
- Choose slot 1 or 2 for private LB based on CV confidence

---

## Competition Type Adaptations

### PlaygroundSeries (PS)
- Shorter duration (1–4 weeks), smaller datasets
- Focus: Feature engineering + diverse baselines + hill climbing
- Skip: Pseudo-labeling (test set often small), skip heavy stacking
- Extra: Generate synthetic data with CTGAN/SDV if leaderboard allows

### Featured Competition (large, 2–3 months)
- Full workflow applies
- Invest extra time in neural net baselines (tabular transformers)
- Multiple stacking levels possible

### Time Series Competition
- Validation: **Always** TimeSeriesSplit — never StratifiedKFold
- Features: Lag/rolling dominant, no future information in any feature
- Baselines: LightGBM with `min_data_in_leaf` tuned for sequence length

---

## Persona + Skill Loading Pattern

At the start of each competition session:

```
Load: personas/kaggle-grandmaster.md   ← identity and judgment filters
Load: .claude/skills/kaggle-<name>/SKILL.md  ← for the current phase
```

Or via slash commands (preferred — auto-loads from .claude/skills/):

```
/kaggle-grandmaster
/kaggle-eda
```

---

## Cross-Skill Data Contract

Each skill produces files that the next skill consumes. Never break this contract:

| Producer | File | Consumer |
|----------|------|----------|
| `/kaggle-validation` | `train_folds.csv` (with `fold` col) | All skills |
| `/kaggle-baselines` | `oof/{model}_oof.npy` | hill-climbing, stacking |
| `/kaggle-baselines` | `test_preds/{model}_test.npy` | hill-climbing, stacking |
| `/kaggle-hill-climbing` | `ensemble/hill_climb_test_pred.npy` | pseudo-labeling, extra-training |
| `/kaggle-stacking` | `ensemble/stacking_test.npy` | extra-training |
| `/kaggle-pseudo-labeling` | `ensemble/pseudo_blend.npy` | extra-training |
| `/kaggle-extra-training` | `submission_final.csv` | Kaggle upload |
