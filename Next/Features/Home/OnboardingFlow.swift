//
//  OnboardingFlow.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

private enum OnboardingStep: Hashable {
    case areas
    case goals
    case ready
}

struct OnboardingFlow: View {
    var onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var state = OnboardingState()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeView(
                onGetStarted: { path.append(OnboardingStep.areas) },
                onSkip: finishSkip
            )
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .areas:
                    OnboardingAreasView(state: $state) {
                        path.append(OnboardingStep.goals)
                    }
                case .goals:
                    OnboardingGoalsView(state: $state) {
                        path.append(OnboardingStep.ready)
                    }
                case .ready:
                    OnboardingReadyView(onStart: finishOnboarding)
                }
            }
        }
    }

    private func finishSkip() {
        state.skip()
        onFinished()
    }

    private func finishOnboarding() {
        state.complete(into: modelContext)
        onFinished()
    }
}

private struct OnboardingWelcomeView: View {
    let onGetStarted: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)
                .accessibilityAddTraits(.isHeader)

            Text("Make your free time count.")
                .nextFont(34, relativeTo: .largeTitle)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 28)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            Text("Spend your time on what matters.\nWe'll help you decide what comes next.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 20)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 48)

            NextPrimaryAction(title: "GET STARTED →", action: onGetStarted)

            Button("Skip for now", action: onSkip)
                .nextFont(16)
                .foregroundStyle(NextTheme.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.top, 8)
        }
        .nextScrollableCanvas()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct OnboardingAreasView: View {
    @Binding var state: OnboardingState
    let onContinue: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressLabel(step: 1)

            Text("WHAT MATTERS TO YOU?")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(2.2)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 28)

            Text("Choose the parts of your life\nyou want to make progress in.")
                .nextFont(28, relativeTo: .title)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: areaColumns, spacing: 4) {
                ForEach(GoalArea.allCases) { area in
                    SelectionOption(
                        title: area.title,
                        isSelected: state.selectedAreas.contains(area)
                    ) {
                        state.toggleArea(area)
                    }
                    .accessibilityLabel(area.title)
                }
            }
            .padding(.top, 28)

            Spacer(minLength: 48)

            NextPrimaryAction(
                title: "NEXT →",
                isEnabled: state.canContinueFromAreas,
                action: onContinue
            )
        }
        .nextScrollableCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var areaColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }
}

private struct OnboardingGoalsView: View {
    @Binding var state: OnboardingState
    let onContinue: () -> Void

    @State private var isAddingCustomGoal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressLabel(step: 2)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("WHAT ARE YOU\nWORKING TOWARD?")
                        .nextFont(28, relativeTo: .title)
                        .foregroundStyle(NextTheme.ink)
                        .padding(.top, 28)
                        .accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Choose anything you'd like\nto make progress on.")
                        .nextFont(17)
                        .foregroundStyle(NextTheme.secondary)
                        .padding(.top, 16)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(orderedSelectedAreas, id: \.self) { area in
                        areaSection(area)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            Button("+ ADD MY OWN GOAL") {
                isAddingCustomGoal = true
            }
            .nextFont(13, weight: .semibold)
            .tracking(2.2)
            .foregroundStyle(NextTheme.botanical)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.top, 8)

            NextPrimaryAction(
                title: "CONTINUE →",
                isEnabled: state.canContinueFromGoals,
                action: onContinue
            )
        }
        .nextCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $isAddingCustomGoal) {
            OnboardingCustomGoalView(availableAreas: orderedSelectedAreas) { title, area in
                state.addCustomGoal(title: title, area: area)
            }
        }
    }

    private var orderedSelectedAreas: [GoalArea] {
        GoalArea.allCases.filter { state.selectedAreas.contains($0) }
    }

    private func areaSection(_ area: GoalArea) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(area.title.uppercased())
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 36)
                .padding(.bottom, 4)

            ForEach(OnboardingGoalSuggestion.suggestions(for: [area])) { suggestion in
                OnboardingChoiceRow(
                    title: suggestion.title,
                    isSelected: state.selectedSuggestionIDs.contains(suggestion.id)
                ) {
                    state.toggleSuggestion(suggestion)
                }
            }

            ForEach(state.customGoals.filter { $0.area == area }) { goal in
                OnboardingChoiceRow(title: goal.title, isSelected: true) {
                    state.removeCustomGoal(goal)
                }
            }
        }
    }
}

