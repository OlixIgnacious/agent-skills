---
name: kaggle-baselines
description: Build diverse model baselines simultaneously for Kaggle competitions — linear models, GBDTs (XGBoost, LightGBM, CatBoost), and neural nets. GPU-accelerated. Establishes the CV score floor before any feature engineering.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Diverse Baselines
**Technique #2 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

After EDA and validation setup. Run all families simultaneously (not sequentially) to establish the CV floor and model diversity for later ensembling. Three families running in parallel beats one perfectly tuned model.

## Why Diversity Matters

- Different model families make orthogonal errors
- Ensemble diversity = free performance
- Linear models reveal which features have clean linear signal
- GBDTs handle non-linearity and interactions naturally
- Neural nets can find patterns neither of the above can

## Step 1 — Linear Baselines (always first — fast signal)

```python
import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge, Lasso, LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline

# Load folds
train = pd.read_csv("train_folds.csv")
feature_cols = [c for c in train.columns if c not in ["id", "target", "fold"]]

# For regression
ridge_pipe = Pipeline([
    ("scaler", StandardScaler()),
    ("model", Ridge(alpha=1.0))
])

# For classification
logistic_pipe = Pipeline([
    ("scaler", StandardScaler()),
    ("model", LogisticRegression(C=1.0, max_iter=1000, solver="lbfgs"))
])

# Try GPU-accelerated linear models first
try:
    from cuml.linear_model import Ridge as cuRidge
    from cuml.linear_model import LogisticRegression as cuLogistic
    print("Using cuML GPU linear models")
    USING_GPU = True
except ImportError:
    print("cuML not available — using sklearn")
    USING_GPU = False
```

## Step 2 — GBDT Baselines (the workhorses)

Run all three GBDT flavors. Each has different default behavior and will diverge over feature engineering iterations, increasing ensemble diversity.

```python
import xgboost as xgb
import lightgbm as lgb
import catboost as cb

def get_xgb_params(task: str = "regression") -> dict:
    base = {
        "n_estimators": 1000, "learning_rate": 0.05, "max_depth": 6,
        "subsample": 0.8, "colsample_bytree": 0.8, "min_child_weight": 3,
        "random_state": 42, "n_jobs": -1, "early_stopping_rounds": 50,
    }
    if task == "regression":
        base.update({"objective": "reg:squarederror", "tree_method": "hist", "device": "cuda"})
    elif task == "binary":
        base.update({"objective": "binary:logistic", "eval_metric": "auc",
                     "tree_method": "hist", "device": "cuda"})
    return base

def get_lgb_params(task: str = "regression") -> dict:
    base = {
        "n_estimators": 1000, "learning_rate": 0.05, "num_leaves": 63,
        "subsample": 0.8, "colsample_bytree": 0.8, "min_child_samples": 20,
        "random_state": 42, "n_jobs": -1, "verbose": -1,
    }
    if task == "regression":
        base.update({"objective": "regression", "metric": "rmse", "device": "gpu"})
    elif task == "binary":
        base.update({"objective": "binary", "metric": "auc", "device": "gpu"})
    return base

def get_cat_params(task: str = "regression") -> dict:
    base = {
        "iterations": 1000, "learning_rate": 0.05, "depth": 6,
        "random_seed": 42, "verbose": 0, "task_type": "GPU",
        "early_stopping_rounds": 50,
    }
    if task == "regression":
        base.update({"loss_function": "RMSE"})
    elif task == "binary":
        base.update({"loss_function": "Logloss", "eval_metric": "AUC"})
    return base
```

## Step 3 — Full OOF Training Loop

