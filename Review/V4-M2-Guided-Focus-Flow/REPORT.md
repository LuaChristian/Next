# V4-M2 — Guided Focus Flow

**Status:** Ready for PM re-review after visual corrections (not committed)  
**Date:** 2026-10-26  
**Simulator:** iPhone 16 / iOS 18.6 (also verified on iPhone 16e)

See `PM-CORRECTIONS.md` for the selected-state, Dynamic Type, and copy fixes.

## 1. Implementation summary

Help me decide is now a calm, page-by-page guided flow:

1. **Focus scope** — Anything / Life area / Specific goal  
2. **Available time** — 15 / 30 / 60 / 90+ presets plus exact **25 minutes**  
3. **Energy** — Low / Good / Ready  
4. **Recommendation** — existing `RecommendationEngine` + `RecommendationView`

Choose a task and Goal Detail FOCUS are unchanged and still share `FocusLaunch` → `FocusView`. No SwiftData schema changes. Ranking and eligibility rules are unchanged.

## 2. Files added and modified

### Added
- `Next/Features/Home/GuidedFocusFlow.swift` — `GuidedFocusDraft`, step enum, progress chrome
- `Next/Features/Home/GuidedTimeStepView.swift` — time step + exact 25-minute control
- `Next/Features/Home/GuidedEnergyStepView.swift` — energy step
- `Review/V4-M2-Guided-Focus-Flow/` — REPORT + screenshots 01–12

### Modified
- `Next/Features/Home/HelpMeDecideView.swift` — step-based guided host (no nested `NavigationStack`)
- `Next/Features/Home/HomeView.swift` — `TimeOption.twentyFive` + `standardPresets`
- `Next/Features/Home/RecommendationEngine.swift` — minutes mapping for `.twentyFive`
- `Next/Features/Home/RecommendationView.swift` — safer return-to-Home after Focus
- `Next/Core/SelectionOption.swift` — optional accessibility identifier
- `NextTests/NextTests.swift` — `GuidedFocusFlowTests`
- `NextUITests/NextUITests.swift` — guided helpers + V4-M2 coverage + visual review

## 3. Architecture summary

```
HomeView
  └─ navigationDestination(HomeFocusEntry.helpMeDecide)
       └─ HelpMeDecideView
            GuidedFocusDraft.step:
              scope → time → energy → recommendation
            Back: draft.goBack() or dismiss() on scope
            RecommendationView.fullScreenCover → FocusView
                 └─ .nextReturnToHomeEntry → dismiss Help me decide
```

- **No nested NavigationStack** for the guided path (avoids flaky path/`dismiss` races).
- One `@Observable` `GuidedFocusDraft` owns scope/time/energy/step.
- Progress label is `01 / 03` … `03 / 03` for the three input decisions (never a fake %).
- Choose a task / Goal Detail remain direct Focus paths.

## 4. Interaction decisions

| Topic | Decision |
|-------|----------|
| Advance | Explicit Continue / SEE WHAT'S NEXT (predictable, accessible) |
| Back | Single toolbar Back; preserves prior answers |
| Edit earlier answer | Returning to a step keeps selection; changing scope clears time/energy |
| Stale recommendation | Rebuilt from current draft when entering the recommendation step |
| 25 minutes | Exact custom row under presets; same eligibility math as other durations |
| Empty states | Existing recommendation empty kinds + scope empty copy |
| Motion | Subtle opacity step change; respects Reduce Motion |

## 5. Test commands and results

Device: **iPhone 16 (iOS 18.6)** simulator. Result bundle: `/tmp/Next-V4M2w.xcresult`.

```bash
xcodebuild test -scheme Next \
  -destination 'platform=iOS Simulator,id=E9B40575-3B7B-4B1F-A7FD-86142F7DA52E' \
  -only-testing:NextTests/GuidedFocusFlowTests \
  -only-testing:NextUITests/NextUITests/testV4M2GuidedScopeTimeEnergyRecommendation \
  -only-testing:NextUITests/NextUITests/testV4M2ExactTwentyFiveMinuteSelection \
  -only-testing:NextUITests/NextUITests/testV4M2BackPreservesSelectionsAndEditingRefreshesRecommendation \
  -only-testing:NextUITests/NextUITests/testV4M2NoEligibleTaskEmptyState \
  -only-testing:NextUITests/NextUITests/testV4M2VisualReview \
  -only-testing:NextUITests/NextUITests/testRecommendationFlow \
  -only-testing:NextUITests/NextUITests/testFocusSessionFromCurrentRecommendation \
  -only-testing:NextUITests/NextUITests/testV4M1ChooseTaskDirectFocusIgnoresRecommendationFilters \
  -only-testing:NextUITests/NextUITests/testV4M1GoalDetailDirectFocus \
  -only-testing:NextUITests/NextUITests/testV4M1DualHomeEntryPointsVisibleAndNavigate \
  -only-testing:NextUITests/NextUITests/testM1MultiAreaPlantEditAndScopeFiltering
```

### Actual results — **TEST SUCCEEDED**

| Area | Result |
|------|--------|
| `GuidedFocusFlowTests` (5) | **Pass** |
| V4-M2 UITests (5) | **Pass** |
| Recommendation + Focus return | **Pass** |
| Choose a task / Goal Detail / dual entry | **Pass** |
| Multi-area scope filtering | **Pass** |

Coverage mapped to brief items 1–12 via the V4-M2 UI cases + visual review + regressions above.

**Not claimed:** full `NextUITests` suite end-to-end.

## 6. Screenshot index

All under `Review/V4-M2-Guided-Focus-Flow/`:

| # | File |
|---|------|
| 01 | Home |
| 02 | Scope selection |
| 03 | Life area selection |
| 04 | Specific goal selection |
| 05 | Time selection, 25 minutes |
| 06 | Energy selection |
| 07 | Recommendation |
| 08 | Recommendation alternative |
| 09 | No eligible task |
| 10 | Direct Choose a task regression |
| 11 | Dark mode guided flow |
| 12 | Large text, small-screen behavior |

## 7. Known limitations

- Guided steps use an in-view step model rather than push navigation; Back is an explicit toolbar control (system chevron hidden on this screen).
- Full `NextUITests` suite was not executed as one job in this milestone pass.
- Screenshot 12 filename uses a comma (not `/`) so the path stays a single file.

## 8. Follow-up recommendations

- Optional: collapse Home dual-entry and guided chrome further if PM wants less nested toolbar chrome.
- Optional: auto-advance on time/energy chip selection once a11y review confirms it feels safer than Continue.
- Run full UITest suite before release cut.

## 9. PM approval recommendation

**Recommend approval.** Guided Scope → Time → Energy → Recommendation is live, 25-minute exact selection works, Choose a task / Goal Detail / Focus safety paths remain intact, ranking unchanged, targeted tests and screenshots are green.

**Do not commit or push until PM sign-off.**
