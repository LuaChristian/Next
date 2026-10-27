//
//  HomeView.swift
//  Next
//
//  Dual Focus entry: Help me decide (guided) and Choose a task (direct).
//

import SwiftData
import SwiftUI

enum TimeOption: CaseIterable, Identifiable {
    case fifteen
    case twentyFive
    case thirty
    case sixty
    case ninetyPlus

    var id: Self { self }

    /// Primary duration chips shown on the guided time step.
    static var standardPresets: [TimeOption] {
        [.fifteen, .thirty, .sixty, .ninetyPlus]
    }

    var title: String {
        switch self {
        case .fifteen: "15 min"
        case .twentyFive: "25 min"
        case .thirty: "30 min"
        case .sixty: "60 min"
        case .ninetyPlus: "90+ min"
        }
    }

    /// Exact custom duration offered beside the standard presets.
    var isExactCustom: Bool {
        self == .twentyFive
    }
}

enum EnergyLevel: String, CaseIterable, Identifiable, Codable {
    case low
    case good
    case ready

    var id: Self { self }

    var title: String {
        switch self {
        case .low: "Low"
        case .good: "Good"
        case .ready: "Ready"
        }
    }
}

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    @State private var greeting = HomeGreeting.text()
    @State private var destination: HomeFocusEntry?

    private var stacksEntries: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                Text("What would you like to work on?")
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 36)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("A little progress is still progress.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.secondaryText)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)

                entryChoices
                    .padding(.top, 36)
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, dynamicTypeSize.isAccessibilitySize ? 16 : 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("homeScreen")
        .navigationDestination(item: $destination) { entry in
            switch entry {
            case .helpMeDecide:
                HelpMeDecideView()
            case .chooseTask:
                ChooseTaskView()
            }
        }
        .onAppear { refreshGreeting() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshGreeting()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshGreeting()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)) { _ in
            refreshGreeting()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextReturnToHomeEntry)) { _ in
            destination = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NEXT")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondaryText)

            Text(greeting)
                .nextFont(34, relativeTo: .largeTitle)
                .foregroundStyle(NextTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("homeGreeting")
        }
    }

    @ViewBuilder
    private var entryChoices: some View {
        if stacksEntries {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(HomeFocusEntry.allCases) { entry in
                    entryButton(entry)
                    if entry != HomeFocusEntry.allCases.last {
                        NextHairline()
                    }
                }
            }
        } else {
            HStack(alignment: .top, spacing: 20) {
                ForEach(HomeFocusEntry.allCases) { entry in
                    entryButton(entry)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private func entryButton(_ entry: HomeFocusEntry) -> some View {
        Button {
            destination = entry
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.title)
                    .nextFont(22, relativeTo: .title3)
                    .foregroundStyle(NextTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(entry.subtitle)
                    .nextFont(15)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text("→")
                    .nextFont(17, weight: .medium)
                    .foregroundStyle(NextTheme.interactiveAccent)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(entry.title)
        .accessibilityHint(entry.accessibilityHint)
        .accessibilityIdentifier(entry.accessibilityIdentifier)
    }

    private func refreshGreeting() {
        greeting = HomeGreeting.text()
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
