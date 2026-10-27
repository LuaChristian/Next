# V4-M4 — Focus Session Recovery & Reliability

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-26  
**Device:** iPhone 16 Simulator (iOS 18.6)

## Summary

Cold-launch recovery no longer auto-resumes a live timer. Interrupted sessions open a calm Resume / End Session prompt. Time while the process was dead is never counted as focus. Existing snapshot store, banking, notifications, and idempotent commit paths are reused — no parallel timer system and no SwiftData schema change.

---

## 1. Existing behavior audit (pre-V4-M4)

V3-M6 already shipped durable unfinished-session recovery:

| Area | Pre-M4 behavior |
| --- | --- |
| Snapshot | `FocusRecoverySnapshot` v1 in UserDefaults (`focus.recovery.snapshot.v1`) |
| Persist | Immediate write on Focus start / pause / resume / mode switch / scenePhase / refresh |
| Restore | `ContentView` auto `fullScreenCover` → live `FocusView(bootstrap:)` |
| Clock | Running sessions advanced via `evaluateCompletion(at: now)` across termination |
| UX | No confirm sheet — effective auto-resume |
| Accounting | `experienceID` idempotent commit; banked focus; orphan task/goal safe |
| Notifications | Cancel + reschedule on Focus appear |
| Tests | Broad `FocusRecoveryTests` + `testSessionRecoveryVisualReview` |

**Gap vs this milestone:** auto-resume into a ticking FocusView and crediting wall time across process death.

---

## 2. Architecture and files changed

Reuse of the V3-M6 stack; policy + gate only.

| File | Change |
| --- | --- |
| `Next/Features/Focus/FocusRecoverySnapshot.swift` | Conservative freeze-on-restore; stale age gate; prompt/resume/end helpers; earned-focus summary |
| `Next/Features/Focus/FocusRecoveryPromptView.swift` | **New** — calm recovery prompt (task, goal, mode, earned focus, Resume, End Session) |
| `Next/App/ContentView.swift` | Present prompt for unfinished sessions; Completion still opens directly for `awaitingCompletion`; in-cover phase handoff |
| `NextTests/NextTests.swift` | Updated + new `FocusRecoveryTests` for freeze / prompt / stale / notifications |
| `NextUITests/NextUITests.swift` | `testV4M4FocusSessionRecoveryVisualReview`; recovery Resume helper for fixture launches |

Unchanged by design: `RecommendationEngine`, Guided Focus, Garden thresholds, History math, Pomodoro presets, onboarding, appearance prefs.

---

## 3. Recovery policy and rationale

**Cold launch (snapshot present, process was dead):**

1. Validate snapshot; reject incompatible / corrupt / empty-title / contradictory mode payloads.
2. Reject snapshots older than 7 days (or extreme backward clock skew beyond 7 days).
3. If `awaitingCompletion` → open Completion (YES / NOT YET) directly.
4. Otherwise freeze any **running** timer as **paused at `savedAt`** (death-gap wall time is not focus).
5. Persist the frozen paused form so a second kill during the prompt cannot reintroduce a running phase.
6. Cancel pending focus notifications.
7. Show calm prompt — **do not** start the timer.
8. **Resume** → resume timers at `now` (pause gap absorbs the death interval) → FocusView.
9. **End Session** → finish while paused (no death-gap credit) → CompletionView with banked merge.

**In-process background → foreground:** unchanged. Live `FocusView` still uses timestamp-based `evaluateCompletion` on scene active. Recovery reconciler is not used while Focus is already active.

**Rationale:** iOS does not guarantee background execution after termination. Crediting uncertain absence invents focus. Freezing as paused preserves earned time and lets the user choose Resume or End.

---

## 4. Data integrity guarantees