private struct OnboardingCustomGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var titleFocused: Bool

    let availableAreas: [GoalArea]
    let onAdd: (String, GoalArea) -> Void

    @State private var title = ""
    @State private var selectedArea: GoalArea?

    private var canAdd: Bool {
        NextInput.trimmedTitle(title) != nil && selectedArea != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ADD A GOAL")
                        .nextFont(13, weight: .medium, relativeTo: .caption)
                        .tracking(2.2)
                        .foregroundStyle(NextTheme.secondary)

                    Text("What are you working toward?")
                        .nextFont(22, relativeTo: .title3)
                        .foregroundStyle(NextTheme.ink)
                        .padding(.top, 36)
                        .accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Learn iOS development", text: $title)
                        .nextFont(22, relativeTo: .title3)
                        .foregroundStyle(NextTheme.ink)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .focused($titleFocused)
                        .padding(.top, 18)
                        .accessibilityLabel("Goal title")

                    Text("AREA")
                        .nextFont(13, weight: .medium, relativeTo: .caption)
                        .tracking(1.8)
                        .foregroundStyle(NextTheme.secondary)
                        .padding(.top, 40)

                    LazyVGrid(columns: areaColumns, spacing: 4) {
                        ForEach(availableAreas) { area in
                            SelectionOption(
                                title: area.title,
                                isSelected: selectedArea == area
                            ) {
                                selectedArea = area
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, NextTheme.pagePadding)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(NextTheme.canvas.ignoresSafeArea())
            .nextKeyboardDone($titleFocused)
            .safeAreaInset(edge: .bottom) {
                NextPrimaryAction(title: "ADD GOAL →", isEnabled: canAdd) {
                    guard let selectedArea, let trimmed = NextInput.trimmedTitle(title) else { return }
                    onAdd(trimmed, selectedArea)
                    dismiss()
                }
                .padding(.horizontal, NextTheme.pagePadding)
                .padding(.bottom, 12)
                .background(NextTheme.canvas)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(NextTheme.secondary)
                }
            }
            .onAppear {
                titleFocused = true
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var areaColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }
}

private struct OnboardingReadyView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressLabel(step: 3)

            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 28)

            Text("YOU'RE READY.")
                .nextFont(34, relativeTo: .largeTitle)
                .foregroundStyle(NextTheme.ink)
                .padding(.top, 28)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your Garden has somewhere\nto start.")
                .nextFont(17)
                .foregroundStyle(NextTheme.secondary)
                .padding(.top, 20)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 48)

            NextPrimaryAction(title: "START USING NEXT →", action: onStart)
        }
        .nextScrollableCanvas()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct OnboardingProgressLabel: View {
    let step: Int

    var body: some View {
        Text("\(step) / 3")
            .nextFont(13, weight: .medium, relativeTo: .caption)
            .tracking(2.2)
            .foregroundStyle(NextTheme.secondary)
            .accessibilityLabel("Step \(step) of 3")
    }
}

private struct OnboardingChoiceRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .nextFont(20, weight: isSelected ? .medium : .regular, relativeTo: .title3)
                    .foregroundStyle(isSelected ? NextTheme.botanical : NextTheme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(isSelected ? NextTheme.botanical : Color.clear)
                    .frame(width: 18, height: 2)
            }
            .padding(.vertical, 16)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

#Preview {
    OnboardingFlow(onFinished: {})
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
