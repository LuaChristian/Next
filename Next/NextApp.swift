//
//  NextApp.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftData
import SwiftUI

@main
struct NextApp: App {
    let container: ModelContainer
    @State private var hasCompletedOnboarding: Bool

    init() {
        do {
            let container = try NextPersistence.makeContainer()
            self.container = container
            let context = ModelContext(container)
            let goalsExist = ((try? context.fetchCount(FetchDescriptor<Goal>())) ?? 0) > 0
            _hasCompletedOnboarding = State(
                initialValue: OnboardingPreference.resolveCompleted(goalsExist: goalsExist)
            )
        } catch {
            fatalError("Could not create persistent ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingFlow {
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(container)
    }
}
