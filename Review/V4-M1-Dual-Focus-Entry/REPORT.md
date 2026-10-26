# V4-M1 — Dual Focus Entry Points

**Status:** Ready for PM review (not committed)  
**Date:** 2026-10-26  
**Simulator:** iPhone 16 / iOS 18.6

## 1. Implementation summary

Home now presents two equally prominent starting points instead of inlining time/energy selection:

1. **Help me decide** — opens the existing guided recommendation experience (time, energy, scope → `RecommendationEngine` → Focus).
2. **Choose a task** — opens a searchable goal list → incomplete tasks → the same `FocusView`.

Goal Detail also gained a compact **FOCUS** action per incomplete task, sharing `FocusLaunch` with Choose a task. No SwiftData schema changes. Recommendation ranking is unchanged.

## 2. Files added and modified

### Added
- `Next/Features/Focus/FocusLaunch.swift` — shared launch boundary + `HomeFocusEntry`
- `Next/Features/Home/HelpMeDecideView.swift` — relocated guided inputs
- `Next/Features/Home/ChooseTaskView.swift` — goal/task direct selection (+ `ChooseTaskTasksView`)
- `Review/V4-M1-Dual-Focus-Entry/` — REPORT + screenshots 01–12

### Modified
- `Next/Features/Home/HomeView.swift` — dual-entry Home; typed `navigationDestination`
- `Next/Features/Home/RecommendationView.swift` — posts `.nextReturnToHomeEntry` after Focus
- `Next/Features/Goals/GoalDetailView.swift` — FOCUS affordance via `FocusLaunch` + `fullScreenCover`
- `Next/Features/Focus/FocusSessionPresence.swift` — `.nextReturnToHomeEntry` notification name
- `NextTests/NextTests.swift` — `FocusLaunchTests`
- `NextUITests/NextUITests.swift` — dual-entry helpers, migrated recommendation paths, V4-M1 UI + visual review

## 3. Navigation architecture

```
ContentView
  TabView
    NavigationStack { HomeView }
      .navigationDestination(item: HomeFocusEntry)
        → HelpMeDecideView
             .navigationDestination(RecommendationInput)
               → RecommendationView
                    .fullScreenCover → FocusView
        → ChooseTaskView
             .navigationDestination(goalID)
               → ChooseTaskTasksView
                    .fullScreenCover → FocusView
    NavigationStack { GardenView → GoalDetailView }
      GoalDetailView.fullScreenCover → FocusView
```

- Single `NavigationStack` per tab (no nested stacks on Home).
- Finishing Focus from Home paths posts `.nextReturnToHomeEntry`, clearing the Home destination so the dual-entry screen is restored.
- Goal Detail Focus dismisses in place (Garden context preserved).
- Back navigation uses the system bar; tab switches do not leave a stuck recommendation presentation when returning via the notification.

## 4. Shared Focus entry strategy

`FocusLaunch.taskItem(from:)` converts an active `GoalTask` into the existing `TaskItem` used by `FocusView`. Both Choose a task and Goal Detail call this helper. Recommendation path continues to pass ranked `TaskItem` values into the same `FocusView(task:)`.

Shared after launch: `FocusView`, timers, accounting, recovery, notifications, completion, persistence, history, garden growth.

## 5. Direct-selection eligibility rules

| Rule | Behavior |
|------|----------|
| Incomplete tasks | Included |
| Completed tasks | Excluded (`isActive == false`) |
| Deleted tasks | Absent from query; stale tap shows alert |
| Time / energy filters | **Not** applied |
| Recommendation scope | **Not** applied |
| Goals with no active tasks | Goal-specific empty copy |
| No goals | Plant-a-goal empty + route to `PlantGoalView` |
| All goals without active tasks | Global empty copy |

`RecommendationEngine` is not used on this path.

## 6. Timer initialization behavior

Direct Focus initializes Simple Focus with `task.durationMinutes` (existing `FocusView` / `FocusSessionTimer` behavior). Pomodoro remains optional and requires explicit enable. No new settings surface.

## 7. Empty-state handling

- **No goals:** “Plant a goal first.” + `+ PLANT A GOAL`
- **Goals but no incomplete tasks:** “Nothing available to focus on.”
- **One goal empty:** “No tasks ready here.”
- **Stale task:** alert “Couldn't start focus” / choose another

