//
//  PlantGoalView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct PlantGoalView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    @State private var title = ""
    @State private var selectedArea: GoalArea?
    @State private var selectedPriority: GoalPriority = .normal

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canPlant: Bool {
        !trimmedTitle.isEmpty && selectedArea != nil
    }

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("PLANT A GOAL")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("What do you want to work toward?")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.primary)
                    .padding(.top, 36)

                TextField("Study for MCAT", text: $title)
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

                areaGrid
                    .padding(.top, 8)

                Text("PRIORITY")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)

                HStack(spacing: 8) {
                    ForEach(GoalPriority.allCases) { priority in
                        SelectionOption(
                            title: priority.title,
                            isSelected: selectedPriority == priority
                        ) {
                            selectedPriority = priority
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
            plantAction
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onTapGesture {
            titleFocused = false
        }
    }

    private var areaGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            ForEach(GoalArea.allCases) { area in
                SelectionOption(
                    title: area.title,
                    isSelected: selectedArea == area
                ) {
                    selectedArea = area
                }
            }
        }
    }

    private var plantAction: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("PLANT GOAL →") {
                guard let area = selectedArea else { return }
                store.addGoal(title: trimmedTitle, area: area, priority: selectedPriority)
                dismiss()
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(canPlant ? Color.accentColor : Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!canPlant)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
        .background(canvasColor)
    }
}
