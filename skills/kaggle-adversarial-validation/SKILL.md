---
name: kaggle-adversarial-validation
description: Detect train/test distribution shift by training a classifier to distinguish train from test rows. AUC near 0.5 means distributions match and CV is trustworthy. High AUC signals your CV will mislead you. Run before locking any fold strategy.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Adversarial Validation
**Critical pre-validation technique used by Kaggle Grandmasters**

## When to Use

- **Always** — run before any modeling on a new competition
- When your local CV doesn't correlate with public LB (diagnosis)
- When you suspect temporal or domain shift between train and test
- To build a validation set that mimics the test distribution

## What It Tells You

| AUC of adversarial classifier | Meaning |
|-------------------------------|---------|
| ~0.5 | Train and test are indistinguishable — CV is trustworthy |
| 0.6–0.7 | Moderate shift — identify which features cause it |
| > 0.75 | Severe shift — your random CV folds will mislead you |

## Step 1 — Run the Adversarial Classifier

```python
import pandas as pd
import numpy as np
import lightgbm as lgb
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import roc_auc_score

train = pd.read_csv("train.csv")
test  = pd.read_csv("test.csv")

# Drop target, keep only shared feature columns
shared_cols = [c for c in train.columns if c in test.columns
               and c not in ["id", "target"]]

train_adv = train[shared_cols].copy()
test_adv  = test[shared_cols].copy()

train_adv["is_test"] = 0
test_adv["is_test"]  = 1

combined = pd.concat([train_adv, test_adv], ignore_index=True)

X = combined[shared_cols]
y = combined["is_test"]

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
oof = np.zeros(len(combined))

for fold, (tr_idx, val_idx) in enumerate(skf.split(X, y)):
    model = lgb.LGBMClassifier(
        n_estimators=300, num_leaves=31, learning_rate=0.05,
        verbose=-1, random_state=fold, n_jobs=-1
    )
    model.fit(X.iloc[tr_idx], y.iloc[tr_idx])
    oof[val_idx] = model.predict_proba(X.iloc[val_idx])[:, 1]

auc = roc_auc_score(y, oof)
print(f"\nAdversarial AUC: {auc:.4f}")

if auc < 0.55:
    print("✓ Low shift — standard CV folds are trustworthy")
elif auc < 0.70:
    print("⚠ Moderate shift — investigate top features below")
else:
    print("✗ HIGH SHIFT — CV will mislead; use adversarial-based validation set")
```

## Step 2 — Identify Which Features Drive the Shift

```python
import pandas as pd
import matplotlib.pyplot as plt

feature_imp = pd.Series(
    model.feature_importances_,
    index=shared_cols
).sort_values(ascending=False)

print("\nTop features driving train/test shift:")
print(feature_imp.head(15).to_string())

# These features are candidates to:
# (a) drop if they're noise/ID proxies
# (b) engineer carefully if they carry real signal
# (c) use for stratified CV split to match test distribution

high_shift_features = feature_imp[feature_imp > feature_imp.mean() * 2].index.tolist()
print(f"\nHigh-shift features: {high_shift_features}")
```

## Step 3a — If Shift is Low: Proceed with Standard CV

```python
# AUC < 0.55 → use StratifiedKFold / TimeSeriesSplit / GroupKFold as normal
# See /kaggle-validation for fold selection
print("Proceeding with standard fold strategy.")
```

## Step 3b — If Shift is High: Build an Adversarial Validation Set

Use the test-like rows from train as your validation set. This creates a local validation that matches the test distribution — far more reliable than random folds.

```python
# Rows in TRAIN that the adversarial model predicted as "test-like"
train_adv_scores = oof[:len(train)]  # OOF scores for train rows only
train["adv_score"] = train_adv_scores

# Use the most test-like 20% of train as your local validation set
threshold = np.percentile(train["adv_score"], 80)
val_mask   = train["adv_score"] >= threshold
train_mask = train["adv_score"] <  threshold

print(f"Adversarial validation set: {val_mask.sum()} rows")
print(f"Adversarial train set:      {train_mask.sum()} rows")

# Save for use in other skills
train.loc[val_mask,   "fold"] = 0   # single held-out fold
train.loc[train_mask, "fold"] = 1   # training fold
train.to_csv("train_folds.csv", index=False)
```

## Step 4 — Feature Drop Decision

```python
from scipy.stats import ks_2samp

# For each high-shift feature: KS test to quantify how different it is
print("\nKS test for high-shift features:")
for col in high_shift_features:
    stat, pval = ks_2samp(train[col].dropna(), test[col].dropna())
    action = "DROP" if (stat > 0.3 and "id" in col.lower()) else "INVESTIGATE"
    print(f"  {col}: KS={stat:.3f}, p={pval:.4f} → {action}")
```

**Drop if:**
- Feature is an ID or row-number proxy (high shift, no real signal)
- Feature is missing in > 30% of test but present in train

**Keep but engineer carefully if:**
- Feature is temporal (date, sequence number) — extract relative features
- Feature has business meaning but different scale in test

## Step 5 — Use for CV-LB Calibration

After submitting 3+ times, check if adversarial-val CV correlates better with LB than random CV:

```python
# Compare: adversarial_val_score vs random_cv_score vs public_LB
# If adversarial correlates better → use it as your primary validation signal
cv_random = [0.891, 0.893, 0.895]
cv_adv     = [0.881, 0.884, 0.886]
lb_scores  = [0.880, 0.883, 0.885]

import numpy as np
r_random = np.corrcoef(cv_random, lb_scores)[0, 1]
r_adv    = np.corrcoef(cv_adv,    lb_scores)[0, 1]
print(f"Random CV–LB correlation: {r_random:.3f}")
print(f"Adversarial CV–LB corr:   {r_adv:.3f}")
```

## Output / Deliverables

- Adversarial AUC score (sanity metric for your CV)
- List of high-shift features with KS statistics
- `train_folds.csv` updated with adversarial-based splits (if shift is high)
- Decision: drop / keep / engineer each high-shift feature

## Gotchas

- **Don't drop every high-shift feature** — some carry real signal. Investigate before dropping.
- **Adversarial AUC > 0.5 on a small dataset is expected** — high variance with < 1K rows.
- **Using adversarial val as the only CV signal** → one fold = high variance. Use it alongside k-fold, weighted by shift severity.
- **If test is much larger than train**, adversarial AUC will naturally be higher (class imbalance). Use `scale_pos_weight` or `class_weight` to correct.
- **Running adversarial validation after feature engineering** → some engineered features may cause artificial shift. Run it on raw features first.

Next skill: `/kaggle-validation`
