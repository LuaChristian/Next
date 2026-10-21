//
//  GardenView.swift
//  Next
//
//  Living Garden — botanical collection presentation.
//  Growth math stays in GardenGrowth / Goal; this surface only presents.
//

import SwiftData
import SwiftUI

struct GardenView: View {
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPlanting = false

    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - (NextTheme.pagePadding * 2), 1)

            Group {
                if isAccessibilitySize {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            gardenHeader
                            gardenBody(contentWidth: contentWidth)
                            plantGoalAction
                                .padding(.top, 28)
                        }
                        .padding(.horizontal, NextTheme.pagePadding)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .scrollDismissesKeyboard(.interactively)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        gardenHeader
                        ScrollView {
                            gardenBody(contentWidth: contentWidth)
                        }
                        .scrollDismissesKeyboard(.interactively)

                        plantGoalAction
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, NextTheme.pagePadding)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(NextTheme.canvas.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { goalID in
            GoalDetailView(goalID: goalID)
        }
        .navigationDestination(isPresented: $isPlanting) {
            PlantGoalView()
        }
    }

    private var gardenHeader: some View {
        Text("GARDEN")
            .nextFont(13, weight: .medium, relativeTo: .caption)
            .tracking(3.2)
            .foregroundStyle(NextTheme.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private var plantGoalAction: some View {
        NextPrimaryAction(title: "+ PLANT A GOAL") {
            isPlanting = true
        }
    }

    @ViewBuilder
    private func gardenBody(contentWidth: CGFloat) -> some View {
        if goals.isEmpty {
            emptyState
        } else {
            gardenSummary
            collection(contentWidth: contentWidth)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Every garden starts somewhere.")
                .nextFont(28, relativeTo: .title)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 48)
                .fixedSize(horizontal: false, vertical: true)

            Text("Plant a goal to begin growing something meaningful.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gardenEmptyState")
    }

    private var gardenSummary: some View {
        let focused = GardenCollectionSummary.totalFocusedSeconds(across: goals)
        return VStack(alignment: .leading, spacing: 10) {
            Text("YOUR GARDEN")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.4)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 36)
                .accessibilityAddTraits(.isHeader)

            Text(GardenCollectionSummary.goalsGrowingLabel(count: goals.count))
                .nextFont(22, relativeTo: .title3)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(GardenCollectionSummary.focusedTimeLabel(seconds: focused))
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gardenSummary")
        .accessibilityLabel(
            "Your garden. \(GardenCollectionSummary.goalsGrowingLabel(count: goals.count)). \(GardenCollectionSummary.focusedTimeLabel(seconds: focused))."
        )
    }

    private func collection(contentWidth: CGFloat) -> some View {
        // One goal stays full-width so the plant isn't stranded in an empty grid.
        let preferred = GardenCollectionLayout.columnCount(
            contentWidth: contentWidth,
            isAccessibilitySize: isAccessibilitySize
        )
        let columns = goals.count < 2 ? 1 : preferred
        let plantSize = GardenCollectionLayout.plantSize(
            columns: columns,
            isAccessibilitySize: isAccessibilitySize
        )

        return Group {
            if columns == 1 {
                singleColumnCollection(plantSize: plantSize)
            } else {
                gridCollection(plantSize: plantSize)
            }
        }
        .padding(.top, 28)
        .padding(.bottom, 12)
        .accessibilityIdentifier("gardenCollection")
    }

    private func singleColumnCollection(plantSize: CGSize) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(goals) { goal in
                NavigationLink(value: goal.id) {
                    GardenPlantCell(goal: goal, plantSize: plantSize, columns: 1)
                        .padding(.vertical, 24)
                }
                .buttonStyle(.plain)

                if goal.id != goals.last?.id {
                    NextHairline()
                }
            }
        }
    }

    private func gridCollection(plantSize: CGSize) -> some View {
        let gridItems = [
            GridItem(.flexible(minimum: 120), spacing: 28, alignment: .top),
            GridItem(.flexible(minimum: 120), spacing: 28, alignment: .top)
        ]

        return LazyVGrid(columns: gridItems, alignment: .center, spacing: 36) {
            ForEach(goals) { goal in
                NavigationLink(value: goal.id) {
                    GardenPlantCell(goal: goal, plantSize: plantSize, columns: 2)
                }
                .buttonStyle(.plain)
            }
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
