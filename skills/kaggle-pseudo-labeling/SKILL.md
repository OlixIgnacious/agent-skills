---
name: kaggle-pseudo-labeling
description: Add high-confidence test predictions as soft labels to the training set, then retrain. Iterative multi-round approach for competitions with unlabeled test data. Most effective in semi-supervised settings with large test sets.
disable-model-invocation: true
allowed-tools: Bash Read
effort: high
---

# Skill: Pseudo-Labeling
**Technique #6 from NVIDIA Kaggle Grandmasters Playbook**

## When to Use

- Test set is significantly larger than train set (2x or more)
- You have a well-validated ensemble prediction (low CV variance)
- You're in the final week of competition (requires stable base predictions)
- The distribution shift between train and test is not extreme

**Do NOT use when:**
- Train and test have very different distributions (pseudo-labels will corrupt training)
- Your current model already overfits (adding noisy labels makes it worse)
- You have fewer than 3 rounds of improving CV scores to validate the approach

## Concept

```
Round 0: Train on labeled train set → predict test
Round 1: Add high-confidence test predictions to train → retrain → better test pred
Round 2: Update pseudo-labels with Round 1 model → add to train → retrain → ...
Repeat 2-4 rounds until CV stops improving
```

## Step 1 — Generate Initial Pseudo-Labels

```python
import numpy as np
import pandas as pd
from pathlib import Path

train = pd.read_csv("train_folds.csv")
test  = pd.read_csv("test.csv")

# Load current best ensemble test prediction
test_pred = np.load("ensemble/hill_climb_test_pred.npy")
test["pseudo_target"] = test_pred

TASK = "binary"  # or "regression"

if TASK == "binary":
    print(f"Test prediction distribution:")
    print(f"  < 0.1: {(test_pred < 0.1).mean():.2%}")
    print(f"  0.1-0.9: {((test_pred >= 0.1) & (test_pred <= 0.9)).mean():.2%}")
    print(f"  > 0.9: {(test_pred > 0.9).mean():.2%}")
```

## Step 2 — Threshold Selection for Hard Pseudo-Labels

```python
# For binary classification: only include very confident predictions
CONFIDENCE_THRESHOLD_HIGH = 0.85   # positives
CONFIDENCE_THRESHOLD_LOW  = 0.15   # negatives

confident_mask = (test_pred > CONFIDENCE_THRESHOLD_HIGH) | \
                 (test_pred < CONFIDENCE_THRESHOLD_LOW)

confident_test = test[confident_mask].copy()
confident_test["target"] = (confident_test["pseudo_target"] > 0.5).astype(int)
confident_test["fold"] = -1   # will be treated as always-train

print(f"Confident pseudo-label samples: {confident_mask.sum()} / {len(test)} "
      f"({confident_mask.mean():.1%})")
print(f"  Pseudo-positives: {(confident_test['target'] == 1).sum()}")
print(f"  Pseudo-negatives: {(confident_test['target'] == 0).sum()}")
```

## Step 3 — Soft Labels (often better than hard thresholding)

```python
# For regression or when you trust the model's calibration:
# Use predicted probabilities directly as targets (soft labels)

def soft_pseudo_label_train(train_df, test_df, test_predictions,
                             confidence_threshold: float = 0.0,
                             soft_weight: float = 0.5):
    """
    confidence_threshold: only include test samples where |pred - 0.5| > threshold
    soft_weight: sample weight given to pseudo-labeled examples (< 1 = downweight)
    """
    pseudo_df = test_df.copy()
    pseudo_df["target"] = test_predictions
    pseudo_df["fold"] = -1

    if confidence_threshold > 0:
        confidence = np.abs(test_predictions - 0.5)
        pseudo_df = pseudo_df[confidence > confidence_threshold]

    pseudo_df["sample_weight"] = soft_weight
    train_df["sample_weight"] = 1.0

    combined = pd.concat([train_df, pseudo_df], ignore_index=True)
    print(f"Training set: {len(train_df)} real + {len(pseudo_df)} pseudo = {len(combined)} total")
    return combined
```

## Step 4 — Retrain with Pseudo-Labels

