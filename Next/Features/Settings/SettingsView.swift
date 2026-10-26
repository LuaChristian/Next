//
//  SettingsView.swift
//  Next
//
//  Settings navigation hub. Each section opens a dedicated page.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SETTINGS")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(SettingsDestination.allCases) { destination in
                        NavigationLink(value: destination) {
                            SettingsRow(destination: destination)
                        }
                        .buttonStyle(.plain)

                        if destination != SettingsDestination.allCases.last {
                            NextHairline()
                        }
                    }
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
            case .history:
                HistoryView()
            case .appearance:
                AppearanceSettingsView()
            case .reminders:
                RemindersSettingsView()
            case .about:
                AboutNextView()
            case .dataManagement:
                DataManagementView()
            }
        }
        .accessibilityIdentifier("settingsScreen")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
