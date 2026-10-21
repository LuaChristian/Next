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
    @AppStorage(AppearancePreference.key) private var appearanceRaw = AppearancePreference.system.rawValue

    init() {
        do {
            let container = try NextPersistence.makeContainer()
            self.container = container
            let context = ModelContext(container)
            let goalsExist = ((try? context.fetchCount(FetchDescriptor<Goal>())) ?? 0) > 0
            _hasCompletedOnboarding = State(
                initialValue: OnboardingPreference.resolveCompleted(goalsExist: goalsExist)
            )
            AppearancePreference.applyLaunchOverrides()
            ReminderPreference.applyLaunchOverrides()
            NextTheme.applyChrome()
            NextNotificationCenterDelegate.register()
        } catch {
            fatalError("Could not create persistent ModelContainer: \(error)")
        }
    }

    private var appearance: AppearancePreference {
        AppearancePreference.resolve(stored: appearanceRaw)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains(NextPersistence.plantComparisonArgument) {
                    PlantComparisonView()
                } else if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingFlow {
                        hasCompletedOnboarding = true
                    }
                }
                #else
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingFlow {
                        hasCompletedOnboarding = true
                    }
                }
                #endif
            }
            .preferredColorScheme(appearance.preferredColorScheme)
            .tint(NextTheme.interactiveAccent)
            .background(NextTheme.canvas.ignoresSafeArea())
        }
        .modelContainer(container)
    }
}
