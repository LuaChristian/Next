//
//  NextTheme.swift
//  Next
//
//  Lightweight shared tokens for V1 consistency and contrast.
//

import SwiftUI

enum NextTheme {
    /// Ivory canvas. #FAF7F0
    static let canvas = Color(red: 250 / 255, green: 247 / 255, blue: 240 / 255)

    /// Near-black warm ink. #1A1A17
    static let ink = Color(red: 26 / 255, green: 26 / 255, blue: 23 / 255)

    /// Supporting copy. #615E57
    static let secondary = Color(red: 97 / 255, green: 94 / 255, blue: 87 / 255)

    /// Signature accent, aligned to the leaf-arrow icon. #405743
    static let botanical = Color(red: 64 / 255, green: 87 / 255, blue: 67 / 255)

    /// Disabled / unselected chrome. #857F75
    static let disabled = Color(red: 133 / 255, green: 127 / 255, blue: 117 / 255)

    /// Warm hairline that sits on ivory without going cool gray.
    static let rule = Color(red: 115 / 255, green: 105 / 255, blue: 90 / 255).opacity(0.22)

    static let pagePadding: CGFloat = 28

    static func applyChrome() {
        let selected = UIColor(botanical)
        let muted = UIColor(disabled)
        let ivory = UIColor(canvas)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = ivory
        tab.shadowColor = UIColor(rule)
        for layout in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            layout.normal.iconColor = muted
            layout.normal.titleTextAttributes = [.foregroundColor: muted]
            layout.selected.iconColor = selected
            layout.selected.titleTextAttributes = [.foregroundColor: selected]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = selected
        UITabBar.appearance().unselectedItemTintColor = muted

        UINavigationBar.appearance().tintColor = selected
        UITextField.appearance().tintColor = selected
    }
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
