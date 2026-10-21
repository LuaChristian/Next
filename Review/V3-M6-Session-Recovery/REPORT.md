# V3-M6 — Focus Session Recovery & Reliability

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Device:** iPhone 16 Simulator (iOS 18.x)

## Summary

Active focus experiences now survive backgrounding, lock, process death, relaunch, and SwiftUI view reconstruction via a local recovery snapshot. Restoration is automatic onto the existing Focus UI — no confirm sheet, no redesign of V3-M5 presentation.

---

## 1. Architecture audit

| Area | Finding |
| --- | --- |
| **In-memory only (pre-M6)** | `FocusView` `@State` mode (`FocusSessionTimer` / `PomodoroSessionTimer`), `bankedFocusSeconds`, `experience` identity, `result`, pause/phase, notifications in `FocusNotificationCoordinator`. |
| **Timestamp-derived** | Remaining time, focused elapsed, Pomodoro segment catch-up via `evaluateCompletion(at:)` against wall-clock anchors (`startedAt`, `totalPaused`, segment state). Not a 1 Hz tick counter. |
| **Lost on process death (pre-M6)** | Entire unfinished focus experience; only completed `FocusSession` rows persisted in SwiftData. |
| **Banked focus** | `FocusSessionAccounting.bankFocus` / `mergeBankedFocus`; stored as `bankedFocusSeconds` on the recovery snapshot across mode switches. |
| **Commit path** | `CompletionView` → `FocusSessionStore.commit` → one `FocusSession`; Garden/History derive from focused seconds. |
| **Notifications** | `FocusNotificationCoordinator.sync` schedules completion or segment; pause/end clears. |
| **Completion** | Timer end or Finish early → `FocusSessionResult` → YES / NOT YET → commit. |
| **Relaunch entry** | `ContentView` tabs; onboarding if needed. M6 adds automatic `fullScreenCover` when a valid snapshot exists. |

V3-M6 extends this architecture; it does not replace the timer types.

---

## 2. Recovery snapshot storage design

- **Type:** `FocusRecoverySnapshot` (Codable, `version = 1`) — unfinished experience only; **not** a History/`FocusSession` row.
- **Store:** `FocusRecoveryStore` → JSON in the same local `UserDefaults` suite as other Focus prefs (`FocusPreference.store` / `UITEST_DEFAULTS_SUITE`). Atomic `set` of encoded `Data`; invalid payloads are cleared.
- **Why not SwiftData:** Avoids schema migration for a transient, single-active record.
- **Fields (minimum):** version, `experienceID`, `savedAt`, task/goal IDs + display snapshots, banked focus, mode, nested timer snapshots, optional `awaitingCompletion` + planned/focused/natural completion anchors.
- **Uniqueness:** One key (`focus.recovery.snapshot.v1`); save overwrites; clear on successful commit or invalid load.

DEBUG/UITest only: `UITEST_FOCUS_RECOVERY` + fixture name writes a deterministic snapshot (`FocusRecoveryLaunch`). No-ops in Release.

---

## 3. Timer and clock policy

`FocusRecoveryClockPolicy`:

| Condition | Behavior |
| --- | --- |
| `now < savedAt` (clock moved backward) | Freeze running timers as **paused** at `savedAt`; do not invent remaining time or rewind accrued focus. |
| Forward advance ≤ 7 days | Evaluate at `now` (segment catch-up included). |
| Forward advance > 7 days | Clamp evaluation to `savedAt + 7d` (conservative; avoids runaway focus from absurd jumps). |

Within a process, UI still refreshes with wall `Date()`; cross-launch recovery always uses persisted wall anchors + reconcile. Negative remaining is clamped by existing timer math (`max(0, …)`).

---

## 4. App lifecycle integration

- **Persist:** `FocusView` saves snapshot on appear, disappear (if not cleared), scenePhase changes, pause/resume, mode switch, refresh, finish-early.
- **Restore:** `ContentView` on `.task` and scene active → load → `FocusRecoveryReconciler.restore` → `fullScreenCover` `FocusView(bootstrap:)`.
- **Guards:** Skip if cover already presented or `FocusSessionPresence.isActive`; invalid snapshot → clear.
- Process termination is **not** treated as Finish early.

---

## 5. Pomodoro boundary reconciliation

Restored `PomodoroSessionTimer` runs `evaluateCompletion(at: evalAt)` when phase is running, which walks focus/break segments using existing catch-up. Breaks never add focus. No break is scheduled after the final focus round (existing timer + notification rules).

---

## 6. Focus accounting and idempotency

- Banked seconds restored verbatim; merge into result exactly once at completion.
- **`experienceID`:** Stable UUID for the unfinished experience; used as `FocusSession.id` on commit.
- **`FocusSessionStore.commit(experienceID:)`:** If a session with that id exists, return it (no second insert).
- **Ordering:** Final result → commit (idempotent) → `FocusRecoveryStore.clear()` → dismiss. Failed commit leaves snapshot for retry. `didClearRecovery` prevents `onDisappear` from rewriting after clear.

---

## 7. Missing-task/goal fallback

- Display/recovery uses snapshot `TaskItem` fields (never crashes on missing relationships).
- Commit looks up live `Goal`/`GoalTask` by id; if missing, inserts a snapshot-only `FocusSession` (title snapshots preserved). Does **not** resurrect deleted entities or attach to a different task.
- YES only completes a live task when present.

