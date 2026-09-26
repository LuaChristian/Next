//
//  EditGoalView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/26/26.
//

import SwiftData
import SwiftUI

struct EditGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var goals: [Goal]
    @FocusState private var titleFocused: Bool

    let goalID: UUID

    @State private var title = ""
    @State private var selectedArea: GoalArea?
    @State private var selectedPriority: GoalPriority = .normal
    @State private var didLoad = false

    private var goal: Goal? {
        goals.first(where: { $0.id == goalID })
    }

    private var canSave: Bool {
        NextInput.trimmedTitle(title) != nil && selectedArea != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("EDIT GOAL")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(2.2)
                    .foregroundStyle(NextTheme.secondary)

                Text("What do you want to work toward?")
                    .nextFont(22, relativeTo: .title3)
                    .foregroundStyle(NextTheme.ink)
                    .padding(.top, 36)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("Study for MCAT", text: $title)
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

                areaGrid
                    .padding(.top, 8)

                Text("PRIORITY")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.8)
                    .foregroundStyle(NextTheme.secondary)
                    .padding(.top, 32)

                choiceStack {
                    ForEach(GoalPriority.allCases) { priority in
                        SelectionOption(
                            title: priority.title,
                            isSelected: selectedPriority == priority
                        ) {
                            titleFocused = false
                            selectedPriority = priority
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
            saveAction
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear(perform: loadCurrentValues)
        .onChange(of: goal?.id) { _, _ in
            loadCurrentValues()
        }
    }

    private var areaGrid: some View {
        LazyVGrid(columns: areaColumns, spacing: 4) {
            ForEach(GoalArea.allCases) { area in
                SelectionOption(
                    title: area.title,
                    isSelected: selectedArea == area
                ) {
                    titleFocused = false
                    selectedArea = area
                }
            }
        }
    }

    private var areaColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    @ViewBuilder
    private func choiceStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 4) { content() }
        } else {
            HStack(spacing: 8) { content() }
        }
    }

    private var saveAction: some View {
        NextPrimaryAction(title: "SAVE GOAL →", isEnabled: canSave) {
            titleFocused = false
            guard let goal, let area = selectedArea else { return }
            try? PlanningStore.updateGoal(
                goal,
                title: title,
                area: area,
                priority: selectedPriority,
                context: modelContext
            )
            dismiss()
        }
        .padding(.horizontal, NextTheme.pagePadding)
        .padding(.bottom, 12)
        .background(NextTheme.canvas)
    }

    private func loadCurrentValues() {
        guard !didLoad, let goal else { return }
        title = goal.title
        selectedArea = goal.area
        selectedPriority = goal.priority
        didLoad = true
    }
}
