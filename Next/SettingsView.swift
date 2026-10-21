//
//  SettingsView.swift
//  Next
//
//  Main Settings tab: Appearance, Reminders, History destination.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppearancePreference.key) private var appearanceRaw = AppearancePreference.system.rawValue
    @Environment(\.modelContext) private var modelContext

    @State private var reminderEnabled = ReminderPreference.isEnabled()
    @State private var reminderTime = ReminderPreference.timeDate()
    @State private var authorization = DailyReminderAuthorization.notDetermined
    @State private var showDeniedGuidance = false

    private var selectedAppearance: AppearancePreference {
        AppearancePreference.resolve(stored: appearanceRaw)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SETTINGS")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                appearanceSection
                    .padding(.top, 28)

                NextHairline()
                    .padding(.vertical, 28)

                remindersSection

                NextHairline()
                    .padding(.vertical, 28)

                historySection
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await refreshAuthorization() }
        .accessibilityIdentifier("settingsScreen")
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("APPEARANCE")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(AppearancePreference.allCases) { option in
                    appearanceRow(option)
                    if option != AppearancePreference.allCases.last {
                        NextHairline()
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("REMINDERS")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)

            Text("An optional daily reminder to begin a focus session.")
                .nextFont(17)
                .foregroundStyle(NextTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: reminderToggleBinding) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily reminder")
                        .nextFont(20, relativeTo: .title3)
                        .foregroundStyle(NextTheme.primaryText)
                    Text(reminderEnabled ? "On" : "Off — default")
                        .nextFont(13, relativeTo: .caption)
                        .foregroundStyle(NextTheme.secondaryText)
                }
            }
            .tint(NextTheme.interactiveAccent)
            .accessibilityIdentifier("dailyReminderToggle")
            .accessibilityHint("When on, Next may send one calm local reminder each day at your chosen time.")

            if reminderEnabled {
                DatePicker(
                    "Reminder time",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .tint(NextTheme.interactiveAccent)
                .accessibilityIdentifier("dailyReminderTime")

                Text(timeSummaryLabel)
                    .nextFont(13, relativeTo: .caption)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityIdentifier("dailyReminderTimeSummary")
            }

            if showDeniedGuidance {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications are turned off for Next in iOS Settings. Reminders cannot be delivered until you allow them.")
                        .nextFont(15)
                        .foregroundStyle(NextTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Open iOS Settings") {
                        DailyReminderSettingsLink.openSystemNotificationSettings()
                    }
                    .nextFont(13, weight: .semibold)
                    .tracking(1.4)
                    .foregroundStyle(NextTheme.interactiveAccent)
                    .accessibilityIdentifier("openNotificationSettings")
                }
                .padding(.top, 4)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HISTORY")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)

            NavigationLink {
                HistoryView()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("View Focus History")
                        .nextFont(20, relativeTo: .title3)
                        .foregroundStyle(NextTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(">")
                        .nextFont(20, relativeTo: .title3)
                        .foregroundStyle(NextTheme.interactiveAccent)
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settingsHistoryLink")
            .accessibilityLabel("View Focus History")
            .accessibilityHint("Opens your focus session history")
        }
    }

    private var timeSummaryLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "Around \(formatter.string(from: reminderTime))"
    }

    private var reminderToggleBinding: Binding<Bool> {
        Binding(
            get: { reminderEnabled },
            set: { newValue in
                Task { await setReminderEnabled(newValue) }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { reminderTime },
            set: { newValue in
                reminderTime = newValue
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                Task {
                    await DailyReminderCoordinator.shared.updateTime(
                        hour: parts.hour ?? ReminderPreference.defaultHour,
                        minute: parts.minute ?? ReminderPreference.defaultMinute,
                        hasFocusedToday: DailyReminderCoordinator.hasFocusedToday(context: modelContext)
                    )
                }
            }
        )
    }

    private func appearanceRow(_ option: AppearancePreference) -> some View {
        let isSelected = selectedAppearance == option
        return Button {
            appearanceRaw = option.rawValue
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .nextFont(22, relativeTo: .title3)
                        .foregroundStyle(isSelected ? NextTheme.interactiveAccent : NextTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(option.accessibilityHint)
                        .nextFont(13, relativeTo: .caption)
                        .foregroundStyle(NextTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Text("SELECTED")
                        .nextFont(11, weight: .semibold, relativeTo: .caption2)
                        .tracking(1.4)
                        .foregroundStyle(NextTheme.interactiveAccent)
                }
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel(option.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(option.accessibilityHint)
        .accessibilityIdentifier("appearance-\(option.rawValue)")
    }

    private func setReminderEnabled(_ enabled: Bool) async {
        showDeniedGuidance = false
        if enabled {
            let auth = await DailyReminderCoordinator.shared.enable(
                hasFocusedToday: DailyReminderCoordinator.hasFocusedToday(context: modelContext)
            )
            authorization = auth
            reminderEnabled = ReminderPreference.isEnabled()
            showDeniedGuidance = !auth.canDeliver
        } else {
            DailyReminderCoordinator.shared.disable()
            reminderEnabled = false
            authorization = await DailyReminderCoordinator.shared.authorization()
        }
    }

    private func refreshAuthorization() async {
        authorization = await DailyReminderCoordinator.shared.authorization()
        reminderEnabled = ReminderPreference.isEnabled()
        reminderTime = ReminderPreference.timeDate()
        if reminderEnabled, !authorization.canDeliver {
            DailyReminderCoordinator.shared.disable()
            reminderEnabled = false
            showDeniedGuidance = authorization == .denied || authorization == .unavailable
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
