//
//  FocusSessionTimer.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

enum FocusSessionPhase: Equatable {
    case running
    case paused
    case ended
}

struct FocusSessionTimer: Equatable {
    let duration: TimeInterval

    private var startedAt: Date
    private var totalPaused: TimeInterval = 0
    private var pausedAt: Date?
    private var endedAt: Date?
    private var endedNaturally = false

    private(set) var phase: FocusSessionPhase = .running

    init(durationMinutes: Int, startedAt: Date = Date()) {
        duration = TimeInterval(durationMinutes * 60)
        self.startedAt = startedAt
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, duration - activeElapsed(at: now))
    }

    func remainingSeconds(at now: Date) -> Int {
        Int(remaining(at: now).rounded(.down))
    }

    func remainingDisplay(at now: Date) -> String {
        let total = remainingSeconds(at: now)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    func activeElapsed(at now: Date) -> TimeInterval {
        let referenceDate: Date
        switch phase {
        case .running:
            referenceDate = now
        case .paused:
            referenceDate = pausedAt ?? now
        case .ended:
            referenceDate = endedAt ?? now
        }

        let rawElapsed = referenceDate.timeIntervalSince(startedAt) - totalPaused
        return min(duration, max(0, rawElapsed))
    }

    mutating func pause(at now: Date) {
        guard phase == .running else { return }
        if remaining(at: now) <= 0 {
            end(at: now, naturally: true)
            return
        }
        pausedAt = now
        phase = .paused
    }

    mutating func resume(at now: Date) {
        guard phase == .paused, let pausedAt else { return }
        totalPaused += now.timeIntervalSince(pausedAt)
        self.pausedAt = nil
        phase = .running
        evaluateCompletion(at: now)
    }

    mutating func finish(at now: Date) {
        end(at: now, naturally: false)
    }

    mutating func evaluateCompletion(at now: Date) {
        guard phase == .running, remaining(at: now) <= 0 else { return }
        end(at: now, naturally: true)
    }

    func makeResult(for task: TaskItem, at now: Date) -> FocusSessionResult? {
        guard phase == .ended else { return nil }
        return FocusSessionResult(
            task: task,
            plannedDurationSeconds: duration,
            focusedDurationSeconds: activeElapsed(at: now),
            endedNaturally: endedNaturally
        )
    }

    private mutating func end(at now: Date, naturally: Bool) {
        guard phase != .ended else { return }
        if phase == .paused, let pausedAt {
            totalPaused += now.timeIntervalSince(pausedAt)
            self.pausedAt = nil
        }
        endedAt = now
        endedNaturally = naturally
        phase = .ended
    }
}
