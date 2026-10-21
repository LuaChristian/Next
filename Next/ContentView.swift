//
//  ContentView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                GardenView()
            }
            .tabItem {
                Label("Garden", systemImage: "leaf")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .tint(NextTheme.interactiveAccent)
        .toolbarBackground(NextTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await DailyReminderCoordinator.shared.reconcile(context: modelContext)
            }
        }
        .task {
            await DailyReminderCoordinator.shared.reconcile(context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextPreferHomeTab)) { _ in
            guard !FocusSessionPresence.isActive else { return }
            selectedTab = 0
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
