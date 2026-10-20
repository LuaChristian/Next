//
//  PreferencesView.swift
//  Next
//
//  Lightweight Home sheet: Appearance + optional Reminders.
//

import SwiftData
import SwiftUI

struct PreferencesView: View {
    @Binding var appearanceRaw: String
    @Environment(\.dismiss) private var dismiss
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
                Text("PREFERENCES")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                appearanceSection
                    .padding(.top, 28)

                NextHairline()
                    .padding(.vertical, 28)

                remindersSection
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        // Pin DONE above the home indicator so the taller enabled-reminders
        // layout cannot scroll the action into the unsafe bottom edge.
        // Sheets often report a collapsed bottom safe area, so keep explicit
        // padding under the action hairline (not only the system inset).
        .safeAreaInset(edge: .bottom) {
            NextPrimaryAction(title: "DONE") {
                dismiss()
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.bottom, 28)
            .background(NextTheme.canvas)
        }
        .task { await refreshAuthorization() }
        .accessibilityIdentifier("preferencesSheet")
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("APPEARANCE")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondaryText)

            Text("Calm Garden by day. Twilight Quiet by night.")
                .nextFont(17)
                .foregroundStyle(NextTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(AppearancePreference.allCases) { option in
                    appearanceRow(option)
                    if option != AppearancePreference.allCases.last {
                        NextHairline()
                    }
                }
            }
            .padding(.top, 20)
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("REMINDERS")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(1.8)
                .foregroundStyle(NextTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)

            Text("An optional daily invitation to begin a focus session. Soft, never urgent.")
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
            .tint(NextTheme.botanicalAccent)
            .accessibilityIdentifier("dailyReminderToggle")
            .accessibilityHint("When on, Next may send one calm local reminder each day at your chosen time.")

            if reminderEnabled {
                DatePicker(
                    "Reminder time",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .tint(NextTheme.botanicalAccent)
                .accessibilityIdentifier("dailyReminderTime")

                Text(timeSummaryLabel)
                    .nextFont(13, relativeTo: .caption)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityIdentifier("dailyReminderTimeSummary")

                Text("Next schedules a single local reminder for the next open day. If you already focused today, the next invitation waits until tomorrow.")
                    .nextFont(13, relativeTo: .caption)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .foregroundStyle(NextTheme.botanicalAccent)
                    .accessibilityIdentifier("openNotificationSettings")
                }
                .padding(.top, 4)
            }
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
                        .foregroundStyle(isSelected ? NextTheme.botanicalAccent : NextTheme.primaryText)
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
                        .foregroundStyle(NextTheme.botanicalAccent)
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
            // Preference was left enabled while OS revoked access — correct the UI.
            DailyReminderCoordinator.shared.disable()
            reminderEnabled = false
            showDeniedGuidance = authorization == .denied || authorization == .unavailable
        }
    }
}
