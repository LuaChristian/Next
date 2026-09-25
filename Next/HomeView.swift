//
//  HomeView.swift
//  Next
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import SwiftUI

enum TimeOption: CaseIterable, Identifiable {
    case fifteen
    case thirty
    case sixty
    case ninetyPlus

    var id: Self { self }

    var title: String {
        switch self {
        case .fifteen: "15 min"
        case .thirty: "30 min"
        case .sixty: "60 min"
        case .ninetyPlus: "90+ min"
        }
    }
}

enum EnergyLevel: CaseIterable, Identifiable {
    case low
    case good
    case ready

    var id: Self { self }

    var title: String {
        switch self {
        case .low: "Low"
        case .good: "Good"
        case .ready: "Ready"
        }
    }
}

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTime: TimeOption?
    @State private var selectedEnergy: EnergyLevel?
    @State private var recommendationInput: RecommendationInput?

    private var canProceed: Bool {
        selectedTime != nil && selectedEnergy != nil
    }

    private var canvasColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.11)
            : Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: 48)
            timeSection
            Spacer(minLength: 40)
            energySection
            Spacer(minLength: 48)
            primaryAction
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(canvasColor.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $recommendationInput) { input in
            RecommendationView(availableTime: input.time, energy: input.energy)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("NEXT")
                .font(.system(size: 13, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(.secondary)

            Text("Good afternoon.")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("What do you have time for?")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                ForEach(TimeOption.allCases) { option in
                    SelectionOption(
                        title: option.title,
                        isSelected: selectedTime == option
                    ) {
                        selectedTime = option
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("How are you feeling?")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                ForEach(EnergyLevel.allCases) { option in
                    SelectionOption(
                        title: option.title,
                        isSelected: selectedEnergy == option
                    ) {
                        selectedEnergy = option
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var primaryAction: some View {
        VStack(spacing: 18) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            Button("WHAT'S NEXT?") {
                guard let time = selectedTime, let energy = selectedEnergy else { return }
                recommendationInput = RecommendationInput(time: time, energy: energy)
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(canProceed ? Color.accentColor : Color.secondary.opacity(0.45))
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(!canProceed)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

private struct SelectionOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 18, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct RecommendationInput: Hashable, Identifiable {
    let id = UUID()
    let time: TimeOption
    let energy: EnergyLevel
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
