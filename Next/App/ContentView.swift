//
//  ContentView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

@MainActor
@Observable
private final class FocusRecoveryGate: Identifiable {
    enum Phase {
        case prompt(FocusRecoveryPromptModel)
        case focus(FocusRecoveryBootstrap)
    }

    let id: UUID
    var phase: Phase

    init(prompt: FocusRecoveryPromptModel) {
        id = prompt.experienceID
        phase = .prompt(prompt)
    }

    init(focus bootstrap: FocusRecoveryBootstrap) {
        id = bootstrap.experienceID
        phase = .focus(bootstrap)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var recoveredFocus: FocusRecoveryGate?

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
        .fullScreenCover(item: $recoveredFocus) { gate in
            FocusRecoveryGateHost(gate: gate) {
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

        let now = Date()

        // Awaiting completion → open Completion directly (no Resume/End gate).
        if snapshot.awaitingCompletion {
            guard let bootstrap = FocusRecoveryReconciler.restore(snapshot: snapshot, now: now) else {
                FocusRecoveryStore.clear()
                return
            }
            FocusNotificationCoordinator.shared.cancel()
            recoveredFocus = FocusRecoveryGate(focus: bootstrap)
            return
        }

        guard let prompt = FocusRecoveryReconciler.makePrompt(snapshot: snapshot, now: now) else {
            FocusRecoveryStore.clear()
            return
        }

        // Rewrite running → paused so a second kill during the prompt stays conservative.
        FocusRecoveryReconciler.persistFrozenSnapshotIfNeeded(snapshot, now: now)
        FocusNotificationCoordinator.shared.cancel()
        recoveredFocus = FocusRecoveryGate(prompt: prompt)
    }
}

/// Hosts prompt → focus within one cover so Resume/End never race a second prompt.
private struct FocusRecoveryGateHost: View {
    @Bindable var gate: FocusRecoveryGate
    let onDone: () -> Void

    var body: some View {
        switch gate.phase {
        case .prompt(let model):
            FocusRecoveryPromptView(
                model: model,
                onResume: {
                    let resumed = FocusRecoveryReconciler.resume(model.bootstrap, at: Date())
                    gate.phase = .focus(resumed)
                },
                onEndSession: {
                    let ended = FocusRecoveryReconciler.endSession(model.bootstrap, at: Date())
                    gate.phase = .focus(ended)
                }
            )
        case .focus(let bootstrap):
            FocusView(
                task: bootstrap.task,
                bootstrap: bootstrap,
                onDone: onDone
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
