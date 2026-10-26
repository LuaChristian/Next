//
//  HelpMeDecideView.swift
//  Next
//
//  Guided entry: time, energy, and recommendation scope → RecommendationView.
//  Ranking stays in RecommendationEngine; this view only collects inputs.
//

import SwiftData
import SwiftUI

struct HelpMeDecideView: View {
    @Query(sort: \GoalTask.createdAt) private var persistedTasks: [GoalTask]
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var selectedTime: TimeOption?
    @State private var selectedEnergy: EnergyLevel?
    @State private var recommendationScope = RecommendationScope.anything
    @State private var recommendationInput: RecommendationInput?
    @State private var showingAreaSheet = false
    @State private var showingGoalSheet = false

    private var canProceed: Bool {
        // Scope readiness is enforced as an empty recommendation state
        // (CHOOSE A FOCUS), not by disabling WHAT'S NEXT?
        selectedTime != nil && selectedEnergy != nil
    }

    private var stacksChoices: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var selectedGoalTitle: String? {
        guard let id = recommendationScope.selectedGoalID else { return nil }
        return goals.first(where: { $0.id == id })?.title
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("HELP ME DECIDE")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("Tell me how much time and energy you have.")
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 28)
                    .fixedSize(horizontal: false, vertical: true)

                focusSection
                    .padding(.top, 28)

                NextHairline()
                    .padding(.top, 22)

                timeSection
                    .padding(.top, 22)

                NextHairline()
                    .padding(.top, 22)

                energySection
                    .padding(.top, 22)

                NextPrimaryAction(title: "WHAT'S NEXT?", isEnabled: canProceed) {
                    guard let time = selectedTime, let energy = selectedEnergy else { return }
                    recommendationScope.validate(against: goals)
                    recommendationInput = RecommendationInput(
                        time: time,
                        energy: energy,
                        scope: recommendationScope
                    )
                }
                .padding(.top, 28)
                .accessibilityIdentifier("whatsNextButton")
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
        .accessibilityIdentifier("helpMeDecideScreen")
        .navigationDestination(item: $recommendationInput) { input in
            let tasks = persistedTasks.recommendationItems(matching: input.scope)
            let ranked = RecommendationEngine().rankedRecommendations(
                tasks: tasks,
                availableTime: input.time,
                energy: input.energy
            )
            RecommendationView(
                recommendations: ranked,
                hasAnyTasks: !persistedTasks.isEmpty,
                emptyKind: RecommendationEmptyKindResolver.resolve(
                    scope: input.scope,
                    scopedActiveTaskCount: tasks.count,
                    rankedCount: ranked.count,
                    hasAnyTasksInApp: !persistedTasks.isEmpty
                )
            )
        }
        .sheet(isPresented: $showingAreaSheet) {
            SearchableAreaSelectSheet { area in
                recommendationScope.selectedArea = area
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(NextTheme.canvas)
        }
        .sheet(isPresented: $showingGoalSheet) {
            SearchableGoalSelectSheet(goals: goals) { goal in
                recommendationScope.selectedGoalID = goal.id
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(NextTheme.canvas)
        }
        .onAppear {
            recommendationScope.validate(against: goals)
        }
        .onChange(of: goals.map(\.id)) { _, _ in
            recommendationScope.validate(against: goals)
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("01 / FOCUS")

            Text("What would you like to focus on?")
                .nextFont(17)
                .foregroundStyle(NextTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Focus scope", selection: Binding(
                get: { recommendationScope.mode },
                set: { recommendationScope.selectMode($0) }
            )) {
                ForEach(RecommendationScopeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Focus scope")
            .accessibilityValue(recommendationScope.mode.title)
            .accessibilityIdentifier("recommendationScopePicker")

            switch recommendationScope.mode {
            case .anything:
                EmptyView()
            case .lifeArea:
                SearchableSingleSelectField(
                    label: "LIFE AREA",
                    placeholder: "Choose an area",
                    displayValue: recommendationScope.selectedArea?.title,
                    accessibilityIdentifier: "scopeAreaField"
                ) {
                    showingAreaSheet = true
                }
                .padding(.top, 4)
            case .specificGoal:
                SearchableSingleSelectField(
                    label: "GOAL",
                    placeholder: "Choose a goal",
                    displayValue: selectedGoalTitle,
                    accessibilityIdentifier: "scopeGoalField"
                ) {
                    showingGoalSheet = true
                }
                .padding(.top, 4)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeFocusSection")
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("02 / TIME")

            Text("How much time do you have?")
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
        .accessibilityIdentifier("homeTimeSection")
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("03 / ENERGY")

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
        .accessibilityIdentifier("homeEnergySection")
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .nextFont(13, weight: .medium, relativeTo: .caption)
            .tracking(1.8)
            .foregroundStyle(NextTheme.secondaryText)
            .accessibilityAddTraits(.isHeader)
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

struct RecommendationInput: Hashable, Identifiable {
    let id = UUID()
    let time: TimeOption
    let energy: EnergyLevel
    let scope: RecommendationScope
}

#Preview {
    NavigationStack {
        HelpMeDecideView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
