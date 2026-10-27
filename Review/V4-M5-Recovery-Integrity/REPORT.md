# V4-M5 — Focus Recovery Edge Cases & Data Integrity

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-26  
**Device:** iPhone 16 Simulator (iOS 18.6)

## Summary

Hardened V4-M4 recovery against lifecycle races without redesigning the UI or adding a parallel timer/store. Resume and End Session now durable-write before Focus appears; live Focus claims presence at construction so cold-launch recovery cannot stack over an active session. Extended deterministic tests cover repeated kills, interrupted completion, exactly-once commit, missing data, and notification cycles.

---

## 1. Existing architecture audit

V4-M4 baseline (reused):

| Piece | Role |
| --- | --- |
| `FocusRecoverySnapshot` v1 | Local JSON unfinished-session record |
| `FocusRecoveryStore` | Load / validate / clear; stale-after-commit gate |
| `FocusRecoveryReconciler` | Freeze running → paused at `savedAt`; prompt / resume / end |
| `FocusRecoveryPromptView` | Calm Resume / End Session gate |
| `ContentView` + `FocusRecoveryGate` | Prompt → focus within one cover |
| `FocusSessionStore.commit(experienceID:)` | Exactly-once History row |
| `FocusNotificationCoordinator` | Cancel on prompt; sync on Focus appear |

**Already correct (no change):** death-gap exclusion, pause/break exclusion, banked focus, orphan task/goal commit, awaiting-completion → Completion, notification cancel+reschedule IDs, idempotent commit on YES/NOT YET retry.

---

## 2. Bugs discovered

### Bug A — Resume / End not durable until FocusView.onAppear

**Repro:** Cold-launch recovery prompt → Resume or End Session → force-quit before Focus/Completion appears.

**Effect:**
- After Resume: store still paused → next launch shows prompt again (intent lost, not unsafe).
- After End Session: store not `awaitingCompletion` → next launch shows Resume/End again instead of Completion (earned focus still present, but End intent lost).

**Severity:** Medium

**Fix:** `FocusRecoveryReconciler.resumeAndPersist` / `endSessionAndPersist` write immediately from `FocusRecoveryGateHost`. `FocusRecoveryPersistence.writeBootstrap` also runs from `FocusView` bootstrap init (defense in depth).

### Bug B — False cold recovery over a live FocusView

**Repro:** Start a new Focus session while `ContentView.task` is still awaiting daily-reminder reconcile; `FocusView.init` writes a running snapshot while `FocusSessionPresence.isActive` is still false → `presentRecoveredFocusIfNeeded` can present recovery over the live session.

**Severity:** High (narrow window, real race)

**Fix:** Set `FocusSessionPresence.isActive = true` at the start of both `FocusView` inits (still cleared in `onDisappear`).

No other production bugs found that were not already covered by V4-M4.

---

## 3. Files changed and why

| File | Why |
| --- | --- |
| `Next/Features/Focus/FocusRecoverySnapshot.swift` | `writeBootstrap`, `resumeAndPersist`, `endSessionAndPersist` |
| `Next/App/ContentView.swift` | GateHost uses persist helpers on Resume / End |
| `Next/Features/Focus/FocusView.swift` | Claim presence + write bootstrap at init |
| `NextTests/NextTests.swift` | V4-M5 integrity cases in `FocusRecoveryTests` |
| `NextUITests/NextUITests.swift` | `testV4M5RecoveryIntegrityVisualReview` |
| `Review/V4-M5-Recovery-Integrity/` | Screenshots + this report |

No SwiftData schema change. No new timer engine or snapshot store.

---

## 4. Accounting and persistence invariants

