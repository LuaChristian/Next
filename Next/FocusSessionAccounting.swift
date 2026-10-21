//
//  FocusSessionAccounting.swift
//  Next
//
//  Focus-time banking across Simple ↔ Pomodoro mode switches.
//  Break time is never banked. Results merge banked focus exactly once.
//

import Foundation

enum FocusSessionAccounting {
    /// Adds current mode focus into the session bank. Breaks contribute nothing.
    static func bankFocus(currentFocused: TimeInterval, previousBank: TimeInterval) -> TimeInterval {
        max(0, previousBank) + max(0, currentFocused)
    }

    /// Live total for display: banked focus + current-mode focused seconds only.
    /// Never includes breaks or paused gaps (callers pass focused elapsed that already excludes pause).
    static func displayedAccumulatedFocus(
        banked: TimeInterval,
        currentFocused: TimeInterval
    ) -> TimeInterval {
        max(0, banked) + max(0, currentFocused)
    }

    /// Show accumulated focus when the user has banked time, or while Pomodoro is active.
    static func shouldShowAccumulatedFocus(banked: TimeInterval, isPomodoroActive: Bool) -> Bool {
        isPomodoroActive || max(0, banked) > 0
    }

    /// Concise secondary label, e.g. "12 MIN FOCUSED".
    static func accumulatedFocusLabel(seconds: TimeInterval) -> String {
        GardenMetrics.focusedDurationLabel(seconds: max(0, seconds))
    }

    /// Merges banked focus into a completed session result without changing planned duration.
    static func mergeBankedFocus(_ banked: TimeInterval, into result: FocusSessionResult) -> FocusSessionResult {
        let extra = max(0, banked)
        guard extra > 0 else { return result }
        return FocusSessionResult(
            task: result.task,
            plannedDurationSeconds: result.plannedDurationSeconds,
            focusedDurationSeconds: result.focusedDurationSeconds + extra,
            endedNaturally: result.endedNaturally
        )
    }

    /// True when switching modes would restart the countdown while focus already exists.
    static func requiresModeSwitchConfirmation(
        currentFocused: TimeInterval,
        bankedFocus: TimeInterval
    ) -> Bool {
        (max(0, currentFocused) + max(0, bankedFocus)) > 0
    }
}
