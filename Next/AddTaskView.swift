//
//  AddTaskView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    let goalID: UUID

    @State private var title = ""
    @State private var selectedDuration: TaskDuration?
    @State private var selectedEnergy: EnergyLevel?

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAdd: Bool {
        !trimmedTitle.isEmpty && selectedDuration != nil && selectedEnergy != nil
    }

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("ADD TASK")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("What needs to get done?")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.primary)
                    .padding(.top, 36)

                TextField("Review amino acids", text: $title)
                    .font(.system(size: 22, weight: .regular))
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($titleFocused)
                    .padding(.top, 18)
                    .accessibilityLabel("Task title")

                Text("HOW LONG?")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)

                HStack(spacing: 6) {
                    ForEach(TaskDuration.allCases) { duration in
                        SelectionOption(
                            title: duration.title,
                            isSelected: selectedDuration == duration
                        ) {
                            selectedDuration = duration
                        }
                    }
                }
                .padding(.top, 8)

                Text("ENERGY NEEDED?")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)

                HStack(spacing: 8) {
                    ForEach(EnergyLevel.allCases) { energy in
                        SelectionOption(
                            title: energy.title,
                            isSelected: selectedEnergy == energy
                        ) {
                            selectedEnergy = energy
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
        .background(canvasColor.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            addAction
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onTapGesture {
            titleFocused = false
        }
    }

    private var addAction: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("ADD TASK →") {
                guard let duration = selectedDuration, let energy = selectedEnergy else { return }
                store.addTask(
                    to: goalID,
                    title: trimmedTitle,
                    durationMinutes: duration.minutes,
                    energyRequired: energy
                )
                dismiss()
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(canAdd ? Color.accentColor : Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!canAdd)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
        .background(canvasColor)
    }
}
