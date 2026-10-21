//
//  ContentView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

private struct FocusRecoveryPresentation: Identifiable {
    var id: UUID { bootstrap.experienceID }
    let bootstrap: FocusRecoveryBootstrap
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var recoveredFocus: FocusRecoveryPresentation?

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
            presentRecoveredFocusIfNeeded()
        }
        .task {
            await DailyReminderCoordinator.shared.reconcile(context: modelContext)
            presentRecoveredFocusIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextPreferHomeTab)) { _ in
            guard !FocusSessionPresence.isActive else { return }
            selectedTab = 0
        }
        .fullScreenCover(item: $recoveredFocus) { presentation in
            FocusView(
                task: presentation.bootstrap.task,
                bootstrap: presentation.bootstrap
            ) {
                recoveredFocus = nil
                presentRecoveredFocusIfNeeded()
            }
        }
    }

    private func presentRecoveredFocusIfNeeded() {
        guard recoveredFocus == nil else { return }
        guard !FocusSessionPresence.isActive else { return }
        // Drops stale snapshots when FocusSession commit already succeeded.
        guard let snapshot = FocusRecoveryStore.loadForPresentation(context: modelContext) else {
            return
        }
        guard let bootstrap = FocusRecoveryReconciler.restore(snapshot: snapshot) else {
            FocusRecoveryStore.clear()
            return
        }
        recoveredFocus = FocusRecoveryPresentation(bootstrap: bootstrap)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