| Invariant | Status |
| --- | --- |
| Terminated-app wall time never credited | Preserved (freeze at `savedAt`) |
| Paused time excluded | Preserved |
| Pomodoro breaks excluded | Preserved |
| Earned focus preserved across repeated kills | Covered by multi-resume cycle test |
| Correct mode / round / segment | Covered for focus + break |
| No auto-restart on cold launch | Preserved (prompt gate) |
| No recovery prompt after successful commit | `loadForPresentation` + clear |
| YES / NOT YET → ≤1 `FocusSession` | Idempotent `experienceID` |
| Repeated End Session → ≤1 session | Covered |
| Snapshot cleanup only after successful commit | Preserved; failed commit keeps awaiting |
| Deleted / renamed task/goal | Snapshot titles; orphan-safe commit; no recreate |

---

## 5. Exact tests executed and results

### Unit

| Suite | Result |
| --- | --- |
| `NextTests/FocusRecoveryTests` (incl. new V4-M5 cases) | **PASSED** |
| `NextTests/FocusSessionAccountingTests` | **PASSED** |
| `NextTests/PomodoroSessionTimerTests` | **PASSED** |

New / highlighted integrity cases:

- `killDuringRecoveryPromptStillPresentsFrozenPrompt`
- `resumePersistsRunningStateBeforeFocusAppear`
- `endSessionPersistsAwaitingCompletionBeforeFocusAppear`
- `repeatedResumeCyclesPreserveEarnedFocusWithoutDeathGap`
- `pomodoroFocusKillDuringPromptThenResumePreservesRound`
- `pomodoroBreakKillThenEndExcludesBreakFromFocus`
- `interruptedCompletionRelaunchDoesNotShowResumePrompt`
- `yesAndNotYetEachCommitExactlyOnceForSameExperience`
- `repeatedEndSessionCannotDuplicateFocusSession`
- `deletedTaskAndGoalStillRecoverAndCommitSnapshotOnly`
- `changedLiveTitlesDoNotReplaceSnapshotDisplayOnRecovery`
- `liveFocusPresenceSuppressesColdRecoveryPresentation`
- `notificationCycleAcrossRepeatedInterruptDoesNotAccumulate`
- `writeBootstrapRoundTripMatchesResumeAndEndIntent`

### UI

| Test | Result |
| --- | --- |
| `testV4M5RecoveryIntegrityVisualReview` | **PASSED** |
| `testV4M4FocusSessionRecoveryVisualReview` (regression) | **PASSED** |

No unexecuted suites claimed as passing.

---

## 6. Screenshot inventory

`Review/V4-M5-Recovery-Integrity/`

| # | File |
| --- | --- |
| 01 | `01 — Simple Focus repeated recovery.png` |
| 02 | `02 — Pomodoro focus repeated recovery.png` |
| 03 | `03 — Pomodoro break recovery.png` |
| 04 | `04 — Recovery after multiple interruptions.png` |
| 05 | `05 — Completion after recovery.png` |
| 06 | `06 — Dark mode recovery.png` |
| 07 | `07 — Large Dynamic Type recovery.png` |
| 08 | `08 — Small-screen recovery.png` |

UI unchanged from V4-M4 by design (editorial ivory / charcoal / lavender; Resume vs End Session).

---

## 7. Remaining risks and limitations

- Presence flag is process-local; it cannot help across process death (snapshots do).
- Multi-kill “repeated recovery” UI shots use fixture re-launch (deterministic); deepest multi-cycle math is unit-tested with injected clocks.
- Extreme clock skew still fails closed (>7 days stale).
- No Live Activities / background execution guarantees.

---

## 8. Regression concerns

- Low: V4-M4 prompt UX and conservative freeze policy unchanged.
- Mitigated: V4-M4 visual UITest re-run passed; accounting / Pomodoro suites passed.
- Watch: any future Focus entry that constructs `FocusView` without going through init (none today).

---

## 9. PM approval readiness

**Ready for PM approval.**

Please confirm:

1. Kill during Resume/End handoff no longer loses End → Completion or Resume intent.  
2. Starting Focus while Home is loading cannot show a false recovery prompt.  
3. Repeated interruptions still never invent or double-count focus.  
4. Visual recovery experience remains calm and unchanged.

**Do not commit** — user owns Git.
