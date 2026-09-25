//
//  NextUITests.swift
//  NextUITests
//
//  Created by Christian Lua-Lua on 9/25/26.
//

import XCTest

final class NextUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRecommendationFlow() throws {
        let app = launchSeededApp()

        let whatsNext = app.buttons["WHAT'S NEXT?"]
        XCTAssertFalse(whatsNext.isEnabled)

        app.buttons["30 min"].tap()
        XCTAssertFalse(whatsNext.isEnabled)

        app.buttons["Good"].tap()
        XCTAssertTrue(whatsNext.isEnabled)

        whatsNext.tap()

        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        XCTAssertTrue(app.staticTexts["25 MINUTES"].exists)
        XCTAssertTrue(app.staticTexts["EDUCATION"].exists)
        XCTAssertTrue(app.staticTexts["Study for MCAT"].exists)
        XCTAssertTrue(app.staticTexts["Fits the time you have."].exists)
        XCTAssertTrue(app.staticTexts["Matches your energy."].exists)
        XCTAssertTrue(app.buttons["START SESSION →"].exists)

        let notThisOne = app.buttons["Not this one"]
        XCTAssertTrue(notThisOne.isEnabled)

        notThisOne.tap()
        XCTAssertTrue(app.staticTexts["Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Review amino acids"].exists)

