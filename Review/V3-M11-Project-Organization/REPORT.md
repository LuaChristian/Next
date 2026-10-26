# V3-M11 — Project File Organization

**Status:** Organizational phase complete (uncommitted)  
**Date:** 2026-10-26  
**Base:** `d07def3` — V3-M10 settings navigation  
**Scope:** Folder moves only — **0** source-code line changes

## 1. Objective

Reorganize Next into a feature-oriented layout for maintainability before the full V3-M11 regression suite. No application behavior changes.

## 2. Before / after structure

### Before

```
Next/                          # 64 Swift files flat + Assets.xcassets
Next.xcodeproj/
NextTests/                     # unit tests (unchanged)
NextUITests/                   # UI tests (unchanged)
Review/                        # milestone screenshots (unchanged)
Docs/
scripts/
```

### After

```
Next/
  App/                         # entry + root shell
  Core/                        # genuinely shared UI / helpers
  Models/                      # SwiftData models + persistence
  Features/
    Home/                      # home, recommendation, onboarding
    Garden/                    # garden + botanical artwork
    Goals/                     # plant / edit goals & tasks
    Focus/                     # focus session, pomodoro, recovery
    History/                   # history presentation
    Settings/                  # settings hub + preferences
  Resources/
    Assets.xcassets/
NextTests/                     # unchanged target root
NextUITests/                   # unchanged target root
Review/                        # unchanged (includes this REPORT)
Docs/                          # unchanged
scripts/                       # unchanged
```

**Not created (empty / unnecessary):** separate `Tests/` or `Review/` under `Next/` — those already live as first-class roots. No `Features/Onboarding` — onboarding lives under `Features/Home`.

## 3. Placement rationale

| Area | Contents |
| --- | --- |
| **App** | `NextApp`, `ContentView` |
| **Core** | Theme, shared pickers / selection controls, UITest launch helpers, life-area picker (Home + Goals) |
| **Models** | `Goal` / `GoalTask`, `FocusSession`, `TaskItem`, `Persistence`, `PlanningStore` |
| **Home** | Home, greeting, recommendation engine/UI/scope, onboarding |
| **Garden** | Living garden UI, growth metrics, plant/pixel/botanical artwork |
| **Goals** | Create/edit goal & task flows, goal detail |
| **Focus** | Focus UI, timers, pomodoro, notifications, recovery |
| **History** | History view + presentation helpers |
| **Settings** | Hub, appearance, reminders, about, preference stores |
| **Resources** | Asset catalog |

## 4. Moved files (git rename)

All moves used `git mv` to preserve history. **68** path renames; **0** content diffs.

### App (2)
- `NextApp.swift`, `ContentView.swift`

### Core (5)
- `NextTheme.swift`, `SelectionOption.swift`, `SearchableSingleSelect.swift`, `NextUITestLaunch.swift`, `LifeAreaPicker.swift`

### Models (5)
- `Goal.swift`, `FocusSession.swift`, `TaskItem.swift`, `Persistence.swift`, `PlanningStore.swift`

### Features/Home (8)
- `HomeView.swift`, `HomeGreeting.swift`, `RecommendationView.swift`, `RecommendationEngine.swift`, `RecommendationScope.swift`, `OnboardingFlow.swift`, `OnboardingState.swift`, `OnboardingPreference.swift`

### Features/Garden (15)
- `GardenView.swift`, `GardenGrowth.swift`, `GardenCollectionSummary.swift`, `GardenPlantCell.swift`, `PlantView.swift`, `PlantArtwork.swift`, `PlantIdentity.swift`, `BotanicalPlantView.swift`, `BotanicalSpecies.swift`, `BotanicalSpeciesPicker.swift`, `BotanicalPlaceholderArt.swift`, `PixelPlantArt.swift`, `FernPixelArt.swift`, `FernStageShowcaseView.swift`, `PlantComparisonView.swift`

### Features/Goals (5)
- `PlantGoalView.swift`, `EditGoalView.swift`, `GoalDetailView.swift`, `AddTaskView.swift`, `EditTaskView.swift`

### Features/Focus (12)
- `FocusView.swift`, `CompletionView.swift`, `FocusSessionTimer.swift`, `PomodoroSessionTimer.swift`, `PomodoroConfiguration.swift`, `FocusSessionResult.swift`, `FocusSessionAccounting.swift`, `FocusSessionPresence.swift`, `FocusPreferences.swift`, `FocusNotification.swift`, `FocusRecoverySnapshot.swift`, `FocusRecoveryLaunch.swift`

### Features/History (2)
- `HistoryView.swift`, `HistoryPresentation.swift`

### Features/Settings (10)
- `SettingsView.swift`, `SettingsDestination.swift`, `SettingsRow.swift`, `AppearanceSettingsView.swift`, `AppearancePreference.swift`, `RemindersSettingsView.swift`, `ReminderPreference.swift`, `DailyReminder.swift`, `DailyReminderCoordinator.swift`, `AboutNextView.swift`

### Resources
- `Assets.xcassets/` → `Next/Resources/Assets.xcassets/`

## 5. Xcode / target membership

The app, unit, and UI targets use **`PBXFileSystemSynchronizedRootGroup`** (`Next`, `NextTests`, `NextUITests`). Folder moves under those roots are picked up automatically.

| Check | Result |
| --- | --- |
| `project.pbxproj` edits | **None** |
| Duplicate Swift filenames | **None** |
| Broken file references | **None observed** |
| Asset catalog (`AppIcon` / `AccentColor`) | Loads via synchronized Resources path |

## 6. Build verification

| Build | Result |
| --- | --- |
| Debug (`iPhone 16` Simulator) | **BUILD SUCCEEDED** |
| Release (`iPhone 16` Simulator) | **BUILD SUCCEEDED** |

Pre-existing Swift 6 concurrency warnings in `FocusView` remain; none introduced by this move.

## 7. Test discovery verification

| Suite | Result |
| --- | --- |
| `NextTests/GardenGrowthTests` | **PASS** |
| `NextTests/LivingGardenSummaryTests` | **PASS** |
| `NextTests/SettingsNavigationTests` | **PASS** |
| `NextUITests/.../testSettingsNavigationHubOpensEachDestination` | **PASS** |

Unit and UI test targets remain discoverable; no test files were moved.

## 8. Unresolved issues

**None.** No Xcode reference repairs required.

## 9. Next step

Organizational phase is complete. Full V3-M11 regression suite can proceed on this tree.

**Do not commit or push until PM approval.**
