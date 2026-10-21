//
//  AppearanceSettingsView.swift
//  Next
//
//  Dedicated Appearance settings page. Persistence via AppearancePreference.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage(AppearancePreference.key) private var appearanceRaw = AppearancePreference.system.rawValue

    private var selectedAppearance: AppearancePreference {
        AppearancePreference.resolve(stored: appearanceRaw)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("APPEARANCE")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("Choose how Next looks on this device.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 28)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(AppearancePreference.allCases) { option in
                        appearanceRow(option)
                        if option != AppearancePreference.allCases.last {
                            NextHairline()
                        }
                    }
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .accessibilityIdentifier("settingsAppearanceScreen")
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
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
