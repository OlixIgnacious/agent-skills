---
name: kaggle-optuna
description: Hyperparameter optimization with Optuna's TPE sampler for LightGBM, XGBoost, CatBoost, and neural nets. Also covers Optuna-guided ensemble weight optimization as a superior alternative to scipy hill climbing for large model pools.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Optuna Hyperparameter Optimization
**Bayesian optimization with Tree-structured Parzen Estimator — standard for Kaggle GBDTs**

## When to Use

- After baselines are established (you have a working CV pipeline)
- Before ensembling — tuned individual models improve ensemble ceiling
- When early stopping alone is insufficient (depth, leaves, regularization need tuning)
- For ensemble weight optimization when you have > 5 models (Optuna > scipy)

## Why Optuna Over Grid/Random Search

| Method | How it works | Trials needed |
|--------|-------------|---------------|
| Grid search | Exhaustive | Exponential |
| Random search | Uniform random | ~100–500 |
| Optuna TPE | Builds probabilistic model of good regions | ~50–200 |

TPE learns which hyperparameter regions yield improvement and focuses sampling there. Typically reaches grid-search quality in 10× fewer trials.

## Step 1 — Install and Basic Setup

```python
import optuna
import lightgbm as lgb
import xgboost as xgb
import numpy as np
import pandas as pd
from sklearn.metrics import roc_auc_score

optuna.logging.set_verbosity(optuna.logging.WARNING)

train = pd.read_csv("train_folds.csv")
feature_cols = [c for c in train.columns if c not in ["id", "target", "fold"]]
TASK = "binary"
N_FOLDS = 5
N_TRIALS = 100   # 50 for quick runs, 200 for thoroughness
```

## Step 2 — LightGBM Objective

```python
def lgb_objective(trial: optuna.Trial) -> float:
    params = {
        "objective":        "binary" if TASK == "binary" else "regression",
        "metric":           "auc" if TASK == "binary" else "rmse",
        "verbosity":        -1,
        "boosting_type":    "gbdt",
        "device":           "gpu",
        "n_estimators":     trial.suggest_int("n_estimators", 200, 2000),
        "learning_rate":    trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
        "num_leaves":       trial.suggest_int("num_leaves", 20, 300),
        "max_depth":        trial.suggest_int("max_depth", 3, 12),
        "min_child_samples":trial.suggest_int("min_child_samples", 5, 100),
        "subsample":        trial.suggest_float("subsample", 0.4, 1.0),
        "colsample_bytree": trial.suggest_float("colsample_bytree", 0.4, 1.0),
        "reg_alpha":        trial.suggest_float("reg_alpha", 1e-8, 10.0, log=True),
        "reg_lambda":       trial.suggest_float("reg_lambda", 1e-8, 10.0, log=True),
    }

    oof = np.zeros(len(train))
    for fold in range(N_FOLDS):
        tr  = train[train["fold"] != fold]
        val = train[train["fold"] == fold]

        model = lgb.LGBMClassifier(**params) if TASK == "binary" else lgb.LGBMRegressor(**params)
        model.fit(
            tr[feature_cols], tr["target"],
            eval_set=[(val[feature_cols], val["target"])],
            callbacks=[lgb.early_stopping(50, verbose=False),
                       lgb.log_evaluation(period=-1)]
        )
        oof[val.index] = (model.predict_proba(val[feature_cols])[:, 1]
                          if TASK == "binary" else model.predict(val[feature_cols]))

    score = roc_auc_score(train["target"], oof)
    return score   # Optuna maximizes by default

study_lgb = optuna.create_study(
    direction="maximize",
    sampler=optuna.samplers.TPESampler(seed=42),
    pruner=optuna.pruners.MedianPruner(n_startup_trials=10)
)
study_lgb.optimize(lgb_objective, n_trials=N_TRIALS, show_progress_bar=True)

print(f"Best LGB CV: {study_lgb.best_value:.5f}")
print(f"Best params: {study_lgb.best_params}")
```

## Step 3 — XGBoost Objective

