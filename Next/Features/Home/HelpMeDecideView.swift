//
//  HelpMeDecideView.swift
//  Next
//
//  Guided Help me decide: Scope → Time → Energy → Recommendation.
//  Ranking stays in RecommendationEngine; this flow only collects inputs.
//  Uses an explicit step model (no nested NavigationStack).
//

import SwiftData
import SwiftUI

struct HelpMeDecideView: View {
    @Query(sort: \GoalTask.createdAt) private var persistedTasks: [GoalTask]
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var draft = GuidedFocusDraft()
    @State private var showingAreaSheet = false
    @State private var showingGoalSheet = false

    private var selectedGoalTitle: String? {
        guard let id = draft.scope.selectedGoalID else { return nil }
        return goals.first(where: { $0.id == id })?.title
    }

    var body: some View {
        stepContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(NextTheme.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            // Opaque bar keeps Back clear of scroll content and the status bar.
            .toolbarBackground(NextTheme.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { handleBack() }
                        .accessibilityIdentifier(
                            draft.step == .scope ? "guidedFlowDismiss" : "guidedStepBack"
                        )
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: draft.step)
            .sheet(isPresented: $showingAreaSheet) {
                SearchableAreaSelectSheet { area in
                    draft.scope.selectedArea = area
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(NextTheme.canvas)
            }
            .sheet(isPresented: $showingGoalSheet) {
                SearchableGoalSelectSheet(goals: goals) { goal in
                    draft.scope.selectedGoalID = goal.id
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(NextTheme.canvas)
            }
            .onAppear {
                draft.scope.validate(against: goals)
            }
            .onChange(of: goals.map(\.id)) { _, _ in
                draft.scope.validate(against: goals)
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextReturnToHomeEntry)) { _ in
                draft.resetToScope()
                dismiss()
            }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch draft.step {
        case .scope:
            scopeStep
                .accessibilityIdentifier("helpMeDecideScreen")
                .transition(.opacity)
        case .time:
            GuidedTimeStepView(draft: draft)
                .transition(.opacity)
        case .energy:
            GuidedEnergyStepView(draft: draft)
                .transition(.opacity)
        case .recommendation:
            recommendationDestination
                .transition(.opacity)
        }
    }

    private var scopeStep: some View {
        GuidedFocusStepChrome(
            eyebrow: "HELP ME DECIDE",
            progressStep: 1,
            title: "What would you like to focus on?"
        ) {
            scopeChoices
                .padding(.top, 4)

            if draft.scope.mode == .lifeArea {
                lifeAreaAccessory
                    .padding(.top, 20)
            }

            if draft.scope.mode == .specificGoal {
                specificGoalAccessory
                    .padding(.top, 20)
            }

            if draft.canLeaveScope {
                Button {
                    draft.goToTime(validatingAgainst: goals)
                } label: {
                    Text("CONTINUE →")
                        .nextFont(13, weight: .semibold)
                        .tracking(2.2)
                        .foregroundStyle(NextTheme.interactiveAccent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .padding(.top, 32)
                .accessibilityIdentifier("guidedContinue")
            }
        }
    }

    private var scopeChoices: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(RecommendationScopeMode.allCases) { mode in
                Button {
                    draft.selectScopeMode(mode)
                } label: {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(mode.title)
                                .nextFont(22, relativeTo: .title3)
                                .foregroundStyle(
                                    draft.scope.mode == mode
                                        ? NextTheme.interactiveAccent
                                        : NextTheme.primaryText
                                )
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)

                            Text(scopeSubtitle(mode))
                                .nextFont(15)
                                .foregroundStyle(NextTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if draft.scope.mode == mode {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(NextTheme.interactiveAccent)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 18)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(draft.scope.mode == mode ? [.isSelected, .isButton] : .isButton)
                .accessibilityIdentifier("guidedScope-\(mode.rawValue)")

                if mode != RecommendationScopeMode.allCases.last {
                    NextHairline()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recommendationScopePicker")
    }

    private var lifeAreaAccessory: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchableSingleSelectField(
                label: "LIFE AREA",
                placeholder: "Choose an area",
                displayValue: draft.scope.selectedArea?.title,
                accessibilityIdentifier: "scopeAreaField"
            ) {
                showingAreaSheet = true
            }

            Text("Goals that include this life area stay eligible.")
                .nextFont(15)
                .foregroundStyle(NextTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var specificGoalAccessory: some View {
        if goals.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("No goals planted yet.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Plant a goal from the Garden, or choose Anything for now.")
                    .nextFont(15)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityIdentifier("guidedScopeEmptyGoals")
        } else {
            SearchableSingleSelectField(
                label: "GOAL",
                placeholder: "Choose a goal",
                displayValue: selectedGoalTitle,
                accessibilityIdentifier: "scopeGoalField"
            ) {
                showingGoalSheet = true
            }
        }
    }

    private var recommendationDestination: some View {
        let input = draft.validatedInput(against: goals)
        let scope = input?.scope ?? draft.scope
        let time = input?.time ?? draft.time ?? .thirty
        let energy = input?.energy ?? draft.energy ?? .good
        let tasks = persistedTasks.recommendationItems(matching: scope)
        let ranked = RecommendationEngine().rankedRecommendations(
            tasks: tasks,
            availableTime: time,
            energy: energy
        )
        return RecommendationView(
            recommendations: ranked,
            hasAnyTasks: !persistedTasks.isEmpty,
            emptyKind: RecommendationEmptyKindResolver.resolve(
                scope: scope,
                scopedActiveTaskCount: tasks.count,
                rankedCount: ranked.count,
                hasAnyTasksInApp: !persistedTasks.isEmpty
            )
        )
        .accessibilityIdentifier("guidedRecommendationStep")
    }

    private func handleBack() {
        if draft.goBack() { return }
        dismiss()
    }

    private func scopeSubtitle(_ mode: RecommendationScopeMode) -> String {
        switch mode {
        case .anything: "Consider every open task."
        case .lifeArea: "Stay within one part of life."
        case .specificGoal: "Work on one goal only."
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
