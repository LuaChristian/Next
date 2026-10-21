//
//  DailyReminderCoordinator.swift
//  Next
//
//  Schedules at most one pending daily reminder. Never touches M4 completion ids.
//

import Foundation
import SwiftData
import UIKit
import UserNotifications

protocol DailyReminderScheduling: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func pendingReminderIdentifiers() async -> [String]
    func scheduleReminder(_ request: UNNotificationRequest) async
    func cancelReminderNotifications()
}

enum DailyReminderAuthorization {
    case authorized
    case provisional
    case denied
    case notDetermined
    case unavailable

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        case .ephemeral: self = .unavailable
        @unknown default: self = .unavailable
        }
    }

    var canDeliver: Bool {
        self == .authorized || self == .provisional
    }
}

@MainActor
final class DailyReminderCoordinator {
    static let shared = DailyReminderCoordinator()

    private let scheduler: DailyReminderScheduling
    private let skipsSystemPrompt: Bool
    private let defaults: UserDefaults
    private let calendar: Calendar

    private(set) var lastScheduledFireDate: Date?
    private(set) var authorizationRequests = 0

    init(
        scheduler: DailyReminderScheduling = SystemDailyReminderScheduler(),
        skipsSystemPrompt: Bool = NextUITestLaunch.isActive,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.skipsSystemPrompt = skipsSystemPrompt
        self.defaults = defaults
        self.calendar = calendar
    }

    func authorization() async -> DailyReminderAuthorization {
        DailyReminderAuthorization(await scheduler.authorizationStatus())
    }

    /// Enable reminders: request permission if needed. Returns whether delivery is possible.
    @discardableResult
    func enable(now: Date = Date(), hasFocusedToday: Bool) async -> DailyReminderAuthorization {
        var auth = await authorization()
        if auth == .notDetermined, !skipsSystemPrompt {
            authorizationRequests += 1
            _ = await scheduler.requestAuthorization()
            auth = await authorization()
        }

        if auth.canDeliver {
            ReminderPreference.setEnabled(true, in: defaults)
            await scheduleNext(now: now, hasFocusedToday: hasFocusedToday)
        } else {
            // Never leave a misleading enabled preference when the system cannot deliver.
            ReminderPreference.setEnabled(false, in: defaults)
            cancelRemindersOnly()
        }
        return auth
    }

    func disable() {
        ReminderPreference.setEnabled(false, in: defaults)
        cancelRemindersOnly()
    }

    func updateTime(hour: Int, minute: Int, now: Date = Date(), hasFocusedToday: Bool) async {
        ReminderPreference.setTime(hour: hour, minute: minute, in: defaults)
        guard ReminderPreference.isEnabled(in: defaults) else { return }
        await reconcile(now: now, hasFocusedToday: hasFocusedToday)
    }

    /// Call on preference changes and when the app becomes active.
    func reconcile(now: Date = Date(), hasFocusedToday: Bool) async {
        guard ReminderPreference.isEnabled(in: defaults) else {
            cancelRemindersOnly()
            return
        }

        let auth = await authorization()
        guard auth.canDeliver else {
            ReminderPreference.setEnabled(false, in: defaults)
            cancelRemindersOnly()
            return
        }

        await scheduleNext(now: now, hasFocusedToday: hasFocusedToday)
    }

    func reconcile(now: Date = Date(), context: ModelContext) async {
        let hasFocused = Self.hasFocusedToday(context: context, now: now, calendar: calendar)
        await reconcile(now: now, hasFocusedToday: hasFocused)
    }

    static func hasFocusedToday(
        context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        return DailyReminder.hasFocusedToday(
            completedAtDates: sessions.map(\.completedAt),
            now: now,
            calendar: calendar
        )
    }

    /// Cancels only `next.reminder.daily` — never M4 completion notifications.
    func cancelRemindersOnly() {
        scheduler.cancelReminderNotifications()
        lastScheduledFireDate = nil
    }

    private func scheduleNext(now: Date, hasFocusedToday: Bool) async {
        let fire = DailyReminder.nextFireDate(
            now: now,
            hour: ReminderPreference.hour(in: defaults),
            minute: ReminderPreference.minute(in: defaults),
            hasFocusedToday: hasFocusedToday,
            calendar: calendar
        )
        let request = DailyReminder.request(fireDate: fire, calendar: calendar)

        // Replace any existing reminder request so duplicates cannot accumulate.
        scheduler.cancelReminderNotifications()
        await scheduler.scheduleReminder(request)
        lastScheduledFireDate = fire
    }
}

final class SystemDailyReminderScheduler: DailyReminderScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus {
        if let override = ReminderPreference.launchAuthorizationOverride() {
            return override
        }
        return await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        if let override = ReminderPreference.launchAuthorizationOverride() {
            return override == .authorized || override == .provisional
        }
        return (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func pendingReminderIdentifiers() async -> [String] {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.map(\.identifier).filter { $0 == DailyReminder.identifier }
    }

    func scheduleReminder(_ request: UNNotificationRequest) async {
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelReminderNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [DailyReminder.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [DailyReminder.identifier])
    }
}

enum DailyReminderSettingsLink {
    static func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
