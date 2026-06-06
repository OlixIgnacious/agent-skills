---
name: kaggle-hill-climbing
description: Build an ensemble by greedy forward selection — start with the best single model and add others only when the metric improves. Uses CuPy for vectorized metric computation and scipy for weight optimization.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Hill Climbing Ensemble
**Technique #5 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

After you have OOF predictions from at least 3 diverse models. Begin hill climbing 3–5 days before deadline. It is always worthwhile — the gain is "free" (no additional training required, just combining existing predictions).

## Why Hill Climbing

Simple averaging assumes equal model quality and equal error types. Hill climbing finds the optimal combination by:
1. Starting with the best single model
2. Greedily testing each candidate: "does adding this improve the ensemble?"
3. Keeping only additions that improve the metric
4. Optionally running weight optimization over the selected set

## Step 1 — Load OOF Predictions

```python
import numpy as np
import pandas as pd
from pathlib import Path

train = pd.read_csv("train_folds.csv")
y_true = train["target"].values

# Load all OOF predictions
oof_dir = Path("oof")
model_names = []
oof_preds = {}

for path in sorted(oof_dir.glob("*.npy")):
    name = path.stem.replace("_oof", "")
    oof_preds[name] = np.load(path)
    model_names.append(name)
    print(f"Loaded {name}: shape={oof_preds[name].shape}")

print(f"\nTotal models: {len(model_names)}")
```

## Step 2 — Define Metric Function

```python
from sklearn.metrics import roc_auc_score, mean_squared_error, log_loss

# Choose one metric that matches competition
def metric(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    return roc_auc_score(y_true, y_pred)          # classification (higher=better)
    # return -np.sqrt(mean_squared_error(y_true, y_pred))  # regression (higher=better)
    # return -log_loss(y_true, y_pred)             # log loss (higher=better)

HIGHER_IS_BETTER = True
```

## Step 3 — Score Each Individual Model

```python
individual_scores = {}
for name in model_names:
    score = metric(y_true, oof_preds[name])
    individual_scores[name] = score
    print(f"  {name}: {score:.5f}")

best_model = max(individual_scores, key=individual_scores.get)
best_score = individual_scores[best_model]
print(f"\nBest single model: {best_model} ({best_score:.5f})")
```

## Step 4 — Greedy Forward Selection (GPU-accelerated with CuPy)

```python
try:
    import cupy as cp
    def to_array(x): return cp.array(x)
    def to_numpy(x): return cp.asnumpy(x)
    print("Using CuPy for vectorized metric computation")
except ImportError:
    cp = np
    def to_array(x): return np.array(x)
    def to_numpy(x): return x
    print("CuPy not available — using NumPy")


def greedy_ensemble(model_names: list, oof_preds: dict, y_true: np.ndarray,
                    metric_fn, higher_is_better: bool = True,
                    n_rounds: int = 100) -> dict:
    """
    Greedy forward selection with replacement (Caruana et al. ensemble method).
    Allows the same model to be selected multiple times — equivalent to weight optimization.
    """
    y_gpu = to_array(y_true)
    preds_gpu = {name: to_array(pred) for name, pred in oof_preds.items()}
    
    # Start with best model
    best_model = max({n: metric_fn(y_true, oof_preds[n]) for n in model_names}.items(),
                     key=lambda x: x[1] if higher_is_better else -x[1])[0]
    
    ensemble = [best_model]
    current_pred = preds_gpu[best_model].copy()
    current_score = metric_fn(y_true, to_numpy(current_pred))
    
    print(f"Start: {best_model} = {current_score:.5f}")
    
    selection_counts = {name: 0 for name in model_names}
    selection_counts[best_model] = 1
    
    for round_i in range(n_rounds):
        best_candidate = None
        best_candidate_score = current_score
        
        for candidate in model_names:
            # Test: current ensemble + candidate (equal weight average)
            n = len(ensemble) + 1
            test_pred = (current_pred * len(ensemble) + preds_gpu[candidate]) / n
            test_score = metric_fn(y_true, to_numpy(test_pred))
            
            if (higher_is_better and test_score > best_candidate_score) or \
               (not higher_is_better and test_score < best_candidate_score):
                best_candidate = candidate
                best_candidate_score = test_score
        
        if best_candidate is None:
            print(f"Round {round_i+1}: no improvement, stopping")
            break
        
        ensemble.append(best_candidate)
        selection_counts[best_candidate] += 1
        n = len(ensemble)
        current_pred = (current_pred * (n-1) + preds_gpu[best_candidate]) / n
        current_score = best_candidate_score
        print(f"Round {round_i+1}: +{best_candidate} → {current_score:.5f}")
    
    # Compute effective weights
    total = sum(selection_counts.values())
    weights = {k: v/total for k, v in selection_counts.items() if v > 0}
    
    return {
        "ensemble_pred": to_numpy(current_pred),
        "weights": weights,
        "score": current_score,
        "n_rounds": round_i + 1,
    }

result = greedy_ensemble(model_names, oof_preds, y_true, metric, HIGHER_IS_BETTER)
print(f"\nEnsemble OOF: {result['score']:.5f}")
print(f"Weights: {result['weights']}")
```

