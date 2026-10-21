# V3-M5 — Focus Experience Refinement

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Device:** iPhone 16 Simulator (iOS 18.6)

## Summary

Refined Simple Focus and Pomodoro presentation without redesigning the product.

1. **Accumulated focus** — Secondary `N MIN FOCUSED` under the countdown when banked focus exists or Pomodoro is active (banked + current focus only; never breaks/pause).
2. **Break clarity** — Distinct BREAK state: muted countdown, round context, calm reassurance, next-round cue, `End session` label; focused total stays frozen during breaks.
3. **Controls** — Pause/Resume unchanged; finish vs end labels by mode; guards against double end/switch; mode switch still banks focus and preserves pause; confirmation only for Pomodoro → Simple with existing focus.
4. **Completion** — Still merges banked focus once into a single `FocusSession`; YES/NOT YET unchanged.

## Files changed

| File | Change |
| --- | --- |
| `Next/FocusSessionAccounting.swift` | Display helpers for accumulated focus |
| `Next/FocusView.swift` | Status UI, break presentation, control guards/labels |
| `Next/PomodoroSessionTimer.swift` | Break copy, next-round helper, DEBUG preview jumps |
| `Next/NextUITestLaunch.swift` | `UITEST_POMODORO_PREVIEW` for visual QA |
| `NextTests/NextTests.swift` | Display + break + preview unit tests |
| `NextUITests/NextUITests.swift` | V3-M5 visual review + identifier updates |

## Targeted test results

All **PASSED** (injected clocks / preview args; no real Pomodoro waits).

### FocusSessionAccountingTests
- bankFocusPreservesPriorAndCurrentWithoutDuplication — PASS  
- displayedAccumulatedFocusSumsBankedAndCurrentWithoutBreaks — PASS  
- accumulatedFocusVisibilityRules — PASS  
- breakTimeIsNeverBankedBecauseCallerPassesFocusOnly — PASS  
- mergeBankedFocusAddsExactlyOnceToResult — PASS  
- modeSwitchConfirmationRequiredOnlyWhenFocusExists — PASS  
- simpleToPomodoroToSimplePreservesTotalFocusInMergedResult — PASS  
- mergedPomodoroCommitRecordsSingleSessionWithBankedFocus — PASS  

### PomodoroSessionTimerTests (incl. prior + new)
- Transitions, catch-up, no trailing break, pause on break — PASS  
- breakReassuranceNamesNextFocusRound — PASS  
- debugPreviewHelpersJumpWithoutWaitingRealIntervals — PASS  

### FocusExperienceTests (notification cleanup smoke)
- modeSwitchCancelClearsSegmentAndCompletionNotifications — PASS  
- finishEarlyClearsPendingPomodoroNotifications — PASS  

### UI
- testFocusRefinementVisualReview — PASS  
- testPomodoroRemainsOptionalAndSimpleFocusIsDefault — PASS  
- testPomodoroPresetsCustomizeAndPersistAcrossLaunches — PASS  

## Screenshots

`Review/V3-M5-Focus-Experience/`

1. Simple Focus default  
2. Simple Focus with accumulated focus  
3. Pomodoro active focus round  
4. Pomodoro active break  
5. Pomodoro later focus round  
6. Paused Pomodoro  
7. Completion showing accumulated focus  
8. Pomodoro break — Dark  
9. Pomodoro break — Large Dynamic Type  

## Remaining limitations / risks

- Accumulated focus on Simple appears only after banked time (mode switch); pure Simple sessions stay uncluttered by design.
- Break/later-round screenshots use DEBUG `UITEST_POMODORO_PREVIEW` (not a production path).
- Full regression not run (per scope).
- Narrow-phone screenshot not separately captured; Large DT break shot covers readability.

## Not committed / not pushed
