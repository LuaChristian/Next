//
//  AppDataResetCoordinator.swift
//  Next
//
//  Centralized destructive reset: SwiftData domain + recovery + reminders +
//  onboarding. Appearance is preserved. Never deletes store files.
//

import Foundation
import SwiftData

enum AppDataResetError: Error, Equatable {
    case alreadyInProgress
    case persistenceFailed
}

extension Notification.Name {
    /// Posted only after a successful reset. NextApp returns to onboarding.
    static let nextAppDataDidReset = Notification.Name("next.appDataDidReset")
}

/// Dependencies injectable for unit tests. Production uses live coordinators.
struct AppDataResetServices {
    var cancelFocusNotifications: () -> Void
    var disableReminders: () -> Void
    var clearRecovery: (UserDefaults?) -> Void
    var saveContext: (ModelContext) throws -> Void
    var postDidReset: () -> Void

    @MainActor
    static let live = AppDataResetServices(
        cancelFocusNotifications: {
            FocusNotificationCoordinator.shared.cancel()
        },
        disableReminders: {
            DailyReminderCoordinator.shared.disable()
        },
        clearRecovery: { defaults in
            FocusRecoveryStore.clear(in: defaults)
        },
        saveContext: { context in
            try context.save()
        },
        postDidReset: {
            FocusSessionPresence.isActive = false
            NotificationCenter.default.post(name: .nextAppDataDidReset, object: nil)
        }
    )
}

@MainActor
final class AppDataResetCoordinator {
    static let shared = AppDataResetCoordinator()

    private(set) var isResetting = false
    private let services: AppDataResetServices

    init(services: AppDataResetServices? = nil) {
        self.services = services ?? .live
    }

    /// Erases all local app data and restarts onboarding.
    ///
    /// Domain deletes + save run inside `ModelContext.transaction` on the
    /// caller's context (avoids scratch-context invalidation of live
    /// relationship registrations, and avoids explicit `rollback()` after
    /// deletes — both fatal in current SwiftData SDKs).
    ///
    /// If save fails: onboarding / notifications / recovery / reminders are
    /// left untouched and success is not posted. The on-disk store remains
    /// unchanged (verified via a fresh context in tests). The caller's
    /// context may retain pending in-memory deletes until the next successful
    /// save or process relaunch — Data Management surfaces that guidance.
    ///
    /// Side effects run only after a successful save and empty-store check.
    func resetAllAppData(
        context: ModelContext,
        defaults: UserDefaults? = nil
    ) throws {
        guard !isResetting else { throw AppDataResetError.alreadyInProgress }
        isResetting = true
        defer { isResetting = false }

        let defaults = defaults ?? OnboardingPreference.store()

        do {
            try context.transaction {
                try Self.deleteAllDomainRecords(in: context)
                try services.saveContext(context)
            }
        } catch {
            throw AppDataResetError.persistenceFailed
        }

        let remainingGoals = (try? context.fetchCount(FetchDescriptor<Goal>())) ?? -1
        let remainingTasks = (try? context.fetchCount(FetchDescriptor<GoalTask>())) ?? -1
        let remainingSessions = (try? context.fetchCount(FetchDescriptor<FocusSession>())) ?? -1
        guard remainingGoals == 0, remainingTasks == 0, remainingSessions == 0 else {
            throw AppDataResetError.persistenceFailed
        }

        services.cancelFocusNotifications()
        services.clearRecovery(defaults)
        services.disableReminders()
        OnboardingPreference.clearCompleted(in: defaults)
        services.postDidReset()
    }

    /// Deletes Goals (cascade → GoalTasks), FocusSessions, and any orphan tasks.
    /// Does not touch UserDefaults or notifications.
    static func deleteAllDomainRecords(in context: ModelContext) throws {
        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        for session in sessions {
            context.delete(session)
        }

        let goals = try context.fetch(FetchDescriptor<Goal>())
        for goal in goals {
            context.delete(goal)
        }

        // Defensive: cascade should have removed tasks; clear any orphans.
        let tasks = try context.fetch(FetchDescriptor<GoalTask>())
        for task in tasks {
            context.delete(task)
        }
    }
}