## Step 5 — Weight Optimization with Scipy

Fine-tune weights after greedy selection narrows the candidate set.

```python
from scipy.optimize import minimize

def neg_metric(weights, preds_matrix, y_true, metric_fn):
    weights = np.array(weights)
    weights = np.abs(weights) / np.abs(weights).sum()   # normalize
    ensemble_pred = (preds_matrix * weights[:, None]).sum(axis=0)
    return -metric_fn(y_true, ensemble_pred)

selected_names = [k for k, v in result["weights"].items() if v > 0]
preds_matrix = np.stack([oof_preds[n] for n in selected_names], axis=0)

# Initial weights: proportional to individual scores
init_weights = np.array([individual_scores[n] for n in selected_names])
init_weights /= init_weights.sum()

opt = minimize(
    neg_metric,
    init_weights,
    args=(preds_matrix, y_true, metric),
    method="Nelder-Mead",
    options={"maxiter": 10000, "xatol": 1e-6, "fatol": 1e-6}
)

optimized_weights = np.abs(opt.x) / np.abs(opt.x).sum()
optimized_pred = (preds_matrix * optimized_weights[:, None]).sum(axis=0)
optimized_score = metric(y_true, optimized_pred)

print(f"\nOptimized OOF: {optimized_score:.5f}")
for name, w in zip(selected_names, optimized_weights):
    print(f"  {name}: {w:.4f}")
```

## Step 6 — Generate Test Predictions

```python
test_pred_dir = Path("test_preds")
final_test_pred = np.zeros(len(pd.read_csv("test.csv")))

for name, weight in zip(selected_names, optimized_weights):
    test_pred = np.load(test_pred_dir / f"{name}_test.npy")
    final_test_pred += weight * test_pred

np.save("ensemble/hill_climb_test_pred.npy", final_test_pred)
print(f"Saved final ensemble test prediction")
```

## Step 7 — Log Results

```python
import json

log = {
    "method": "hill_climbing_greedy",
    "individual_scores": individual_scores,
    "ensemble_score": optimized_score,
    "gain_over_best": optimized_score - best_score,
    "weights": {n: float(w) for n, w in zip(selected_names, optimized_weights)},
}
with open("experiments/hill_climbing.json", "w") as f:
    json.dump(log, f, indent=2)
print(f"Gain over best single model: +{optimized_score - best_score:.5f}")
```

## Output / Deliverables

- `ensemble/hill_climb_test_pred.npy` — final blended test prediction
- `experiments/hill_climbing.json` — weights, scores, gains logged
- Ensemble OOF CV score (must beat best individual model)

## Alternative: Optuna Weight Optimization (Better for > 5 Models)

When you have many models, Optuna's TPE sampler outperforms scipy for weight search:

```python
import optuna

def ensemble_objective(trial):
    weights = np.array([
        trial.suggest_float(f"w_{n}", 0.0, 1.0) for n in model_names
    ])
    weights /= weights.sum()
    pred = sum(w * oof_preds[n] for w, n in zip(weights, model_names))
    return metric(y_true, pred)

study = optuna.create_study(direction="maximize",
                             sampler=optuna.samplers.TPESampler(seed=42))
study.optimize(ensemble_objective, n_trials=500, show_progress_bar=True)
print(f"Optuna ensemble CV: {study.best_value:.5f}")
# See /kaggle-optuna for full Optuna weight optimization workflow
```

## Pitfalls

- Ensemble weight on one model > 0.8 → not actually ensembling. Add more diverse models.
- Optimizing weights on the full OOF without any holdout → slight overfitting to OOF noise.
- Ignoring correlation between model predictions → high correlation kills ensemble benefit.
- Running weight optimization before greedy selection → gets stuck in local optima with high-dimensional search.
- Using scipy Nelder-Mead with > 8 models → slow convergence. Switch to Optuna.

Next skills: `/kaggle-stacking`, `/kaggle-pseudo-labeling`, `/kaggle-optuna`
