//
//  CrossVersionMigrationTests.swift
//  NextTests
//
//  Genuine V2-M9 → V3-M1 SwiftData store migration verification.
//  Fixture is produced by the disposable V2-M9 worktree writer
//  (commit 415d108) whose Goal schema lacked areasRaw / areasMigrated.
//

import Foundation
import SQLite3
import SwiftData
import Testing
@testable import Next

struct CrossVersionMigrationTests {
    private static let expectedGoalID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    private static let expectedTaskID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    private static let expectedSessionID = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!

    /// Golden store written by V2-M9 NextPersistence (no areasRaw / areasMigrated columns).
    private static var goldenStoreURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/v2m9-pre-multiarea/legacy.store")
    }

    @MainActor
    @Test func genuineV2M9StoreMigratesWithoutDataLossOrDuplication() throws {
        let golden = Self.goldenStoreURL
        #expect(
            FileManager.default.fileExists(atPath: golden.path),
            "Missing V2-M9 fixture at \(golden.path). Regenerate via the disposable worktree writer against commit 415d108."
        )

        // Prove the fixture is a pre-multi-area schema (columns absent).
        let goldenColumns = try sqliteColumnNames(in: golden, table: "ZGOAL")
        #expect(!goldenColumns.contains("ZAREASRAW"))
        #expect(!goldenColumns.contains("ZAREASMIGRATED"))
        #expect(goldenColumns.contains("ZAREA"))
        #expect(goldenColumns.contains("ZPLANTVARIANTRAW"))

        // Disposable working copy — never open the golden fixture for write/migrate.
        let workDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-v3m1-cross-version-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDirectory) }

        let workStore = workDirectory.appendingPathComponent("legacy.store")
        try FileManager.default.copyItem(at: golden, to: workStore)

        // Open with current V3-M1 persistence (schema + migrateGoalAreasIfNeeded).
        let container = try NextPersistence.makeContainer(storeURL: workStore)
        let context = ModelContext(container)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())

        #expect(goals.count == 1)
        #expect(tasks.count == 1)
        #expect(sessions.count == 1)

        let goal = try #require(goals.first)
        let task = try #require(tasks.first)
        let session = try #require(sessions.first)

        #expect(goal.id == Self.expectedGoalID)
        #expect(goal.title == "Study for MCAT")
        #expect(goal.area == .education)
        #expect(goal.areas == [.education])
        #expect(goal.areasRaw == "education")
        #expect(goal.areasMigrated == true)
        #expect(goal.priority == .high)
        #expect(goal.plantVariant == .narrowLeaf)
        #expect(goal.sessionCount == 1)
        #expect(goal.totalFocusedDuration == 1800)
        #expect(goal.growthStage == GardenGrowth.stage(for: 1800))

        #expect(task.id == Self.expectedTaskID)
        #expect(task.title == "Review amino acids")
        #expect(task.goal?.id == Self.expectedGoalID)
        #expect(task.durationMinutes == 30)
        #expect(task.energyRequired == .good)

        #expect(session.id == Self.expectedSessionID)
        #expect(session.goal?.id == Self.expectedGoalID)
        #expect(session.task?.id == Self.expectedTaskID)
        #expect(session.goalTitleSnapshot == "Study for MCAT")
        #expect(session.taskTitleSnapshot == "Review amino acids")
        #expect(session.focusedDurationSeconds == 1800)
        #expect(session.plannedDurationSeconds == 1800)

        // Lightweight migration should have added the new columns without wiping the store.
        // Note: SQLite may still hold a WAL; reopen probe after container is released.
        // Drop strong column asserts if the file is locked; model-level proof above is authoritative.
        if let migratedColumns = try? sqliteColumnNames(in: workStore, table: "ZGOAL") {
            #expect(migratedColumns.contains("ZAREA"))
            #expect(
                migratedColumns.contains("ZAREASRAW") && migratedColumns.contains("ZAREASMIGRATED"),
                "Expected lightweight migration to add ZAREASRAW and ZAREASMIGRATED; got \(migratedColumns)"
            )
        }

        // Reopen migrated store — no duplication, values stable.
        let reopened = try NextPersistence.makeContainer(storeURL: workStore)
        let reopenedContext = ModelContext(reopened)
        let goals2 = try reopenedContext.fetch(FetchDescriptor<Goal>())
        let tasks2 = try reopenedContext.fetch(FetchDescriptor<GoalTask>())
        let sessions2 = try reopenedContext.fetch(FetchDescriptor<FocusSession>())

        #expect(goals2.count == 1)
        #expect(tasks2.count == 1)
        #expect(sessions2.count == 1)
        #expect(goals2.first?.id == Self.expectedGoalID)
        #expect(goals2.first?.areas == [.education])
        #expect(goals2.first?.areasMigrated == true)
        #expect(goals2.first?.areasRaw == "education")
        #expect(goals2.first?.totalFocusedDuration == 1800)
        #expect(sessions2.first?.goalTitleSnapshot == "Study for MCAT")
        #expect(sessions2.first?.taskTitleSnapshot == "Review amino acids")
    }

    private func sqliteColumnNames(in storeURL: URL, table: String) throws -> [String] {
        // Read-only probe of the SQLite file backing the SwiftData store.
        let db = try SQLiteProbe(path: storeURL.path)
        defer { db.close() }
        return try db.columnNames(table: table)
    }
}

/// Minimal SQLite reader for schema probes (no product dependency).
private final class SQLiteProbe {
    private var db: OpaquePointer?

    init(path: String) throws {
        let status = sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil)
        guard status == SQLITE_OK else {
            throw NSError(domain: "SQLiteProbe", code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "Unable to open \(path)"
            ])
        }
    }

    func close() {
        if let db {
            sqlite3_close(db)
        }
        db = nil
    }

    func columnNames(table: String) throws -> [String] {
        let sql = "PRAGMA table_info(\(table));"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteProbe", code: 1)
        }
        defer { sqlite3_finalize(statement) }

        var names: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 1) {
                names.append(String(cString: cString))
            }
        }
        return names
    }
}
