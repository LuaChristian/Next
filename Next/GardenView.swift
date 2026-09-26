//
//  GardenView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct GardenView: View {
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPlanting = false

    private var compactPlant: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("GARDEN")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityAddTraits(.isHeader)

            if goals.isEmpty {
                ScrollView {
                    emptyState
                }
            } else {
                goalList
            }

            Spacer(minLength: 24)

            NextPrimaryAction(title: "+ PLANT A GOAL") {
                isPlanting = true
            }
        }
        .nextCanvas()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { goalID in
            GoalDetailView(goalID: goalID)
        }
        .navigationDestination(isPresented: $isPlanting) {
            PlantGoalView()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nothing planted yet.")
                .nextFont(28, relativeTo: .title)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 48)
                .fixedSize(horizontal: false, vertical: true)

            Text("Start with something you want to make progress on.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var goalList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Your goals")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.ink)
                    .padding(.top, 36)
                    .padding(.bottom, 12)

                ForEach(goals) { goal in
                    NavigationLink(value: goal.id) {
                        goalRow(goal)
                    }
                    .buttonStyle(.plain)

                    if goal.id != goals.last?.id {
                        NextHairline()
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func goalRow(_ goal: Goal) -> some View {
        HStack(alignment: .center, spacing: compactPlant ? 12 : 18) {
            BotanicalPlantView(stage: goal.growthStage)
                .frame(
                    width: compactPlant ? 36 : 58,
                    height: compactPlant ? 50 : 82
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .nextFont(22, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(goal.area.title.uppercased())
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(NextTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(goal.progressMetricsLabel)
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.2)
                    .foregroundStyle(NextTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 22)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.progressAccessibilityLabel)
        .accessibilityValue("stage \(goal.growthStage.rawValue)")
        .accessibilityIdentifier("gardenGoal-\(goal.title)")
    }
}

#Preview("Empty garden") {
    NavigationStack {
        GardenView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}

#Preview("Full plant growth") {
    GardenGrowthPreview()
}

private struct GardenGrowthPreview: View {
    let container: ModelContainer

    init() {
        let configuration = ModelConfiguration(schema: NextPersistence.schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: NextPersistence.schema, configurations: [configuration])
        NextPersistence.seedGrowthStages(ModelContext(container))
        self.container = container
    }

    var body: some View {
        NavigationStack {
            GardenView()
        }
        .modelContainer(container)
    }
}
