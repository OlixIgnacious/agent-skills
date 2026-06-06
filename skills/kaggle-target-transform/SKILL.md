---
name: kaggle-target-transform
description: Target and prediction transformations for Kaggle — log/sqrt target transforms for skewed regression targets, winsorization for outlier robustness, isotonic regression for probability calibration, and beta-sharpening for confidence-boosting predictions. Apply before training and reverse after.
disable-model-invocation: true
allowed-tools: Bash Read
effort: medium
---

# Skill: Target & Prediction Transformations
**Grandmaster technique for squeezing performance from regression and probability tasks**

## When to Use

- **Log/sqrt transform**: Regression target is right-skewed (skewness > 1.0)
- **Winsorization**: Outliers in train target or features are distorting gradient updates
- **Calibration**: Your model's predicted probabilities are not well-calibrated (Brier score is high, reliability diagram shows systematic bias)
- **Beta sharpening**: Competition metric rewards confident predictions (e.g., MAP@K, or AUC where sharp predictions help)

## Step 1 — Diagnose the Target

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import skew

train = pd.read_csv("train_folds.csv")
target = train["target"]

print(f"Skewness: {skew(target):.3f}")
print(f"Min: {target.min():.4f}  Max: {target.max():.4f}")
print(f"% zeros: {(target == 0).mean():.2%}")

target.hist(bins=50)
plt.title("Target distribution")
plt.savefig("artifacts/target_dist.png")
```

| Skewness | Recommended transform |
|----------|-----------------------|
| > 1.5 | log1p (log(1+y)) |
| 0.5–1.5 | sqrt or box-cox |
| < 0.5 | No transform needed |
| Zero-inflated | Two-stage model (binary + regression) |

## Step 2 — Log Transform (Most Common)

```python
# Apply before training
train["target_orig"] = train["target"].copy()
train["target"] = np.log1p(train["target"])   # log(1+y) handles zeros

# Verify — should be approximately normal
print(f"Transformed skewness: {skew(train['target']):.3f}")

# ... train all models on transformed target ...

# Reverse after prediction (apply to test predictions)
def reverse_log(pred: np.ndarray) -> np.ndarray:
    return np.expm1(pred)   # exp(x) - 1

test_pred_raw = model.predict(test[feature_cols])
test_pred = reverse_log(test_pred_raw)
```

## Step 3 — Winsorization

Clip extreme values to reduce outlier influence on gradient updates.

```python
from scipy.stats import mstats

def winsorize_features(df: pd.DataFrame, feature_cols: list,
                        lower: float = 0.01, upper: float = 0.99) -> pd.DataFrame:
    df = df.copy()
    for col in feature_cols:
        if df[col].dtype in [np.float64, np.float32, np.int64]:
            lo = df[col].quantile(lower)
            hi = df[col].quantile(upper)
            n_clipped = ((df[col] < lo) | (df[col] > hi)).sum()
            if n_clipped > 0:
                df[col] = df[col].clip(lo, hi)
    return df

def winsorize_target(train: pd.DataFrame, target_col: str = "target",
                      upper_pct: float = 0.99) -> tuple:
    cap = train[target_col].quantile(upper_pct)
    n_clipped = (train[target_col] > cap).sum()
    print(f"Winsorizing target: clipping {n_clipped} rows above {cap:.4f}")
    train = train.copy()
    train[target_col] = train[target_col].clip(upper=cap)
    return train, cap

train, target_cap = winsorize_target(train)
feature_cols = [c for c in train.columns if c not in ["id", "target", "fold"]]
train = winsorize_features(train, feature_cols)
```

## Step 4 — Probability Calibration (Isotonic Regression)

Post-process binary classification probabilities so they're actually probabilities.

```python
from sklearn.calibration import CalibratedClassifierCV, calibration_curve
import matplotlib.pyplot as plt

# Diagnose: reliability diagram (calibration curve)
def plot_calibration(y_true: np.ndarray, y_pred: np.ndarray, label: str = "Model"):
    fraction_pos, mean_pred = calibration_curve(y_true, y_pred, n_bins=10)
    plt.figure(figsize=(6, 6))
    plt.plot([0, 1], [0, 1], "k--", label="Perfectly calibrated")
    plt.plot(mean_pred, fraction_pos, "s-", label=label)
    plt.xlabel("Mean predicted probability")
    plt.ylabel("Fraction of positives")
    plt.legend()
    plt.savefig(f"artifacts/calibration_{label}.png")

