//
//  NextTheme.swift
//  Next
//
//  Appearance-aware semantic tokens.
//  Light = warm ivory + muted lavender accents.
//  Dark = twilight charcoal + lavender interactive accents.
//  Plants keep botanical green via botanicalInk.
//

import SwiftUI
import UIKit

enum NextTheme {
    // MARK: - Semantic tokens (adaptive)

    /// Page background. Light ivory / dark warm charcoal.
    static let canvas = Color(uiColor: Palette.canvas)

    /// Slightly elevated surface (sheets, grouped areas).
    static let surface = Color(uiColor: Palette.surface)

    /// Soft lavender selection / chip surface.
    static let accentSurface = Color(uiColor: Palette.accentSurface)

    /// Primary copy.
    static let primaryText = Color(uiColor: Palette.primaryText)

    /// Supporting copy.
    static let secondaryText = Color(uiColor: Palette.secondaryText)

    /// Interactive UI accent (tabs, selection, actions). Lavender — not plant ink.
    static let interactiveAccent = Color(uiColor: Palette.interactiveAccent)

    /// Botanical green for plant illustration only.
    static let botanicalInk = Color(uiColor: Palette.botanicalInk)

    /// Hairlines and separators.
    static let separator = Color(uiColor: Palette.separator)

    /// Disabled / unselected chrome.
    static let disabledText = Color(uiColor: Palette.disabledText)

    /// Destructive actions (delete).
    static let destructive = Color(uiColor: Palette.destructive)

    // MARK: - Compatibility aliases

    static let ink = primaryText
    static let secondary = secondaryText
    /// Legacy name — maps to interactive lavender, not plant green.
    static let botanicalAccent = interactiveAccent
    static let botanical = interactiveAccent
    static let disabled = disabledText
    static let rule = separator

    static let pagePadding: CGFloat = 28

    /// Apply once at launch. Uses dynamic UIColors so chrome tracks appearance.
    static func applyChrome() {
        let selected = Palette.interactiveAccent
        let muted = Palette.disabledText
        let background = Palette.canvas
        let shadow = Palette.separator

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = background
        tab.shadowColor = shadow
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

    // MARK: - Palette

    enum Palette {
        /// Warm ivory — Light (#FAF7F0)
        static let lightCanvas = UIColor(red: 250 / 255, green: 247 / 255, blue: 240 / 255, alpha: 1)
        static let lightSurface = UIColor(red: 250 / 255, green: 247 / 255, blue: 240 / 255, alpha: 1)
        static let lightAccentSurface = UIColor(red: 234 / 255, green: 226 / 255, blue: 240 / 255, alpha: 1) // #EAE2F0
        static let lightPrimary = UIColor(red: 26 / 255, green: 26 / 255, blue: 23 / 255, alpha: 1)
        static let lightSecondary = UIColor(red: 97 / 255, green: 94 / 255, blue: 87 / 255, alpha: 1)
        /// Muted lavender interactive (#79628F)
        static let lightInteractive = UIColor(red: 121 / 255, green: 98 / 255, blue: 143 / 255, alpha: 1)
        /// Botanical green for plants only (#405743)
        static let lightBotanicalInk = UIColor(red: 64 / 255, green: 87 / 255, blue: 67 / 255, alpha: 1)
        static let lightDisabled = UIColor(red: 133 / 255, green: 127 / 255, blue: 117 / 255, alpha: 1)
        static let lightSeparator = UIColor(red: 115 / 255, green: 105 / 255, blue: 90 / 255, alpha: 0.22)
        static let lightDestructive = UIColor(red: 0.55, green: 0.18, blue: 0.16, alpha: 1)

        /// Twilight Quiet — Dark (#171F1B)
        static let darkCanvas = UIColor(red: 23 / 255, green: 31 / 255, blue: 27 / 255, alpha: 1)
        static let darkSurface = UIColor(red: 34 / 255, green: 44 / 255, blue: 37 / 255, alpha: 1)
        static let darkAccentSurface = UIColor(red: 64 / 255, green: 54 / 255, blue: 75 / 255, alpha: 1) // #40364B
        static let darkPrimary = UIColor(red: 242 / 255, green: 240 / 255, blue: 232 / 255, alpha: 1)
        static let darkSecondary = UIColor(red: 179 / 255, green: 190 / 255, blue: 179 / 255, alpha: 1)
        /// Soft lavender interactive (#C8B5DC)
        static let darkInteractive = UIColor(red: 200 / 255, green: 181 / 255, blue: 220 / 255, alpha: 1)
        /// Botanical green plant ink (#8EAD91)
        static let darkBotanicalInk = UIColor(red: 142 / 255, green: 173 / 255, blue: 145 / 255, alpha: 1)
        static let darkDisabled = UIColor(red: 135 / 255, green: 148 / 255, blue: 137 / 255, alpha: 1)
        static let darkSeparator = UIColor(red: 58 / 255, green: 73 / 255, blue: 62 / 255, alpha: 1)
        static let darkDestructive = UIColor(red: 0.90, green: 0.55, blue: 0.50, alpha: 1)

        static let canvas = adaptive(light: lightCanvas, dark: darkCanvas)
        static let surface = adaptive(light: lightSurface, dark: darkSurface)
        static let accentSurface = adaptive(light: lightAccentSurface, dark: darkAccentSurface)
        static let primaryText = adaptive(light: lightPrimary, dark: darkPrimary)
        static let secondaryText = adaptive(light: lightSecondary, dark: darkSecondary)
        static let interactiveAccent = adaptive(light: lightInteractive, dark: darkInteractive)
        static let botanicalInk = adaptive(light: lightBotanicalInk, dark: darkBotanicalInk)
        static let disabledText = adaptive(light: lightDisabled, dark: darkDisabled)
        static let separator = adaptive(light: lightSeparator, dark: darkSeparator)
        static let destructive = adaptive(light: lightDestructive, dark: darkDestructive)

        static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
            UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        }
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
            .fill(NextTheme.separator)
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
                .foregroundStyle(isEnabled ? NextTheme.interactiveAccent : NextTheme.disabledText)
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
