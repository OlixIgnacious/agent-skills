---
name: kaggle-validation
description: Design and lock the validation strategy for a Kaggle competition. Covers fold type selection (KFold, StratifiedKFold, TimeSeriesSplit, GroupKFold), CV-LB correlation verification, and out-of-fold prediction framework. Run this before any feature engineering or modeling.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Validation Strategy
**Cross-cutting foundation — run before any other modeling skill**

## When to Use

Immediately after EDA, before writing a single model. Changing validation strategy mid-competition destroys comparability of all prior experiments. Lock it once and never change it.

## Step 0 — Run Adversarial Validation First

Before choosing a fold type, check if train and test come from the same distribution. A high adversarial AUC means random folds will mislead you.

```python
# Quick check — run /kaggle-adversarial-validation for full analysis
import lightgbm as lgb
import numpy as np
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import cross_val_score

train = pd.read_csv("train.csv")
test  = pd.read_csv("test.csv")
shared = [c for c in train.columns if c in test.columns and c not in ["id", "target"]]

adv_X = pd.concat([train[shared].assign(is_test=0),
                   test[shared].assign(is_test=1)], ignore_index=True)
adv_y = adv_X.pop("is_test")

adv_score = cross_val_score(
    lgb.LGBMClassifier(n_estimators=100, verbose=-1),
    adv_X, adv_y, cv=5, scoring="roc_auc"
).mean()
print(f"Adversarial AUC: {adv_score:.4f}")
# < 0.55: proceed normally | > 0.70: run /kaggle-adversarial-validation
```

## Step 1 — Choose Your Fold Type

**Decision tree:**

```
Is the test set drawn from a future time period?
├── YES → TimeSeriesSplit (never shuffle temporal data)
│         └── Are groups present (e.g., customer_id appears in train AND test)?
│             └── YES → GroupTimeSeriesSplit (rare, requires custom implementation)
└── NO  → Are groups present that must not leak across folds?
          ├── YES → GroupKFold(n_splits=5, group_col="<id_column>")
          └── NO  → Is it multi-label classification?
                    ├── YES → MultilabelStratifiedKFold (iterative-stratification library)
                    └── NO  → Is it classification with imbalanced classes?
                              ├── YES → StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
                              └── NO  → KFold(n_splits=5, shuffle=True, random_state=42)
```

**Use 5 folds as the default.** 10 folds only when dataset < 5000 rows.

### MultilabelStratifiedKFold

```python
# pip install iterative-stratification
from iterstrat.ml_stratifiers import MultilabelStratifiedKFold

mlskf = MultilabelStratifiedKFold(n_splits=5, shuffle=True, random_state=42)
y_multilabel = train[label_cols].values  # shape: (n_samples, n_labels)

for fold, (tr_idx, val_idx) in enumerate(mlskf.split(train, y_multilabel)):
    train.loc[val_idx, "fold"] = fold
```

## Step 2 — Lock Fold Indices Early

Generate and save fold assignments to disk before any feature engineering. Every experiment must use the same splits.

```python
import numpy as np
import pandas as pd
from sklearn.model_selection import StratifiedKFold, KFold, GroupKFold
from sklearn.model_selection import TimeSeriesSplit

def create_folds(df: pd.DataFrame, 
                 target_col: str = "target",
                 fold_type: str = "stratified",  # stratified | kfold | time | group
                 group_col: str = None,
                 n_splits: int = 5,
                 random_state: int = 42) -> pd.DataFrame:
    df = df.copy()
    df["fold"] = -1

    if fold_type == "stratified":
        skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=random_state)
        for fold, (_, val_idx) in enumerate(skf.split(df, df[target_col])):
            df.loc[val_idx, "fold"] = fold

    elif fold_type == "kfold":
        kf = KFold(n_splits=n_splits, shuffle=True, random_state=random_state)
        for fold, (_, val_idx) in enumerate(kf.split(df)):
            df.loc[val_idx, "fold"] = fold

    elif fold_type == "time":
        tss = TimeSeriesSplit(n_splits=n_splits)
        for fold, (_, val_idx) in enumerate(tss.split(df)):
            df.loc[val_idx, "fold"] = fold

    elif fold_type == "group":
        assert group_col is not None, "group_col required for GroupKFold"
        gkf = GroupKFold(n_splits=n_splits)
        for fold, (_, val_idx) in enumerate(gkf.split(df, df[target_col], df[group_col])):
            df.loc[val_idx, "fold"] = fold

    assert (df["fold"] == -1).sum() == 0, "Some rows unassigned to folds"
    return df

# Usage
df = pd.read_csv("train.csv")
df = create_folds(df, target_col="target", fold_type="stratified")
df.to_csv("train_folds.csv", index=False)
print(df["fold"].value_counts().sort_index())
```

