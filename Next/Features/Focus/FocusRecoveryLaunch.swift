//
//  FocusRecoveryLaunch.swift
//  Next
//
//  DEBUG/UITest fixtures for recoverable focus sessions. No-ops in Release.
//

import Foundation

enum FocusRecoveryLaunch {
    /// UITest: `UITEST_FOCUS_RECOVERY` followed by one of:
    /// `simple` | `pausedSimple` | `pomodoroFocus` | `pomodoroBreak` | `pausedPomodoro` | `completed`
    static let argument = "UITEST_FOCUS_RECOVERY"

    enum Fixture: String {
        case simple
        case pausedSimple
        case pomodoroFocus
        case pomodoroBreak
        case pausedPomodoro
        case completed
    }

    static func applyFixturesIfNeeded(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        now: Date = Date()
    ) {
        #if DEBUG
        // UITest launches that do not opt into recovery must start clean.
        // Otherwise a leftover UserDefaults snapshot full-screens Focus and
        // blocks Settings / Home / Garden interactions for later tests.
        if NextUITestLaunch.isActive, !arguments.contains(argument) {
            FocusRecoveryStore.clear(arguments: arguments)
            return
        }

        guard let index = arguments.firstIndex(of: argument),
              arguments.indices.contains(index + 1),
              let fixture = Fixture(rawValue: arguments[index + 1])
        else { return }

        let taskID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let goalID = UUID(uuidString: "FFFFFFFF-0000-1111-2222-333333333333")!
        let experienceID = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!

        let taskTitle = "Review amino acids"
        let goalTitle = "Study for MCAT"
        let banked: TimeInterval = 120

        switch fixture {
        case .simple:
            var timer = FocusSessionTimer(durationMinutes: 25, startedAt: now.addingTimeInterval(-180))
            timer.evaluateCompletion(at: now)
            save(
                experienceID: experienceID,
                taskID: taskID,
                goalID: goalID,
                taskTitle: taskTitle,
                goalTitle: goalTitle,
                banked: 0,
                mode: .simple,
                simple: timer.snapshot,
                pomodoro: nil,
                awaitingCompletion: false,
                now: now
            )

        case .pausedSimple:
            var timer = FocusSessionTimer(durationMinutes: 25, startedAt: now.addingTimeInterval(-300))
            timer.pause(at: now.addingTimeInterval(-60))
            save(
                experienceID: experienceID,
                taskID: taskID,
                goalID: goalID,
                taskTitle: taskTitle,
                goalTitle: goalTitle,
                banked: banked,
                mode: .simple,
                simple: timer.snapshot,
                pomodoro: nil,
                awaitingCompletion: false,
                now: now
            )

        case .pomodoroFocus:
            var session = PomodoroSessionTimer(configuration: .recommended, startedAt: now.addingTimeInterval(-120))
            session.evaluateCompletion(at: now)
            save(
                experienceID: experienceID,
                taskID: taskID,
                goalID: goalID,
                taskTitle: taskTitle,
                goalTitle: goalTitle,
                banked: banked,
                mode: .pomodoro,
                simple: nil,
                pomodoro: session.snapshot,
                awaitingCompletion: false,
                now: now
            )

        case .pomodoroBreak:
            var session = PomodoroSessionTimer(configuration: .recommended, startedAt: now)
            session.debugEnterBreakAfterRound1(at: now.addingTimeInterval(-30))
            save(
                experienceID: experienceID,
                taskID: taskID,
                goalID: goalID,
                taskTitle: taskTitle,
                goalTitle: goalTitle,
                banked: 0,
                mode: .pomodoro,
                simple: nil,
                pomodoro: session.snapshot,
                awaitingCompletion: false,
                now: now
            )

        case .pausedPomodoro:
            var session = PomodoroSessionTimer(configuration: .recommended, startedAt: now.addingTimeInterval(-90))
            session.pause(at: now.addingTimeInterval(-20))
            save(
                experienceID: experienceID,
                taskID: taskID,
                goalID: goalID,
                taskTitle: taskTitle,
                goalTitle: goalTitle,
                banked: banked,
                mode: .pomodoro,
                simple: nil,
                pomodoro: session.snapshot,
                awaitingCompletion: false,
                now: now
            )

        case .completed:
            var timer = FocusSessionTimer(durationMinutes: 25, startedAt: now.addingTimeInterval(-25 * 60))
            timer.evaluateCompletion(at: now)
            let focused = timer.activeElapsed(at: now) + banked
            save(
                experienceID: experienceID,
                taskID: taskID,
                goalID: goalID,
                taskTitle: taskTitle,
                goalTitle: goalTitle,
                banked: 0,
                mode: .simple,
                simple: timer.snapshot,
                pomodoro: nil,
                awaitingCompletion: true,
                planned: 25 * 60,
                focused: focused,
                natural: true,
                now: now
            )
        }
        #else
        _ = (arguments, now)
        #endif
    }

    #if DEBUG
    private static func save(
        experienceID: UUID,
        taskID: UUID,
        goalID: UUID,
        taskTitle: String,
        goalTitle: String,
        banked: TimeInterval,
        mode: FocusRecoveryModeKind,
        simple: FocusSessionTimer.Snapshot?,
        pomodoro: PomodoroSessionTimer.Snapshot?,
        awaitingCompletion: Bool,
        planned: TimeInterval? = nil,
        focused: TimeInterval? = nil,
        natural: Bool? = nil,
        now: Date
    ) {
        let snapshot = FocusRecoverySnapshot(
            version: FocusRecoverySnapshot.currentVersion,
            experienceID: experienceID,
            savedAt: now,
            taskID: taskID,
            goalID: goalID,
            taskTitle: taskTitle,
            goalTitle: goalTitle,
            taskDurationMinutes: 25,
            energyRequiredRaw: EnergyLevel.good.rawValue,
            area: "Education",
            bankedFocusSeconds: banked,
            mode: mode,
            simple: simple,
            pomodoro: pomodoro,
            awaitingCompletion: awaitingCompletion,
            completionPlannedSeconds: planned,
            completionFocusedSeconds: focused,
            completionEndedNaturally: natural
        )
        FocusRecoveryStore.save(snapshot)
    }
    #endif
}
