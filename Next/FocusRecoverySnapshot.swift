//
//  FocusRecoverySnapshot.swift
//  Next
//
//  Durable unfinished-focus recovery. Not a completed FocusSession / History row.
//  Local JSON via UserDefaults suite (atomic replace). No SwiftData schema change.
//

import Foundation
import SwiftData

enum FocusRecoveryModeKind: String, Codable, Equatable {
    case simple
    case pomodoro
}

/// Minimum durable state to reconstruct an unfinished focus experience.
struct FocusRecoverySnapshot: Equatable, Codable {
    static let currentVersion = 1

    var version: Int
    /// Stable identity for exactly-once FocusSession commit.
    var experienceID: UUID
    var savedAt: Date

    var taskID: UUID
    var goalID: UUID?
    var taskTitle: String
    var goalTitle: String
    var taskDurationMinutes: Int
    var energyRequiredRaw: String
    var area: String

    var bankedFocusSeconds: TimeInterval
    var mode: FocusRecoveryModeKind

    var simple: FocusSessionTimer.Snapshot?
    var pomodoro: PomodoroSessionTimer.Snapshot?

    /// When the timer already ended (natural or early) but completion UI was not committed.
    var awaitingCompletion: Bool
    var completionPlannedSeconds: TimeInterval?
    var completionFocusedSeconds: TimeInterval?
    var completionEndedNaturally: Bool?

    func makeTaskItem() -> TaskItem {
        TaskItem(
            id: taskID,
            goalID: goalID,
            title: taskTitle,
            durationMinutes: max(1, taskDurationMinutes),
            energyRequired: EnergyLevel(rawValue: energyRequiredRaw) ?? .good,
            area: area,
            goal: goalTitle
        )
    }
}

enum FocusRecoveryClockPolicy {
    /// Maximum wall time we will advance a running session in one reconcile.
    /// Longer absences still advance via segment catch-up, but absurd jumps are frozen.
    static let maxForwardAdvance: TimeInterval = 7 * 24 * 60 * 60

    /// Resolve the evaluation clock for recovery.
    /// - Clock moved backward (`now < savedAt`): freeze at `savedAt` (no invented focus, no rewind).
    /// - Extreme forward jump: clamp advance to `maxForwardAdvance` from `savedAt`.
    static func evaluationDate(now: Date, savedAt: Date) -> Date {
        if now < savedAt {
            return savedAt
        }
        let delta = now.timeIntervalSince(savedAt)
        if delta > maxForwardAdvance {
            return savedAt.addingTimeInterval(maxForwardAdvance)
        }
        return now
    }

    /// When the wall clock moved backward, keep a running timer from inventing remaining time
    /// by freezing it as paused at the saved moment.
    static func shouldFreezeRunningAsPaused(now: Date, savedAt: Date) -> Bool {
        now < savedAt
    }
}

enum FocusRecoveryStore {
    static let key = "focus.recovery.snapshot.v1"

    static func store(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        FocusPreference.store(arguments: arguments)
    }

    static func load(
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> FocusRecoverySnapshot? {
        let defaults = defaults ?? store(arguments: arguments)
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            let decoded = try JSONDecoder().decode(FocusRecoverySnapshot.self, from: data)
            return validate(decoded)
        } catch {
            defaults.removeObject(forKey: key)
            return nil
        }
    }

