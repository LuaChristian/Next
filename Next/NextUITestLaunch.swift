//
//  NextUITestLaunch.swift
//  Next
//
//  Detects UITest launch arguments. Always false in Release builds.
//

import Foundation

enum NextUITestLaunch {
    static var isActive: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("UITEST_") }
        #else
        false
        #endif
    }
}
