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

        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
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

        XCTAssertTrue(app.buttons["+ ADD TASK"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["Review amino acids"].exists
                || app.descendants(matching: .any)["goalTask-Review amino acids"].exists
        )

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

        XCTAssertTrue(app.buttons["+ ADD TASK"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["Review amino acids"].exists
                || app.descendants(matching: .any)["goalTask-Review amino acids"].exists
        )
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

    @MainActor
    func testFinishEarlySessionAppearsInGarden() throws {
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)

        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        app.buttons["Finish early"].tap()

        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        app.buttons["NOT YET"].tap()
        app.buttons["I'M DONE"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()

        let row = app.descendants(matching: .any)["gardenGoal-Study for MCAT"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        XCTAssertTrue(row.label.contains("1 session"))
        XCTAssertTrue(row.label.contains("focused"))
        XCTAssertFalse(row.label.contains("0 minutes focused"))
    }

    @MainActor
    func testSeededGrowthStagesRender() throws {
        let app = launchGrowthShowcase()

        XCTAssertEqual(gardenRow("Beginning study", in: app).value as? String, "stage 0")
        XCTAssertTrue(gardenRow("Beginning study", in: app).label.contains("0 sessions"))
        XCTAssertEqual(gardenRow("First growth", in: app).value as? String, "stage 1")
        XCTAssertTrue(gardenRow("First growth", in: app).label.contains("30 minutes focused"))
        XCTAssertEqual(gardenRow("Young plant", in: app).value as? String, "stage 2")
        XCTAssertTrue(gardenRow("Young plant", in: app).label.contains("2 hours focused"))
        XCTAssertEqual(gardenRow("Growing plant", in: app).value as? String, "stage 3")
        XCTAssertTrue(gardenRow("Growing plant", in: app).label.contains("5 hours focused"))
        XCTAssertEqual(gardenRow("Mature plant", in: app).value as? String, "stage 4")
        XCTAssertTrue(gardenRow("Mature plant", in: app).label.contains("10 hours focused"))
    }

    @MainActor
    func testShowcaseFullPlantGrowth() throws {
        let app = launchGrowthShowcase()
        attachScreenshot(of: app, named: "01 Garden — all five stages")

        let stages: [(title: String, stage: String, spoken: String, detailMetric: String)] = [
            ("Beginning study", "stage 0", "0 minutes focused", "0 MIN FOCUSED"),
            ("First growth", "stage 1", "30 minutes focused", "30 MIN FOCUSED"),
            ("Young plant", "stage 2", "2 hours focused", "2H FOCUSED"),
            ("Growing plant", "stage 3", "5 hours focused", "5H FOCUSED"),
            ("Mature plant", "stage 4", "10 hours focused", "10H FOCUSED")
        ]

        for (index, stage) in stages.enumerated() {
            let row = gardenRow(stage.title, in: app)
            reveal(row, in: app)
            XCTAssertTrue(row.waitForExistence(timeout: 2), "Missing Garden row for \(stage.title)")
            XCTAssertEqual(row.value as? String, stage.stage)
            XCTAssertTrue(row.label.contains(stage.spoken), row.label)

            row.tap()
            XCTAssertTrue(app.staticTexts[stage.title].waitForExistence(timeout: 2))
            XCTAssertTrue(
                app.staticTexts[stage.detailMetric].waitForExistence(timeout: 2)
                    || app.descendants(matching: .any).containing(
                        NSPredicate(format: "label CONTAINS %@", stage.spoken)
                    ).firstMatch.exists
            )
            attachScreenshot(of: app, named: String(format: "%02d Goal Detail — %@", index + 2, stage.title))
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        }
    }

    @MainActor
    func testHistoryShowsCompletedSession() throws {
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)

        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        app.buttons["Finish early"].tap()
        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        app.buttons["YES"].tap()
        app.buttons["I'M DONE"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["History"].tap()

        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["THIS WEEK"].exists)
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["STUDY FOR MCAT"].exists)
        XCTAssertTrue(app.staticTexts["TODAY"].exists)
        XCTAssertEqual(app.staticTexts["1"].firstMatch.exists, true)
        XCTAssertTrue(app.staticTexts["SESSION"].exists)
        XCTAssertTrue(app.staticTexts["TASK FINISHED"].exists)
        XCTAssertFalse(app.staticTexts["NO FOCUS SESSIONS YET."].exists)
    }

    @MainActor
    func testSeededHistoryGroupsRecentWork() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_HISTORY"]
        app.launch()
        app.tabBars.buttons["History"].tap()

        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["THIS WEEK"].exists)
        XCTAssertTrue(app.staticTexts["TODAY"].exists)
        XCTAssertTrue(app.staticTexts["YESTERDAY"].exists)
        XCTAssertTrue(app.staticTexts["RECENT"].exists)
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        XCTAssertTrue(app.staticTexts["STUDY FOR MCAT"].exists)
        XCTAssertTrue(app.staticTexts["Build Next"].exists)
        XCTAssertTrue(app.staticTexts["Practice arrays"].exists)
        XCTAssertTrue(app.staticTexts["INTERVIEW PREPARATION"].exists)
        XCTAssertTrue(app.staticTexts["Read chapter"].exists)
        XCTAssertTrue(app.staticTexts["FOCUSED"].exists)
        XCTAssertFalse(app.staticTexts["NO FOCUS SESSIONS YET."].exists)
        attachScreenshot(of: app, named: "Seeded History")
    }

    @MainActor
    func testHistorySurvivesProcessTermination() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-history-\(UUID().uuidString).store")
        let suite = "next.uitest.history.\(UUID().uuidString)"
        let storeArguments = [
            "UITEST_STORE_URL", storeURL.path,
            "UITEST_DEFAULTS_SUITE", suite,
            "UITEST_ONBOARDING_COMPLETED"
        ]

        let app = XCUIApplication()
        app.launchArguments = storeArguments + ["UITEST_SEED_HISTORY"]
        app.launch()
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))

        app.terminate()
        app.launchArguments = storeArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["STUDY FOR MCAT"].exists)
        XCTAssertFalse(app.staticTexts["Make your free time count."].exists)
    }

    @MainActor
    func testWhitespaceGoalTitleCannotBePlanted() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_IN_MEMORY", "UITEST_ONBOARDING_COMPLETED"]
        app.launch()

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.buttons["+ PLANT A GOAL"].waitForExistence(timeout: 2))
        app.buttons["+ PLANT A GOAL"].tap()

        let goalField = app.textFields["Goal title"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 2))
        goalField.tap()
        goalField.typeText("     ")
        app.buttons["Education"].tap()
        XCTAssertFalse(app.buttons["PLANT GOAL →"].isEnabled)
    }

    @MainActor
    func testLargeDynamicTypeHistoryRemainsReadable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_SEED_HISTORY",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        app.launch()
        app.tabBars.buttons["History"].tap()

        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["THIS WEEK"].exists)
        XCTAssertTrue(app.staticTexts["FOCUSED"].exists)
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        attachScreenshot(of: app, named: "Large Dynamic Type — History")
    }

    @MainActor
    func testCompleteV1Walkthrough() throws {
        let review = WalkthroughCapture(self)

        let app = launchFreshOnboarding()
        XCTAssertTrue(app.staticTexts["Make your free time count."].waitForExistence(timeout: 3))
        review.capture(app, "01 Welcome")

        app.buttons["GET STARTED →"].tap()
        XCTAssertTrue(app.staticTexts["WHAT MATTERS TO YOU?"].waitForExistence(timeout: 2))
        review.capture(app, "02 Areas")

        app.buttons["Education"].tap()
        app.buttons["Creative"].tap()
        review.capture(app, "03 Areas selected")
        app.buttons["NEXT →"].tap()

        XCTAssertTrue(app.buttons["Study for an exam"].waitForExistence(timeout: 2))
        review.capture(app, "04 Goals")

        app.buttons["Study for an exam"].tap()
        if !app.buttons["Build a project"].exists {
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["Build a project"].waitForExistence(timeout: 2))
        app.buttons["Build a project"].tap()
        review.capture(app, "05 Goals selected")
        app.buttons["CONTINUE →"].tap()

        XCTAssertTrue(app.staticTexts["YOU'RE READY."].waitForExistence(timeout: 2))
        review.capture(app, "06 Ready")
        app.buttons["START USING NEXT →"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        review.capture(app, "07 Home")

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for an exam"].waitForExistence(timeout: 2))
        review.capture(app, "08 Garden after onboarding")
        app.staticTexts["Study for an exam"].tap()
        XCTAssertTrue(app.buttons["+ ADD TASK"].waitForExistence(timeout: 2))
        review.capture(app, "09 Goal Detail no tasks")

        app.buttons["+ ADD TASK"].tap()
        let taskField = app.textFields["Task title"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText("Review amino acids")
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        review.capture(app, "10 Add Task")
        app.buttons["ADD TASK →"].tap()
        XCTAssertTrue(app.buttons["+ ADD TASK"].waitForExistence(timeout: 3))
        review.capture(app, "11 Goal Detail with task")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        review.capture(app, "12 Home ready for What's Next")
        app.buttons["WHAT'S NEXT?"].tap()

        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        review.capture(app, "13 Recommendation")
        app.buttons["START SESSION →"].tap()

        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        review.capture(app, "14 Focus")
        app.buttons["Finish early"].tap()

        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        review.capture(app, "15 Completion")
        app.buttons["YES"].tap()
        review.capture(app, "16 Completion answered")
        app.buttons["I'M DONE"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for an exam"].waitForExistence(timeout: 2))
        review.capture(app, "17 Garden after first session")
        app.staticTexts["Study for an exam"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2)
                      || app.descendants(matching: .any)["goalTask-Review amino acids"].waitForExistence(timeout: 2))
        review.capture(app, "18 Goal Detail after first session")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        review.capture(app, "19 History after first session")
        app.terminate()

        let growth = launchGrowthShowcase()
        review.capture(growth, "20 Garden five stages")
        for title in ["Beginning study", "First growth", "Young plant", "Growing plant", "Mature plant"] {
            let row = gardenRow(title, in: growth)
            reveal(row, in: growth)
            XCTAssertTrue(row.waitForExistence(timeout: 2))
            row.tap()
            XCTAssertTrue(growth.staticTexts[title].waitForExistence(timeout: 2))
            review.capture(growth, "21 Goal Detail — \(title)")
            growth.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(growth.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        }
        growth.terminate()

        let history = XCUIApplication()
        history.launchArguments = ["UITEST_SEED_HISTORY"]
        history.launch()
        history.tabBars.buttons["History"].tap()
        XCTAssertTrue(history.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        review.capture(history, "22 History populated")
        history.swipeUp()
        review.capture(history, "23 History scrolled")
        history.terminate()

        let empty = XCUIApplication()
        empty.launchArguments = ["UITEST_IN_MEMORY", "UITEST_ONBOARDING_COMPLETED"]
        empty.launch()
        empty.tabBars.buttons["History"].tap()
        XCTAssertTrue(empty.staticTexts["NO FOCUS SESSIONS YET."].waitForExistence(timeout: 2))
        review.capture(empty, "24 Empty History")
        empty.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(empty.staticTexts["Nothing planted yet."].waitForExistence(timeout: 2))
        review.capture(empty, "25 Empty Garden")
        empty.terminate()

        let largeType = XCUIApplication()
        largeType.launchArguments = [
            "UITEST_SEED_HISTORY",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        largeType.launch()
        largeType.tabBars.buttons["History"].tap()
        XCTAssertTrue(largeType.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        review.capture(largeType, "26 Large Dynamic Type History")
        largeType.tabBars.buttons["Home"].tap()
        XCTAssertTrue(largeType.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        review.capture(largeType, "27 Large Dynamic Type Home")
        largeType.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(largeType.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(largeType, "28 Large Dynamic Type Garden")
    }

    @MainActor
    func testEmptyHistoryIsNeutral() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_IN_MEMORY", "UITEST_ONBOARDING_COMPLETED"]
        app.launch()
        app.tabBars.buttons["History"].tap()

        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["THIS WEEK"].exists)
        XCTAssertTrue(app.staticTexts["0 MIN"].exists)
        XCTAssertTrue(app.staticTexts["FOCUSED"].exists)
        XCTAssertTrue(app.staticTexts["0"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["SESSIONS"].exists)
        XCTAssertTrue(app.staticTexts["TASKS FINISHED"].exists)
        XCTAssertTrue(app.staticTexts["NO FOCUS SESSIONS YET."].exists)
        XCTAssertFalse(app.staticTexts["Review amino acids"].exists)
        attachScreenshot(of: app, named: "Empty History")
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

    private func launchGrowthShowcase() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_GROWTH"]
        app.launch()
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Beginning study"].waitForExistence(timeout: 2))
        return app
    }

    private func gardenRow(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["gardenGoal-\(title)"]
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while attempts < 4 && (!element.exists || !element.isHittable) {
            app.swipeUp()
            attempts += 1
        }
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        WalkthroughCapture(self).capture(app, name)
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

private struct WalkthroughCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V1-Walkthrough"
    )

    let test: XCTestCase

    init(_ test: XCTestCase) {
        self.test = test
    }

    func capture(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)

        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let file = Self.directory.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: file)
    }
}
