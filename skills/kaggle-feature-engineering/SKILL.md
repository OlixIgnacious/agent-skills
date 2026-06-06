---
name: kaggle-feature-engineering
description: Feature engineering at scale for Kaggle competitions. Covers groupby aggregations, interaction features, target encoding (CV-safe), lag/rolling features for time series, and GPU-accelerated feature generation with cuDF. Run after baselines to measure delta impact of each feature batch.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Feature Engineering at Scale
**Technique #3 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

After establishing baselines. Every new feature batch is measured against the baseline CV score — only keep features that improve. Iterate between this skill and `/kaggle-baselines` until CV plateaus for 2–3 iterations.

## Discipline

**Always measure impact.** Engineer features in batches, retrain, compare CV delta:
```
baseline CV: 0.8910
+ groupby aggs: 0.8943  (+0.0033) ✓ keep
+ interaction: 0.8941  (+0.0031) ✓ keep
+ target enc:  0.8947  (+0.0037) ✓ keep
+ 50 random:   0.8940  (+0.0030) ✓ keep only top 20
```

## Step 1 — GPU-Accelerated Feature Generation

```python
try:
    import cudf
    import cupy as cp
    df = cudf.read_csv("train_folds.csv")
    test = cudf.read_csv("test.csv")
    USING_GPU = True
    print(f"GPU mode: {df.shape}")
except ImportError:
    import pandas as pd
    df = pd.read_csv("train_folds.csv")
    test = pd.read_csv("test.csv")
    USING_GPU = False
    print("CPU mode")
```

## Step 2 — Groupby Aggregations

The highest-EV feature engineering technique for tabular data.

```python
def add_groupby_features(df, group_cols: list, value_cols: list,
                         aggs: list = ["mean", "std", "min", "max", "median"]):
    new_features = []
    for group in group_cols:
        for val in value_cols:
            grouped = df.groupby(group)[val].agg(aggs)
            grouped.columns = [f"{group}_{val}_{a}" for a in aggs]
            df = df.merge(grouped.reset_index(), on=group, how="left")
            new_features.extend(grouped.columns.tolist())
    print(f"Added {len(new_features)} groupby features")
    return df, new_features

# Example: group by categorical features, aggregate numerical features
cat_cols  = ["category_a", "category_b", "category_c"]   # replace with actual cols
num_cols  = ["amount", "quantity", "value"]                 # replace with actual cols

df, new_feats = add_groupby_features(df, cat_cols, num_cols)
```

### Multi-level groupby (pairs of categoricals)

```python
from itertools import combinations

pair_groups = list(combinations(cat_cols, 2))
for g1, g2 in pair_groups[:10]:   # cap at 10 pairs to avoid explosion
    group_key = [g1, g2]
    for val in num_cols[:3]:
        agg = df.groupby(group_key)[val].mean().reset_index()
        agg.rename(columns={val: f"{g1}_{g2}_{val}_mean"}, inplace=True)
        df = df.merge(agg, on=group_key, how="left")
```

## Step 3 — Interaction Features

```python
from itertools import combinations

def add_interactions(df, cols: list, max_pairs: int = 50):
    pairs = list(combinations(cols, 2))[:max_pairs]
    new = []
    for a, b in pairs:
        df[f"{a}_x_{b}"] = df[a] * df[b]
        df[f"{a}_div_{b}"] = df[a] / (df[b].replace(0, 1e-6))
        df[f"{a}_minus_{b}"] = df[a] - df[b]
        new.extend([f"{a}_x_{b}", f"{a}_div_{b}", f"{a}_minus_{b}"])
    print(f"Added {len(new)} interaction features")
    return df, new

# Use top features by importance from baseline
important_features = ["feat1", "feat2", "feat3", "feat4", "feat5"]
df, interaction_feats = add_interactions(df, important_features)
```

## Step 4 — Target Encoding (CV-safe)

**Critical:** Target statistics must be computed inside each fold, never on the full training set.

