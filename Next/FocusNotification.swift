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
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
    }
}

enum FocusNotificationPresentation {
    static func options(for identifier: String) -> UNNotificationPresentationOptions {
        identifier == FocusCompletionNotification.identifier ? [] : [.banner, .list, .sound]
    }
}

protocol FocusNotificationScheduling: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func schedule(_ notification: FocusCompletionNotification) async
    func cancelCompletionNotification()
}

@MainActor
final class FocusNotificationCoordinator {
    static let shared = FocusNotificationCoordinator()

    private let scheduler: FocusNotificationScheduling
    private let skipsSystemPrompt: Bool

    private(set) var scheduled: FocusCompletionNotification?
    private(set) var authorizationRequests = 0

    init(
        scheduler: FocusNotificationScheduling = SystemFocusNotificationScheduler(),
        skipsSystemPrompt: Bool = ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("UITEST_") }
    ) {
        self.scheduler = scheduler
        self.skipsSystemPrompt = skipsSystemPrompt
    }

    func sync(timer: FocusSessionTimer, taskTitle: String, at now: Date) async {
        if let fireDate = timer.expectedNaturalCompletion(at: now) {
            await scheduleIfAllowed(taskTitle: taskTitle, fireDate: fireDate)
        } else {
            cancel()
        }
    }

    func cancel() {
        scheduler.cancelCompletionNotification()
        scheduled = nil
    }

    private func scheduleIfAllowed(taskTitle: String, fireDate: Date) async {
        var status = await scheduler.authorizationStatus()
        if status == .notDetermined, !skipsSystemPrompt {
            authorizationRequests += 1
            _ = await scheduler.requestAuthorization()
            status = await scheduler.authorizationStatus()
        }

        guard status == .authorized || status == .provisional else {
            cancel()
            return
        }

        let notification = FocusCompletionNotification(taskTitle: taskTitle, fireDate: fireDate)
        await scheduler.schedule(notification)
        scheduled = notification
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
        center.removePendingNotificationRequests(withIdentifiers: [FocusCompletionNotification.identifier])
        try? await center.add(notification.request)
    }

    func cancelCompletionNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [FocusCompletionNotification.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [FocusCompletionNotification.identifier])
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
}
