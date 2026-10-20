//
//  AppearancePreference.swift
//  Next
//
//  System / Light / Dark. Persisted in UserDefaults — not SwiftData.
//

import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let key = "appearancePreference"
    /// UITest launch: `UITEST_APPEARANCE` followed by `system` | `light` | `dark`.
    static let launchArgument = "UITEST_APPEARANCE"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .system: "Follows the iOS appearance setting"
        case .light: "Always uses Calm Garden"
        case .dark: "Always uses Twilight Quiet"
        }
    }

    /// nil lets the window follow the system interface style.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    /// AppStorage and the live app always use `.standard`.
    /// Unit tests may pass an isolated suite via `in:`.
    static func store(arguments: [String] = ProcessInfo.processInfo.arguments) -> UserDefaults {
        _ = arguments
        return .standard
    }

    /// Unknown or missing values fall back to System.
    static func resolve(stored raw: String?) -> AppearancePreference {
        guard let raw, let value = AppearancePreference(rawValue: raw) else {
            return .system
        }
        return value
    }

    static func current(in defaults: UserDefaults? = nil) -> AppearancePreference {
        resolve(stored: (defaults ?? .standard).string(forKey: key))
    }

    static func set(_ value: AppearancePreference, in defaults: UserDefaults? = nil) {
        (defaults ?? .standard).set(value.rawValue, forKey: key)
    }

    /// Seed preference before the first frame (UI tests). Writes to `.standard`
    /// so `@AppStorage` sees the value immediately.
    static func applyLaunchOverrides(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults? = nil
    ) {
        let defaults = defaults ?? .standard
        guard let index = arguments.firstIndex(of: launchArgument),
              arguments.indices.contains(index + 1) else { return }
        let value = resolve(stored: arguments[index + 1])
        defaults.set(value.rawValue, forKey: key)
    }
}
