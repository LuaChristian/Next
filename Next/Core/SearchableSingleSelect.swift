//
//  SearchableSingleSelect.swift
//  Next
//
//  Compact single-select field + searchable sheet for areas or goals.
//

import SwiftUI

struct SearchableSingleSelectField: View {
    let label: String
    let placeholder: String
    let displayValue: String?
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(label)
                        .nextFont(13, weight: .medium, relativeTo: .caption)
                        .tracking(1.4)
                        .foregroundStyle(NextTheme.secondaryText)
                    Text(displayValue ?? placeholder)
                        .nextFont(17)
                        .foregroundStyle(displayValue == nil ? NextTheme.secondaryText : NextTheme.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(">")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.interactiveAccent)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(label)
        .accessibilityValue(displayValue ?? placeholder)
        .accessibilityHint("Opens a searchable list")
    }
}

struct SearchableAreaSelectSheet: View {
    let onSelect: (GoalArea) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [GoalArea] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return GoalArea.allCases }
        return GoalArea.allCases.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Search areas", text: $query)
                    .nextFont(17)
                    .padding(.horizontal, NextTheme.pagePadding)
                    .padding(.vertical, 12)
                    .accessibilityLabel("Search life areas")

                NextHairline()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filtered) { area in
                            Button {
                                onSelect(area)
                                dismiss()
                            } label: {
                                Text(area.title)
                                    .nextFont(20, relativeTo: .title3)
                                    .foregroundStyle(NextTheme.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("scopeArea-\(area.rawValue)")

                            if area != filtered.last {
                                NextHairline()
                            }
                        }
                    }
                    .padding(.horizontal, NextTheme.pagePadding)
                }
            }
            .background(NextTheme.canvas.ignoresSafeArea())
            .navigationTitle("Choose a life area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(NextTheme.interactiveAccent)
                }
            }
            .toolbarBackground(NextTheme.canvas, for: .navigationBar)
        }
        .accessibilityIdentifier("scopeAreaSheet")
    }
}

struct SearchableGoalSelectSheet: View {
    let goals: [Goal]
    let onSelect: (Goal) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [Goal] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = goals.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        guard !q.isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Search goals", text: $query)
                    .nextFont(17)
                    .padding(.horizontal, NextTheme.pagePadding)
                    .padding(.vertical, 12)
                    .accessibilityLabel("Search goals")

                NextHairline()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if filtered.isEmpty {
                            Text("No matching goals.")
                                .nextFont(17)
                                .foregroundStyle(NextTheme.secondaryText)
                                .padding(NextTheme.pagePadding)
                        } else {
                            ForEach(filtered, id: \.id) { goal in
                                Button {
                                    onSelect(goal)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(goal.title)
                                            .nextFont(20, relativeTo: .title3)
                                            .foregroundStyle(NextTheme.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if !goal.areasDisplayLabel.isEmpty {
                                            Text(goal.areasDisplayLabel)
                                                .nextFont(13, relativeTo: .caption)
                                                .foregroundStyle(NextTheme.secondaryText)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(goal.title)
                                .accessibilityIdentifier("scopeGoal-\(goal.id.uuidString)")

                                if goal.id != filtered.last?.id {
                                    NextHairline()
                                }
                            }
                            .padding(.horizontal, NextTheme.pagePadding)
                        }
                    }
                }
            }
            .background(NextTheme.canvas.ignoresSafeArea())
            .navigationTitle("Choose a goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(NextTheme.interactiveAccent)
                }
            }
            .toolbarBackground(NextTheme.canvas, for: .navigationBar)
        }
        .accessibilityIdentifier("scopeGoalSheet")
    }
}
