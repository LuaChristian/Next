//
//  FocusNotification.swift
//  Next
//
//  Local completion notification companion. Timestamps remain source of truth.
//

import Foundation
import UserNotifications

struct FocusCompletionNotification: Equatable {
    static let identifier = "next.focus.completion"

    let taskTitle: String
    let fireDate: Date

    var title: String { "Focus complete" }

    var body: String {
        "You finished your focus session for \(taskTitle)."
    }

    var request: UNNotificationRequest {
        Self.makeRequest(identifier: Self.identifier, title: title, body: body, fireDate: fireDate)
    }

    static func makeRequest(
        identifier: String,
        title: String,
        body: String,
        fireDate: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}

struct FocusSegmentNotification: Equatable {
    static let identifier = "next.focus.segment"

    enum Kind: Equatable {
        case focusRoundComplete(round: Int, total: Int)
        case breakComplete(nextRound: Int, total: Int)
    }

    let kind: Kind
    let taskTitle: String
    let fireDate: Date

    var title: String {
        switch kind {
        case .focusRoundComplete:
            return "Break time"
        case .breakComplete:
            return "Back to focus"
        }
    }

    var body: String {
        switch kind {
        case .focusRoundComplete(let round, let total):
            return "Round \(round) of \(total) complete for \(taskTitle). Take a short break."
        case .breakComplete(let nextRound, let total):
            return "Break over. Starting round \(nextRound) of \(total) for \(taskTitle)."
        }
    }

    var request: UNNotificationRequest {
        FocusCompletionNotification.makeRequest(
            identifier: Self.identifier,
            title: title,
            body: body,
            fireDate: fireDate
        )
    }
}

enum FocusNotificationPresentation {
    static func options(for identifier: String) -> UNNotificationPresentationOptions {
        switch identifier {
        case FocusCompletionNotification.identifier, FocusSegmentNotification.identifier:
            return []
        default:
            return [.banner, .list, .sound]
        }
    }
}

protocol FocusNotificationScheduling: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func schedule(_ notification: FocusCompletionNotification) async
    func scheduleSegment(_ notification: FocusSegmentNotification) async
    func cancelCompletionNotification()
}

@MainActor
final class FocusNotificationCoordinator {
    static let shared = FocusNotificationCoordinator()

    private let scheduler: FocusNotificationScheduling
    private let skipsSystemPrompt: Bool

    private(set) var scheduled: FocusCompletionNotification?
    private(set) var scheduledSegment: FocusSegmentNotification?
    private(set) var authorizationRequests = 0

    /// Serializes overlapping syncs so a late schedule cannot resurrect a cancel.
    private var syncChain: Task<Void, Never>?

    init(
        scheduler: FocusNotificationScheduling = SystemFocusNotificationScheduler(),
        skipsSystemPrompt: Bool = NextUITestLaunch.isActive
    ) {
        self.scheduler = scheduler
        self.skipsSystemPrompt = skipsSystemPrompt
    }

    func sync(timer: FocusSessionTimer, taskTitle: String, at now: Date) async {
        let previous = syncChain
        let work = Task { @MainActor in
            await previous?.value
            guard !Task.isCancelled else { return }
            await self.performSync(timer: timer, taskTitle: taskTitle, at: now)
        }
        syncChain = work
        await work.value
    }

    func sync(pomodoro: PomodoroSessionTimer, taskTitle: String, at now: Date) async {
        let previous = syncChain
        let work = Task { @MainActor in
            await previous?.value
            guard !Task.isCancelled else { return }
            await self.performSync(pomodoro: pomodoro, taskTitle: taskTitle, at: now)
        }
        syncChain = work
        await work.value
    }

    func cancel() {
        syncChain?.cancel()
        syncChain = nil
        scheduler.cancelCompletionNotification()
        scheduled = nil
        scheduledSegment = nil
    }

    private func performSync(timer: FocusSessionTimer, taskTitle: String, at now: Date) async {
        scheduledSegment = nil
        if let fireDate = timer.expectedNaturalCompletion(at: now) {
            await scheduleCompletionIfAllowed(taskTitle: taskTitle, fireDate: fireDate)
        } else {
            clearPending()
        }
    }

    private func performSync(pomodoro: PomodoroSessionTimer, taskTitle: String, at now: Date) async {
        guard let fireDate = pomodoro.expectedNaturalCompletion(at: now) else {
            clearPending()
            return
        }

        if pomodoro.willCompleteSessionAtNextNaturalEnd {
            scheduledSegment = nil
            await scheduleCompletionIfAllowed(taskTitle: taskTitle, fireDate: fireDate)
            return
        }

        scheduled = nil
        let kind: FocusSegmentNotification.Kind
        switch pomodoro.kind {
        case .focus(let round):
            kind = .focusRoundComplete(round: round, total: pomodoro.totalRounds)
        case .breakTime(let afterRound):
            kind = .breakComplete(nextRound: afterRound + 1, total: pomodoro.totalRounds)
        }
        await scheduleSegmentIfAllowed(
            FocusSegmentNotification(kind: kind, taskTitle: taskTitle, fireDate: fireDate)
        )
    }

    private func clearPending() {
        scheduler.cancelCompletionNotification()
        scheduled = nil
        scheduledSegment = nil
    }

    private func scheduleCompletionIfAllowed(taskTitle: String, fireDate: Date) async {
        guard await ensureAuthorized() else {
            clearPending()
            return
        }
        guard !Task.isCancelled else { return }

        let notification = FocusCompletionNotification(taskTitle: taskTitle, fireDate: fireDate)
        await scheduler.schedule(notification)
        guard !Task.isCancelled else {
            clearPending()
            return
        }
        scheduled = notification
        scheduledSegment = nil
    }

    private func scheduleSegmentIfAllowed(_ notification: FocusSegmentNotification) async {
        guard await ensureAuthorized() else {
            clearPending()
            return
        }
        guard !Task.isCancelled else { return }

        await scheduler.scheduleSegment(notification)
        guard !Task.isCancelled else {
            clearPending()
            return
        }
        scheduledSegment = notification
        scheduled = nil
    }

    private func ensureAuthorized() async -> Bool {
        var status = await scheduler.authorizationStatus()
        if status == .notDetermined, !skipsSystemPrompt {
            authorizationRequests += 1
            _ = await scheduler.requestAuthorization()
            status = await scheduler.authorizationStatus()
        }
        return status == .authorized || status == .provisional
    }
}

final class SystemFocusNotificationScheduler: FocusNotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ notification: FocusCompletionNotification) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            FocusCompletionNotification.identifier,
            FocusSegmentNotification.identifier
        ])
        try? await center.add(notification.request)
    }

    func scheduleSegment(_ notification: FocusSegmentNotification) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            FocusCompletionNotification.identifier,
            FocusSegmentNotification.identifier
        ])
        try? await center.add(notification.request)
    }

    func cancelCompletionNotification() {
        let center = UNUserNotificationCenter.current()
        let ids = [
            FocusCompletionNotification.identifier,
            FocusSegmentNotification.identifier
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }
}

final class NextNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NextNotificationCenterDelegate()

    static func register() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        FocusNotificationPresentation.options(for: notification.request.identifier)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        guard identifier == DailyReminder.identifier else { return }
        await MainActor.run {
            guard !FocusSessionPresence.isActive else { return }
            NotificationCenter.default.post(name: .nextPreferHomeTab, object: nil)
        }
    }
}
