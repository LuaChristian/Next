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
    @Environment(\.colorScheme) private var colorScheme

    let onGetStarted: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NEXT")
                .font(.system(size: 13, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            Text("Make your free time count.")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 28)
                .accessibilityAddTraits(.isHeader)

            Text("Spend your time on what matters.\nWe'll help you decide what comes next.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, 20)

            Spacer(minLength: 48)

            OnboardingPrimaryAction(title: "GET STARTED →", isEnabled: true, action: onGetStarted)

            Button("Skip for now", action: onSkip)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.top, 8)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(OnboardingCanvas.color(for: colorScheme).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct OnboardingAreasView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var state: OnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressLabel(step: 1)

            Text("WHAT MATTERS TO YOU?")
                .font(.system(size: 13, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(.secondary)
                .padding(.top, 28)

            Text("Choose the parts of your life\nyou want to make progress in.")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(GoalArea.allCases) { area in
                    SelectionOption(
                        title: area.title,
                        isSelected: state.selectedAreas.contains(area)
                    ) {
                        state.toggleArea(area)
                    }
                    .accessibilityLabel(area.title)
                    .accessibilityValue(state.selectedAreas.contains(area) ? "Selected" : "Not selected")
                }
            }
            .padding(.top, 28)

            Spacer(minLength: 48)

            OnboardingPrimaryAction(
                title: "NEXT →",
                isEnabled: state.canContinueFromAreas,
                action: onContinue
            )
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(OnboardingCanvas.color(for: colorScheme).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct OnboardingGoalsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var state: OnboardingState
    let onContinue: () -> Void

    @State private var isAddingCustomGoal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressLabel(step: 2)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("WHAT ARE YOU\nWORKING TOWARD?")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.primary)
                        .padding(.top, 28)
                        .accessibilityAddTraits(.isHeader)

                    Text("Choose anything you'd like\nto make progress on.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)

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
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.top, 8)

            OnboardingPrimaryAction(
                title: "CONTINUE →",
                isEnabled: state.canContinueFromGoals,
                action: onContinue
            )
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(OnboardingCanvas.color(for: colorScheme).ignoresSafeArea())
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
                .font(.system(size: 13, weight: .medium))
                .tracking(1.8)
                .foregroundStyle(.secondary)
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    let availableAreas: [GoalArea]
    let onAdd: (String, GoalArea) -> Void

    @State private var title = ""
    @State private var selectedArea: GoalArea?

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAdd: Bool {
        !trimmedTitle.isEmpty && selectedArea != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ADD A GOAL")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(2.2)
                        .foregroundStyle(.secondary)

                    Text("What are you working toward?")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.primary)
                        .padding(.top, 36)
                        .accessibilityAddTraits(.isHeader)

                    TextField("Learn iOS development", text: $title)
                        .font(.system(size: 22, weight: .regular))
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .focused($titleFocused)
                        .padding(.top, 18)
                        .accessibilityLabel("Goal title")

                    Text("AREA")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.8)
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
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
                .padding(.horizontal, 28)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(OnboardingCanvas.color(for: colorScheme).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                OnboardingPrimaryAction(title: "ADD GOAL →", isEnabled: canAdd) {
                    guard let selectedArea else { return }
                    onAdd(trimmedTitle, selectedArea)
                    dismiss()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
                .background(OnboardingCanvas.color(for: colorScheme))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                titleFocused = true
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private struct OnboardingReadyView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressLabel(step: 3)

            Text("NEXT")
                .font(.system(size: 13, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(.secondary)
                .padding(.top, 28)

            Text("YOU'RE READY.")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.top, 28)
                .accessibilityAddTraits(.isHeader)

            Text("Your Garden has somewhere\nto start.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, 20)

            Spacer(minLength: 48)

            OnboardingPrimaryAction(title: "START USING NEXT →", isEnabled: true, action: onStart)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(OnboardingCanvas.color(for: colorScheme).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct OnboardingProgressLabel: View {
    let step: Int

    var body: some View {
        Text("\(step) / 3")
            .font(.system(size: 13, weight: .medium))
            .tracking(2.2)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Step \(step) of 3")
    }
}

private struct OnboardingChoiceRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 18, height: 2)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct OnboardingPrimaryAction: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button(title, action: action)
                .font(.system(size: 13, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary.opacity(0.45))
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(!isEnabled)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

private enum OnboardingCanvas {
    static func color(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }
}

#Preview {
    OnboardingFlow(onFinished: {})
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