    /// Load a snapshot for auto-restore. If a FocusSession already exists for
    /// `experienceID` (commit succeeded, cleanup interrupted), discard the stale
    /// snapshot instead of reopening a completed experience.
    static func loadForPresentation(
        context: ModelContext,
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> FocusRecoverySnapshot? {
        guard let snapshot = load(in: defaults, arguments: arguments) else { return nil }
        if experienceAlreadyCommitted(snapshot.experienceID, context: context) {
            clear(in: defaults, arguments: arguments)
            return nil
        }
        return snapshot
    }

    static func experienceAlreadyCommitted(_ experienceID: UUID, context: ModelContext) -> Bool {
        let id = experienceID
        let found = try? context.fetch(
            FetchDescriptor<FocusSession>(predicate: #Predicate { $0.id == id })
        )
        return !(found ?? []).isEmpty
    }

    static func save(
        _ snapshot: FocusRecoverySnapshot,
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        guard let clean = validate(snapshot) else {
            clear(in: defaults, arguments: arguments)
            return
        }
        let defaults = defaults ?? store(arguments: arguments)
        do {
            let data = try JSONEncoder().encode(clean)
            defaults.set(data, forKey: key)
        } catch {
            defaults.removeObject(forKey: key)
        }
    }

    static func clear(
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        (defaults ?? store(arguments: arguments)).removeObject(forKey: key)
    }

    /// Reject malformed or contradictory snapshots rather than inventing state.
    static func validate(_ snapshot: FocusRecoverySnapshot) -> FocusRecoverySnapshot? {
        guard snapshot.version == FocusRecoverySnapshot.currentVersion else { return nil }
        guard !snapshot.taskTitle.isEmpty else { return nil }
        guard snapshot.bankedFocusSeconds >= 0, snapshot.bankedFocusSeconds < 7 * 24 * 3600 else {
            return nil
        }

        switch snapshot.mode {
        case .simple:
            guard let simple = snapshot.simple, simple.duration > 0 else { return nil }
            guard snapshot.pomodoro == nil else { return nil }
        case .pomodoro:
            guard let pomodoro = snapshot.pomodoro else { return nil }
            guard snapshot.simple == nil else { return nil }
            let config = pomodoro.configuration.sanitized()
            guard config.focusMinutes >= 5, config.rounds >= 1 else { return nil }
        }

        if snapshot.awaitingCompletion {
            guard let focused = snapshot.completionFocusedSeconds, focused >= 0 else { return nil }
            guard let planned = snapshot.completionPlannedSeconds, planned >= 0 else { return nil }
        }

        return snapshot
    }
}

/// Builds and writes recovery snapshots immediately on state changes
/// (start / pause / resume / mode switch) — not only on scenePhase.
enum FocusRecoveryPersistence {
    static func makeSnapshot(
        experienceID: UUID,
        task: TaskItem,
        bankedFocusSeconds: TimeInterval,
        simple: FocusSessionTimer.Snapshot?,
        pomodoro: PomodoroSessionTimer.Snapshot?,
        result: FocusSessionResult?,
        at current: Date
    ) -> FocusRecoverySnapshot {
        var snapshot = FocusRecoverySnapshot(
            version: FocusRecoverySnapshot.currentVersion,
            experienceID: experienceID,
            savedAt: current,
            taskID: task.id,
            goalID: task.goalID,
            taskTitle: task.title,
            goalTitle: task.goal,
            taskDurationMinutes: task.durationMinutes,
            energyRequiredRaw: task.energyRequired.rawValue,
            area: task.area,
            bankedFocusSeconds: bankedFocusSeconds,
            mode: pomodoro != nil ? .pomodoro : .simple,
            simple: simple,
            pomodoro: pomodoro,
            awaitingCompletion: false,
            completionPlannedSeconds: nil,
            completionFocusedSeconds: nil,
            completionEndedNaturally: nil
        )

        if let result {
            snapshot.awaitingCompletion = true
            snapshot.completionPlannedSeconds = result.plannedDurationSeconds
            snapshot.completionFocusedSeconds = result.focusedDurationSeconds
            snapshot.completionEndedNaturally = result.endedNaturally
            snapshot.bankedFocusSeconds = 0
        }

        return snapshot
    }

    /// Durable write used at session start and after each authoritative mutation.
    static func writeImmediate(
        experienceID: UUID,
        task: TaskItem,
        bankedFocusSeconds: TimeInterval,
        simple: FocusSessionTimer.Snapshot?,
        pomodoro: PomodoroSessionTimer.Snapshot?,
        result: FocusSessionResult? = nil,
        at current: Date = Date(),
        in defaults: UserDefaults? = nil
    ) {
        let snapshot = makeSnapshot(
            experienceID: experienceID,
            task: task,
            bankedFocusSeconds: bankedFocusSeconds,
            simple: simple,
            pomodoro: pomodoro,
            result: result,
            at: current
        )
        FocusRecoveryStore.save(snapshot, in: defaults)
    }
}

/// Reconstructed in-memory focus state after loading a snapshot.
struct FocusRecoveryBootstrap: Equatable {
    var experienceID: UUID
    var task: TaskItem
    var bankedFocusSeconds: TimeInterval
    var mode: FocusRunModeRestore
    var result: FocusSessionResult?
}

enum FocusRunModeRestore: Equatable {
    case simple(FocusSessionTimer)
    case pomodoro(PomodoroSessionTimer)
}

enum FocusRecoveryReconciler {
    /// Load, validate, and reconcile a snapshot against `now`.
    static func restore(
        snapshot: FocusRecoverySnapshot,
        now: Date = Date()
    ) -> FocusRecoveryBootstrap? {
        guard let snapshot = FocusRecoveryStore.validate(snapshot) else { return nil }

        let task = snapshot.makeTaskItem()
        let evalAt: Date
        var working = snapshot

        if FocusRecoveryClockPolicy.shouldFreezeRunningAsPaused(now: now, savedAt: snapshot.savedAt) {
            working = freezeRunningAsPaused(snapshot)
            evalAt = snapshot.savedAt
        } else {
            evalAt = FocusRecoveryClockPolicy.evaluationDate(now: now, savedAt: snapshot.savedAt)
        }

        if working.awaitingCompletion {
            let planned = working.completionPlannedSeconds ?? 0
            let focused = working.completionFocusedSeconds ?? 0
            let natural = working.completionEndedNaturally ?? true
            return FocusRecoveryBootstrap(
                experienceID: working.experienceID,
                task: task,
                bankedFocusSeconds: 0,
                mode: .simple(FocusSessionTimer(durationMinutes: task.durationMinutes)),
                result: FocusSessionResult(
                    task: task,
                    plannedDurationSeconds: planned,
                    focusedDurationSeconds: focused,
                    endedNaturally: natural
                )
            )
        }

        switch working.mode {
        case .simple:
            guard var timer = working.simple.map(FocusSessionTimer.init(restoring:)) else { return nil }
            if timer.phase == .running {
                timer.evaluateCompletion(at: evalAt)
            }
            if timer.phase == .ended {
                let raw = timer.makeResult(for: task, at: evalAt)!
                let merged = FocusSessionAccounting.mergeBankedFocus(working.bankedFocusSeconds, into: raw)
                return FocusRecoveryBootstrap(
                    experienceID: working.experienceID,
                    task: task,
                    bankedFocusSeconds: 0,
                    mode: .simple(timer),
                    result: merged
                )
            }
            return FocusRecoveryBootstrap(
                experienceID: working.experienceID,
                task: task,
                bankedFocusSeconds: working.bankedFocusSeconds,
                mode: .simple(timer),
                result: nil
            )

        case .pomodoro:
            guard var session = working.pomodoro.map(PomodoroSessionTimer.init(restoring:)) else {
                return nil
            }
            if session.phase == .running {
                session.evaluateCompletion(at: evalAt)
            }
            if session.phase == .ended {
                let raw = session.makeResult(for: task, at: evalAt)!
                let merged = FocusSessionAccounting.mergeBankedFocus(working.bankedFocusSeconds, into: raw)
                return FocusRecoveryBootstrap(
                    experienceID: working.experienceID,
                    task: task,
                    bankedFocusSeconds: 0,
                    mode: .pomodoro(session),
                    result: merged
                )
            }
            return FocusRecoveryBootstrap(
                experienceID: working.experienceID,
                task: task,
                bankedFocusSeconds: working.bankedFocusSeconds,
                mode: .pomodoro(session),
                result: nil
            )
        }
    }

    private static func freezeRunningAsPaused(_ snapshot: FocusRecoverySnapshot) -> FocusRecoverySnapshot {
        var copy = snapshot
        switch copy.mode {
        case .simple:
            if var simple = copy.simple, simple.phase == .running {
                simple.phase = .paused
                simple.pausedAt = snapshot.savedAt
                copy.simple = simple
            }
        case .pomodoro:
            if var pomo = copy.pomodoro, pomo.phase == .running {
                pomo.phase = .paused
                var segment = pomo.segment
                if segment.phase == .running {
                    segment.phase = .paused
                    segment.pausedAt = snapshot.savedAt
                }
                pomo.segment = segment
                copy.pomodoro = pomo
            }
        }
        return copy
    }
}