| Invariant | How |
| --- | --- |
| Only actual focused time credited | Freeze + paused finish; breaks never bank |
| Pauses excluded | Timer anchors already exclude pause; death gap becomes pause |
| Breaks excluded | Pomodoro `focusedElapsed` ignores break segments |
| Banked focus preserved | Restored verbatim; merged once at completion |
| Mode-switch accounting | Unchanged `FocusSessionAccounting` |
| Exactly one `FocusSession` | `experienceID` idempotent `FocusSessionStore.commit` |
| YES / NOT YET unchanged | Same `CompletionView` |
| No Garden/History double-count | Stale snapshot cleared when session row already exists |
| Missing task/goal | Display from snapshot titles; commit attaches live links if present else snapshot-only row |

---

## 5. Tests executed with results

### Unit — `NextTests/FocusRecoveryTests`

**Result: PASSED** (all cases in suite)

Including (non-exhaustive):

1. Recovery snapshot serialization round trip  
2. Running Simple Focus freezes paused without death-gap credit  
3. Paused Simple Focus stays paused  
4. Running Pomodoro focus freezes at saved moment  
5. Pomodoro break freezes without break credit  
6. Round / phase not skipped across termination gap  
7. Banked focus preservation  
8. No break-time credit  
9. No paused-time credit  
10. Duplicate completion protection (`experienceID`)  
11. Invalid / stale / extreme clock-skew handling  
12. Missing / deleted task or goal display restore  
13. Notification reconciliation + cleared while recovered-paused  
14. Recovery snapshot cleanup after commit / clear  
15. Prompt Resume / End Session accounting  
16. Immediate write after start / pause / mode switch  

In-process Pomodoro segment catch-up covered as direct timer tests (not via cold-launch restore).

### UI

| Test | Result |
| --- | --- |
| `testV4M4FocusSessionRecoveryVisualReview` | **PASSED** |
| `testSessionRecoveryVisualReview` (legacy path + Resume gate) | **PASSED** |
| `testFocusSessionFromCurrentRecommendation` | **PASSED** |

No unexecuted suites are claimed as passing.

---

## 6. Screenshots

`Review/V4-M4-Focus-Session-Recovery/`

| # | File | What |
| --- | --- | --- |
| 01 | `01 — Simple Focus recovery prompt.png` | Interrupted Simple Focus gate |
| 02 | `02 — Paused Simple Focus recovery.png` | Paused Simple recovery |
| 03 | `03 — Pomodoro focus recovery.png` | Pomodoro focus gate |
| 04 | `04 — Pomodoro break recovery.png` | Pomodoro break gate |
| 05 | `05 — Resume into Simple Focus.png` | Resume → live Focus |
| 06 | `06 — End Session completion after recovery.png` | End Session → YES/NOT YET |
| 07 | `07 — Completion after recovery.png` | Awaiting-completion path |
| 08 | `08 — Dark mode recovery.png` | Dark prompt |
| 09 | `09 — Large Dynamic Type recovery.png` | Accessibility XL prompt |
| 10 | `10 — Small-screen recovery.png` | Compact prompt layout |
| 11 | `11 — Dark mode resumed Pomodoro.png` | Dark resumed Pomodoro |
| 12 | `12 — Completion after recovered Pomodoro.png` | Completion after recovered Pomodoro |

---

## 7. Known limitations

- Recovery prompt is a full-screen cover over tabs (no new permanent tab) — intentional.
- Death-gap policy is conservative: if the user kept focusing mentally after a force-quit, that time is not credited.
- Snapshot version remains `1`; incompatible future versions fail closed (clear / ignore).
- UITest Accessibility XL content-size injection can vary by simulator; layout remains scrollable via `nextScrollableCanvas`.
- No Live Activities / background execution assumptions.

---

## 8. PM review readiness

**Ready for PM approval.**

Please verify:

1. Cold launch after kill shows Resume / End — timer does **not** auto-start.  
2. Earned focus is preserved; interruption copy is calm.  
3. Resume continues the correct mode (Simple / Pomodoro focus or break).  
4. End Session opens Completion with earned minutes only.  
5. Light / dark / large type remain editorial (ivory / charcoal / lavender).  
6. Garden and History do not double-count after recovery completion.

**Do not commit** — user owns Git.
