//
//  NextUITestLaunch.swift
//  Next
//
//  Detects UITest launch arguments. Always false in Release builds.
//

import Foundation

enum NextUITestLaunch {
    /// UITest: `UITEST_POMODORO_PREVIEW` followed by `break` | `focus2` | `paused`.
    static let pomodoroPreviewArgument = "UITEST_POMODORO_PREVIEW"

    enum PomodoroPreview: String {
        case breakTime = "break"
        case focusRound2 = "focus2"
        case paused = "paused"
    }

    static var isActive: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("UITEST_") }
        #else
        false
        #endif
    }

    static func pomodoroPreview(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> PomodoroPreview? {
        #if DEBUG
        guard let index = arguments.firstIndex(of: pomodoroPreviewArgument),
              arguments.indices.contains(index + 1)
        else { return nil }
        return PomodoroPreview(rawValue: arguments[index + 1])
        #else
        _ = arguments
        return nil
        #endif
    }
}