# OOF calibration: fit isotonic regression on OOF predictions
from sklearn.isotonic import IsotonicRegression

oof_pred = np.load("oof/lgb_oof.npy")
y_true   = train["target"].values

# Split OOF into calibration train / val (80/20)
n = len(oof_pred)
idx = np.random.RandomState(42).permutation(n)
cal_tr  = idx[:int(0.8 * n)]
cal_val = idx[int(0.8 * n):]

iso = IsotonicRegression(out_of_bounds="clip")
iso.fit(oof_pred[cal_tr], y_true[cal_tr])

oof_calibrated = iso.transform(oof_pred)
plot_calibration(y_true, oof_pred, "Uncalibrated")
plot_calibration(y_true, oof_calibrated, "Isotonic")

print(f"Pre-calibration:  {roc_auc_score(y_true, oof_pred):.5f}")
print(f"Post-calibration: {roc_auc_score(y_true, oof_calibrated):.5f}")

# Apply same isotonic transform to test predictions
test_pred = np.load("test_preds/lgb_test.npy")
test_pred_calibrated = iso.transform(test_pred)
np.save("test_preds/lgb_test_calibrated.npy", test_pred_calibrated)
```

## Step 5 — Beta Sharpening

Push predictions away from 0.5 toward 0/1. Useful when the competition metric rewards confident predictions.

```python
def sharpen_predictions(pred: np.ndarray, beta: float = 0.5) -> np.ndarray:
    """
    beta < 1: sharpen (push toward 0/1)
    beta = 1: no change
    beta > 1: soften (push toward 0.5)
    """
    return pred ** beta / (pred ** beta + (1 - pred) ** beta)

# Try different beta values on OOF to find optimal
from sklearn.metrics import roc_auc_score

betas = [0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 1.3]
print("Beta sharpening search:")
for beta in betas:
    sharpened = sharpen_predictions(oof_pred, beta)
    score = roc_auc_score(y_true, sharpened)
    print(f"  beta={beta}: {score:.5f}")

# Note: AUC is rank-invariant to monotonic transforms
# Sharpening only helps for metrics like Brier score, log loss, or MAP@K
```

## Step 6 — Two-Stage Modeling for Zero-Inflated Targets

```python
# Stage 1: binary — does the event occur at all?
# Stage 2: regression — given it occurs, what is the magnitude?

import numpy as np

def two_stage_predict(train, test, feature_cols):
    y_binary = (train["target"] > 0).astype(int)
    y_amount  = train.loc[train["target"] > 0, "target"]
    
    # Stage 1: classify occurrence
    model_binary = lgb.LGBMClassifier(n_estimators=500, verbose=-1)
    model_binary.fit(train[feature_cols], y_binary)
    prob_occur = model_binary.predict_proba(test[feature_cols])[:, 1]
    
    # Stage 2: regress magnitude (only on positive samples)
    pos_train = train[train["target"] > 0]
    model_amount = lgb.LGBMRegressor(n_estimators=500, verbose=-1)
    model_amount.fit(pos_train[feature_cols], np.log1p(y_amount))
    pred_amount = np.expm1(model_amount.predict(test[feature_cols]))
    
    # Combine
    final_pred = prob_occur * pred_amount
    return final_pred
```

## Output / Deliverables

- `artifacts/target_dist.png` — pre/post transform distributions
- `artifacts/calibration_*.png` — reliability diagrams
- `test_preds/*_calibrated.npy` — calibrated test predictions
- Optimal beta value logged
- Target cap value for winsorization (needed to reverse transform)

## Gotchas

- **Applying log1p when target has negatives** → NaN. Add offset: `log1p(target - target.min() + 1)`.
- **Calibrating on the same data used for training** → overfits the calibration. Always use held-out OOF.
- **Applying calibration before computing ensemble weights** vs. after — order matters. Calibrate individual models, then ensemble, then re-evaluate.
- **Beta sharpening doesn't help AUC** — AUC is rank-invariant to monotonic transforms. Only use for log loss, Brier, or MAP@K.
- **Winsorizing test features with train quantiles** → correct. Never compute test quantiles from test data alone.
- **Not reversing log transform** → predictions in log space are meaningless for submission. Always apply `expm1` before submitting.

Next skill: `/kaggle-extra-training`
