# Cost suggestion

The meal editor offers a local, rule-based starting price using existing SQLite purchase logs. No cloud service or trained model is used.

The pure Dart function `suggestCost` takes a meal ID, log rows, and the current time. It selects the three most recent purchases at or before that time, ordered by date descending, then ID descending. It averages integer-cent prices and rounds to the nearest cent, halves up. With three integer inputs, an exact half-cent tie cannot occur. Three purchases smooth some variation while keeping all inputs visible.

Inputs are `meal_id`, `id`, `price_paid_cents`, and `purchased_at`. Amounts use US cents; displayed dates use UTC. Invalid history blocks the estimate with feedback. Negative entered prices cannot be saved. Fewer than three valid purchases shows "Not enough history."

The editor reads saved logs on each opening and shows the estimate, three prices, date range, and explanation. Applying fills the price field only. Users can ignore or edit it; only Save stores the meal.

## Manual evaluation

Five synthetic cases were run through the function using a temporary Dart console script. Inputs are dated January 3, 2, and 1, 2026, newest first, at midnight UTC. The cutoff is January 4; reference outcomes are January 5 and excluded from predictions.

The baseline uses the last eligible purchase price. All table amounts are cents. Error is `abs(prediction - reference)`.

| Case | Inputs | Reference | Expected helper / baseline | Actual helper / baseline | Absolute errors | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Normal | 1000, 1200, 1100 | 1150 | 1100 / 1000 | 1100 / 1000 | 50 / 150 | Pass |
| Insufficient history | 1000, 1200 | None | No estimate | No estimate; two valid inputs | Not evaluated | Pass |
| Invalid input | 1000, 1200, -100 | None | Reject negative; no estimate | invalid=true; no estimate | Not evaluated | Pass |
| Rounding/boundary | 0, 1, 1 | 1 | 1 / 0 | 1 / 0 | 0 / 1 | Pass |
| Expensive outlier | 1000, 4000, 1000 | 1000 | 2000 / 1000 | 2000 / 1000 | 1000 / 0 | Pass |

Across three valid predictions, total absolute errors are 1050 cents for the helper and 151 for the baseline. Mean absolute errors are $3.50 and about $0.5033. Pass means expected behavior, not better accuracy.

The expensive outlier makes the average worse than the baseline, so keep the suggestion advisory. A median of three could resist this outlier but is not implemented. This small sample does not establish real-world accuracy.

## Checks

`flutter analyze`: no issues. Pre-existing preference tests are unchanged; no helper tests remain. Editor controls/messages, corrected or deleted SQLite history, phone layout, offline use, and full app restart are unverified in this manual evaluation.
