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
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTime: TimeOption?
    @State private var selectedEnergy: EnergyLevel?
    @State private var recommendationScope = RecommendationScope.anything
    @State private var recommendationInput: RecommendationInput?
    @State private var greeting = HomeGreeting.text()
    @State private var showingAreaSheet = false
    @State private var showingGoalSheet = false

    private var canProceed: Bool {
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
                header

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
            .padding(.top, dynamicTypeSize.isAccessibilitySize ? 16 : 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(NextTheme.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
            refreshGreeting()
            recommendationScope.validate(against: goals)
        }
        .onChange(of: goals.map(\.id)) { _, _ in
            recommendationScope.validate(against: goals)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshGreeting()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshGreeting()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)) { _ in
            refreshGreeting()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondaryText)

            Text(greeting)
                .nextFont(34, relativeTo: .largeTitle)
                .foregroundStyle(NextTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("homeGreeting")
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

    private func refreshGreeting() {
        greeting = HomeGreeting.text()
    }
}

private struct RecommendationInput: Hashable, Identifiable {
    let id = UUID()
    let time: TimeOption
    let energy: EnergyLevel
    let scope: RecommendationScope
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
