//
//  AddTaskView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var goals: [Goal]
    @FocusState private var titleFocused: Bool

    let goalID: UUID

    @State private var title = ""
    @State private var selectedDuration: TaskDuration?
    @State private var selectedEnergy: EnergyLevel?

    private var canAdd: Bool {
        NextInput.trimmedTitle(title) != nil && selectedDuration != nil && selectedEnergy != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("ADD TASK")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(2.2)
                    .foregroundStyle(NextTheme.secondary)

                Text("What needs to get done?")
                    .nextFont(22, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                    .padding(.top, 36)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("Review amino acids", text: $title)
                    .nextFont(22, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($titleFocused)
                    .padding(.top, 18)
                    .accessibilityLabel("Task title")

                Text("HOW LONG?")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.8)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 40)

                choiceStack(spacing: 6) {
                    ForEach(TaskDuration.allCases) { duration in
                        SelectionOption(
                            title: duration.title,
                            isSelected: selectedDuration == duration
                        ) {
                            titleFocused = false
                            selectedDuration = duration
                        }
                    }
                }
                .padding(.top, 8)

                Text("ENERGY NEEDED?")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.8)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 32)

                choiceStack(spacing: 8) {
                    ForEach(EnergyLevel.allCases) { energy in
                        SelectionOption(
                            title: energy.title,
                            isSelected: selectedEnergy == energy
                        ) {
                            titleFocused = false
                            selectedEnergy = energy
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
            addAction
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func choiceStack<Content: View>(
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 4) { content() }
        } else {
            HStack(spacing: spacing) { content() }
        }
    }

    private var addAction: some View {
        NextPrimaryAction(title: "ADD TASK →", isEnabled: canAdd) {
            titleFocused = false
            guard let duration = selectedDuration,
                  let energy = selectedEnergy,
                  let goal = goals.first(where: { $0.id == goalID }),
                  let trimmed = NextInput.trimmedTitle(title)
            else { return }
            modelContext.insert(
                GoalTask(
                    title: trimmed,
                    durationMinutes: duration.minutes,
                    energyRequired: energy,
                    goal: goal
                )
            )
            try? modelContext.save()
            dismiss()
        }
        .padding(.horizontal, NextTheme.pagePadding)
        .padding(.bottom, 12)
        .background(NextTheme.canvas)
    }
}