## Step 3 — OOF Prediction Framework

Use this template for every model. It accumulates out-of-fold predictions for ensembling.

```python
import numpy as np
from typing import Callable, Any

def train_with_oof(df: pd.DataFrame,
                   feature_cols: list[str],
                   target_col: str,
                   model_fn: Callable,          # factory: returns a fresh model
                   predict_fn: Callable,         # (model, X) → predictions
                   metric_fn: Callable,          # (y_true, y_pred) → float
                   n_folds: int = 5) -> dict:
    oof_preds = np.zeros(len(df))
    models = []

    for fold in range(n_folds):
        train_mask = df["fold"] != fold
        val_mask   = df["fold"] == fold

        X_tr, y_tr = df.loc[train_mask, feature_cols], df.loc[train_mask, target_col]
        X_val, y_val = df.loc[val_mask, feature_cols], df.loc[val_mask, target_col]

        model = model_fn()
        model.fit(X_tr, y_tr)

        oof_preds[val_mask] = predict_fn(model, X_val)
        fold_score = metric_fn(y_val, oof_preds[val_mask])
        print(f"Fold {fold}: {fold_score:.5f}")
        models.append(model)

    overall = metric_fn(df[target_col], oof_preds)
    print(f"\nOOF Score: {overall:.5f}")
    return {"oof_preds": oof_preds, "models": models, "score": overall}
```

## Step 4 — Verify CV–LB Correlation

After your first 3–5 submissions, plot local CV vs public LB scores. If they don't correlate, your validation is broken.

```python
import matplotlib.pyplot as plt

cv_scores  = [0.891, 0.893, 0.895, 0.888, 0.897]  # fill in
lb_scores  = [0.884, 0.886, 0.889, 0.881, 0.890]  # fill in

plt.scatter(cv_scores, lb_scores)
plt.xlabel("Local CV"); plt.ylabel("Public LB")
for i, (cv, lb) in enumerate(zip(cv_scores, lb_scores)):
    plt.annotate(f"sub{i+1}", (cv, lb))
plt.title("CV vs LB Correlation")
plt.savefig("cv_lb_correlation.png")
```

Pearson r > 0.9: trust your CV. r < 0.7: investigate immediately.

## Step 5 — Validation Checklist

- [ ] Fold type chosen based on data structure (temporal / grouped / random)
- [ ] Fold indices saved to `train_folds.csv` before any feature engineering
- [ ] OOF framework tested on a trivial baseline (e.g., mean prediction)
- [ ] No future data visible in any training fold
- [ ] Target encoding / statistics computed per-fold (not on full train)
- [ ] CV–LB correlation established after first 3 submissions

## Output

- `train_folds.csv` — train data with `fold` column attached
- `oof_baseline.npy` — OOF predictions from trivial baseline for sanity check
- Baseline CV score logged (used as the "0" in all future delta comparisons)

## Pitfalls

- **Shuffling time series data** → future leaks into training folds. Always use TimeSeriesSplit.
- **Computing target statistics on full train** → leaks into validation folds. Always compute inside each fold.
- **Changing fold seed mid-competition** → all prior experiment scores become incomparable.
- **Using public LB as a fold selection signal** → overfits to the 20–30% public test split.

Next skill: `/kaggle-eda`