        notThisOne.tap()
        XCTAssertTrue(app.staticTexts["Clean your space"].waitForExistence(timeout: 2))
        XCTAssertFalse(notThisOne.isEnabled)

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["30 min"].isSelected)
        XCTAssertTrue(app.buttons["Good"].isSelected)
        XCTAssertTrue(whatsNext.isEnabled)
    }

    @MainActor
    func testFocusSessionFromCurrentRecommendation() throws {
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)

        app.buttons["START SESSION →"].tap()

        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["STUDY FOR MCAT"].exists)
        XCTAssertTrue(timerIsNear(minutes: 25, in: app))
        XCTAssertTrue(app.buttons["PAUSE"].exists)

        app.buttons["PAUSE"].tap()
        XCTAssertTrue(app.buttons["RESUME"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Finish early"].exists)

        app.buttons["RESUME"].tap()
        XCTAssertTrue(app.buttons["PAUSE"].waitForExistence(timeout: 2))

        app.buttons["Finish early"].tap()
        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        XCTAssertTrue(app.staticTexts["STUDY FOR MCAT"].exists)
        XCTAssertTrue(app.staticTexts["Did you finish it?"].exists)
        XCTAssertTrue(app.buttons["YES"].exists)
        XCTAssertTrue(app.buttons["NOT YET"].exists)
        XCTAssertFalse(app.buttons["YES"].isSelected)
        XCTAssertFalse(app.buttons["NOT YET"].isSelected)
        XCTAssertFalse(app.buttons["WHAT'S NEXT? →"].isEnabled)
        XCTAssertFalse(app.buttons["I'M DONE"].isEnabled)
        XCTAssertFalse(app.buttons["PAUSE"].exists)
        XCTAssertFalse(app.buttons["Finish early"].exists)

        app.buttons["YES"].tap()
        XCTAssertTrue(app.buttons["WHAT'S NEXT? →"].isEnabled)
        app.buttons["WHAT'S NEXT? →"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["30 min"].isSelected)
        XCTAssertTrue(app.buttons["Good"].isSelected)
    }

    @MainActor
    func testCompletionNotYetReturnsHome() throws {
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)

        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        app.buttons["Finish early"].tap()

        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["I'M DONE"].isEnabled)

        app.buttons["NOT YET"].tap()
        XCTAssertTrue(app.buttons["I'M DONE"].isEnabled)
        app.buttons["I'M DONE"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["30 min"].isSelected)
        XCTAssertTrue(app.buttons["Good"].isSelected)
    }

    @MainActor
    func testFocusUsesAcceptedRecommendationDuration() throws {
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)

        app.buttons["Not this one"].tap()
        XCTAssertTrue(app.staticTexts["Review flashcards"].waitForExistence(timeout: 2))

        app.buttons["START SESSION →"].tap()

        XCTAssertTrue(app.staticTexts["Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["STUDY FOR MCAT"].exists)
        XCTAssertTrue(timerIsNear(minutes: 15, in: app))
        XCTAssertFalse(app.staticTexts["Review amino acids"].exists)
    }

    @MainActor
    func testUserCreatedGoalAndTaskFeedRecommendation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_IN_MEMORY", "UITEST_ONBOARDING_COMPLETED"]
        app.launch()

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Nothing planted yet."].waitForExistence(timeout: 2))

        app.buttons["+ PLANT A GOAL"].tap()
        let goalField = app.textFields["Goal title"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 2))
        goalField.tap()
        goalField.typeText("Study for MCAT")
        app.buttons["Education"].tap()
        app.buttons["High"].tap()
        app.buttons["PLANT GOAL →"].tap()

        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()

        app.buttons["+ ADD TASK"].tap()
        let taskField = app.textFields["Task title"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText("Review amino acids")
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["ADD TASK →"].tap()

        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Home"].tap()
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()

        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        XCTAssertTrue(app.staticTexts["30 MINUTES"].exists)
        XCTAssertTrue(app.staticTexts["EDUCATION"].exists)
        XCTAssertTrue(app.staticTexts["Study for MCAT"].exists)

        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        app.buttons["Finish early"].tap()

        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        app.buttons["NOT YET"].tap()
        app.buttons["I'M DONE"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testGardenPersistsAcrossProcessTermination() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-ui-\(UUID().uuidString).store")
        let storeArguments = [
            "UITEST_STORE_URL", storeURL.path,
            "UITEST_ONBOARDING_COMPLETED"
        ]

        let app = XCUIApplication()
        app.launchArguments = storeArguments
        app.launch()

        plantMCATGoalAndAminoTask(in: app)

        app.terminate()
        app.launchArguments = storeArguments
        app.launch()

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Home"].tap()
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()

        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        XCTAssertTrue(app.staticTexts["EDUCATION"].exists)
        XCTAssertTrue(app.staticTexts["Study for MCAT"].exists)
    }

    private func plantMCATGoalAndAminoTask(in app: XCUIApplication) {
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Nothing planted yet."].waitForExistence(timeout: 2))

        app.buttons["+ PLANT A GOAL"].tap()
        let goalField = app.textFields["Goal title"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 2))
        goalField.tap()
        goalField.typeText("Study for MCAT")
        app.buttons["Education"].tap()
        app.buttons["High"].tap()
        app.buttons["PLANT GOAL →"].tap()

        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()

        app.buttons["+ ADD TASK"].tap()
        let taskField = app.textFields["Task title"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText("Review amino acids")
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["ADD TASK →"].tap()

        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFreshOnboardingCreatesGardenGoal() throws {
        let app = launchFreshOnboarding()

        XCTAssertTrue(app.staticTexts["Make your free time count."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.tabBars.buttons["Home"].exists)

        app.buttons["GET STARTED →"].tap()
        XCTAssertTrue(app.staticTexts["WHAT MATTERS TO YOU?"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["NEXT →"].isEnabled)

        app.buttons["Education"].tap()
        XCTAssertTrue(app.buttons["NEXT →"].isEnabled)
        app.buttons["NEXT →"].tap()

        XCTAssertTrue(app.staticTexts["WHAT ARE YOU\nWORKING TOWARD?"].waitForExistence(timeout: 2)
                      || app.staticTexts["WORKING TOWARD?"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["CONTINUE →"].isEnabled)

        app.buttons["Study for an exam"].tap()
        XCTAssertTrue(app.buttons["CONTINUE →"].isEnabled)
        app.buttons["CONTINUE →"].tap()

        XCTAssertTrue(app.staticTexts["YOU'RE READY."].waitForExistence(timeout: 2))
        app.buttons["START USING NEXT →"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for an exam"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testOnboardingSuggestedAndCustomGoalsAppearInGarden() throws {
        let app = launchFreshOnboarding()

        XCTAssertTrue(app.buttons["GET STARTED →"].waitForExistence(timeout: 2))
        app.buttons["GET STARTED →"].tap()
        XCTAssertTrue(app.buttons["Education"].waitForExistence(timeout: 2))
        app.buttons["Education"].tap()
        app.buttons["Creative"].tap()
        app.buttons["NEXT →"].tap()

        XCTAssertTrue(app.buttons["Study for an exam"].waitForExistence(timeout: 2))
        app.buttons["Study for an exam"].tap()
        app.buttons["+ ADD MY OWN GOAL"].tap()

        let field = app.textFields["Goal title"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.typeText("Build Next")
        app.buttons["Creative"].tap()
        app.buttons["ADD GOAL →"].tap()

        XCTAssertTrue(app.buttons["CONTINUE →"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["CONTINUE →"].isEnabled)
        app.buttons["CONTINUE →"].tap()
        app.buttons["START USING NEXT →"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for an exam"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Build Next"].exists)
    }

    @MainActor
    func testSkipOnboardingLeavesGardenEmpty() throws {
        let app = launchFreshOnboarding()

        XCTAssertTrue(app.buttons["Skip for now"].waitForExistence(timeout: 2))
        app.buttons["Skip for now"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Nothing planted yet."].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCompletedOnboardingSurvivesProcessTermination() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-onboarding-\(UUID().uuidString).store")
        let suite = "next.uitest.onboarding.\(UUID().uuidString)"
        let storeArguments = [
            "UITEST_STORE_URL", storeURL.path,
            "UITEST_DEFAULTS_SUITE", suite
        ]

        let app = XCUIApplication()
        app.launchArguments = storeArguments + ["UITEST_FRESH_ONBOARDING"]
        app.launch()

        completeEducationExamOnboarding(in: app)

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for an exam"].waitForExistence(timeout: 2))

        app.terminate()
        app.launchArguments = storeArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Make your free time count."].exists)
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for an exam"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSkipSurvivesProcessTermination() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-onboarding-skip-\(UUID().uuidString).store")
        let suite = "next.uitest.onboarding.skip.\(UUID().uuidString)"
        let storeArguments = [
            "UITEST_STORE_URL", storeURL.path,
            "UITEST_DEFAULTS_SUITE", suite
        ]

        let app = XCUIApplication()
        app.launchArguments = storeArguments + ["UITEST_FRESH_ONBOARDING"]
        app.launch()

        XCTAssertTrue(app.buttons["Skip for now"].waitForExistence(timeout: 2))
        app.buttons["Skip for now"].tap()
        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))

        app.terminate()
        app.launchArguments = storeArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Make your free time count."].exists)
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Nothing planted yet."].waitForExistence(timeout: 2))
    }

    private func launchFreshOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_IN_MEMORY",
            "UITEST_FRESH_ONBOARDING",
            "UITEST_DEFAULTS_SUITE",
            "next.uitest.onboarding.\(UUID().uuidString)"
        ]
        app.launch()
        return app
    }

    private func completeEducationExamOnboarding(in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["GET STARTED →"].waitForExistence(timeout: 2))
        app.buttons["GET STARTED →"].tap()
        XCTAssertTrue(app.buttons["Education"].waitForExistence(timeout: 2))
        app.buttons["Education"].tap()
        app.buttons["NEXT →"].tap()
        XCTAssertTrue(app.buttons["Study for an exam"].waitForExistence(timeout: 2))
        app.buttons["Study for an exam"].tap()
        app.buttons["CONTINUE →"].tap()
        XCTAssertTrue(app.buttons["START USING NEXT →"].waitForExistence(timeout: 2))
        app.buttons["START USING NEXT →"].tap()
        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
    }

    private func launchSeededApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_GARDEN"]
        app.launch()
        return app
    }

    @MainActor
    private func navigateToFirstRecommendation(in app: XCUIApplication) {
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
    }

    private func timerIsNear(minutes: Int, in app: XCUIApplication) -> Bool {
        let timer = app.staticTexts["focusTimer"]
        guard timer.waitForExistence(timeout: 2) else { return false }
        let value = timer.value as? String ?? ""
        return value.hasPrefix("\(minutes) minutes") || value.hasPrefix("\(minutes - 1) minutes")
    }
}
