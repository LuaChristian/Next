//
//  SelectionOption.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

struct SelectionOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .nextFont(16, weight: isSelected ? .medium : .regular)
                    .foregroundStyle(isSelected ? NextTheme.interactiveAccent : NextTheme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.75 : 0.8)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                    .fixedSize(horizontal: false, vertical: true)

                Capsule()
                    .fill(isSelected ? NextTheme.interactiveAccent : Color.clear)
                    .frame(width: 18, height: 2)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
