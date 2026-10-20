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
}
