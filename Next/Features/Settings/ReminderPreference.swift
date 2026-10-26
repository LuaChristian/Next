//
//  ReminderPreference.swift
//  Next
//
//  Optional daily focus invitation. UserDefaults only — not SwiftData.
//

import Foundation
import UserNotifications

enum ReminderPreference {
    static let enabledKey = "dailyReminderEnabled"
    static let hourKey = "dailyReminderHour"
    static let minuteKey = "dailyReminderMinute"

    /// Calm morning default. User can change anytime.
    static let defaultHour = 9
    static let defaultMinute = 0

    /// UITest: `UITEST_REMINDER_AUTH` followed by `authorized` | `denied` | `provisional` | `notDetermined`.
    static let authLaunchArgument = "UITEST_REMINDER_AUTH"
    /// UITest: `UITEST_REMINDER` followed by `on` | `off`.
    static let enabledLaunchArgument = "UITEST_REMINDER"
    /// UITest: `UITEST_REMINDER_HOUR` / `UITEST_REMINDER_MINUTE` followed by integers.
    static let hourLaunchArgument = "UITEST_REMINDER_HOUR"
    static let minuteLaunchArgument = "UITEST_REMINDER_MINUTE"

    static func isEnabled(in defaults: UserDefaults? = nil) -> Bool {
        (defaults ?? .standard).bool(forKey: enabledKey)
    }

    static func setEnabled(_ value: Bool, in defaults: UserDefaults? = nil) {
        (defaults ?? .standard).set(value, forKey: enabledKey)
    }

    static func hour(in defaults: UserDefaults? = nil) -> Int {
        let defaults = defaults ?? .standard
        if defaults.object(forKey: hourKey) == nil { return defaultHour }
        return defaults.integer(forKey: hourKey)
    }

    static func minute(in defaults: UserDefaults? = nil) -> Int {
        let defaults = defaults ?? .standard
        if defaults.object(forKey: minuteKey) == nil { return defaultMinute }
        return defaults.integer(forKey: minuteKey)
    }

    static func setTime(hour: Int, minute: Int, in defaults: UserDefaults? = nil) {
        let defaults = defaults ?? .standard
        defaults.set(min(max(hour, 0), 23), forKey: hourKey)
        defaults.set(min(max(minute, 0), 59), forKey: minuteKey)
    }

    static func timeDate(
        on day: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults? = nil
    ) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour(in: defaults)
        components.minute = minute(in: defaults)
        components.second = 0
        return calendar.date(from: components) ?? day
    }

    /// Human-readable clock for VoiceOver / review screenshots.
    static func timeSummary(
        defaults: UserDefaults? = nil,
        calendar: Calendar = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "Around \(formatter.string(from: timeDate(calendar: calendar, defaults: defaults)))"
    }

    /// Apply UITest launch overrides before first scene. Does not request notification permission.
    /// No-op in Release — production must never inherit test reminder state from launch args.
    static func applyLaunchOverrides(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if DEBUG
        if let value = valueAfter(enabledLaunchArgument, in: arguments) {
            setEnabled(value == "on" || value == "1" || value == "true")
        }
        if let hourValue = valueAfter(hourLaunchArgument, in: arguments), let hour = Int(hourValue) {
            setTime(hour: hour, minute: minute())
        }
        if let minuteValue = valueAfter(minuteLaunchArgument, in: arguments), let minute = Int(minuteValue) {
            setTime(hour: hour(), minute: minute)
        }
        #else
        _ = arguments
        #endif
    }

    static func launchAuthorizationOverride(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> UNAuthorizationStatus? {
        #if DEBUG
        guard let value = valueAfter(authLaunchArgument, in: arguments) else { return nil }
        switch value {
        case "authorized": return .authorized
        case "denied": return .denied
        case "provisional": return .provisional
        case "notDetermined": return .notDetermined
        default: return nil
        }
        #else
        _ = arguments
        return nil
        #endif
    }

    private static func valueAfter(_ flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