## 8. Accessibility decisions

- Dual entries use combined accessibility labels + hints; identifiers `homeHelpMeDecide` / `homeChooseATask`
- Large Dynamic Type stacks entries vertically
- Goal/task rows expose title + metadata; Focus actions labeled (“Focus on …”)
- Help me decide preserves existing section identifiers (`homeFocusSection`, scope picker, etc.)

## 9. Exact test results

Device: **iPhone 16 (iOS 18.6)** simulator.

### Targeted — V4-M1 new coverage

| Suite | Pass | Fail | Skip |
|-------|------|------|------|
| `NextTests/FocusLaunchTests` | **4** | 0 | 0 |
| `NextUITests` V4-M1 (7 cases) | **7** | 0 | 0 |

V4-M1 UI cases: dual entry navigate, Help me decide → Focus, Choose a task ignores filters + history, excludes completed, Goal Detail FOCUS, empty states, visual review.

### Regression — NextTests + key Home UI

Initial combined run (`NextTests` + 8 Home/recommendation UITests):

| | Count |
|--|------:|
| Passed | 330 |
| Failed | 2 |
| Skipped | 0 |
| Total | 332 |

Failures (pre-fix): `testM1MultiAreaPlantEditAndScopeFiltering`, `testM3HomeAccessibilitySelectionState` — caused by incorrectly gating WHAT'S NEXT? on `recommendationScope.isReady`. Restored prior product behavior (time + energy only; incomplete scope → CHOOSE A FOCUS empty).

Re-run after fix:

| | Count |
|--|------:|
| Passed | **3** / 3 |
| Failed | **0** |

Included: both previously failing UITests + `testV4M1HelpMeDecideOpensExistingRecommendationFlow`.

Also verified in the regression batch (passed): `testRecommendationFlow`, `testFocusSessionFromCurrentRecommendation`, `testNotYetLeavesTaskRecommendable`, `testCompletedTaskLeavesWhatsNextAndCanBeReopened`, `testRecommendationEngine2Ranking`, `testM3NarrowPhoneHomeLayout`.

### Coverage distinction

| Kind | Status |
|------|--------|
| Verified functionality | Dual entry, both Focus paths, Goal Detail FOCUS, empty states, return-to-Home, ranking unchanged (unit + UI) |
| Automated coverage | FocusLaunch unit; 7 V4-M1 UI; full NextTests suite; selected Home/recommendation UI regressions |
| Manual visual review | Screenshots 01–12 on iPhone 16 |
| Untested assumptions | Exhaustive full `NextUITests` suite not re-run end-to-end in this milestone pass; Pomodoro + recovery smoke covered by existing unit tests and prior V4-M1 Focus regressions, not a dedicated dual-entry Pomodoro UI case |

## 10. Screenshot inventory

All under `Review/V4-M1-Dual-Focus-Entry/`:

| # | File |
|---|------|
| 01 | Home, light appearance |
| 02 | Home, dark appearance |
| 03 | Home, large Dynamic Type |
| 04 | Help me decide, initial screen |
| 05 | Help me decide, recommendation |
| 06 | Choose a task, goal selection |
| 07 | Choose a task, task selection |
| 08 | Direct Focus, selected task |
| 09 | Goal Detail, direct Focus action |
| 10 | Direct Focus, completion |
| 11 | Empty state, no goals |
| 12 | Empty state, no available tasks |

Fixtures: `UITEST_SEED_GARDEN`, `UITEST_SEED_TASK_LIFECYCLE`, empty in-memory store — no production data.

## 11. Known limitations

- Full UITest suite was not executed in one shot after the `isReady` fix; targeted re-verification covered the two known regressions.
- Historical V3 Home visual-review tests still capture Help me decide as “Home” in some titles (legacy naming).
- Global “all tasks completed” empty uses quiet copy; celebration language is minimal by design.

## 12. Deferred to V4-M2

- Page-by-page guided focus experience
- Any redesign of recommendation explanation UX beyond relocation
- Analytics / planning / recurring tasks

## 13. PM approval recommendation

**Recommend approval.** Dual entry is live, both paths share Focus, ranking and schema are untouched, targeted tests and screenshots are green, and the scope-empty regression was restored to the established CHOOSE A FOCUS behavior.

**Do not commit or push until PM sign-off.**