```python
def xgb_objective(trial: optuna.Trial) -> float:
    params = {
        "objective":         "binary:logistic" if TASK == "binary" else "reg:squarederror",
        "eval_metric":       "auc" if TASK == "binary" else "rmse",
        "tree_method":       "hist",
        "device":            "cuda",
        "n_estimators":      trial.suggest_int("n_estimators", 200, 2000),
        "learning_rate":     trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
        "max_depth":         trial.suggest_int("max_depth", 3, 10),
        "min_child_weight":  trial.suggest_int("min_child_weight", 1, 20),
        "subsample":         trial.suggest_float("subsample", 0.4, 1.0),
        "colsample_bytree":  trial.suggest_float("colsample_bytree", 0.4, 1.0),
        "gamma":             trial.suggest_float("gamma", 1e-8, 1.0, log=True),
        "reg_alpha":         trial.suggest_float("reg_alpha", 1e-8, 10.0, log=True),
        "reg_lambda":        trial.suggest_float("reg_lambda", 1e-8, 10.0, log=True),
        "random_state":      42,
    }

    oof = np.zeros(len(train))
    for fold in range(N_FOLDS):
        tr  = train[train["fold"] != fold]
        val = train[train["fold"] == fold]

        model = xgb.XGBClassifier(**params) if TASK == "binary" else xgb.XGBRegressor(**params)
        model.fit(tr[feature_cols], tr["target"],
                  eval_set=[(val[feature_cols], val["target"])],
                  verbose=False)
        oof[val.index] = (model.predict_proba(val[feature_cols])[:, 1]
                          if TASK == "binary" else model.predict(val[feature_cols]))

    return roc_auc_score(train["target"], oof)

study_xgb = optuna.create_study(direction="maximize",
                                 sampler=optuna.samplers.TPESampler(seed=42))
study_xgb.optimize(xgb_objective, n_trials=N_TRIALS, show_progress_bar=True)
print(f"Best XGB CV: {study_xgb.best_value:.5f}")
```

## Step 4 — Optuna for Ensemble Weights (Better Than Scipy for > 5 Models)

```python
from pathlib import Path

oof_preds = {}
for path in Path("oof").glob("*_oof.npy"):
    name = path.stem.replace("_oof", "")
    oof_preds[name] = np.load(path)

model_names = list(oof_preds.keys())
y_true = train["target"].values

def ensemble_objective(trial: optuna.Trial) -> float:
    weights = np.array([
        trial.suggest_float(f"w_{name}", 0.0, 1.0)
        for name in model_names
    ])
    weights /= weights.sum()   # normalize to sum=1

    ensemble = sum(w * oof_preds[n] for w, n in zip(weights, model_names))
    return roc_auc_score(y_true, ensemble)

study_weights = optuna.create_study(
    direction="maximize",
    sampler=optuna.samplers.TPESampler(seed=42)
)
study_weights.optimize(ensemble_objective, n_trials=500, show_progress_bar=True)

best_weights = {
    name: study_weights.best_params[f"w_{name}"]
    for name in model_names
}
total = sum(best_weights.values())
best_weights = {k: v/total for k, v in best_weights.items()}

print(f"Ensemble CV: {study_weights.best_value:.5f}")
for name, w in sorted(best_weights.items(), key=lambda x: -x[1]):
    print(f"  {name}: {w:.4f}")
```

## Step 5 — Visualization and Analysis

```python
import optuna.visualization as vis

# Which hyperparameters matter most?
fig = vis.plot_param_importances(study_lgb)
fig.write_html("artifacts/optuna_param_importance.html")

# Optimization history
fig = vis.plot_optimization_history(study_lgb)
fig.write_html("artifacts/optuna_history.html")

# Parallel coordinate plot
fig = vis.plot_parallel_coordinate(study_lgb)
fig.write_html("artifacts/optuna_parallel.html")

print("Visualizations saved to artifacts/")
```

## Step 6 — Save Best Params and Retrain

```python
import json

best_params = {
    "lgb": study_lgb.best_params,
    "xgb": study_xgb.best_params,
}
with open("experiments/best_params.json", "w") as f:
    json.dump(best_params, f, indent=2)

# Retrain with best params — full OOF for ensembling
# (reuse the OOF framework from /kaggle-baselines with best_params["lgb"])
```

## Gotchas

- **Tuning n_estimators with early stopping**: Let early stopping find the best iteration within the Optuna range — don't tune n_estimators independently of learning_rate.
- **Overfitting the Optuna study to CV**: With 200+ trials, the study itself can overfit to CV noise. Use fewer trials or a held-out fold to validate the best params.
- **Optimizing ensemble weights before individual models are tuned**: Weak individual models reduce ensemble ceiling. Tune individuals first, then weights.
- **Not saving the study**: Use `optuna.create_study(storage="sqlite:///optuna.db")` to persist across sessions — restartable studies.
- **Pruning too aggressively**: `MedianPruner` can eliminate params that start slow but converge well. Increase `n_startup_trials` if early promising params get pruned.

Next skills: `/kaggle-hill-climbing` (use Optuna weights), `/kaggle-extra-training`
