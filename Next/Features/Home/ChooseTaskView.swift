//
//  ChooseTaskView.swift
//  Next
//
//  Direct Focus entry: browse goals → pick an incomplete task → FocusView.
//  Does not apply recommendation time/energy/scope filters.
//

import SwiftData
import SwiftUI

struct ChooseTaskView: View {
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""
    @State private var isPlanting = false
    @State private var selectedGoalID: UUID?

    private var selectable: [Goal] {
        FocusLaunch.selectableGoals(from: goals)
    }

    private var filtered: [Goal] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return selectable }
        return selectable.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.areasDisplayLabel.localizedCaseInsensitiveContains(q)
        }
    }

    private var stacksColumns: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("CHOOSE A TASK")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("Select a goal, then the task you want to work on.")
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 28)
                    .fixedSize(horizontal: false, vertical: true)

                if selectable.isEmpty {
                    emptyNoGoals
                        .padding(.top, 36)
                } else if !FocusLaunch.hasAnySelectableTasks(in: selectable) {
                    emptyNoAvailableTasks
                        .padding(.top, 36)
                } else {
                    TextField("Search goals", text: $query)
                        .nextFont(17)
                        .padding(.top, 28)
                        .accessibilityLabel("Search goals")
                        .accessibilityIdentifier("chooseTaskSearch")

                    NextHairline()
                        .padding(.top, 16)

                    goalList
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityIdentifier("chooseTaskScreen")
        .navigationDestination(item: $selectedGoalID) { goalID in
            ChooseTaskTasksView(goalID: goalID)
        }
        .navigationDestination(isPresented: $isPlanting) {
            PlantGoalView()
        }
    }

    @ViewBuilder
    private var goalList: some View {
        if filtered.isEmpty {
            Text("No matching goals.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondaryText)
                .padding(.top, 24)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(filtered, id: \.id) { goal in
                    Button {
                        selectedGoalID = goal.id
                    } label: {
                        goalRow(goal)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("chooseTaskGoal-\(goal.title)")

                    if goal.id != filtered.last?.id {
                        NextHairline()
                    }
                }
            }
        }
    }

    private func goalRow(_ goal: Goal) -> some View {
        HStack(alignment: .center, spacing: 16) {
            PlantView(species: goal.botanicalSpecies, stage: goal.growthStage)
                .frame(width: stacksColumns ? 40 : 52, height: stacksColumns ? 54 : 70)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title)
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(NextTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(goal.activeTaskCountLabel)
                    .nextFont(15)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if !goal.areasDisplayLabel.isEmpty {
                    Text(goal.areasDisplayLabel)
                        .nextFont(13, relativeTo: .caption)
                        .foregroundStyle(NextTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(NextTheme.interactiveAccent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(goal.title). \(goal.activeTaskCountLabel)")
        .accessibilityHint("Shows tasks you can focus on")
    }

    private var emptyNoGoals: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plant a goal first.")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Once you have a goal with a task, you can choose exactly what to work on.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            NextPrimaryAction(title: "+ PLANT A GOAL") {
                isPlanting = true
            }
            .padding(.top, 12)
            .accessibilityIdentifier("chooseTaskPlantGoal")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chooseTaskEmptyNoGoals")
    }

    private var emptyNoAvailableTasks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nothing available to focus on.")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your goals are planted. Add a task when you're ready for another session.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("chooseTaskEmptyNoTasks")
    }
}

struct ChooseTaskTasksView: View {
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    let goalID: UUID

    @State private var focusTask: TaskItem?
    @State private var staleSelectionMessage: String?

    private var goal: Goal? {
        goals.first(where: { $0.id == goalID })
    }

    private var tasks: [GoalTask] {
        guard let goal else { return [] }
        return FocusLaunch.selectableTasks(on: goal)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("TASKS")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                if let goal {
                    Text(goal.title)
                        .nextFont(28, relativeTo: .title)
                        .foregroundStyle(NextTheme.primaryText)
                        .padding(.top, 28)
                        .fixedSize(horizontal: false, vertical: true)

                    if tasks.isEmpty {
                        emptyTasks
                            .padding(.top, 36)
                    } else {
                        taskList
                            .padding(.top, 28)
                    }
                } else {
                    Text("This goal is no longer available.")
                        .nextFont(22, relativeTo: .title3)
                        .foregroundStyle(NextTheme.ink)
                        .padding(.top, 28)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityIdentifier("chooseTaskTasksScreen")
        .fullScreenCover(item: $focusTask) { task in
            FocusView(task: task) {
                focusTask = nil
                NotificationCenter.default.post(name: .nextReturnToHomeEntry, object: nil)
            }
        }
        .alert(
            "Couldn't start focus",
            isPresented: Binding(
                get: { staleSelectionMessage != nil },
                set: { if !$0 { staleSelectionMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { staleSelectionMessage = nil }
        } message: {
            Text(staleSelectionMessage ?? "Please choose another task.")
        }
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(tasks) { task in
                Button {
                    startFocus(task)
                } label: {
                    taskRow(task)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("chooseTaskItem-\(task.title)")

                if task.id != tasks.last?.id {
                    NextHairline()
                }
            }
        }
    }

    private func taskRow(_ task: GoalTask) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(NextTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(task.durationMinutes) MIN  ·  \(task.energyRequired.title.uppercased())")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("FOCUS")
                .nextFont(13, weight: .semibold, relativeTo: .caption)
                .tracking(1.6)
                .foregroundStyle(NextTheme.interactiveAccent)
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            "\(task.title). \(task.durationMinutes) minutes. \(task.energyRequired.title) energy."
        )
        .accessibilityHint("Starts a focus session")
    }

    private var emptyTasks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No tasks ready here.")
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Add a task to this goal from the Garden when you're ready.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("chooseTaskGoalEmpty")
    }

    private func startFocus(_ task: GoalTask) {
        guard let item = FocusLaunch.taskItem(from: task) else {
            staleSelectionMessage = "That task is no longer available. Choose another one."
            return
        }
        focusTask = item
    }
}

#Preview {
    NavigationStack {
        ChooseTaskView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
