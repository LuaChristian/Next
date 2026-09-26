//
//  HistoryPresentation.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

struct HistorySessionRecord: Identifiable, Equatable, Hashable {
    let id: UUID
    let completedAt: Date
    let focusedDurationSeconds: TimeInterval
    let taskWasFinished: Bool
    let taskTitle: String
    let goalTitle: String
}

struct HistoryWeeklySummary: Equatable {
    var focusedDuration: TimeInterval
    var sessionCount: Int
    var tasksFinished: Int

    static let empty = HistoryWeeklySummary(focusedDuration: 0, sessionCount: 0, tasksFinished: 0)

    var tasksFinishedLabel: String {
        tasksFinished == 1 ? "TASK FINISHED" : "TASKS FINISHED"
    }

    var sessionsLabel: String {
        sessionCount == 1 ? "SESSION" : "SESSIONS"
    }

    var accessibilityLabel: String {
        let focused = GardenMetrics.focusedDurationSpoken(seconds: focusedDuration)
        let sessions = GardenMetrics.sessionCountSpoken(sessionCount)
        let finished = tasksFinished == 1 ? "1 task finished" : "\(tasksFinished) tasks finished"
        return "This week. \(focused). \(sessions). \(finished)."
    }
}

struct HistoryDaySection: Identifiable, Equatable {
    let id: Date
    let title: String
    let sessions: [HistorySessionRecord]
}

enum HistoryPresentation {
    static func weeklySummary(
        sessions: [HistorySessionRecord],
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> HistoryWeeklySummary {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return .empty
        }

        let thisWeek = sessions.filter { week.contains($0.completedAt) }
        return HistoryWeeklySummary(
            focusedDuration: thisWeek.reduce(0) { $0 + $1.focusedDurationSeconds },
            sessionCount: thisWeek.count,
            tasksFinished: thisWeek.filter(\.taskWasFinished).count
        )
    }

    static func daySections(
        sessions: [HistorySessionRecord],
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> [HistoryDaySection] {
        let newestFirst = sessions.sorted { $0.completedAt > $1.completedAt }
        var grouped: [(day: Date, sessions: [HistorySessionRecord])] = []

        for session in newestFirst {
            let day = calendar.startOfDay(for: session.completedAt)
            if let index = grouped.firstIndex(where: { $0.day == day }) {
                grouped[index].sessions.append(session)
            } else {
                grouped.append((day, [session]))
            }
        }

        return grouped.map { entry in
            HistoryDaySection(
                id: entry.day,
                title: dayTitle(for: entry.day, calendar: calendar, referenceDate: referenceDate),
                sessions: entry.sessions
            )
        }
    }

    static func dayTitle(
        for date: Date,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> String {
        if calendar.isDate(date, inSameDayAs: referenceDate) {
            return "TODAY"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "YESTERDAY"
        }

        var format = Date.FormatStyle()
            .month(.abbreviated)
            .day()
        format.calendar = calendar
        format.timeZone = calendar.timeZone
        return date.formatted(format).uppercased()
    }
}
