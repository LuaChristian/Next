//
//  ContentView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                GardenView()
            }
            .tabItem {
                Label("Garden", systemImage: "leaf")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
        .tint(NextTheme.botanical)
        .toolbarBackground(NextTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
