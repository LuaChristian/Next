//
//  PomodoroSessionTimer.swift
//  Next
//
//  Multi-round Pomodoro engine. Focus counts; breaks never count as focused time.
//  All rounds belong to one FocusSession when completed.
//

import Foundation

enum PomodoroSegmentKind: Equatable {
    case focus(round: Int)
    case breakTime(afterRound: Int)

    var isFocus: Bool {
        if case .focus = self { return true }
        return false
    }

    var isBreak: Bool {
        if case .breakTime = self { return true }
        return false
    }
}

struct PomodoroSessionTimer: Equatable {
    let configuration: PomodoroConfiguration

    private(set) var kind: PomodoroSegmentKind
    private var segment: FocusSessionTimer
    private var completedFocusSeconds: TimeInterval = 0
    private var completedBreakSeconds: TimeInterval = 0
    private var finalizedFocusSeconds: TimeInterval?
    private(set) var endedNaturally = false
    private(set) var phase: FocusSessionPhase = .running

    init(configuration: PomodoroConfiguration, startedAt: Date = Date()) {
        let clean = configuration.sanitized()
        self.configuration = clean
        self.kind = .focus(round: 1)
        self.segment = FocusSessionTimer(durationMinutes: clean.focusMinutes, startedAt: startedAt)
    }

    var currentRound: Int {
        switch kind {
        case .focus(let round): return round
        case .breakTime(let afterRound): return afterRound
        }
    }

    var totalRounds: Int { configuration.rounds }

    var isOnBreak: Bool { kind.isBreak }

    /// True when the next natural segment end finishes the whole Pomodoro session.
    var willCompleteSessionAtNextNaturalEnd: Bool {
        guard phase == .running || phase == .paused else { return false }
        if case .focus(let round) = kind, round >= configuration.rounds {
            return true
        }
        return false
    }

    func remainingDisplay(at now: Date) -> String {
        segment.remainingDisplay(at: now)
    }

    func remainingSeconds(at now: Date) -> Int {
        segment.remainingSeconds(at: now)
    }

    func expectedNaturalCompletion(at now: Date) -> Date? {
        guard phase == .running else { return nil }
        return segment.expectedNaturalCompletion(at: now)
    }

    /// Focus time only (completed focus segments + current focus segment if active).
    func focusedElapsed(at now: Date) -> TimeInterval {
        if let finalizedFocusSeconds { return finalizedFocusSeconds }
        var total = completedFocusSeconds
        if kind.isFocus {
            total += segment.activeElapsed(at: now)
        }
        return total
    }

    /// Active elapsed across focus and between-round breaks (excludes user pause).
    func totalElapsedIncludingBreaks(at now: Date) -> TimeInterval {
        if phase == .ended {
            return (finalizedFocusSeconds ?? completedFocusSeconds) + completedBreakSeconds
        }
        return completedFocusSeconds + completedBreakSeconds + segment.activeElapsed(at: now)
    }

    mutating func pause(at now: Date) {
        guard phase == .running else { return }
        segment.pause(at: now)
        if segment.phase == .ended {
            evaluateCompletion(at: now)
        } else {
            phase = .paused
        }
    }

    mutating func resume(at now: Date) {
        guard phase == .paused else { return }
        segment.resume(at: now)
        if segment.phase == .ended {
            evaluateCompletion(at: now)
        } else {
            phase = .running
        }
    }

    mutating func finish(at now: Date) {
        guard phase != .ended else { return }
        if kind.isFocus, segment.phase != .ended {
            completedFocusSeconds += segment.activeElapsed(at: now)
        }
        endSession(naturally: false, at: now)
    }

    mutating func evaluateCompletion(at now: Date) {
        guard phase != .ended else { return }
        var safety = 0
        while phase != .ended, safety < 64 {
            safety += 1
            if segment.phase != .ended {
                segment.evaluateCompletion(at: now)
            }
            guard segment.phase == .ended else {
                phase = segment.phase
                return
            }
            advanceAfterSegmentEnded(at: now)
        }
    }

    func makeResult(for task: TaskItem, at now: Date) -> FocusSessionResult? {
        guard phase == .ended else { return nil }
        return FocusSessionResult(
            task: task,
            plannedDurationSeconds: configuration.plannedFocusSeconds,
            focusedDurationSeconds: focusedElapsed(at: now),
            endedNaturally: endedNaturally
        )
    }

    private mutating func advanceAfterSegmentEnded(at now: Date) {
        let completedAt = segment.endedAt ?? now
        let natural = segment.endedNaturally

        switch kind {
        case .focus(let round):
            completedFocusSeconds += segment.activeElapsed(at: completedAt)
            if round >= configuration.rounds {
                endSession(naturally: natural, at: completedAt)
                return
            }
            kind = .breakTime(afterRound: round)
            segment = FocusSessionTimer(
                durationMinutes: configuration.breakMinutes,
                startedAt: completedAt
            )
            phase = .running

        case .breakTime(let afterRound):
            completedBreakSeconds += segment.activeElapsed(at: completedAt)
            kind = .focus(round: afterRound + 1)
            segment = FocusSessionTimer(
                durationMinutes: configuration.focusMinutes,
                startedAt: completedAt
            )
            phase = .running
        }
    }

    private mutating func endSession(naturally: Bool, at now: Date) {
        if kind.isBreak, segment.phase != .ended {
            completedBreakSeconds += segment.activeElapsed(at: now)
        }
        finalizedFocusSeconds = completedFocusSeconds
        endedNaturally = naturally
        phase = .ended
    }
}
