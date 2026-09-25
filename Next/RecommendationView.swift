//
//  RecommendationView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct RecommendationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let recommendations: [TaskItem]
    let hasAnyTasks: Bool

    @State private var currentIndex = 0
    @State private var focusTask: TaskItem?

    init(availableTime: TimeOption, energy: EnergyLevel, tasks: [TaskItem]) {
        recommendations = RecommendationEngine().recommendations(
            tasks: tasks,
            availableTime: availableTime,
            energy: energy
        )
        hasAnyTasks = !tasks.isEmpty
    }

    init(recommendations: [TaskItem], hasAnyTasks: Bool? = nil) {
        self.recommendations = recommendations
        self.hasAnyTasks = hasAnyTasks ?? !recommendations.isEmpty
    }

    private var currentTask: TaskItem? {
        recommendations.indices.contains(currentIndex)
            ? recommendations[currentIndex]
            : nil
    }

    private var hasAnotherRecommendation: Bool {
        currentIndex + 1 < recommendations.count
    }

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand

            Spacer(minLength: 40)

            if let task = currentTask {
                recommendationContent(for: task)
            } else {
                emptyContent
            }

            Spacer(minLength: 40)

            if currentTask != nil {
                actions
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(canvasColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(item: $focusTask) { task in
            FocusView(task: task) {
                focusTask = nil
                dismiss()
            }
        }
    }

    private var brand: some View {
        Text("NEXT")
            .font(.system(size: 13, weight: .medium))
            .tracking(3.2)
            .foregroundStyle(.secondary)
    }

    private func recommendationContent(for task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR NEXT MOVE")
                .font(.system(size: 13, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            Text(task.title)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 22)

            Text("\(task.durationMinutes) MINUTES")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 16)

            Text(task.area.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(.secondary)
                .padding(.top, 36)

            Text(task.goal)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 8)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
                .padding(.top, 36)

            VStack(alignment: .leading, spacing: 8) {
                Text("Fits the time you have.")
                Text("Matches your energy.")
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(.secondary)
            .padding(.top, 20)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(hasAnyTasks ? "NOTHING FITS RIGHT NOW" : "NO TASKS YET")
                .font(.system(size: 13, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            Text(
                hasAnyTasks
                    ? "None of your tasks fit this time and energy combination."
                    : "Plant a goal and add a task before asking what's next."
            )
            .font(.system(size: 28, weight: .regular))
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button("START SESSION →") {
                focusTask = currentTask
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 44)

            Button("Not this one") {
                guard hasAnotherRecommendation else { return }
                currentIndex += 1
            }
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(hasAnotherRecommendation ? Color.primary : Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!hasAnotherRecommendation)
        }
    }
}

#Preview("Recommendation") {
    NavigationStack {
        RecommendationView(
            availableTime: .thirty,
            energy: .good,
            tasks: [
                TaskItem(
                    title: "Review amino acids",
                    durationMinutes: 30,
                    energyRequired: .good,
                    area: "Education",
                    goal: "Study for MCAT"
                )
            ]
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        RecommendationView(recommendations: [])
    }
}
