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
    @Environment(\.modelContext) private var modelContext

    @State private var pendingDeletionID: UUID?
    @State private var saveErrorMessage: String?

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

    private var pendingSession: FocusSession? {
        guard let pendingDeletionID else { return nil }
        return sessions.first(where: { $0.id == pendingDeletionID })
    }

    var body: some View {
        List {
            Section {
                Text("HISTORY")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 4)

                weeklySummary
                    .padding(.top, 36)
                    .padding(.bottom, 8)
            }
            .listRowInsets(EdgeInsets(
                top: 0,
                leading: NextTheme.pagePadding,
                bottom: 0,
                trailing: NextTheme.pagePadding
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(NextTheme.canvas)

            if sessions.isEmpty {
                Section {
                    emptyState
                }
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: NextTheme.pagePadding,
                    bottom: 28,
                    trailing: NextTheme.pagePadding
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(NextTheme.canvas)
            } else {
                Section {
                    Text("RECENT")
                        .nextFont(13, weight: .medium, relativeTo: .caption)
                        .tracking(1.8)
                        .foregroundStyle(NextTheme.secondary)
                        .padding(.top, 40)
                        .padding(.bottom, 4)
                        .accessibilityAddTraits(.isHeader)
                        .listRowInsets(EdgeInsets(
                            top: 0,
                            leading: NextTheme.pagePadding,
                            bottom: 0,
                            trailing: NextTheme.pagePadding
                        ))
                        .listRowSeparator(.hidden)
                        .listRowBackground(NextTheme.canvas)

                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        Text(section.title)
                            .nextFont(13, weight: .medium, relativeTo: .caption)
                            .tracking(1.8)
                            .foregroundStyle(NextTheme.secondary)
                            .padding(.top, index == 0 ? 12 : 28)
                            .accessibilityAddTraits(.isHeader)
                            .listRowInsets(EdgeInsets(
                                top: 0,
                                leading: NextTheme.pagePadding,
                                bottom: 0,
                                trailing: NextTheme.pagePadding
                            ))
                            .listRowSeparator(.hidden)
                            .listRowBackground(NextTheme.canvas)

                        ForEach(section.sessions) { record in
                            historyRow(record, showDivider: record.id != section.sessions.last?.id)
                                .listRowInsets(EdgeInsets(
                                    top: 0,
                                    leading: NextTheme.pagePadding,
                                    bottom: 0,
                                    trailing: NextTheme.pagePadding
                                ))
                                .listRowSeparator(.hidden)
                                .listRowBackground(NextTheme.canvas)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        pendingDeletionID = record.id
                                    }
                                    .tint(Color.red)
                                    .accessibilityIdentifier("historyDeleteAction")
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(NextTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NextTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Delete focus session?",
            isPresented: Binding(
                get: { pendingDeletionID != nil },
                set: { if !$0 { pendingDeletionID = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingSession
        ) { session in
            Button("Delete Session", role: .destructive) {
                confirmDeletion(of: session)
            }
            .accessibilityIdentifier("confirmDeleteSession")
            Button("Cancel", role: .cancel) {
                pendingDeletionID = nil
            }
            .accessibilityIdentifier("cancelDeleteSession")
        } message: { _ in
            Text("This session will be removed from your history. Your focused time and garden growth will update.")
        }
        .alert(
            "Couldn't delete session",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
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
        .accessibilityIdentifier("historyWeeklySummary")
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
        .accessibilityIdentifier("historyEmptyState")
    }

    private func historyRow(_ session: HistorySessionRecord, showDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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

            if showDivider {
                NextHairline()
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(session.taskTitle). \(session.goalTitle). \(GardenMetrics.focusedDurationSpoken(seconds: session.focusedDurationSeconds))."
        )
        .accessibilityIdentifier("historySession-\(session.taskTitle)")
        .accessibilityAction(named: Text("Delete")) {
            pendingDeletionID = session.id
        }
        .contextMenu {
            Button("Delete Session", role: .destructive) {
                pendingDeletionID = session.id
            }
        }
    }

    private func confirmDeletion(of session: FocusSession) {
        do {
            try PlanningStore.deleteFocusSession(session, context: modelContext)
            pendingDeletionID = nil
        } catch {
            pendingDeletionID = nil
            saveErrorMessage = "Something went wrong saving your history. Please try again."
        }
    }
}

#Preview("Empty") {
    HistoryView()
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
