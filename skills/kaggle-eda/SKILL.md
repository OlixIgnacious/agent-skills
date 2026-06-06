---
name: kaggle-eda
description: Smarter EDA for Kaggle competitions. Goes beyond basic statistics to detect train/test distribution shift, temporal patterns, target leakage signals, and data quality issues that directly affect modeling decisions.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Smarter EDA
**Technique #1 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

Before any modeling. EDA informs fold type choice, feature engineering strategy, and baseline selection. Spend 10–20% of competition time here — it pays back 3–5x in avoided mistakes.

## Step 1 — Load and Profile

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

train = pd.read_csv("train.csv")
test  = pd.read_csv("test.csv")

print(f"Train: {train.shape}  |  Test: {test.shape}")
print(f"\nTarget distribution:\n{train['target'].describe()}")
print(f"\nTrain dtypes:\n{train.dtypes.value_counts()}")
print(f"\nMissing (train):\n{train.isnull().mean().sort_values(ascending=False).head(20)}")
print(f"\nMissing (test):\n{test.isnull().mean().sort_values(ascending=False).head(20)}")
```

## Step 2 — Train/Test Distribution Shift

Distribution shift means the test set comes from a different distribution than train. Features with high shift are either: (a) leaky, (b) temporal, or (c) unreliable for modeling.

```python
from scipy.stats import ks_2samp

feature_cols = [c for c in train.columns if c not in ["id", "target"]]
shift_report = []

for col in feature_cols:
    if train[col].dtype in [np.float64, np.float32, np.int64, np.int32]:
        tr = train[col].dropna()
        te = test[col].dropna()
        stat, pval = ks_2samp(tr, te)
        shift_report.append({"feature": col, "ks_stat": stat, "p_value": pval})

shift_df = pd.DataFrame(shift_report).sort_values("ks_stat", ascending=False)
print("Top distribution-shifted features:")
print(shift_df.head(20).to_string(index=False))

# Flag severe shift
high_shift = shift_df[shift_df["ks_stat"] > 0.2]["feature"].tolist()
print(f"\nHigh-shift features (KS > 0.2): {high_shift}")
```

**Action rules:**
- KS > 0.3: likely temporal or ID-linked — investigate, consider dropping or engineering carefully
- KS < 0.1: safe to use as-is

## Step 3 — Temporal Pattern Detection

```python
# Check if any column correlates with row order (temporal proxy)
for col in feature_cols[:20]:
    if train[col].dtype in [np.float64, np.float32]:
        corr = train[col].corr(pd.Series(range(len(train))))
        if abs(corr) > 0.3:
            print(f"TEMPORAL SIGNAL: {col} | row-order corr = {corr:.3f}")

# If a date column exists
if "date" in train.columns or any("date" in c.lower() for c in train.columns):
    date_col = [c for c in train.columns if "date" in c.lower()][0]
    train[date_col] = pd.to_datetime(train[date_col])
    train.set_index(date_col)["target"].resample("W").mean().plot()
    plt.title(f"Target over time ({date_col})")
    plt.savefig("target_over_time.png")
    print("TEMPORAL DATA DETECTED → use TimeSeriesSplit validation")
```

## Step 4 — Target Analysis

```python
target = train["target"]

# Classification
if target.nunique() < 20:
    print("Classification task")
    print(target.value_counts(normalize=True))
    imbalance_ratio = target.value_counts().max() / target.value_counts().min()
    if imbalance_ratio > 5:
        print(f"WARNING: Imbalanced ({imbalance_ratio:.1f}x) → use StratifiedKFold + class weights")

# Regression
else:
    print("Regression task")
    print(target.describe())
    skewness = target.skew()
    print(f"Skewness: {skewness:.3f}")
    if abs(skewness) > 1.0:
        print("Consider log-transforming target (log1p)")
    target.hist(bins=50)
    plt.savefig("target_distribution.png")
```

## Step 5 — Target Leakage Scan

```python
# Features that are almost perfectly correlated with target = likely leakage
leak_candidates = []
for col in feature_cols:
    if train[col].dtype in [np.float64, np.float32, np.int64]:
        corr = abs(train[col].corr(train["target"]))
        if corr > 0.95:
            leak_candidates.append((col, corr))

if leak_candidates:
    print("LEAKAGE CANDIDATES (|corr| > 0.95 with target):")
    for col, corr in sorted(leak_candidates, key=lambda x: -x[1]):
        print(f"  {col}: {corr:.4f}")
else:
    print("No obvious leakage detected")
```

## Step 6 — Categorical Feature Analysis

```python
cat_cols = train.select_dtypes(include="object").columns.tolist()
for col in cat_cols:
    n_train = train[col].nunique()
    n_test  = test[col].nunique() if col in test.columns else "N/A"
    # values in test not seen in train
    if col in test.columns:
        unseen = set(test[col].dropna().unique()) - set(train[col].dropna().unique())
        print(f"{col}: train_nunique={n_train}, test_nunique={n_test}, unseen_in_train={len(unseen)}")
    else:
        print(f"{col}: train_nunique={n_train} (not in test)")
```

High cardinality (> 100 unique values) → target encoding or embedding.
Unseen test values → handle with unknown category token.

## Step 7 — GPU-Accelerated EDA (if available)

```python
try:
    import cudf
    train_gpu = cudf.from_pandas(train)
    test_gpu  = cudf.from_pandas(test)
    print("cuDF loaded — EDA running on GPU")
    # All standard pandas operations work on cuDF
    corr_matrix = train_gpu[feature_cols].corr().to_pandas()
except ImportError:
    print("cuDF not available — running on CPU")
    corr_matrix = train[feature_cols].corr()

# Plot top correlations with target
target_corr = corr_matrix["target"].abs().sort_values(ascending=False)
print("Top 15 features by |correlation| with target:")
print(target_corr.head(15))
```

## Output / Deliverables

- `eda_report.md` — summary of key findings (data type, target type, temporal signal, leakage, shift)
- `train_folds.csv` — folds assigned (if not done yet — call `/kaggle-validation` first)
- Confirmed fold type decision
- List of high-shift features to watch
- List of high-cardinality categoricals and encoding strategy

## EDA Decision Summary Template

```
## EDA Findings

- Task type: [classification / regression]
- Target: [column name], [distribution notes]
- Temporal: [YES → TimeSeriesSplit | NO]
- Grouped: [YES → GroupKFold, group_col=X | NO]
- High-shift features: [list or "none"]
- Leakage candidates: [list or "none"]
- High-cardinality cats: [list with nunique counts]
- Recommended fold type: [StratifiedKFold(5) / TimeSeriesSplit(5) / GroupKFold(5)]
- Notes: [any other anomalies]
```

## Pitfalls

- Spending > 25% of competition time on EDA without touching a model — EDA is a means, not the end.
- Ignoring train/test shift — it will bite you at LB evaluation.
- Not checking for temporal signal before choosing KFold — shuffled time splits cause severe overfitting.
- Missing unseen categories in test — causes model errors at inference time.

Next skills: `/kaggle-validation` (if not done), then `/kaggle-baselines`
