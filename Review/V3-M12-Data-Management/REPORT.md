# V3-M12 — Data Management & Fresh Start

**Status:** Final safety review — ready for PM approval (not committed)  
**Date:** 2026-10-26

## Implementation summary

Added a fifth Settings hub destination, **Data Management**, with a dedicated page and a confirmation-gated destructive erase that clears all local SwiftData domain data, focus recovery, reminders/notifications, and onboarding — while preserving appearance.

Reset runs through `AppDataResetCoordinator`. Domain deletes + save run inside `ModelContext.transaction` on the caller's context. Notification / recovery / reminder / onboarding side effects run **only** after a successful save and empty-store verification. `NextApp` listens for `.nextAppDataDidReset` and returns to onboarding without terminating the process.

## Git gate (V3-M11)

**Confirmed committed before V3-M12 approval:**

| Commit | Summary |
|--------|---------|
| `d1a9f92` | Project organization (feature-based directories) |
| `c9e5d7b` | V3-M11 release readiness and QA |

Working tree for M12 remains **uncommitted** (as required).

## Files added / modified

### Added
- `Next/Features/Settings/AppDataResetCoordinator.swift`
- `Next/Features/Settings/DataManagementView.swift`
- `Review/V3-M12-Data-Management/` (REPORT + screenshots)

### Modified
- `Next/Features/Settings/SettingsDestination.swift` — fifth destination
- `Next/Features/Settings/SettingsView.swift` — navigation wiring
- `Next/Features/Home/OnboardingPreference.swift` — `clearCompleted`
- `Next/App/NextApp.swift` — post-reset onboarding return
- `NextTests/NextTests.swift` — `AppDataResetTests` + hub metadata update
- `NextUITests/NextUITests.swift` — cancel / success / visual review + hub coverage

## Reset architecture

```
DataManagementView
  → confirmationDialog (Cancel | Erase All App Data)
  → AppDataResetCoordinator.resetAllAppData(context:)
       1. Guard re-entry (isResetting)
       2. context.transaction {
            delete FocusSession → Goal (cascade GoalTask) → orphan tasks
            saveContext
          }
            on failure → throw persistenceFailed
              (no onboarding / notification / recovery side effects)
       3. Verify fetch counts == 0 on the same context
       4. Cancel focus completion + Pomodoro segment notifications
       5. Clear FocusRecoveryStore snapshot
       6. DailyReminderCoordinator.disable()
       7. OnboardingPreference.clearCompleted
       8. Post .nextAppDataDidReset
  → NextApp sets hasCompletedOnboarding = false
```

## Exact deletion semantics

| Record | Action |
|--------|--------|
| `FocusSession` | Explicit delete (Goal→session is `.nullify`) |
| `Goal` | Explicit delete; tasks cascade |
| `GoalTask` | Cascade from Goal; defensive orphan sweep |
| Store files | **Not** deleted; no schema change |

## Final failure-handling behavior

### Investigation findings

1. **`ModelContext.rollback()` after deletes is unsafe** on the current SwiftData SDK. It can fatal with:  
   `ModelSnapshot must be initialized with a known-keys dictionary`.

2. **Scratch / sibling `ModelContext` erase is unsafe** while another context still registers the same rows. Committing deletes from a second context can fatal with:  
   `This model instance was invalidated because its backing data could no longer be found the store`.

3. **`ModelContext.transaction` on the live context** is the minimal reliable approach:
   - Deletes + save stay on the UI / caller context (no cross-context invalidation).
   - No explicit `rollback()` call.
   - If `save` throws before commit, the **on-disk store is unchanged** (verified by reopening the store / fresh container).
   - The caller's in-memory context may retain pending deletes until a successful retry save or process relaunch.

### Guarantees after a failed save

| Check | Result |
|-------|--------|
| Onboarding remains completed | Yes |
| Success notification / UI transition | Not posted |
| Side effects (reminders / recovery / focus notifications) | Not applied |
| Persisted store rows remain | Yes (reopen / relaunch) |
| Retry on the **same** ModelContext | Yes (pending deletes commit on success) |
| Relaunch consistency | Yes (disk never received the failed transaction) |

### Supported recovery paths

1. **Retry in-session** — tap Erase again on the same context; second attempt saves successfully (`retryOnSameContextAfterFailedSaveSucceeds`).
2. **Relaunch** — if the UI looks empty after a failed attempt, relaunch restores from disk; user may erase again (`failedSaveLeavesFileStoreIntactAcrossRelaunch` + success suites).

Error copy tells the user nothing was permanently erased and to relaunch if the app looks empty.

### Approaches rejected

| Approach | Why rejected |
|----------|--------------|
| Explicit `rollback()` after failed save | SDK fatal (`ModelSnapshot`) |
| Scratch context delete + save | SDK fatal (invalidated relationship backing) while live context still registers rows |
| Rebuild persistence / new schema | Out of scope |

## Preference preservation decisions

| Preference | Decision |
|------------|----------|
| Appearance | **Preserve** (PM approved) |
| Onboarding completion | **Clear** on success only |
| Reminder enabled | **Disable** on success only |
| Reminder hour/minute | **Preserve** |
| Pomodoro config | **Preserve** |
| Keep Screen Awake | **Preserve** |
| Focus recovery snapshot | **Clear** on success only |
| System notification auth | **Untouched** |

## Test results

### Unit (`AppDataResetTests`) — final safety pass
**PASSED** 12/12 (2026-10-26, iPhone 16, serial)

Includes:
- Empty / populated erase, historical session removal, garden progress basis
- Appearance preserve + onboarding reset
- Reminder disable + recovery clear + notification cancel hooks
- Repeated-reset prevention
- Cancel path (no coordinator call)
- **`failureDoesNotClearOnboardingOrReportSuccess`** — side effects gated; store durable after reopen
- **`failedSaveLeavesFileStoreIntactAcrossRelaunch`** — disk unchanged across process-equivalent reopen
- **`retryOnSameContextAfterFailedSaveSucceeds`** — in-session retry commits pending deletes
- Relaunch persistence of successful erase

### UI (prior; unchanged by this safety pass)
**PASSED** — Settings hub, cancel, successful reset → onboarding, visual review (5 shots)

Visual design / Settings navigation / confirmation / preference policy: **PM APPROVED**.

## Screenshots

1. `01 Settings with Data Management row.png`
2. `02 Data Management page — light.png`
3. `03 Destructive confirmation.png`
4. `04 Data Management page — dark.png`
5. `05 Onboarding after successful reset.png`

## Known limitations / remaining risks

1. After a **failed** save, the live `ModelContext` may show empty `@Query` results until retry succeeds or the app relaunches — disk is intact. Error alert documents this.
2. Opening a **second** context against the same store while a tainted context still registers deleted rows can fatal in SwiftData — avoided in production (single environment context) and in tests.
3. Active Focus is not concurrent with Settings; recovery cleanup runs only after successful erase.
4. No cloud / export / partial reset by design.

## Recommendation for PM approval

**Go for commit** — V3-M11 readiness is on `main` (`c9e5d7b`); failure path no longer uses unsafe `rollback()` or scratch-context erasure; store durability, same-context retry, and relaunch consistency are covered by targeted tests; side effects remain success-gated. No design/feature changes in this safety pass. Do not push until explicitly requested.
