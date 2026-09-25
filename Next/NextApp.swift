//
//  NextApp.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI
import SwiftData

@main
struct NextApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try NextPersistence.makeContainer()
        } catch {
            fatalError("Could not create persistent ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