```python
from sklearn.metrics import roc_auc_score, mean_squared_error
import warnings; warnings.filterwarnings("ignore")

TASK = "binary"  # or "regression"
METRIC = roc_auc_score  # or lambda y, p: -mean_squared_error(y, p, squared=False)

results = {}

def run_gbdt_oof(model_name: str, model_fn, fit_kwargs_fn=None):
    oof = np.zeros(len(train))
    models = []
    scores = []

    for fold in range(5):
        tr_mask  = train["fold"] != fold
        val_mask = train["fold"] == fold

        X_tr  = train.loc[tr_mask,  feature_cols]
        y_tr  = train.loc[tr_mask,  "target"]
        X_val = train.loc[val_mask, feature_cols]
        y_val = train.loc[val_mask, "target"]

        model = model_fn()
        fit_kwargs = fit_kwargs_fn(X_val, y_val) if fit_kwargs_fn else {}
        model.fit(X_tr, y_tr, **fit_kwargs)

        if TASK == "binary":
            oof[val_mask] = model.predict_proba(X_val)[:, 1]
        else:
            oof[val_mask] = model.predict(X_val)

        score = METRIC(y_val, oof[val_mask])
        scores.append(score)
        models.append(model)
        print(f"  [{model_name}] Fold {fold}: {score:.5f}")

    overall = METRIC(train["target"], oof)
    print(f"  [{model_name}] OOF: {overall:.5f} ± {np.std(scores):.5f}\n")
    results[model_name] = {"oof": oof, "models": models, "score": overall}

# XGBoost
run_gbdt_oof(
    "xgb",
    lambda: xgb.XGBClassifier(**get_xgb_params(TASK)),
    lambda X_val, y_val: {"eval_set": [(X_val, y_val)], "verbose": False}
)

# LightGBM
run_gbdt_oof(
    "lgb",
    lambda: lgb.LGBMClassifier(**get_lgb_params(TASK)),
    lambda X_val, y_val: {"eval_set": [(X_val, y_val)], "callbacks": [lgb.early_stopping(50, verbose=False)]}
)

# CatBoost
run_gbdt_oof(
    "cat",
    lambda: cb.CatBoostClassifier(**get_cat_params(TASK)),
    lambda X_val, y_val: {"eval_set": (X_val, y_val)}
)

# Summary
print("\n=== BASELINE SUMMARY ===")
for name, res in sorted(results.items(), key=lambda x: -x[1]["score"]):
    print(f"  {name}: {res['score']:.5f}")
```

## Step 4 — MLP Baseline (optional, dataset > 50K rows)

```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset

class MLP(nn.Module):
    def __init__(self, in_dim: int, hidden: list[int] = [256, 128, 64]):
        super().__init__()
        layers = []
        prev = in_dim
        for h in hidden:
            layers += [nn.Linear(prev, h), nn.BatchNorm1d(h), nn.ReLU(), nn.Dropout(0.3)]
            prev = h
        layers.append(nn.Linear(prev, 1))
        self.net = nn.Sequential(*layers)

    def forward(self, x):
        return self.net(x).squeeze()
```

## Step 5 — Log Results

```python
import json
from datetime import datetime

baseline_log = {
    "timestamp": datetime.now().isoformat(),
    "features": feature_cols,
    "n_features": len(feature_cols),
    "task": TASK,
    "results": {k: {"score": v["score"]} for k, v in results.items()}
}
with open("experiments/baselines.json", "w") as f:
    json.dump(baseline_log, f, indent=2)

# Save OOF predictions for ensembling
for name, res in results.items():
    np.save(f"oof/{name}_oof.npy", res["oof"])
```

## Output / Deliverables

- OOF predictions per model: `oof/xgb_oof.npy`, `oof/lgb_oof.npy`, `oof/cat_oof.npy`
- `experiments/baselines.json` — CV scores per model
- Best baseline CV score identified → this becomes the ensemble starting point

## GPU Tips

| Library | GPU param |
|---------|-----------|
| XGBoost | `tree_method="hist", device="cuda"` |
| LightGBM | `device="gpu"` |
| CatBoost | `task_type="GPU"` |
| cuML Ridge | Drop-in sklearn replacement on GPU |

Expect 5–20x speedup vs CPU on large datasets (> 100K rows).

## Pitfalls

- Running one model to convergence before trying others — you lose diversity for ensembling.
- Forgetting `early_stopping_rounds` → overfitting and wasted compute.
- Using default hyperparameters for final predictions — they are placeholders; tune after establishing diversity.
- Skipping the linear baseline — it's the fastest model and reveals which features have linear signal.

Next skill: `/kaggle-feature-engineering`
