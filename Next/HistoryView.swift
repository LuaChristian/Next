//
//  HistoryView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \FocusSession.completedAt, order: .reverse) private var sessions: [FocusSession]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var records: [HistorySessionRecord] {
        sessions.map(\.historyRecord)
    }

    private var summary: HistoryWeeklySummary {
        HistoryPresentation.weeklySummary(sessions: records)
    }

    private var sections: [HistoryDaySection] {
        HistoryPresentation.daySections(sessions: records)
    }

    private var stacksMetrics: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("HISTORY")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondary)
                    .accessibilityAddTraits(.isHeader)

                weeklySummary
                    .padding(.top, 36)

                if sessions.isEmpty {
                    emptyState
                } else {
                    recentActivity
                }
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var weeklySummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THIS WEEK")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)

            Group {
                if stacksMetrics {
                    VStack(alignment: .leading, spacing: 20) {
                        summaryMetric(
                            value: GardenMetrics.durationText(seconds: summary.focusedDuration),
                            label: "FOCUSED"
                        )
                        summaryMetric(value: "\(summary.sessionCount)", label: summary.sessionsLabel)
                        summaryMetric(value: "\(summary.tasksFinished)", label: summary.tasksFinishedLabel)
                    }
                } else {
                    HStack(alignment: .top, spacing: 0) {
                        summaryMetric(
                            value: GardenMetrics.durationText(seconds: summary.focusedDuration),
                            label: "FOCUSED"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        summaryMetric(value: "\(summary.sessionCount)", label: summary.sessionsLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        summaryMetric(value: "\(summary.tasksFinished)", label: summary.tasksFinishedLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, 18)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summary.accessibilityLabel)
    }

    private func summaryMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(label)
                .nextFont(11, weight: .medium, relativeTo: .caption2)
                .tracking(1.2)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NO FOCUS SESSIONS YET.")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 48)

            Text("When you spend time on something,\nyour work will show up here.")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Return to Home to find\nwhat's next.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("RECENT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 48)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                Text(section.title)
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.8)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, index == 0 ? 12 : 28)
                    .accessibilityAddTraits(.isHeader)

                ForEach(section.sessions) { session in
                    historyRow(session)

                    if session.id != section.sessions.last?.id {
                        NextHairline()
                    }
                }
            }
        }
    }

    private func historyRow(_ session: HistorySessionRecord) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.taskTitle)
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(session.goalTitle.uppercased())
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(NextTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(GardenMetrics.durationText(seconds: session.focusedDurationSeconds))
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.2)
                .foregroundStyle(NextTheme.botanical)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(session.taskTitle). \(session.goalTitle). \(GardenMetrics.focusedDurationSpoken(seconds: session.focusedDurationSeconds))."
        )
        .accessibilityIdentifier("historySession-\(session.taskTitle)")
    }
}

#Preview("Empty") {
    HistoryView()
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
