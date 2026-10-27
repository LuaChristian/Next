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
    /// Maximum age of a recovery snapshot before it is discarded as stale.
    static let maxSnapshotAge: TimeInterval = 7 * 24 * 60 * 60

    /// Cold-launch recovery never credits wall time that passed while the process was dead.
    /// Running timers are frozen as paused at `savedAt`. In-process background/foreground
    /// catch-up remains the responsibility of the live FocusView (timestamp-based refresh).
    static func shouldFreezeRunningAsPaused(now: Date, savedAt: Date) -> Bool {
        // Always freeze on cold-launch restore. `now` / `savedAt` retained for call-site clarity
        // and clock-skew documentation; forward absence is intentionally not credited.
        _ = (now, savedAt)
        return true
    }

    /// Snapshots older than `maxSnapshotAge` are discarded rather than resumed.
    static func isStale(now: Date, savedAt: Date) -> Bool {
        now.timeIntervalSince(savedAt) > maxSnapshotAge || now < savedAt.addingTimeInterval(-maxSnapshotAge)
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

    /// Persist a restored bootstrap immediately (Resume / End / awaiting-completion).
    /// Must not wait for FocusView.onAppear — kill before appear must not lose intent.
    static func writeBootstrap(
        _ bootstrap: FocusRecoveryBootstrap,
        at current: Date = Date(),
        in defaults: UserDefaults? = nil
    ) {
        let simple: FocusSessionTimer.Snapshot?
        let pomodoro: PomodoroSessionTimer.Snapshot?
        switch bootstrap.mode {
        case .simple(let timer):
            simple = timer.snapshot
            pomodoro = nil
        case .pomodoro(let session):
            simple = nil
            pomodoro = session.snapshot
        }
        writeImmediate(
            experienceID: bootstrap.experienceID,
            task: bootstrap.task,
            bankedFocusSeconds: bootstrap.bankedFocusSeconds,
            simple: simple,
            pomodoro: pomodoro,
            result: bootstrap.result,
            at: current,
            in: defaults
        )
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

/// Display model for the calm cold-launch recovery prompt.
struct FocusRecoveryPromptModel: Equatable, Identifiable {
    var id: UUID { experienceID }

    let experienceID: UUID
    let taskTitle: String
    let goalTitle: String
    let modeLabel: String
    let earnedFocusSeconds: TimeInterval
    let wasInterruptedWhileRunning: Bool
    /// Frozen bootstrap ready for Resume / End Session (never auto-running).
    let bootstrap: FocusRecoveryBootstrap
}

enum FocusRecoveryReconciler {
    /// Load, validate, and reconcile a snapshot for cold launch.
    /// Running timers are frozen as paused at `savedAt` — death-gap wall time is never focus.
    static func restore(
        snapshot: FocusRecoverySnapshot,
        now: Date = Date()
    ) -> FocusRecoveryBootstrap? {
        guard let snapshot = FocusRecoveryStore.validate(snapshot) else { return nil }
        if FocusRecoveryClockPolicy.isStale(now: now, savedAt: snapshot.savedAt) {
            return nil
        }

        let task = snapshot.makeTaskItem()
        var working = snapshot

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

        // Conservative policy: never evaluateCompletion across the termination gap.
        if FocusRecoveryClockPolicy.shouldFreezeRunningAsPaused(now: now, savedAt: snapshot.savedAt) {
            working = freezeRunningAsPaused(snapshot)
        }

        switch working.mode {
        case .simple:
            guard let timer = working.simple.map(FocusSessionTimer.init(restoring:)) else { return nil }
            // Ended-while-paused should not occur; unfinished snapshots stay active/paused.
            return FocusRecoveryBootstrap(
                experienceID: working.experienceID,
                task: task,
                bankedFocusSeconds: working.bankedFocusSeconds,
                mode: .simple(timer),
                result: nil
            )

        case .pomodoro:
            guard let session = working.pomodoro.map(PomodoroSessionTimer.init(restoring:)) else {
                return nil
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

    /// Build the calm recovery prompt. Returns nil for awaiting-completion (open Completion directly).
    static func makePrompt(
        snapshot: FocusRecoverySnapshot,
        now: Date = Date()
    ) -> FocusRecoveryPromptModel? {
        guard let snapshot = FocusRecoveryStore.validate(snapshot) else { return nil }
        if snapshot.awaitingCompletion { return nil }
        guard let bootstrap = restore(snapshot: snapshot, now: now) else { return nil }

        let wasRunning = isRunning(snapshot)
        let earned = earnedFocusSeconds(from: bootstrap, at: snapshot.savedAt)

        return FocusRecoveryPromptModel(
            experienceID: bootstrap.experienceID,
            taskTitle: bootstrap.task.title,
            goalTitle: bootstrap.task.goal,
            modeLabel: modeLabel(for: bootstrap),
            earnedFocusSeconds: earned,
            wasInterruptedWhileRunning: wasRunning,
            bootstrap: bootstrap
        )
    }

    /// Persist the frozen paused form of a running snapshot so a second kill during the
    /// prompt cannot reintroduce a running phase.
    static func persistFrozenSnapshotIfNeeded(
        _ snapshot: FocusRecoverySnapshot,
        now: Date = Date(),
        in defaults: UserDefaults? = nil
    ) {
        guard FocusRecoveryStore.validate(snapshot) != nil else { return }
        guard !snapshot.awaitingCompletion else { return }
        guard isRunning(snapshot) else { return }
        var frozen = freezeRunningAsPaused(snapshot)
        frozen.savedAt = min(now, snapshot.savedAt)
        FocusRecoveryStore.save(frozen, in: defaults)
    }

    /// User chose Resume — start the recovered (paused) timers at `now`.
    static func resume(
        _ bootstrap: FocusRecoveryBootstrap,
        at now: Date = Date()
    ) -> FocusRecoveryBootstrap {
        var boot = bootstrap
        switch boot.mode {
        case .simple(var timer):
            if timer.phase == .paused {
                timer.resume(at: now)
            }
            boot.mode = .simple(timer)
        case .pomodoro(var session):
            if session.phase == .paused {
                session.resume(at: now)
            }
            boot.mode = .pomodoro(session)
        }
        return boot
    }

    /// Resume and durable-write immediately (survives kill before FocusView.onAppear).
    static func resumeAndPersist(
        _ bootstrap: FocusRecoveryBootstrap,
        at now: Date = Date(),
        in defaults: UserDefaults? = nil
    ) -> FocusRecoveryBootstrap {
        let resumed = resume(bootstrap, at: now)
        FocusRecoveryPersistence.writeBootstrap(resumed, at: now, in: defaults)
        return resumed
    }

    /// User chose End Session — finish without crediting death-gap time (paused finish).
    static func endSession(
        _ bootstrap: FocusRecoveryBootstrap,
        at now: Date = Date()
    ) -> FocusRecoveryBootstrap {
        var boot = bootstrap
        let task = boot.task
        switch boot.mode {
        case .simple(var timer):
            if timer.phase != .ended {
                timer.finish(at: now)
            }
            if let raw = timer.makeResult(for: task, at: now) {
                boot.result = FocusSessionAccounting.mergeBankedFocus(boot.bankedFocusSeconds, into: raw)
                boot.bankedFocusSeconds = 0
            }
            boot.mode = .simple(timer)
        case .pomodoro(var session):
            if session.phase != .ended {
                session.finish(at: now)
            }
            if let raw = session.makeResult(for: task, at: now) {
                boot.result = FocusSessionAccounting.mergeBankedFocus(boot.bankedFocusSeconds, into: raw)
                boot.bankedFocusSeconds = 0
            }
            boot.mode = .pomodoro(session)
        }
        return boot
    }

    /// End Session and durable-write awaiting-completion immediately.
    static func endSessionAndPersist(
        _ bootstrap: FocusRecoveryBootstrap,
        at now: Date = Date(),
        in defaults: UserDefaults? = nil
    ) -> FocusRecoveryBootstrap {
        let ended = endSession(bootstrap, at: now)
        FocusRecoveryPersistence.writeBootstrap(ended, at: now, in: defaults)
        return ended
    }

    static func earnedFocusSeconds(from bootstrap: FocusRecoveryBootstrap, at now: Date) -> TimeInterval {
        let current: TimeInterval
        switch bootstrap.mode {
        case .simple(let timer):
            current = timer.phase == .ended ? 0 : timer.activeElapsed(at: now)
        case .pomodoro(let session):
            current = session.phase == .ended ? 0 : session.focusedElapsed(at: now)
        }
        return FocusSessionAccounting.displayedAccumulatedFocus(
            banked: bootstrap.bankedFocusSeconds,
            currentFocused: current
        )
    }

    static func modeLabel(for bootstrap: FocusRecoveryBootstrap) -> String {
        switch bootstrap.mode {
        case .simple:
            return "Simple Focus"
        case .pomodoro(let session):
            if session.isOnBreak {
                return "Pomodoro · Break"
            }
            return "Pomodoro · Focus"
        }
    }

    private static func isRunning(_ snapshot: FocusRecoverySnapshot) -> Bool {
        switch snapshot.mode {
        case .simple:
            return snapshot.simple?.phase == .running
        case .pomodoro:
            return snapshot.pomodoro?.phase == .running
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
