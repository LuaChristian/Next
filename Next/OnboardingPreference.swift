//
//  OnboardingPreference.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation

enum OnboardingPreference {
    static let completedKey = "hasCompletedOnboarding"
    static let suiteArgument = "UITEST_DEFAULTS_SUITE"
    static let completedArgument = "UITEST_ONBOARDING_COMPLETED"
    static let freshArgument = "UITEST_FRESH_ONBOARDING"

    static func store(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        if let index = arguments.firstIndex(of: suiteArgument),
           arguments.indices.contains(index + 1),
           let defaults = UserDefaults(suiteName: arguments[index + 1]) {
            return defaults
        }

        if arguments.contains(where: { $0.hasPrefix("UITEST_") }) {
            return UserDefaults(suiteName: "next.uitest.ephemeral") ?? .standard
        }

        return .standard
    }

    static func applyLaunchOverrides(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults? = nil
    ) {
        let defaults = defaults ?? store(arguments: arguments)
        if arguments.contains(completedArgument) {
            defaults.set(true, forKey: completedKey)
        } else if arguments.contains(freshArgument) {
            defaults.removeObject(forKey: completedKey)
        }
    }

    static func resolveCompleted(
        goalsExist: Bool,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults? = nil
    ) -> Bool {
        let defaults = defaults ?? store(arguments: arguments)
        applyLaunchOverrides(arguments: arguments, defaults: defaults)

        if defaults.object(forKey: completedKey) != nil {
            return defaults.bool(forKey: completedKey)
        }

        if goalsExist {
            markCompleted(in: defaults)
            return true
        }

        return false
    }

    static func markCompleted(in defaults: UserDefaults? = nil) {
        (defaults ?? store()).set(true, forKey: completedKey)
    }

    static func isCompleted(in defaults: UserDefaults? = nil) -> Bool {
        (defaults ?? store()).bool(forKey: completedKey)
    }
}
