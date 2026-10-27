# V4-M2 PM Corrections

**Status:** Ready for PM re-review (not committed)  
**Date:** 2026-10-26

## Fixes

### 1. Selected states
`SelectionOption` now uses a clearer editorial selected treatment:
- Lavender text weight
- Adjacent checkmark
- Slightly stronger lavender underline

Accessibility keeps `.isSelected` + value `"Selected"` / `"Not selected"`.  
No cards, gradients, or filled buttons.

### 2. Large Dynamic Type layout
- Opaque navigation-bar canvas background so content no longer draws under the status bar / Back
- Progress (`01 / 03`) lives in scroll content below the bar (never overlaps Back)
- ScrollView remains the content host; text is not scaled down to fit
- Continue remains reachable via scroll

### 3. Copy
Time helper copy is now: **“Choose how much time you have.”**

### 4. Unchanged
Guided draft/step architecture, ranking, eligibility, Not This One, FocusLaunch/FocusView, Choose a task, SwiftData schema.

## Updated screenshots

| File | What to verify |
|------|----------------|
| `05 — Time selection, 25 minutes.png` | 25 min selected (lavender + check + underline); new copy |
| `06 — Energy selection.png` | Good selected with same treatment |
| `11 — Dark mode guided flow.png` | 30 min selected in dark mode |
| `12 — Large text, small-screen behavior.png` | Back clear of status bar; progress below Back; no overlap |

## Test results

### iPhone 16 (iOS 18.6) — `/tmp/Next-V4M2-fix.xcresult`
**TEST SUCCEEDED**

- `GuidedFocusFlowTests` (5)
- `testV4M2GuidedScopeTimeEnergyRecommendation`
- `testV4M2ExactTwentyFiveMinuteSelection`
- `testV4M2BackPreservesSelectionsAndEditingRefreshesRecommendation`
- `testV4M2NoEligibleTaskEmptyState`
- `testV4M2VisualReview`
- `testRecommendationFlow`
- `testFocusSessionFromCurrentRecommendation`
- `testV4M1ChooseTaskDirectFocusIgnoresRecommendationFilters`
- `testV4M1GoalDetailDirectFocus`

### iPhone 16e (smaller) — `/tmp/Next-V4M2-fix-se.xcresult`
**TEST SUCCEEDED** — `testV4M2VisualReview`, `testV4M2GuidedScopeTimeEnergyRecommendation`

### Recapture after XL Dynamic Type shot fix — `/tmp/Next-V4M2-fix2.xcresult`
**TEST SUCCEEDED** — `testV4M2VisualReview`

**Do not commit or push until PM sign-off.**
