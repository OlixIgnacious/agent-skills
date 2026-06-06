---
name: kaggle-stacking
description: Multi-level stacking for Kaggle — Stage 1 generates out-of-fold predictions as meta-features, Stage 2 trains a meta-learner on them. Produces more powerful ensembles than weighted averaging alone.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Stacking
**Technique #4 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

When you have 4+ diverse models with good individual CV scores and hill climbing is already yielding diminishing returns. Stacking adds a learned combination layer on top of weighted averaging. Most effective when models have different error patterns.

## Stacking vs Hill Climbing

| Method | How it combines | Best when |
|--------|----------------|-----------|
| Hill climbing | Fixed weights | Models are moderately diverse |
| Stacking | Learned meta-model | Models have very different error patterns |
| Both | Use both + blend outputs | Final submission for competitive rankings |

## Architecture

```
Stage 1 (Base Models)                Stage 2 (Meta-learner)
─────────────────────                ──────────────────────
XGBoost  ──┐                         ┌── Ridge / LightGBM
LightGBM ──┤── OOF predictions ──────┤── LogisticRegression
CatBoost ──┤   (meta-features)        └── Output: final pred
MLP      ──┘
```

## Step 1 — Prepare OOF Meta-Features

```python
import numpy as np
import pandas as pd
from pathlib import Path

train = pd.read_csv("train_folds.csv")
y_true = train["target"].values

# Load all Stage 1 OOF predictions
oof_dir = Path("oof")
meta_train = {}
meta_test = {}

for path in sorted(oof_dir.glob("*_oof.npy")):
    name = path.stem.replace("_oof", "")
    meta_train[name] = np.load(path)
    
    test_path = Path("test_preds") / f"{name}_test.npy"
    if test_path.exists():
        meta_test[name] = np.load(test_path)

# Stack into meta-feature matrix
X_meta_train = np.column_stack(list(meta_train.values()))
X_meta_test  = np.column_stack(list(meta_test.values()))
meta_feature_names = list(meta_train.keys())

print(f"Meta-feature matrix: {X_meta_train.shape}")
print(f"Features: {meta_feature_names}")
```

## Step 2 — Add Original Features to Meta Matrix (optional but often helpful)

```python
# Include top N original features alongside model predictions
INCLUDE_ORIGINAL_FEATURES = True
TOP_N_ORIGINAL = 20

if INCLUDE_ORIGINAL_FEATURES:
    import lightgbm as lgb
    
    feature_cols = [c for c in train.columns if c not in ["id", "target", "fold"]]
    # Get top features by importance
    model = lgb.LGBMClassifier(n_estimators=100, verbose=-1)
    model.fit(train[feature_cols], y_true)
    imp = pd.Series(model.feature_importances_, index=feature_cols).nlargest(TOP_N_ORIGINAL)
    top_feats = imp.index.tolist()
    
    X_meta_train = np.column_stack([X_meta_train, train[top_feats].values])
    test_df = pd.read_csv("test.csv")
    X_meta_test  = np.column_stack([X_meta_test,  test_df[top_feats].values])
    meta_feature_names += top_feats
    print(f"Meta-feature matrix with original feats: {X_meta_train.shape}")
```

## Step 3 — Stage 2 Meta-Learner Training

Train the meta-learner using the same fold structure as Stage 1.