```python
import numpy as np

def target_encode_cv_safe(df: "pd.DataFrame", 
                           cat_col: str, 
                           target_col: str = "target",
                           smoothing: float = 20.0) -> "pd.DataFrame":
    """
    Computes target encoding inside each fold to prevent leakage.
    Smoothing formula: (n_cat * cat_mean + global_mean * smoothing) / (n_cat + smoothing)
    """
    global_mean = df[target_col].mean()
    df[f"{cat_col}_te"] = np.nan

    for fold in df["fold"].unique():
        val_mask  = df["fold"] == fold
        train_mask = ~val_mask

        stats = df.loc[train_mask].groupby(cat_col)[target_col].agg(["mean", "count"])
        stats["smoothed"] = (
            (stats["count"] * stats["mean"] + smoothing * global_mean)
            / (stats["count"] + smoothing)
        )
        df.loc[val_mask, f"{cat_col}_te"] = (
            df.loc[val_mask, cat_col].map(stats["smoothed"]).fillna(global_mean)
        )

    return df

for col in cat_cols:
    df = target_encode_cv_safe(df, col)
```

## Step 5 — Lag and Rolling Features (Time Series)

Only use when temporal ordering is confirmed from EDA.

```python
def add_time_features(df, date_col: str, value_cols: list,
                       group_col: str = None,
                       lags: list = [1, 2, 3, 7, 14, 28],
                       windows: list = [3, 7, 14, 28]):
    df = df.sort_values(date_col)
    
    for val in value_cols:
        series = df.groupby(group_col)[val] if group_col else df[val]
        
        # Lag features
        for lag in lags:
            col_name = f"{val}_lag_{lag}"
            df[col_name] = series.shift(lag) if not group_col else series.shift(lag).reset_index(level=0, drop=True)
        
        # Rolling statistics
        for w in windows:
            shifted = series.shift(1)
            if group_col:
                shifted = shifted.reset_index(level=0, drop=True)
            df[f"{val}_roll_mean_{w}"] = shifted.rolling(w, min_periods=1).mean()
            df[f"{val}_roll_std_{w}"]  = shifted.rolling(w, min_periods=1).std()
            df[f"{val}_roll_max_{w}"]  = shifted.rolling(w, min_periods=1).max()
    
    return df
```

## Step 6 — Feature Selection After Each Batch

Don't blindly add all features. Select by importance to avoid noise.

```python
import lightgbm as lgb
import pandas as pd

def get_feature_importance(df, feature_cols, target_col="target", fold=0):
    tr = df[df["fold"] != fold]
    val = df[df["fold"] == fold]
    
    model = lgb.LGBMRegressor(n_estimators=200, verbose=-1, n_jobs=-1)
    model.fit(tr[feature_cols], tr[target_col],
              eval_set=[(val[feature_cols], val[target_col])],
              callbacks=[lgb.early_stopping(20, verbose=False)])
    
    imp = pd.Series(model.feature_importances_, index=feature_cols).sort_values(ascending=False)
    return imp

# Drop zero-importance features
imp = get_feature_importance(df, feature_cols)
zero_imp = imp[imp == 0].index.tolist()
print(f"Dropping {len(zero_imp)} zero-importance features")
feature_cols = [f for f in feature_cols if f not in zero_imp]
```

## Step 7 — GPU-Accelerated Aggregations with cuDF

```python
# cuDF drop-in for pandas groupby — 10-100x faster
if USING_GPU:
    # All pandas groupby operations work identically on cuDF
    gpu_agg = df.groupby("category_a").agg({"value": ["mean", "std", "count"]})
    gpu_agg.columns = ["category_a_value_mean", "category_a_value_std", "category_a_value_count"]
    df = df.merge(gpu_agg.reset_index(), on="category_a", how="left")
```

## Feature Engineering Experiment Log Template

```
## Experiment: [batch name]
Date: YYYY-MM-DD
Features added: [list]
Baseline CV: 0.XXXX
New CV: 0.XXXX
Delta: +0.XXXX
Decision: KEEP / DROP
Notes: [why it worked or didn't]
```

## Output / Deliverables

- `train_features.csv` / `test_features.csv` — full feature matrices
- `feature_log.md` — which batches were kept and their CV delta
- Updated `feature_cols` list for downstream skills
- Feature importance plot saved to `artifacts/feature_importance.png`

## Pitfalls

- Target encoding without fold isolation → largest single source of leakage in Kaggle.
- Adding 500 features at once without measuring impact → impossible to attribute gains.
- Interaction features between low-importance features → noise, hurts generalization.
- Lag features without sorting by time first → random noise that looks like signal.
- Not applying identical feature engineering to test set → train/test feature mismatch.

Next skills: `/kaggle-hill-climbing`, `/kaggle-stacking`
