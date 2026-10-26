//
//  DataManagementView.swift
//  Next
//
//  Destructive fresh-start controls. Confirmation required before any erase.
//

import SwiftData
import SwiftUI

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showConfirmErase = false
    @State private var isResetting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("DATA MANAGEMENT")
                    .nextFont(13, weight: .medium, relativeTo: .caption)
                    .tracking(3.2)
                    .foregroundStyle(NextTheme.secondaryText)
                    .accessibilityAddTraits(.isHeader)

                Text("A fresh start.")
                    .nextFont(28, relativeTo: .title)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 36)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text("Erase everything stored in Next on this device and return to the beginning. This cannot be undone.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.primaryText)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your appearance preference stays as you set it. System notification permission is managed by iOS and is not changed.")
                    .nextFont(17)
                    .foregroundStyle(NextTheme.secondaryText)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                NextHairline()
                    .padding(.vertical, 28)

                Button {
                    showConfirmErase = true
                } label: {
                    Text("Erase All App Data")
                        .nextFont(17, weight: .medium, relativeTo: .body)
                        .foregroundStyle(NextTheme.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isResetting)
                .accessibilityIdentifier("eraseAllAppDataButton")
                .accessibilityHint("Presents a confirmation before permanently erasing your data")
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
        .accessibilityIdentifier("dataManagementScreen")
        .confirmationDialog(
            "Erase all app data?",
            isPresented: $showConfirmErase,
            titleVisibility: .visible
        ) {
            Button("Erase All App Data", role: .destructive) {
                performReset()
            }
            .accessibilityIdentifier("confirmEraseAllAppData")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("cancelEraseAllAppData")
        } message: {
            Text("""
            The following will be permanently erased:
            • Goals
            • Tasks
            • Focus history
            • Garden progress
            • Active focus recovery
            • Onboarding completion state

            Reminders will be disabled and pending Next notifications canceled.

            Appearance preferences will remain unchanged.
            """)
        }
        .alert(
            "Couldn't erase data",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func performReset() {
        guard !isResetting else { return }
        isResetting = true
        do {
            try AppDataResetCoordinator.shared.resetAllAppData(context: modelContext)
            // Successful reset posts `.nextAppDataDidReset`; NextApp swaps to onboarding.
        } catch AppDataResetError.alreadyInProgress {
            errorMessage = "A reset is already in progress."
            isResetting = false
        } catch {
            errorMessage = "Something went wrong while erasing your data. Nothing was permanently erased and onboarding was not changed. Please try again. If the app looks empty, relaunch Next."
            isResetting = false
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
    }
    .modelContainer(for: [Goal.self, GoalTask.self, FocusSession.self], inMemory: true)
}
