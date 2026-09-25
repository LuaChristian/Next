//
//  ContentView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

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
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
}
