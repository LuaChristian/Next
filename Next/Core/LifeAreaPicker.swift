//
//  LifeAreaPicker.swift
//  Next
//
//  Compact multi-select life-area field + searchable sheet.
//

import SwiftUI

struct LifeAreaMultiSelectField: View {
    @Binding var selected: Set<GoalArea>
    @State private var showingSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFE AREAS")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondary)

            Button {
                showingSheet = true
            } label: {
                HStack {
                    Text("Choose life areas")
                        .nextFont(17)
                        .foregroundStyle(NextTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(">")
                        .nextFont(17)
                        .foregroundStyle(NextTheme.interactiveAccent)
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("lifeAreasField")
            .accessibilityLabel("Life areas")
            .accessibilityValue(selected.isEmpty ? "None selected" : summaryLabel)
            .accessibilityHint("Opens a searchable list to choose one or more life areas")

            if !selected.isEmpty {
                Text(summaryLabel)
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(1.0)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: $showingSheet) {
            LifeAreaMultiSelectSheet(selected: $selected)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(NextTheme.canvas)
        }
    }

    private var summaryLabel: String {
        Goal.normalized(Array(selected)).map(\.title).joined(separator: " · ")
    }
}

struct LifeAreaMultiSelectSheet: View {
    @Binding var selected: Set<GoalArea>
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
                            areaRow(area)
                            if area != filtered.last {
                                NextHairline()
                            }
                        }
                    }
                    .padding(.horizontal, NextTheme.pagePadding)
                }
            }
            .background(NextTheme.canvas.ignoresSafeArea())
            .navigationTitle("Life areas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NextTheme.interactiveAccent)
                        .accessibilityIdentifier("lifeAreasDone")
                }
            }
            .toolbarBackground(NextTheme.canvas, for: .navigationBar)
        }
        .accessibilityIdentifier("lifeAreasSheet")
    }

    private func areaRow(_ area: GoalArea) -> some View {
        let isOn = selected.contains(area)
        return Button {
            if isOn {
                selected.remove(area)
            } else {
                selected.insert(area)
            }
        } label: {
            HStack {
                Text(area.title)
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(isOn ? NextTheme.interactiveAccent : NextTheme.primaryText)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .foregroundStyle(NextTheme.interactiveAccent)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel(area.title)
        .accessibilityValue(isOn ? "Selected" : "Not selected")
        .accessibilityIdentifier("lifeArea-\(area.rawValue)")
    }
}
