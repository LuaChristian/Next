//
//  GoalDetailView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct GoalDetailView: View {
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let goalID: UUID

    @State private var isAddingTask = false

    private var goal: Goal? {
        goals.first(where: { $0.id == goalID })
    }

    private var compactPlant: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let goal {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header(goal)

                        if goal.tasks.isEmpty {
                            emptyTasks
                        } else {
                            taskList(goal.sortedTasks)
                        }
                    }
                }

                Spacer(minLength: 24)

                NextPrimaryAction(title: "+ ADD TASK") {
                    isAddingTask = true
                }
            }
        }
        .nextCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isAddingTask) {
            AddTaskView(goalID: goalID)
        }
    }

    private func header(_ goal: Goal) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                Text(goal.title)
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(goal.area.title.uppercased())
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.8)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 10)

                Text(goal.priority.title.uppercased() + " PRIORITY")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.4)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 8)

                Text(GardenMetrics.sessionCountLabel(goal.sessionCount))
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.4)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 18)

                Text(GardenMetrics.focusedDurationLabel(seconds: goal.totalFocusedDuration))
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.4)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            BotanicalPlantView(stage: goal.growthStage)
                .frame(
                    width: compactPlant ? 56 : 84,
                    height: compactPlant ? 76 : 116
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.progressAccessibilityLabel)
    }

    private var emptyTasks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No tasks yet.")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 48)
                .fixedSize(horizontal: false, vertical: true)

            Text("Add something you can work on the next time you have a few minutes.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func taskList(_ tasks: [GoalTask]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR TASKS")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 40)
                .padding(.bottom, 8)

            ForEach(tasks) { task in
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .nextFont(20, relativeTo: .title3)
                        .foregroundStyle(NextTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(task.durationMinutes) MIN  ·  \(task.energyRequired.title.uppercased())")
                        .nextFont(13, weight: .medium, relativeTo: .caption)
                        .tracking(1.2)
                        .foregroundStyle(NextTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 20)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("goalTask-\(task.title)")

                if task.id != tasks.last?.id {
                    NextHairline()
                }
            }
        }
    }
}
