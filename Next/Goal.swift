//
//  Goal.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import Foundation
import SwiftData

enum GoalArea: String, CaseIterable, Identifiable, Codable {
    case education
    case career
    case fitness
    case creative
    case wellness
    case finance
    case social
    case personal

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }
}

enum GoalPriority: String, CaseIterable, Identifiable, Codable, Comparable {
    case low
    case normal
    case high

    var id: Self { self }

    var title: String {
        rawValue.capitalized
    }

    var rank: Int {
        switch self {
        case .high: 3
        case .normal: 2
        case .low: 1
        }
    }

    static func < (lhs: GoalPriority, rhs: GoalPriority) -> Bool {
        lhs.rank < rhs.rank
    }
}

enum TaskDuration: CaseIterable, Identifiable {
    case fifteen
    case thirty
    case fortyFive
    case sixty
    case ninetyPlus

    var id: Self { self }

    var minutes: Int {
        switch self {
        case .fifteen: 15
        case .thirty: 30
        case .fortyFive: 45
        case .sixty: 60
        case .ninetyPlus: 90
        }
    }

    var title: String {
        switch self {
        case .fifteen: "15 min"
        case .thirty: "30 min"
        case .fortyFive: "45 min"
        case .sixty: "60 min"
        case .ninetyPlus: "90+ min"
        }
    }

    static func matching(minutes: Int) -> TaskDuration? {
        allCases.first { $0.minutes == minutes }
    }
}

@Model
final class Goal {
    var id: UUID
    var title: String
    /// Legacy single-area field retained for SwiftData lightweight compatibility.
    /// Authoritative membership lives in `areasRaw` after `areasMigrated` is true.
    var area: GoalArea
    /// Pipe-separated unique `GoalArea.rawValue`s. Empty means zero areas (after migration).
    var areasRaw: String = ""
    /// False on rows that only have the legacy `area` field populated.
    var areasMigrated: Bool = false
    var priority: GoalPriority
    var createdAt: Date
    /// Additive V2-M5 identity. Existing rows migrate to broadLeaf via the stored default.
    var plantVariantRaw: String = "broadLeaf"

    @Relationship(deleteRule: .cascade, inverse: \GoalTask.goal)
    var tasks: [GoalTask]

    /// Nullify, not cascade: deleting a Goal must keep historical FocusSessions.
    @Relationship(deleteRule: .nullify, inverse: \FocusSession.goal)
    var focusSessions: [FocusSession]

    init(
        id: UUID = UUID(),
        title: String,
        area: GoalArea,
        priority: GoalPriority,
        createdAt: Date = Date(),
        plantVariant: PlantVariant = .broadLeaf,
        tasks: [GoalTask] = [],
        focusSessions: [FocusSession] = []
    ) {
        self.id = id
        self.title = title
        self.area = area
        self.areasRaw = Self.encodeAreas([area])
        self.areasMigrated = true
        self.priority = priority
        self.createdAt = createdAt
        self.plantVariantRaw = plantVariant.rawValue
        self.tasks = tasks
        self.focusSessions = focusSessions
    }

    init(
        id: UUID = UUID(),
        title: String,
        areas: [GoalArea],
        priority: GoalPriority,
        createdAt: Date = Date(),
        plantVariant: PlantVariant = .broadLeaf,
        tasks: [GoalTask] = [],
        focusSessions: [FocusSession] = []
    ) {
        let normalized = Self.normalized(areas)
        self.id = id
        self.title = title
        self.area = normalized.first ?? .personal
        self.areasRaw = Self.encodeAreas(normalized)
        self.areasMigrated = true
        self.priority = priority
        self.createdAt = createdAt
        self.plantVariantRaw = plantVariant.rawValue
        self.tasks = tasks
        self.focusSessions = focusSessions
    }

    /// Deduplicated areas in stable GoalArea.allCases order.
    var areas: [GoalArea] {
        get {
            if areasMigrated {
                return Self.decodeAreas(areasRaw)
            }
            return [area]
        }
        set {
            let normalized = Self.normalized(newValue)
            areasRaw = Self.encodeAreas(normalized)
            if let first = normalized.first {
                area = first
            }
            areasMigrated = true
        }
    }

    var areasDisplayLabel: String {
        areas.map { $0.title.uppercased() }.joined(separator: " · ")
    }

    var sortedTasks: [GoalTask] {
        tasks.sorted { $0.createdAt < $1.createdAt }
    }

    var activeTasks: [GoalTask] {
        sortedTasks.filter(\.isActive)
    }

    var completedTasks: [GoalTask] {
        tasks.filter(\.isCompleted).sorted { lhs, rhs in
            (lhs.completedAt ?? lhs.createdAt) > (rhs.completedAt ?? rhs.createdAt)
        }
    }

    var taskCountLabel: String {
        tasks.count == 1 ? "1 TASK" : "\(tasks.count) TASKS"
    }