```python
import lightgbm as lgb
from sklearn.metrics import roc_auc_score

feature_cols = [c for c in train.columns if c not in ["id", "target", "fold", "sample_weight"]]

def retrain_with_pseudo(combined_df, feature_cols, n_rounds: int = 3):
    best_test_pred = np.load("ensemble/hill_climb_test_pred.npy")
    base_oof = np.zeros(len(train))
    
    for round_num in range(1, n_rounds + 1):
        print(f"\n=== Pseudo-Label Round {round_num} ===")
        
        # Retrain on combined data using same fold structure
        oof_pred = np.zeros(len(train))
        test_preds_per_fold = []

        for fold in range(5):
            real_train_mask = (combined_df["fold"] != fold) & (combined_df["fold"] != -1)
            pseudo_mask     = combined_df["fold"] == -1
            val_mask        = combined_df["fold"] == fold

            # Always include pseudo-labels in training
            train_mask = real_train_mask | pseudo_mask

            X_tr  = combined_df.loc[train_mask, feature_cols]
            y_tr  = combined_df.loc[train_mask, "target"]
            w_tr  = combined_df.loc[train_mask, "sample_weight"] \
                    if "sample_weight" in combined_df else None
            X_val = combined_df.loc[val_mask, feature_cols]
            y_val = combined_df.loc[val_mask, "target"]

            model = lgb.LGBMClassifier(n_estimators=1000, learning_rate=0.05,
                                        num_leaves=63, verbose=-1, random_state=42)
            fit_kwargs = {"eval_set": [(X_val, y_val)],
                          "callbacks": [lgb.early_stopping(50, verbose=False)]}
            if w_tr is not None:
                fit_kwargs["sample_weight"] = w_tr
            
            model.fit(X_tr, y_tr, **fit_kwargs)
            oof_pred[val_mask.values[:len(train)]] = model.predict_proba(X_val)[:, 1]
            test_preds_per_fold.append(model.predict_proba(test[feature_cols])[:, 1])

        round_cv = roc_auc_score(train["target"], oof_pred[:len(train)])
        new_test_pred = np.mean(test_preds_per_fold, axis=0)

        print(f"Round {round_num} CV: {round_cv:.5f}")
        
        # Update pseudo-labels for next round
        combined_df.loc[combined_df["fold"] == -1, "target"] = new_test_pred
        best_test_pred = new_test_pred

    return best_test_pred

# Run
combined = soft_pseudo_label_train(train, test, test_pred,
                                    confidence_threshold=0.2, soft_weight=0.5)
final_pseudo_pred = retrain_with_pseudo(combined, feature_cols, n_rounds=3)
np.save("ensemble/pseudo_label_test.npy", final_pseudo_pred)
```

## Step 5 — Validate and Blend

```python
# Pseudo-labeling doesn't have a direct OOF score (test labels are unknown)
# Proxy validation: compare distribution of pseudo-label predictions across rounds
# If predictions become more extreme (0 or 1), the model is learning signal
# If predictions become more uniform (toward 0.5), it's getting confused

print("\nPrediction evolution (should become more confident):")
# Compare round 0 vs final round entropy
from scipy.stats import entropy

r0_dist = np.histogram(test_pred, bins=20, density=True)[0]
rf_dist = np.histogram(final_pseudo_pred, bins=20, density=True)[0]
print(f"Round 0 entropy: {entropy(r0_dist + 1e-8):.3f}")
print(f"Final entropy:   {entropy(rf_dist + 1e-8):.3f}  (lower = more confident = good)")

# Blend with hill climbing ensemble
PSEUDO_WEIGHT = 0.3  # tune based on CV signal
hc_pred = np.load("ensemble/hill_climb_test_pred.npy")
blended = (1 - PSEUDO_WEIGHT) * hc_pred + PSEUDO_WEIGHT * final_pseudo_pred
np.save("ensemble/pseudo_blend.npy", blended)
```

## Output / Deliverables

- `ensemble/pseudo_label_test.npy` — test predictions after pseudo-label training
- `ensemble/pseudo_blend.npy` — blended prediction with hill climbing
- Per-round CV scores logged
- Prediction entropy trend (validation that pseudo-labeling is learning, not degrading)

## Pitfalls

- **Using low-confidence pseudo-labels** → noisy labels corrupt training. Start at 0.85/0.15 thresholds.
- **Running too many rounds** → model overfits to its own predictions (confirmation bias). Cap at 3–4 rounds.
- **Not downweighting pseudo-labeled samples** → pseudo-labels dominate real labels. Always use `sample_weight < 1`.
- **No stopping criterion** → if round N CV < round N-1 CV, stop immediately.
- **Skipping when train ≫ test** — pseudo-labeling adds minimal data; skip and invest time in extra training instead.

Next skill: `/kaggle-extra-training`