---

## 8. Notification reconciliation

On Focus appear / restore / refresh: `syncNotifications` cancels-and-reschedules via coordinator for current state.

- Paused → no running-timer notifications.
- Ended / awaiting completion → cancel.
- Mid-Pomodoro → segment only; final focus → completion only; no trailing break after last round.
- Permission behavior unchanged; no new prompt; no background execution hacks.

---

## 9. Files changed

| File | Change |
| --- | --- |
| `Next/FocusRecoverySnapshot.swift` | **New** — snapshot, store, clock policy, reconciler |
| `Next/FocusRecoveryLaunch.swift` | **New** — DEBUG `UITEST_FOCUS_RECOVERY` fixtures |
| `Next/FocusSessionTimer.swift` | Codable `Snapshot` + restoring init |
| `Next/PomodoroSessionTimer.swift` | Codable `Snapshot` + restoring init |
| `Next/FocusView.swift` | `experienceID`, bootstrap init, persist/reconcile lifecycle |
| `Next/ContentView.swift` | Auto-present recovered Focus |
| `Next/CompletionView.swift` | Pass `experienceID`; clear snapshot after successful commit |
| `Next/FocusSession.swift` | Idempotent commit by `experienceID`; orphan-safe relationships |
| `Next/NextApp.swift` | Apply recovery fixtures at launch (DEBUG) |
| `NextTests/NextTests.swift` | `FocusRecoveryTests` (unit + integration) |
| `NextUITests/NextUITests.swift` | `testSessionRecoveryVisualReview` + screenshots |

---

## 10. Targeted test results

All **FocusRecoveryTests PASSED** (injected clocks; no real Pomodoro waits).

1. runningSimpleFocusRecoversRemainingTime  
2. pausedSimpleFocusStaysPausedAfterRelaunch  
3. runningPomodoroRecoversFocusSegment  
4. runningPomodoroRecoversBreakSegment  
5. recoveryCrossesOneSegmentBoundary  
6. recoveryCrossesSeveralSegmentBoundaries  
7. recoveryReachesFinalFocusCompletionWithoutTrailingBreak  
8. pausedBreakRemainsPaused  
9. bankedFocusSurvivesRelaunch  
10. simplePomodoroSimpleAccountingPreservedInSnapshotRoundTrip  
11. breakTimeExcludedFromFocusTotalsOnRecovery  
12. clockMovedBackwardFreezesRunningAsPaused  
13. unexpectedForwardJumpStillReconcilesWithoutNegativeRemaining  
14. invalidCorruptedSnapshotIsRejected  
15. missingTaskOrGoalStillRestoresDisplayTask  
16. repeatedRecoveryIsIdempotent  
17. repeatedCompletionCreatesOneFocusSession  
18. recoverySnapshotClearedAfterExplicitClear  
19. recoverySnapshotClearedAfterSuccessfulCommitFlow  
20. missingGoalStillCommitsSnapshotOnlySession  
21. awaitingCompletionRestoresCompletionResult  
22. notificationsReconciledWithoutDuplicatesOnRecovery  
23. integrationRecoverPersistDestroyAndCommitOnce  

**UI:** `testSessionRecoveryVisualReview` — **PASSED** (fixtures + screenshots 01–07).

Full historical regression suite not run (per scope).

### Screenshots

`Review/V3-M6-Session-Recovery/`

1. Recovered running Simple Focus  
2. Recovered paused Simple Focus  
3. Recovered Pomodoro focus  
4. Recovered Pomodoro break  
5. Recovered paused Pomodoro  
6. Recovered naturally completed session  
7. Recovered session in Dark mode  

---

## 11. Remaining limitations and risks

- Wall-clock policy cannot perfectly distinguish intentional clock changes from real absence; backward → freeze paused; extreme forward → 7-day clamp.
- Snapshot is device-local UserDefaults (no iCloud); reinstall clears unfinished recovery (completed History remains in SwiftData).
- Orphan tasks: focus commits with title snapshots only; no broad orphan-session manager.
- Fixtures / `debugEnterBreakAfterRound1` are DEBUG-only.
- Rapid multi-scene callbacks rely on single-key overwrite + presence guard; intentional duplicate-commit protection is at `experienceID` commit time.

## Final reliability QA (post-visual approval)

Localized fixes before commit approval:

1. **Immediate durability** — `FocusRecoveryPersistence.writeImmediate` runs in `FocusView` init (session start) and on every pause / resume / mode switch / refresh / finish path. Does not wait for `scenePhase` or the 1s clock.
2. **Stale snapshot gate** — `FocusRecoveryStore.loadForPresentation(context:)` clears and ignores a snapshot when a `FocusSession` with the same `experienceID` already exists (commit succeeded, clear interrupted).
3. **Completion retry** — failed commit keeps the awaiting-completion snapshot, stays on Completion (`didCommit` reset), and only dismisses after successful commit + clear. Idempotent `experienceID` commit prevents duplicates.

Added tests: immediate start / pause / mode-switch writes; stale snapshot after commit; interrupted cleanup + relaunch; failed commit + successful retry.

## Not committed / not pushed
