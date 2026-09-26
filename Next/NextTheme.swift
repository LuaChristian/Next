//
//  NextTheme.swift
//  Next
//
//  Lightweight shared tokens for V1 consistency and contrast.
//

import SwiftUI

enum NextTheme {
    /// Warm ivory canvas used across V1.
    static let canvas = Color(red: 0.98, green: 0.97, blue: 0.94)

    /// Near-black primary ink.
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.09)

    /// Secondary metadata. Darkened from system gray to meet ~4.5:1 on canvas.
    static let secondary = Color(red: 0.38, green: 0.37, blue: 0.34)

    /// Botanical green (matches AccentColor light appearance).
    static let botanical = Color(red: 0.239, green: 0.353, blue: 0.270)

    /// Disabled actions. Muted but still readable; disabled is also semantic.
    static let disabled = Color(red: 0.52, green: 0.50, blue: 0.46)

    /// Thin editorial rules.
    static let rule = ink.opacity(0.16)

    static let pagePadding: CGFloat = 28
}

enum NextInput {
    static func trimmedTitle(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct NextHairline: View {
    var body: some View {
        Rectangle()
            .fill(NextTheme.rule)
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

struct NextPrimaryAction: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            NextHairline()

            Button(title, action: action)
                .nextFont(13, weight: .semibold)
                .tracking(2.2)
                .foregroundStyle(isEnabled ? NextTheme.botanical : NextTheme.disabled)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(!isEnabled)

            NextHairline()
        }
    }
}

extension View {
    func nextFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo style: Font.TextStyle = .body
    ) -> some View {
        modifier(NextFontModifier(size: size, weight: weight, design: design, style: style))
    }

    func nextCanvas(top: CGFloat = 12, bottom: CGFloat = 28) -> some View {
        self
            .padding(.horizontal, NextTheme.pagePadding)
            .padding(.top, top)
            .padding(.bottom, bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(NextTheme.canvas.ignoresSafeArea())
    }

    func nextScrollableCanvas(top: CGFloat = 12, bottom: CGFloat = 28) -> some View {
        GeometryReader { geo in
            ScrollView {
                self
                    .padding(.horizontal, NextTheme.pagePadding)
                    .padding(.top, top)
                    .padding(.bottom, bottom)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(NextTheme.canvas.ignoresSafeArea())
    }

    func nextKeyboardDone(_ focus: FocusState<Bool>.Binding) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus.wrappedValue = false }
            }
        }
    }
}

private struct NextFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let style: Font.TextStyle

    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }

    private var scaledSize: CGFloat {
        UIFontMetrics(forTextStyle: style.uiTextStyle).scaledValue(
            for: size,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: sizeCategory.uiContentSizeCategory)
        )
    }
}

private extension ContentSizeCategory {
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .extraSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .extraLarge: .extraLarge
        case .extraExtraLarge: .extraExtraLarge
        case .extraExtraExtraLarge: .extraExtraExtraLarge
        case .accessibilityMedium: .accessibilityMedium
        case .accessibilityLarge: .accessibilityLarge
        case .accessibilityExtraLarge: .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}
