//
//  AboutNextView.swift
//  Next
//
//  App name, version/build, and a short product description.
//

import SwiftUI

struct AboutNextView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("ABOUT NEXT")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("Next")
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 36)
                    .fixedSize(horizontal: false, vertical: true)

                Text(AppVersionInfo.versionAndBuildLabel)
                    .nextFont(15)
                    .foregroundStyle(NextTheme.secondaryText)
                    .padding(.top, 10)
                    .accessibilityIdentifier("aboutVersionLabel")
                    .accessibilityLabel(AppVersionInfo.versionAndBuildLabel)

                NextHairline()
                    .padding(.vertical, 28)

                Text("Tell me how much time and energy you have, and I'll tell you what to do next.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your life is a garden. Focused time helps it grow.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.secondaryText)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)
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
        .accessibilityIdentifier("aboutNextScreen")
    }
}

#Preview {
    NavigationStack {
        AboutNextView()
    }
}
