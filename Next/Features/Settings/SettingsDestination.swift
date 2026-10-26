//
//  SettingsDestination.swift
//  Next
//
//  Typed destinations for the Settings navigation hub.
//

import Foundation

enum SettingsDestination: String, Hashable, CaseIterable, Identifiable {
    case history
    case appearance
    case reminders
    case about
    case dataManagement

    var id: Self { self }

    var title: String {
        switch self {
        case .history: "History"
        case .appearance: "Appearance"
        case .reminders: "Reminders"
        case .about: "About Next"
        case .dataManagement: "Data Management"
        }
    }

    var subtitle: String {
        switch self {
        case .history: "Focus sessions and progress"
        case .appearance: "Light, dark, and system theme"
        case .reminders: "Daily reminder preferences"
        case .about: "App information and version"
        case .dataManagement: "Manage your data and start fresh"
        }
    }

    var systemImage: String {
        switch self {
        case .history: "clock"
        case .appearance: "circle.lefthalf.filled"
        case .reminders: "bell"
        case .about: "info.circle"
        case .dataManagement: "externaldrive"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .history: "settingsHistoryLink"
        case .appearance: "settingsAppearanceLink"
        case .reminders: "settingsRemindersLink"
        case .about: "settingsAboutLink"
        case .dataManagement: "settingsDataManagementLink"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .history: "Opens your focus session history"
        case .appearance: "Opens appearance settings"
        case .reminders: "Opens reminder settings"
        case .about: "Opens app information"
        case .dataManagement: "Opens data management and fresh start options"
        }
    }
}

enum AppVersionInfo {
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    static var versionAndBuildLabel: String {
        "Version \(shortVersion) (\(buildNumber))"
    }
}
