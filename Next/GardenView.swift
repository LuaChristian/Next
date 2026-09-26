//
//  GardenView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct GardenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @State private var isPlanting = false

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("GARDEN")
                .font(.system(size: 13, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(.secondary)

            if goals.isEmpty {
                emptyState
            } else {
                goalList
            }

            Spacer(minLength: 24)

            plantAction
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(canvasColor.ignoresSafeArea())
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
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 48)

            Text("Start with something you want to make progress on.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private var goalList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Your goals")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                    .padding(.top, 36)
                    .padding(.bottom, 12)

                ForEach(goals) { goal in
                    NavigationLink(value: goal.id) {
                        goalRow(goal)
                    }
                    .buttonStyle(.plain)

                    if goal.id != goals.last?.id {
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(height: 0.5)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func goalRow(_ goal: Goal) -> some View {
        HStack(alignment: .center, spacing: 18) {
            BotanicalPlantView(stage: goal.growthStage)
                .frame(width: 52, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.primary)

                Text(goal.area.title.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Text(goal.progressMetricsLabel)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
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

    private var plantAction: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("+ PLANT A GOAL") {
                isPlanting = true
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
