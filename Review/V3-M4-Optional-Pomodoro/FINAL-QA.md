# V3-M4 Final QA — Transitions & Mode Switching

**Status:** STOP for PM approval (uncommitted)  
**Date:** 2026-10-21  
**Scope:** Behavior verification only — no redesign, no full regression, no commit/push

## Bugs discovered

1. **Mode switch discarded focus time** — `beginPomodoro` / `beginSimpleFocus` replaced timers and dropped accrued focus with no confirmation.
2. **Notifications not explicitly cleared on finish/mode switch** — sync usually cleared ended timers, but mode switch could leave a race with in-flight schedules.

## Minimal fixes

| Fix | Detail |
| --- | --- |
| `FocusSessionAccounting` | Banks focus across Simple ↔ Pomodoro; merges into result once; never banks breaks |
| `FocusView` | Banks on mode switch; preserves paused state; cancels notifications on switch / finish / completion |
| Confirmation | System dialog when switching Pomodoro → Simple with existing focus (“focused time will be kept…”) |
| Begin Pomodoro | Button itself is the explicit action; focus is banked (not discarded) |

## Focus-time preservation — confirmed

- Simple → Pomodoro: prior Simple focus is banked; Pomodoro focus adds; result = bank + current.
- Pomodoro → Simple: only focused seconds banked (break excluded); confirmation when focus exists.
- No duplication: bank happens at switch; merge happens once at completion.
- Paused → switch: new mode starts paused.

## Notification cleanup — confirmed

- Mode switch calls `notifications.cancel()` then resyncs for the new mode.
- Finish early / natural completion cancel pending completion + segment IDs.
- Tests cover cancel-on-switch, finish-early clear, natural-completion clear, segment→completion handoff.

## Persistence — confirmed

- Multi-round Pomodoro → one `FocusSession`.
- Only focused seconds recorded; breaks excluded.
- History/Garden derive from that single session (`goal.totalFocusedDuration`).
- `CompletionView.didCommit` ensures single commit; YES/NOT YET unchanged (`taskWasFinished`).

## Exact test cases and results

All **PASSED** on iPhone 16 Simulator (iOS 18.6), injected clocks (no real waits).

### PomodoroSessionTimerTests
| Case | Result |
| --- | --- |
| startsOnFocusRoundOneWithRecommendedPlan | PASS |
| breakTimeDoesNotCountAsFocused | PASS |
| multiRoundNaturalCompletionIsOneSessionResult | PASS |
| earlyFinishOnBreakKeepsOnlyCompletedFocus | PASS |
| pauseDuringFocusExcludesPausedTimeFromFocusAndElapsed | PASS |
| pomodoroCommitCreatesSingleFocusSession | PASS |
| focusIntervalTransitionsToBreakWithoutCountingBreakAsFocus | PASS |
| breakEndsStartsNextFocusWithAccurateRoundNumber | PASS |
| finalFocusRoundCompletesWithoutTrailingBreak | PASS |
| backgroundCatchUpResolvesCorrectSegmentAcrossBoundaries | PASS |
| backgroundDuringBreakThenPastEndAdvancesToNextFocus | PASS |
| pauseDuringBreakDoesNotAddFocusAndResumeContinuesBreak | PASS |

### FocusSessionAccountingTests
| Case | Result |
| --- | --- |
| bankFocusPreservesPriorAndCurrentWithoutDuplication | PASS |
| breakTimeIsNeverBankedBecauseCallerPassesFocusOnly | PASS |
| mergeBankedFocusAddsExactlyOnceToResult | PASS |
| modeSwitchConfirmationRequiredOnlyWhenFocusExists | PASS |
| simpleToPomodoroToSimplePreservesTotalFocusInMergedResult | PASS |
| mergedPomodoroCommitRecordsSingleSessionWithBankedFocus | PASS |

### FocusExperienceTests (notification / cleanup subset)
| Case | Result |
| --- | --- |
| pomodoroSchedulesSegmentThenCompletionNotifications | PASS |
| modeSwitchCancelClearsSegmentAndCompletionNotifications | PASS |
| finishEarlyClearsPendingPomodoroNotifications | PASS |
| naturalCompletionClearsNotificationsWithoutReschedule | PASS |
| (+ existing FocusExperience notification/idle tests) | PASS |

### UI smoke (post-fix)
| Case | Result |
| --- | --- |
| testPomodoroRemainsOptionalAndSimpleFocusIsDefault | PASS |
| testPomodoroPresetsCustomizeAndPersistAcrossLaunches | PASS |

## Remaining risks

1. **Banked focus is not shown on Simple Focus UI** after switching back — only reflected at completion / in Pomodoro elapsed line. Low product risk; no redesign this pass.
2. **Round progress is not carried** across mode switches — only focused seconds. Countdown/round state restarts by design after confirmation/Begin.
3. **Extremely long background catch-up** (>64 segment advances) is safety-capped; unrealistic for product ranges (max ~8 rounds).
4. **No dedicated UI test for confirmation dialog** on Switch to Simple Focus; covered by unit accounting + manual dialog copy.
5. **Full regression not run** (per scope).

## Not committed / not pushed
