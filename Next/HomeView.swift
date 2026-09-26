//
//  HomeView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

enum TimeOption: CaseIterable, Identifiable {
    case fifteen
    case thirty
    case sixty
    case ninetyPlus

    var id: Self { self }

    var title: String {
        switch self {
        case .fifteen: "15 min"
        case .thirty: "30 min"
        case .sixty: "60 min"
        case .ninetyPlus: "90+ min"
        }
    }
}

enum EnergyLevel: String, CaseIterable, Identifiable, Codable {
    case low
    case good
    case ready

    var id: Self { self }

    var title: String {
        switch self {
        case .low: "Low"
        case .good: "Good"
        case .ready: "Ready"
        }
    }
}

struct HomeView: View {
    @Query(sort: \GoalTask.createdAt) private var persistedTasks: [GoalTask]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var selectedTime: TimeOption?
    @State private var selectedEnergy: EnergyLevel?
    @State private var recommendationInput: RecommendationInput?

    private var canProceed: Bool {
        selectedTime != nil && selectedEnergy != nil
    }

    private var stacksChoices: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 48)
            timeSection
            Spacer(minLength: 40)
            energySection
            Spacer(minLength: 48)
            NextPrimaryAction(title: "WHAT'S NEXT?", isEnabled: canProceed) {
                guard let time = selectedTime, let energy = selectedEnergy else { return }
                recommendationInput = RecommendationInput(time: time, energy: energy)
            }
        }
        .nextScrollableCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $recommendationInput) { input in
            RecommendationView(
                availableTime: input.time,
                energy: input.energy,
                tasks: persistedTasks.map(\.asTaskItem)
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)

            Text("Good afternoon.")
                .nextFont(34, relativeTo: .largeTitle)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("What do you have time for?")
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            choiceStack {
                ForEach(TimeOption.allCases) { option in
                    SelectionOption(
                        title: option.title,
                        isSelected: selectedTime == option
                    ) {
                        selectedTime = option
                    }
                    .accessibilityLabel(option.title)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("How are you feeling?")
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            choiceStack {
                ForEach(EnergyLevel.allCases) { option in
                    SelectionOption(
                        title: option.title,
                        isSelected: selectedEnergy == option
                    ) {
                        selectedEnergy = option
                    }
                    .accessibilityLabel(option.title)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func choiceStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if stacksChoices {
            VStack(spacing: 4) { content() }
        } else {
            HStack(spacing: 8) { content() }
        }
    }
}

private struct RecommendationInput: Hashable, Identifiable {
    let id = UUID()
    let time: TimeOption
    let energy: EnergyLevel
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
