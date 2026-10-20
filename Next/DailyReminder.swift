//
//  DailyReminder.swift
//  Next
//
//  Pure scheduling + copy for optional daily focus invitations.
//  Distinct from FocusCompletionNotification (M4).
//

import Foundation
import UserNotifications

enum DailyReminder {
    /// Single logical daily reminder. Never reuse the M4 completion id.
    static let identifier = "next.reminder.daily"

    static let messages = [
        "A little time for what matters?",
        "Ready to make your next few minutes count?",
        "Your next step is here when you're ready."
    ]

    static func message(for fireDate: Date, calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .year, for: fireDate) ?? 1
        return messages[(day - 1) % messages.count]
    }

    /// Next one-shot fire time.
    ///
    /// - If the user already focused today → tomorrow at the reminder clock time.
    /// - Else if today's clock time is still ahead → today.
    /// - Else → tomorrow.
    ///
    /// Uses local calendar components so DST transitions stay correct.
    static func nextFireDate(
        now: Date,
        hour: Int,
        minute: Int,
        hasFocusedToday: Bool,
        calendar: Calendar = .current
    ) -> Date {
        var parts = calendar.dateComponents([.year, .month, .day], from: now)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        let todayFire = calendar.date(from: parts) ?? now

        if hasFocusedToday {
            return calendar.date(byAdding: .day, value: 1, to: todayFire) ?? todayFire
        }
        if now < todayFire {
            return todayFire
        }
        return calendar.date(byAdding: .day, value: 1, to: todayFire) ?? todayFire
    }

    static func hasFocusedToday(
        completedAtDates: [Date],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        completedAtDates.contains { calendar.isDate($0, inSameDayAs: now) }
    }

    static func request(fireDate: Date, calendar: Calendar = .current) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Next"
        content.body = message(for: fireDate, calendar: calendar)
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
