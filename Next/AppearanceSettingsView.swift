//
//  AppearanceSettingsView.swift
//  Next
//
//  Lightweight System / Light / Dark picker. Applies immediately.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Binding var appearanceRaw: String
    @Environment(\.dismiss) private var dismiss

    private var selected: AppearancePreference {
        AppearancePreference.resolve(stored: appearanceRaw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("APPEARANCE")
                .nextFont(13, weight: .medium, relativeTo: .caption)
                .tracking(3.2)
                .foregroundStyle(NextTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)

            Text("Calm Garden by day. Twilight Quiet by night.")
                .nextFont(17)
                .foregroundStyle(NextTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(AppearancePreference.allCases) { option in
                    appearanceRow(option)
                    if option != AppearancePreference.allCases.last {
                        NextHairline()
                    }
                }
            }
            .padding(.top, 36)

            Spacer(minLength: 24)

            NextPrimaryAction(title: "DONE") {
                dismiss()
            }
        }
        .nextCanvas()
    }

    private func appearanceRow(_ option: AppearancePreference) -> some View {
        let isSelected = selected == option
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
            .padding(.vertical, 22)
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
}