```python
from sklearn.linear_model import Ridge, LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import roc_auc_score, mean_squared_error
import lightgbm as lgb

TASK = "binary"  # or "regression"

def build_meta_learners(task: str):
    if task == "binary":
        return {
            "meta_ridge": Pipeline([
                ("scaler", StandardScaler()),
                ("model", LogisticRegression(C=0.1, max_iter=1000, random_state=42))
            ]),
            "meta_lgb": lgb.LGBMClassifier(
                n_estimators=500, learning_rate=0.02, num_leaves=15,
                subsample=0.8, colsample_bytree=0.8, random_state=42,
                verbose=-1, min_child_samples=10
            )
        }
    else:
        return {
            "meta_ridge": Pipeline([
                ("scaler", StandardScaler()),
                ("model", Ridge(alpha=1.0))
            ]),
            "meta_lgb": lgb.LGBMRegressor(
                n_estimators=500, learning_rate=0.02, num_leaves=15,
                subsample=0.8, colsample_bytree=0.8, random_state=42,
                verbose=-1
            )
        }

meta_learners = build_meta_learners(TASK)
meta_results = {}

def predict_meta(model, X, task):
    if task == "binary" and hasattr(model, "predict_proba"):
        return model.predict_proba(X)[:, 1]
    return model.predict(X)

metric_fn = roc_auc_score if TASK == "binary" else \
            (lambda y, p: -np.sqrt(mean_squared_error(y, p)))

for meta_name, meta_model in meta_learners.items():
    oof_meta = np.zeros(len(train))
    test_meta_preds = []
    scores = []

    for fold in range(5):
        tr_mask  = train["fold"] != fold
        val_mask = train["fold"] == fold

        X_tr  = X_meta_train[tr_mask]
        y_tr  = y_true[tr_mask]
        X_val = X_meta_train[val_mask]
        y_val = y_true[val_mask]

        meta_model.fit(X_tr, y_tr)
        oof_meta[val_mask] = predict_meta(meta_model, X_val, TASK)
        test_meta_preds.append(predict_meta(meta_model, X_meta_test, TASK))

        score = metric_fn(y_val, oof_meta[val_mask])
        scores.append(score)
        print(f"  [{meta_name}] Fold {fold}: {score:.5f}")

    overall = metric_fn(y_true, oof_meta)
    test_pred_avg = np.mean(test_meta_preds, axis=0)
    print(f"  [{meta_name}] OOF: {overall:.5f} ± {np.std(scores):.5f}\n")

    meta_results[meta_name] = {
        "oof": oof_meta,
        "test_pred": test_pred_avg,
        "score": overall,
    }

    np.save(f"oof/{meta_name}_oof.npy", oof_meta)
    np.save(f"test_preds/{meta_name}_test.npy", test_pred_avg)
```

## Step 4 — Blend Stage 2 Outputs

```python
# Simple average of meta-learners (often works as well as weighted blend)
all_meta_oof  = np.mean([r["oof"]       for r in meta_results.values()], axis=0)
all_meta_test = np.mean([r["test_pred"] for r in meta_results.values()], axis=0)

blend_score = metric_fn(y_true, all_meta_oof)
print(f"Blended meta OOF: {blend_score:.5f}")

np.save("ensemble/stacking_oof.npy", all_meta_oof)
np.save("ensemble/stacking_test.npy", all_meta_test)
```

## Step 5 — Combine Stack with Hill Climbing

```python
# Load hill climbing prediction if available
hc_test = np.load("ensemble/hill_climb_test_pred.npy")
hc_oof  = np.load("ensemble/hill_climb_oof.npy")  # if saved

# Blend: ~70% hill climb + 30% stacking (tune this)
alpha = 0.7
final_test = alpha * hc_test + (1 - alpha) * all_meta_test

if hc_oof is not None:
    final_oof = alpha * hc_oof + (1 - alpha) * all_meta_oof
    final_score = metric_fn(y_true, final_oof)
    print(f"Final blended OOF: {final_score:.5f}")

np.save("ensemble/final_blend.npy", final_test)
```

## Residual Stacking (Advanced)

When the meta-learner should correct Stage 1 residuals:

```python
# Regression only
oof_avg = X_meta_train.mean(axis=1)    # simple average of Stage 1
residuals = y_true - oof_avg           # what Stage 1 gets wrong

# Train residual corrector on same meta-features
from sklearn.linear_model import Ridge
residual_model = Ridge(alpha=10.0)
residual_model.fit(X_meta_train, residuals)

# Final prediction = Stage 1 average + learned correction
residual_correction = residual_model.predict(X_meta_test)
final_with_residual = np.mean(list(meta_test.values()), axis=0) + residual_correction
```

## Output / Deliverables

- `oof/meta_*.npy` — OOF predictions from each meta-learner
- `test_preds/meta_*.npy` — test predictions from each meta-learner
- `ensemble/stacking_test.npy` — blended stack prediction
- `experiments/stacking.json` — meta-learner CV scores

## Pitfalls

- Training Stage 2 on the full train OOF without CV → meta-learner overfits to Stage 1 OOF noise.
- Using a complex meta-learner (deep tree, large GBDT) → overfits; prefer Ridge or shallow GBDT.
- Forgetting to average test predictions across folds for the meta-learner → fold-specific predictions.
- Adding too many original features to the meta matrix → meta-learner just re-learns Stage 1.

Next skills: `/kaggle-pseudo-labeling`, `/kaggle-extra-training`
