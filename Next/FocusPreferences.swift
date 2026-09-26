//
//  FocusPreferences.swift
//  Next
//
//  Lightweight Focus preferences. Not part of the SwiftData domain.
//

import Foundation
import UIKit

enum FocusPreference {
    static let keepScreenAwakeKey = "keepScreenAwake"

    static func store(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        OnboardingPreference.store(arguments: arguments)
    }

    static func keepScreenAwake(
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        (defaults ?? store(arguments: arguments)).bool(forKey: keepScreenAwakeKey)
    }

    static func setKeepScreenAwake(
        _ value: Bool,
        in defaults: UserDefaults? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        (defaults ?? store(arguments: arguments)).set(value, forKey: keepScreenAwakeKey)
    }
}

enum FocusIdleTimerPolicy {
    /// Idle timer is disabled only while Keep Screen Awake is on, Focus is running, and Next is active.
    static func isIdleTimerDisabled(
        keepScreenAwake: Bool,
        phase: FocusSessionPhase,
        sceneActive: Bool
    ) -> Bool {
        keepScreenAwake && phase == .running && sceneActive
    }
}

enum FocusIdleTimer {
    static var isDisabled: Bool {
        get { UIApplication.shared.isIdleTimerDisabled }
        set { UIApplication.shared.isIdleTimerDisabled = newValue }
    }
}
