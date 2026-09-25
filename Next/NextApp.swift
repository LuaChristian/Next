//
//  NextApp.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

@main
struct NextApp: App {
    @State private var store = AppStore.makeForLaunch()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}

private extension AppStore {
    static func makeForLaunch() -> AppStore {
        if ProcessInfo.processInfo.arguments.contains(uiTestSeedArgument) {
            return seededForUITests()
        }
        return AppStore()
    }
}