    var activeTaskCountLabel: String {
        activeTasks.count == 1 ? "1 TASK" : "\(activeTasks.count) TASKS"
    }

    var sessionCount: Int {
        focusSessions.count
    }

    var totalFocusedDuration: TimeInterval {
        focusSessions.reduce(0) { $0 + $1.focusedDurationSeconds }
    }

    var growthStage: GardenGrowthStage {
        GardenGrowth.stage(for: totalFocusedDuration)
    }

    /// Most recent FocusSession for this Goal. Nil means never worked.
    /// Derived from persisted sessions; not stored.
    var lastFocusedAt: Date? {
        focusSessions.map(\.completedAt).max()
    }

    var progressMetricsLabel: String {
        "\(GardenMetrics.sessionCountLabel(sessionCount))  ·  \(GardenMetrics.focusedDurationLabel(seconds: totalFocusedDuration))"
    }

    var progressAccessibilityLabel: String {
        let areaPart = areasDisplayLabel.isEmpty ? "No life areas" : areasDisplayLabel
        return "\(title) plant. \(growthStage.spokenName). \(GardenMetrics.focusedDurationSpoken(seconds: totalFocusedDuration)). \(areaPart). \(GardenMetrics.sessionCountSpoken(sessionCount))"
    }

    /// Backfill `areasRaw` from legacy `area` once. Safe to call repeatedly.
    func migrateAreasIfNeeded() {
        guard !areasMigrated else { return }
        areasRaw = Self.encodeAreas([area])
        areasMigrated = true
    }

    static func normalized(_ areas: [GoalArea]) -> [GoalArea] {
        var seen = Set<GoalArea>()
        var result: [GoalArea] = []
        for area in GoalArea.allCases {
            if areas.contains(area), !seen.contains(area) {
                seen.insert(area)
                result.append(area)
            }
        }
        return result
    }

    static func encodeAreas(_ areas: [GoalArea]) -> String {
        normalized(areas).map(\.rawValue).joined(separator: "|")
    }

    static func decodeAreas(_ raw: String) -> [GoalArea] {
        guard !raw.isEmpty else { return [] }
        let parsed = raw.split(separator: "|").compactMap { GoalArea(rawValue: String($0)) }
        return normalized(parsed)
    }
}

extension Goal {
    var plantVariant: PlantVariant {
        get { PlantVariant(rawValue: plantVariantRaw) ?? .broadLeaf }
        set { plantVariantRaw = newValue.rawValue }
    }
}

@Model
final class GoalTask {
    var id: UUID
    var title: String
    var durationMinutes: Int
    var energyRequired: EnergyLevel
    var createdAt: Date
    /// Additive V2-M1 fields. Existing V1 rows migrate as active via
    /// the stored default (`false`) and optional `completedAt`.
    var isCompleted: Bool = false
    var completedAt: Date?
    var goal: Goal?

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.task)
    var focusSessions: [FocusSession]

    init(
        id: UUID = UUID(),
        title: String,
        durationMinutes: Int,
        energyRequired: EnergyLevel,
        createdAt: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        goal: Goal? = nil,
        focusSessions: [FocusSession] = []
    ) {
        self.id = id
        self.title = title
        self.durationMinutes = durationMinutes
        self.energyRequired = energyRequired
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.goal = goal
        self.focusSessions = focusSessions
    }

    var isActive: Bool {
        !isCompleted
    }

    func complete(at date: Date = Date()) {
        isCompleted = true
        completedAt = date
    }

    func reopen() {
        isCompleted = false
        completedAt = nil
    }

    var asTaskItem: TaskItem {
        asTaskItem(lastFocusedAt: goal?.lastFocusedAt)
    }

    func asTaskItem(lastFocusedAt: Date?) -> TaskItem {
        TaskItem(
            id: id,
            goalID: goal?.id,
            title: title,
            durationMinutes: durationMinutes,
            energyRequired: energyRequired,
            area: goal?.areas.map(\.title).joined(separator: " · ") ?? "",
            goal: goal?.title ?? "",
            goalPriority: goal?.priority ?? .normal,
            lastFocusedAt: lastFocusedAt
        )
    }
}

extension Collection where Element == GoalTask {
    var recommendationItems: [TaskItem] {
        recommendationItems(matching: .anything)
    }

    func recommendationItems(matching scope: RecommendationScope) -> [TaskItem] {
        let active = filter(\.isActive).filter { task in
            guard let goal = task.goal else { return scope.mode == .anything }
            return scope.includes(goal)
        }
        var recency: [UUID: Date] = [:]
        var scanned = Set<UUID>()
        return active.map { task in
            let last: Date?
            if let goal = task.goal {
                if scanned.contains(goal.id) {
                    last = recency[goal.id]
                } else {
                    scanned.insert(goal.id)
                    last = goal.lastFocusedAt
                    if let last {
                        recency[goal.id] = last
                    }
                }
            } else {
                last = nil
            }
            return task.asTaskItem(lastFocusedAt: last)
        }
    }
}
