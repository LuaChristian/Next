//
//  SettingsRow.swift
//  Next
//
//  Editorial navigation row for the Settings hub.
//

import SwiftUI

struct SettingsRow: View {
    let destination: SettingsDestination

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: destination.systemImage)
                .font(.body.weight(.regular))
                .foregroundStyle(NextTheme.secondaryText)
                .frame(width: 22, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(destination.title)
                    .nextFont(20, relativeTo: .title3)
                    .foregroundStyle(NextTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(destination.subtitle)
                    .nextFont(15)
                    .foregroundStyle(NextTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(NextTheme.interactiveAccent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(destination.title)
        .accessibilityHint(destination.accessibilityHint)
        .accessibilityIdentifier(destination.accessibilityIdentifier)
    }
}
