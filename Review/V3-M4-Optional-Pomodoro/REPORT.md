# V3-M4 — Optional Pomodoro + Full Customization

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Device:** iPhone 16 Simulator (iOS 18.6)

## Product summary

Pomodoro is an **optional** focus mode. Simple Focus remains the default entry with no extra setup. Users can opt into Pomodoro from Focus (inline control or Focus settings → compact sheet), choose a preset or customize, then begin. Last Pomodoro settings persist locally; Pomodoro is never auto-enabled on next launch.

## Behavior

| Area | Implementation |
| --- | --- |
| Default entry | Existing Simple Focus timer starts immediately |
| Opt-in | `POMODORO` on Focus + `Set up Pomodoro` in Focus settings |
| Presets | Recommended 25/5/4 (preselected on first enable), Gentle Start 15/5/2, Deep Work 50/10/3 |
| Custom | Focus 5–90 (×5), Break 1–30 (×1), Rounds 1–8; Reset to Recommended |
| Totals | Planned focus (focus only); elapsed includes between-round breaks |
| Persistence | UserDefaults only (`pomodoro.focusMinutes` / `breakMinutes` / `rounds`); invalid values sanitize |
| History / Garden | Focus time only counts; breaks never count; all rounds → one `FocusSession` |
| Completion | Unchanged YES / NOT YET |
| Notifications | Segment alerts for mid-cycle transitions; completion alert on final focus end |
| Schema | No SwiftData changes |

## Files

- `Next/PomodoroConfiguration.swift` — presets, ranges, preference store
- `Next/PomodoroSessionTimer.swift` — multi-segment engine
- `Next/FocusView.swift` — optional enable + config sheet
- `Next/FocusNotification.swift` — segment + completion sync
- `Next/FocusSessionTimer.swift` — natural deadline / endedAt for catch-up
- Tests in `NextTests/NextTests.swift`, `NextUITests/NextUITests.swift`

## QA

**Unit:** `PomodoroConfigurationTests`, `PomodoroSessionTimerTests` — PASSED  
**UI:** `testPomodoroRemainsOptionalAndSimpleFocusIsDefault`, `testPomodoroPresetsCustomizeAndPersistAcrossLaunches`, `testPomodoroVisualReview` — PASSED  

Verified: Simple default; enable/disable without forcing Pomodoro; presets; custom persistence; invalid preference fallback; no Simple Focus setup required.

## Screenshots

`Review/V3-M4-Optional-Pomodoro/`

1. Simple Focus default entry  
2. Focus settings with optional Pomodoro  
3. Config — Recommended selected  
4. Config — Gentle Start  
5. Config — Deep Work  
6. Config — Reset to Recommended  
7. Pomodoro focus round active  
8. Focus settings while Pomodoro active  
9. Completion after Pomodoro — YES or NOT YET  

## Not committed / not pushed
