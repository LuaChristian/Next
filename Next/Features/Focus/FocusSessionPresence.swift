//
//  FocusSessionPresence.swift
//  Next
//
//  Lightweight flag so reminder taps do not interrupt an active focus session.
//

import Foundation

enum FocusSessionPresence {
    @MainActor
    static var isActive = false
}

extension Notification.Name {
    /// Posted when a daily reminder is opened; ContentView prefers the Home tab.
    static let nextPreferHomeTab = Notification.Name("next.preferHomeTab")
    /// Posted when a Focus session finishes from a Home entry path; clears Home navigation.
    static let nextReturnToHomeEntry = Notification.Name("next.returnToHomeEntry")
}
