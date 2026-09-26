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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .nextFont(16, weight: isSelected ? .medium : .regular)
                    .foregroundStyle(isSelected ? NextTheme.botanical : NextTheme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Capsule()
                    .fill(isSelected ? NextTheme.botanical : Color.clear)
                    .frame(width: 18, height: 2)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
