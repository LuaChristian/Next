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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goalID: UUID

    @State private var isAddingTask = false
    @State private var isEditingGoal = false
    @State private var editingTaskID: UUID?
    @State private var confirmDeleteGoal = false
    @State private var taskPendingDeletion: GoalTask?

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
                        taskSections(goal)
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
        .toolbar {
            if goal != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit Goal") {
                            isEditingGoal = true
                        }
                        Button("Delete Goal", role: .destructive) {
                            confirmDeleteGoal = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(NextTheme.ink)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Goal options")
                    .accessibilityIdentifier("goalOptions")
                }
            }
        }
        .navigationDestination(isPresented: $isAddingTask) {
            AddTaskView(goalID: goalID)
        }
        .navigationDestination(isPresented: $isEditingGoal) {
            EditGoalView(goalID: goalID)
        }
        .navigationDestination(item: $editingTaskID) {
            EditTaskView(taskID: $0)
        }
        .confirmationDialog(
            "Delete Goal?",
            isPresented: $confirmDeleteGoal,
            titleVisibility: .visible
        ) {
            Button("Delete Goal", role: .destructive) {
                deleteCurrentGoal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the Goal and its current tasks. Your focus history will be kept.")
        }
        .confirmationDialog(
            "Delete Task?",
            isPresented: Binding(
                get: { taskPendingDeletion != nil },
                set: { if !$0 { taskPendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
                if let task = taskPendingDeletion {
                    try? PlanningStore.deleteTask(task, context: modelContext)
                }
                taskPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                taskPendingDeletion = nil
            }
        } message: {
            Text("This removes the task from this Goal. Your focus history will be kept.")
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

    @ViewBuilder
    private func taskSections(_ goal: Goal) -> some View {
        if goal.tasks.isEmpty {
            emptyTasks
        } else {
            if goal.activeTasks.isEmpty {
                noActiveTasks
            } else {
                taskList(goal.activeTasks)
            }

            if !goal.completedTasks.isEmpty {
                completedTaskList(goal.completedTasks)
            }
        }
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

    private var noActiveTasks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No active tasks.")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 48)
                .fixedSize(horizontal: false, vertical: true)

            Text("Completed work stays here. Add another task when you're ready.")
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
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("goalTask-\(task.title)")
                .taskManagement(task, onEdit: { editingTaskID = task.id }, onDelete: { taskPendingDeletion = task })

                if task.id != tasks.last?.id {
                    NextHairline()
                }
            }
        }
    }

    private func completedTaskList(_ tasks: [GoalTask]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COMPLETED")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 40)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)

            ForEach(tasks) { task in
                HStack(alignment: .top, spacing: 16) {
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(task.title). Completed. \(task.durationMinutes) minutes. \(task.energyRequired.title) energy."
                    )
                    .accessibilityIdentifier("completedTask-\(task.title)")

                    Button("REOPEN") {
                        task.reopen()
                        try? modelContext.save()
                    }
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(NextTheme.secondary)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Reopen \(task.title)")
                    .accessibilityIdentifier("reopen-\(task.title)")
                }
                .padding(.vertical, 20)
                .taskManagement(task, onEdit: { editingTaskID = task.id }, onDelete: { taskPendingDeletion = task })

                if task.id != tasks.last?.id {
                    NextHairline()
                }
            }
        }
    }

    private func deleteCurrentGoal() {
        guard let goal else { return }
        try? PlanningStore.deleteGoal(goal, context: modelContext)
        dismiss()
    }
}

private extension View {
    func taskManagement(
        _ task: GoalTask,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        self
            .contextMenu {
                Button("Edit \(task.title)") { onEdit() }
                Button("Delete \(task.title)", role: .destructive) { onDelete() }
            }
            .accessibilityAction(named: "Edit \(task.title)", onEdit)
            .accessibilityAction(named: "Delete \(task.title)", onDelete)
    }
}
