//
//  RecommendationView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct RecommendationView: View {
    @Environment(\.dismiss) private var dismiss

    let recommendations: [TaskItem]
    let hasAnyTasks: Bool

    @State private var currentIndex = 0
    @State private var focusTask: TaskItem?

    init(
        availableTime: TimeOption,
        energy: EnergyLevel,
        tasks: [TaskItem],
        hasAnyTasks: Bool? = nil
    ) {
        recommendations = RecommendationEngine().recommendations(
            tasks: tasks,
            availableTime: availableTime,
            energy: energy
        )
        self.hasAnyTasks = hasAnyTasks ?? !tasks.isEmpty
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)

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
        .nextScrollableCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(item: $focusTask) { task in
            FocusView(task: task) {
                focusTask = nil
                dismiss()
            }
        }
    }

    private func recommendationContent(for task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR NEXT MOVE")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)

            Text(task.title)
                .nextFont(34, relativeTo: .largeTitle)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 22)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(task.durationMinutes) MINUTES")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.botanical)
                .padding(.top, 16)

            Text(task.area.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 36)

            Text(task.goal)
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

            NextHairline()
                .padding(.top, 36)

            VStack(alignment: .leading, spacing: 8) {
                Text("Fits the time you have.")
                Text("Matches your energy.")
            }
            .nextFont(17)
            .foregroundStyle(NextTheme.secondary)
            .padding(.top, 20)

            NextHairline()
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(task.title). \(task.durationMinutes) minutes. \(task.goal). Fits the time you have. Matches your energy."
        )
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(hasAnyTasks ? "NOTHING FITS RIGHT NOW" : "NO TASKS YET")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)

            Text(
                hasAnyTasks
                    ? "None of your tasks fit this time and energy combination."
                    : "Plant a goal and add a task before asking what's next."
            )
            .nextFont(28, relativeTo: .title)
            .foregroundStyle(NextTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button("START SESSION →") {
                focusTask = currentTask
            }
            .nextFont(13, weight: .semibold)
            .tracking(2.2)
            .foregroundStyle(NextTheme.botanical)
            .frame(maxWidth: .infinity, minHeight: 44)

            Button("Not this one") {
                guard hasAnotherRecommendation else { return }
                currentIndex += 1
            }
            .nextFont(16)
            .foregroundStyle(hasAnotherRecommendation ? NextTheme.ink : NextTheme.disabled)
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
