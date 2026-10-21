//
//  GardenCollectionSummary.swift
//  Next
//
//  Editorial Garden overview. Metrics derive from existing Goal /
//  FocusSession relationships — no second growth system.
//

import Foundation
import SwiftUI

enum GardenCollectionSummary {
    /// Sum focused time across goals. Each FocusSession belongs to one Goal,
    /// so multi-area goals contribute once and sessions are never double-counted.
    static func totalFocusedSeconds(across goals: [Goal]) -> TimeInterval {
        goals.reduce(0) { $0 + max(0, $1.totalFocusedDuration) }
    }

    static func goalsGrowingLabel(count: Int) -> String {
        count == 1 ? "1 goal growing" : "\(count) goals growing"
    }

    static func focusedTimeLabel(seconds: TimeInterval) -> String {
        "\(editorialDuration(seconds: seconds)) of focused time"
    }

    /// Quiet lowercase duration for the Garden summary line.
    static func editorialDuration(seconds: TimeInterval) -> String {
        if seconds <= 0 {
            return "0m"
        }
        if seconds < 60 {
            return "<1m"
        }

        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainder)m"
    }
}

enum GardenCollectionLayout {
    /// Prefer a single column when Dynamic Type is large or the content
    /// width cannot comfortably hold two plant cells with readable titles.
    static func columnCount(contentWidth: CGFloat, isAccessibilitySize: Bool) -> Int {
        if isAccessibilitySize { return 1 }
        // Standard iPhone (~337pt after page padding) gets two columns;
        // smaller phones (SE-class) stay single-column for readable titles.
        return contentWidth >= 320 ? 2 : 1
    }

    /// Prominent plant bounds for collection cells (larger than V3-M8 list rows).
    static func plantSize(columns: Int, isAccessibilitySize: Bool) -> CGSize {
        if isAccessibilitySize {
            return CGSize(width: 96, height: 132)
        }
        if columns == 1 {
            return CGSize(width: 148, height: 200)
        }
        return CGSize(width: 124, height: 168)
    }
}
