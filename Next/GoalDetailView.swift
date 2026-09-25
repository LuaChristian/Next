//
//  GoalDetailView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    let goalID: UUID

    @State private var isAddingTask = false

    private var goal: Goal? {
        store.goal(id: goalID)
    }

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let goal {
                Text(goal.title)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.primary)

                Text(goal.area.title.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)

                Text(goal.priority.title.uppercased() + " PRIORITY")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                if goal.tasks.isEmpty {
                    emptyTasks
                } else {
                    taskList(goal.tasks)
                }

                Spacer(minLength: 24)

                addTaskAction
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(canvasColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $isAddingTask) {
            AddTaskView(goalID: goalID)
        }
    }

    private var emptyTasks: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No tasks yet.")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 48)

            Text("Add something you can work on the next time you have a few minutes.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private func taskList(_ tasks: [TaskItem]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("YOUR TASKS")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
                    .padding(.bottom, 8)

                ForEach(tasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(.primary)

                        Text("\(task.durationMinutes) MIN  ·  \(task.energyRequired.title.uppercased())")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
                    .accessibilityElement(children: .combine)

                    if task.id != tasks.last?.id {
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(height: 0.5)
                    }
                }
            }
        }
    }

    private var addTaskAction: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("+ ADD TASK") {
                isAddingTask = true
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 44)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}
