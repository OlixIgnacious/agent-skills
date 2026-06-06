---
name: kaggle-extra-training
description: Final competition preparation — seed ensembling for variance reduction, full-data retraining after hyperparameter lock, and pre-submission checklist. This is the last skill to run before final submission.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Extra Training (Seeds + Full-Data Retrain)
**Technique #7 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

**Final 24–48 hours of competition.** Hyperparameters are locked. Features are finalized. No more experimentation. This skill squeezes the last performance from your pipeline through:
1. **Seed ensemble** — train the same model with 100+ random seeds, average predictions
2. **Full-data retrain** — retrain on 100% of train data (no validation holdout) for final submission
3. **Final submission checklist** — prevent costly last-minute mistakes

## Why This Works

- **Seeds:** Single-seed predictions have variance from random initialization, feature sampling, and row sampling. Averaging 100 seeds reduces variance toward the true expected prediction, typically yielding +0.001–0.005 on the metric.
- **Full-data retrain:** Validation holdout (20% for 5-fold) withholds signal. Retraining on 100% uses all available information — valid when hyperparameters are already locked via CV.

## Step 1 — Seed Ensemble

```python
import numpy as np
import pandas as pd
import lightgbm as lgb
import xgboost as xgb
import catboost as cb
from pathlib import Path

train = pd.read_csv("train_folds.csv")
test  = pd.read_csv("test.csv")
feature_cols = [c for c in train.columns if c not in ["id", "target", "fold"]]

TASK = "binary"  # or "regression"
N_SEEDS = 50     # start with 50; go to 100 if time allows

def run_seed_ensemble(model_name: str, params: dict,
                      n_seeds: int = 50) -> np.ndarray:
    all_test_preds = []
    
    for seed in range(n_seeds):
        seed_params = {**params, "random_state": seed}
        
        # Train on all 5 folds
        fold_test_preds = []
        for fold in range(5):
            tr_mask = train["fold"] != fold
            X_tr = train.loc[tr_mask, feature_cols]
            y_tr = train.loc[tr_mask, "target"]
            
            if model_name == "lgb":
                seed_params_lgb = {**seed_params, "verbose": -1}
                model = lgb.LGBMClassifier(**seed_params_lgb)
                model.fit(X_tr, y_tr)
                pred = model.predict_proba(test[feature_cols])[:, 1]
            elif model_name == "xgb":
                model = xgb.XGBClassifier(**seed_params)
                model.fit(X_tr, y_tr, verbose=False)
                pred = model.predict_proba(test[feature_cols])[:, 1]
            elif model_name == "cat":
                model = cb.CatBoostClassifier(**seed_params, verbose=0)
                model.fit(X_tr, y_tr)
                pred = model.predict_proba(test[feature_cols])[:, 1]
            
            fold_test_preds.append(pred)
        
        # Average across folds for this seed
        seed_pred = np.mean(fold_test_preds, axis=0)
        all_test_preds.append(seed_pred)
        
        if (seed + 1) % 10 == 0:
            print(f"  Seed {seed+1}/{n_seeds} done")
    
    ensemble_pred = np.mean(all_test_preds, axis=0)
    print(f"Seed ensemble [{model_name}]: {n_seeds} seeds × 5 folds = {n_seeds*5} models")
    return ensemble_pred

# Run seed ensembles for each model family
# (use your locked hyperparameters here)
lgb_params = {
    "n_estimators": 1000, "learning_rate": 0.05, "num_leaves": 63,
    "subsample": 0.8, "colsample_bytree": 0.8, "device": "gpu"
}

seed_pred_lgb = run_seed_ensemble("lgb", lgb_params, N_SEEDS)
np.save("ensemble/seed_lgb.npy", seed_pred_lgb)
```

## Step 2 — Full-Data Retrain

Retrain on 100% of train data. Use the best number of iterations estimated from CV (typically: CV best_iteration × (n_folds / (n_folds - 1)) to account for larger training set).

```python
def full_data_retrain(model_name: str, params: dict,
                       cv_best_iterations: list[int]) -> np.ndarray:
    """
    cv_best_iterations: list of early stopping iterations from each fold
    Full-data n_estimators = mean(cv_best_iterations) * (5/4) for 5-fold
    """
    n_folds = 5
    scale_factor = n_folds / (n_folds - 1)
    full_n_estimators = int(np.mean(cv_best_iterations) * scale_factor)
    print(f"Full-data n_estimators: {full_n_estimators} (CV mean: {np.mean(cv_best_iterations):.0f})")
    
    X_full = train[feature_cols]
    y_full = train["target"]
    X_test = test[feature_cols]
    
    full_preds = []
    for seed in range(10):   # 10 seeds for full-data retrain
        fp = {**params, "n_estimators": full_n_estimators, "random_state": seed}
        
        if model_name == "lgb":
            fp["verbose"] = -1
            model = lgb.LGBMClassifier(**fp)
            model.fit(X_full, y_full)
            full_preds.append(model.predict_proba(X_test)[:, 1])
        
        elif model_name == "xgb":
            model = xgb.XGBClassifier(**fp)
            model.fit(X_full, y_full, verbose=False)
            full_preds.append(model.predict_proba(X_test)[:, 1])
    
    full_pred = np.mean(full_preds, axis=0)
    return full_pred

# You need to collect best_iteration from CV runs
# When using early stopping, save it:
#   best_iters.append(model.best_iteration_)
cv_best_iters = [842, 867, 891, 823, 854]   # replace with actual

full_retrain_pred = full_data_retrain("lgb", lgb_params, cv_best_iters)
np.save("ensemble/full_retrain_lgb.npy", full_retrain_pred)
```

## Step 3 — Blend Seed Ensemble with Full-Data Retrain

```python
# Standard blend: 50% CV-model average + 50% full-data retrain
FULL_DATA_WEIGHT = 0.5

cv_pred = np.load("ensemble/hill_climb_test_pred.npy")   # or pseudo-labeled if applicable
final_pred = (1 - FULL_DATA_WEIGHT) * cv_pred + FULL_DATA_WEIGHT * full_retrain_pred

np.save("ensemble/final_submission.npy", final_pred)
print(f"Final prediction saved. Shape: {final_pred.shape}")
print(f"Prediction range: [{final_pred.min():.4f}, {final_pred.max():.4f}]")
print(f"Mean prediction: {final_pred.mean():.4f}")
```

## Step 4 — Generate Submission File

```python
sample_sub = pd.read_csv("sample_submission.csv")

submission = pd.DataFrame({
    "id": test["id"],
    "target": final_pred   # rename to match competition's target column
})

# Verify submission format
assert len(submission) == len(sample_sub), f"Row count mismatch: {len(submission)} vs {len(sample_sub)}"
assert submission.columns.tolist() == sample_sub.columns.tolist(), \
    f"Column mismatch: {submission.columns.tolist()} vs {sample_sub.columns.tolist()}"

submission.to_csv("submission_final.csv", index=False)
print(f"Submission ready: {submission.shape}")
print(submission.head())
```

## Final Submission Checklist

Before clicking submit:

```
PRE-SUBMISSION CHECKLIST
========================
[ ] submission.csv row count matches sample_submission.csv exactly
[ ] Column names and order match sample_submission.csv
[ ] No NaN or Inf values in predictions
[ ] Prediction range is valid (0-1 for probability, unbounded for regression)
[ ] ID column is correct (not row index)
[ ] File encoding is UTF-8 (no BOM)
[ ] Predictions not clipped to training target range (test may have out-of-range values for regression)

FINAL DAY STRATEGY
==================
[ ] Keep at least 1 submission slot for a "safe" submission (best known CV model)
[ ] Keep 1 slot for the risky submission (most complex ensemble)
[ ] Do NOT submit your only slot 2 minutes before deadline
[ ] Confirm which submission Kaggle will select (private LB = best or last submission)
[ ] If you select: pick the one with best CV, not best public LB
```

## GPU-Accelerated Seed Ensemble with CuPy

```python
try:
    import cupy as cp
    
    # Accumulate predictions on GPU
    gpu_preds = cp.zeros(len(test))
    
    for seed in range(N_SEEDS):
        # ... train model ...
        pred_gpu = cp.array(model.predict_proba(test[feature_cols])[:, 1])
        gpu_preds += pred_gpu
    
    seed_ensemble_pred = cp.asnumpy(gpu_preds / N_SEEDS)
except ImportError:
    pass  # fallback to CPU numpy already shown above
```

## Output / Deliverables

- `ensemble/seed_lgb.npy`, `ensemble/seed_xgb.npy` — seed ensemble predictions
- `ensemble/full_retrain_lgb.npy` — full-data retrain predictions
- `ensemble/final_submission.npy` — final blended prediction
- `submission_final.csv` — ready to upload to Kaggle

## Pitfalls

- **Using early stopping for full-data retrain** → no validation set means early stopping doesn't work. Use fixed n_estimators.
- **Forgetting to scale n_estimators for full-data** → model undertrained (should be ~25% more than CV best for 5-fold).
- **Submitting the final ensemble without checking format** — guaranteed to waste a submission slot.
- **Not keeping a safe submission** → if your complex ensemble is wrong, you lose the entire medal.
- **Training 1000 seeds when 50 suffice** → diminishing returns after ~50 seeds. Spend the time elsewhere.

This is the final skill in the Kaggle competition workflow. See `orchestration/ORCHESTRATION.md` for the full competition timeline.
