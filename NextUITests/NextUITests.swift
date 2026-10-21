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
        XCUIDevice.shared.orientation = .portrait
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
        XCTAssertTrue(app.staticTexts["Fits your 30 minutes and Good energy."].exists)
        XCTAssertTrue(app.staticTexts["Study for MCAT is a high-priority goal you haven't worked on yet."].exists)
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
        selectLifeAreas(["Education"], in: app)
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

    private func selectLifeAreas(_ titles: [String], in app: XCUIApplication) {
        let field = app.descendants(matching: .any)["lifeAreasField"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        XCTAssertTrue(app.descendants(matching: .any)["lifeAreasSheet"].waitForExistence(timeout: 2))
        for title in titles {
            let raw = title.lowercased()
            let row = app.descendants(matching: .any)["lifeArea-\(raw)"]
            XCTAssertTrue(row.waitForExistence(timeout: 2), "Missing life area \(title)")
            row.tap()
        }
        app.buttons["lifeAreasDone"].tap()
        XCTAssertTrue(app.buttons["PLANT GOAL →"].waitForExistence(timeout: 2)
                      || app.buttons["SAVE GOAL →"].waitForExistence(timeout: 2))
    }

    private func plantMCATGoalAndAminoTask(in app: XCUIApplication) {
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Nothing planted yet."].waitForExistence(timeout: 2))

        app.buttons["+ PLANT A GOAL"].tap()
        let goalField = app.textFields["Goal title"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 2))
        goalField.tap()
        goalField.typeText("Study for MCAT")
        selectLifeAreas(["Education"], in: app)
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

        XCTAssertEqual(gardenRow("Beginning study", in: app).value as? String, "Beginning")
        XCTAssertTrue(gardenRow("Beginning study", in: app).label.contains("0 sessions"))
        XCTAssertEqual(gardenRow("First growth", in: app).value as? String, "Establishing")
        XCTAssertTrue(gardenRow("First growth", in: app).label.contains("30 minutes focused"))
        XCTAssertEqual(gardenRow("Young plant", in: app).value as? String, "Developing")
        XCTAssertTrue(gardenRow("Young plant", in: app).label.contains("2 hours focused"))
        XCTAssertEqual(gardenRow("Growing plant", in: app).value as? String, "Flourishing")
        XCTAssertTrue(gardenRow("Growing plant", in: app).label.contains("5 hours focused"))
        XCTAssertEqual(gardenRow("Mature plant", in: app).value as? String, "Mature")
        XCTAssertTrue(gardenRow("Mature plant", in: app).label.contains("10 hours focused"))
    }

    @MainActor
    func testShowcaseFullPlantGrowth() throws {
        let app = launchGrowthShowcase()
        attachScreenshot(of: app, named: "01 Garden — all five stages")

        let stages: [(title: String, stage: String, spoken: String, detailMetric: String)] = [
            ("Beginning study", "Beginning", "0 minutes focused", "0 MIN FOCUSED"),
            ("First growth", "Establishing", "30 minutes focused", "30 MIN FOCUSED"),
            ("Young plant", "Developing", "2 hours focused", "2H FOCUSED"),
            ("Growing plant", "Flourishing", "5 hours focused", "5H FOCUSED"),
            ("Mature plant", "Mature", "10 hours focused", "10H FOCUSED")
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
    func testCompletedTaskLeavesWhatsNextAndCanBeReopened() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("next-lifecycle-\(UUID().uuidString).store")
        let storeArguments = [
            "UITEST_STORE_URL", storeURL.path,
            "UITEST_ONBOARDING_COMPLETED"
        ]

        let app = XCUIApplication()
        app.launchArguments = storeArguments
        app.launch()

        plantMCATGoalAndAminoTask(in: app)
        addTaskOnCurrentGoal(in: app, title: "Review flashcards", duration: "15 min", energy: "Low")

        app.tabBars.buttons["Home"].tap()
        completeRecommendedSession(in: app, answer: "YES", exit: "WHAT'S NEXT? →")

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Review amino acids"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.staticTexts["YOUR TASKS"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["COMPLETED"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["goalTask-Review flashcards"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["completedTask-Review amino acids"].exists)
        XCTAssertTrue(app.buttons["Reopen Review amino acids"].exists)

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["TASK FINISHED"].exists || app.staticTexts["1"].exists)

        app.terminate()
        app.launchArguments = storeArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.tabBars.buttons["Garden"].tap()
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.staticTexts["COMPLETED"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["completedTask-Review amino acids"].waitForExistence(timeout: 2))

        app.buttons["Reopen Review amino acids"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["goalTask-Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["COMPLETED"].exists)

        app.tabBars.buttons["Home"].tap()
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["TASK FINISHED"].exists || app.staticTexts["1"].exists)
    }

    @MainActor
    func testNotYetLeavesTaskRecommendable() throws {
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)
        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        app.buttons["Finish early"].tap()
        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        app.buttons["NOT YET"].tap()
        app.buttons["I'M DONE"].tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Garden"].tap()
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["goalTask-Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["COMPLETED"].exists)
    }

    @MainActor
    func testTaskLifecycleVisualReview() throws {
        let review = TaskLifecycleCapture(self)
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_TASK_LIFECYCLE"]
        app.launch()

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.staticTexts["YOUR TASKS"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["COMPLETED"].exists)
        XCTAssertTrue(app.staticTexts["Review flashcards"].exists)
        XCTAssertTrue(app.staticTexts["Review amino acids"].exists)
        XCTAssertTrue(app.buttons["Reopen Review amino acids"].exists)
        review.capture(app, "01 Goal Detail active and completed")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.staticTexts["Finish book"].tap()
        XCTAssertTrue(app.staticTexts["No active tasks."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["COMPLETED"].exists)
        XCTAssertTrue(app.staticTexts["Read chapter"].exists)
        review.capture(app, "02 Goal Detail only completed")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Review amino acids"].exists)
        review.capture(app, "04 Home recommendation after completion")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tabBars.buttons["Garden"].tap()
        app.staticTexts["Study for MCAT"].tap()
        XCTAssertTrue(app.buttons["Reopen Review amino acids"].waitForExistence(timeout: 2))
        app.buttons["Reopen Review amino acids"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["goalTask-Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["COMPLETED"].exists)
        review.capture(app, "03 Completed-task REOPEN")
    }

    @MainActor
    func testRecommendationEngine2Ranking() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_RECOMMENDATION_ENGINE"]
        app.launch()

        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()

        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["MCAT"].exists)
        XCTAssertTrue(app.staticTexts["Fits your 30 minutes and Good energy."].exists)
        XCTAssertTrue(app.staticTexts["MCAT is a high-priority goal you haven't worked on recently."].exists)

        let notThisOne = app.buttons["Not this one"]
        notThisOne.tap()
        XCTAssertTrue(app.staticTexts["Practice flashcards"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["MCAT"].exists)

        notThisOne.tap()
        XCTAssertTrue(app.staticTexts["Update project description"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["You haven't worked on Portfolio yet."].exists)

        notThisOne.tap()
        XCTAssertTrue(app.staticTexts["Work on movement system"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["This goal has had less attention recently."].exists)
        XCTAssertFalse(notThisOne.isEnabled)
    }

    @MainActor
    func testRecommendationEngine2Explanations() throws {
        let review = RecommendationEngineCapture(self)
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_RECOMMENDATION_ENGINE"]
        app.launch()

        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()

        XCTAssertTrue(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["MCAT is a high-priority goal you haven't worked on recently."].exists)
        review.capture(app, "01 High-priority explanation")

        app.buttons["Not this one"].tap()
        XCTAssertTrue(app.staticTexts["Practice flashcards"].waitForExistence(timeout: 2))
        app.buttons["Not this one"].tap()
        XCTAssertTrue(app.staticTexts["Update project description"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["You haven't worked on Portfolio yet."].exists)
        review.capture(app, "02 Never-worked explanation")

        app.buttons["Not this one"].tap()
        XCTAssertTrue(app.staticTexts["Work on movement system"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["This goal has had less attention recently."].exists)
        review.capture(app, "03 Recency explanation")
    }

    @MainActor
    func testEditGoalAndTaskChangeCurrentStateAndRecommendations() throws {
        let app = launchManagementApp()
        openGardenGoal("Study for MCAT", in: app)

        tapGoalOptions(in: app)
        XCTAssertTrue(app.buttons["Edit Goal"].waitForExistence(timeout: 2))
        app.buttons["Edit Goal"].tap()
        XCTAssertTrue(app.staticTexts["EDIT GOAL"].waitForExistence(timeout: 2))
        let goalField = app.textFields["Goal title"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 2))
        replaceText(in: goalField, with: "MCAT prep")
        dismissKeyboard(in: app)
        // Replace Education with Career via multi-select.
        let areasField = app.descendants(matching: .any)["lifeAreasField"]
        XCTAssertTrue(areasField.waitForExistence(timeout: 2))
        areasField.tap()
        XCTAssertTrue(app.descendants(matching: .any)["lifeAreasSheet"].waitForExistence(timeout: 2))
        app.descendants(matching: .any)["lifeArea-education"].tap()
        app.descendants(matching: .any)["lifeArea-career"].tap()
        app.buttons["lifeAreasDone"].tap()
        app.buttons["SAVE GOAL →"].tap()

        XCTAssertTrue(app.staticTexts["MCAT prep"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["CAREER"].exists)
        XCTAssertTrue(app.staticTexts["HIGH PRIORITY"].exists)

        openTaskEditor("Review amino acids", in: app)
        XCTAssertTrue(app.staticTexts["EDIT TASK"].waitForExistence(timeout: 2))
        let taskField = app.textFields["Task title"]
        replaceText(in: taskField, with: "Review organic chemistry")
        dismissKeyboard(in: app)
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["SAVE TASK →"].tap()
        XCTAssertTrue(app.staticTexts["Review organic chemistry"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["30 MIN  ·  GOOD"].exists || app.staticTexts.matching(NSPredicate(format: "label CONTAINS '30 MIN'")).firstMatch.exists)

        openHome(in: app)
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["Review organic chemistry"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["MCAT prep"].exists)

        app.tabBars.buttons["Garden"].tap()
        openGardenGoal("MCAT prep", in: app)
        tapGoalOptions(in: app)
        XCTAssertTrue(app.buttons["Edit Goal"].waitForExistence(timeout: 2))
        app.buttons["Edit Goal"].tap()
        XCTAssertTrue(app.staticTexts["EDIT GOAL"].waitForExistence(timeout: 2))
        dismissKeyboard(in: app)
        app.buttons["Low"].tap()
        app.buttons["SAVE GOAL →"].tap()
        XCTAssertTrue(app.staticTexts["LOW PRIORITY"].waitForExistence(timeout: 2))

        openHome(in: app)
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["Update project description"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Review organic chemistry"].exists)
    }

    @MainActor
    func testEditCompletedTaskRemainsCompleted() throws {
        let app = launchManagementApp()
        openGardenGoal("Study for MCAT", in: app)
        XCTAssertTrue(app.staticTexts["COMPLETED"].waitForExistence(timeout: 2))

        openTaskEditor("Review flashcards", completed: true, in: app)
        let taskField = app.textFields["Task title"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        replaceText(in: taskField, with: "Anki cards")
        dismissKeyboard(in: app)
        app.buttons["SAVE TASK →"].tap()

        XCTAssertTrue(app.staticTexts["COMPLETED"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["completedTask-Anki cards"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Reopen Anki cards"].exists)

        app.tabBars.buttons["Home"].tap()
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertFalse(app.staticTexts["Anki cards"].exists)
        XCTAssertTrue(app.staticTexts["Update project description"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeleteTaskAndGoalKeepHistory() throws {
        let app = launchManagementApp()
        openGardenGoal("Study for MCAT", in: app)

        openTaskMenu("Review amino acids", in: app)
        tapMenuButton("Delete Review amino acids", in: app)
        XCTAssertTrue(app.staticTexts["Delete Task?"].waitForExistence(timeout: 2))
        app.buttons["Delete Task"].tap()
        XCTAssertFalse(app.staticTexts["Review amino acids"].waitForExistence(timeout: 2))

        app.tabBars.buttons["History"].tap()
        assertHistoryRow(task: "Review amino acids", goal: "Study for MCAT", in: app)

        app.tabBars.buttons["Garden"].tap()
        app.staticTexts["Study for MCAT"].tap()
        tapGoalOptions(in: app)
        app.buttons["Delete Goal"].tap()
        XCTAssertTrue(app.staticTexts["Delete Goal?"].waitForExistence(timeout: 2))
        app.buttons["Delete Goal"].tap()
        XCTAssertTrue(app.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Study for MCAT"].exists)
        XCTAssertTrue(app.staticTexts["Portfolio"].exists)

        app.tabBars.buttons["History"].tap()
        assertHistoryRow(task: "Review amino acids", goal: "Study for MCAT", in: app)
    }

    @MainActor
    func testGoalTaskManagementVisualReview() throws {
        let review = ManagementCapture(self)
        let app = launchManagementApp()
        openGardenGoal("Study for MCAT", in: app)

        tapGoalOptions(in: app)
        XCTAssertTrue(app.buttons["Edit Goal"].waitForExistence(timeout: 2))
        review.capture(app, "01 Goal Detail management menu")
        if !app.buttons["Edit Goal"].exists {
            tapGoalOptions(in: app)
            XCTAssertTrue(app.buttons["Edit Goal"].waitForExistence(timeout: 2))
        }
        app.buttons["Edit Goal"].tap()
        XCTAssertTrue(app.staticTexts["EDIT GOAL"].waitForExistence(timeout: 2))
        review.capture(app, "02 Edit Goal")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openTaskEditor("Review amino acids", in: app)
        XCTAssertTrue(app.staticTexts["EDIT TASK"].waitForExistence(timeout: 2))
        review.capture(app, "03 Edit active Task")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openTaskEditor("Review flashcards", completed: true, in: app)
        XCTAssertTrue(app.staticTexts["EDIT TASK"].waitForExistence(timeout: 2))
        review.capture(app, "04 Edit completed Task")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openTaskMenu("Review amino acids", in: app)
        tapMenuButton("Delete Review amino acids", in: app)
        XCTAssertTrue(app.staticTexts["Delete Task?"].waitForExistence(timeout: 2))
        review.capture(app, "05 Delete Task confirmation")
        app.buttons["Cancel"].tap()

        tapGoalOptions(in: app)
        app.buttons["Delete Goal"].tap()
        XCTAssertTrue(app.staticTexts["Delete Goal?"].waitForExistence(timeout: 2))
        review.capture(app, "06 Delete Goal confirmation")
        app.buttons["Cancel"].tap()

        openTaskEditor("Review amino acids", in: app)
        replaceText(in: app.textFields["Task title"], with: "Renamed amino")
        dismissKeyboard(in: app)
        app.buttons["SAVE TASK →"].tap()
        openTaskMenu("Renamed amino", in: app)
        tapMenuButton("Delete Renamed amino", in: app)
        app.buttons["Delete Task"].tap()
        app.tabBars.buttons["History"].tap()
        assertHistoryRow(task: "Review amino acids", goal: "Study for MCAT", in: app)
        review.capture(app, "07 History after Task rename and delete")

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        app.staticTexts["Study for MCAT"].tap()
        tapGoalOptions(in: app)
        app.buttons["Edit Goal"].tap()
        replaceText(in: app.textFields["Goal title"], with: "MCAT renamed")
        dismissKeyboard(in: app)
        app.buttons["SAVE GOAL →"].tap()
        XCTAssertTrue(app.staticTexts["MCAT renamed"].waitForExistence(timeout: 2))
        tapGoalOptions(in: app)
        app.buttons["Delete Goal"].tap()
        XCTAssertTrue(app.staticTexts["Delete Goal?"].waitForExistence(timeout: 2))
        app.buttons["Delete Goal"].tap()
        XCTAssertTrue(app.staticTexts["GARDEN"].waitForExistence(timeout: 3))
        app.tabBars.buttons["History"].tap()
        assertHistoryRow(task: "Review amino acids", goal: "Study for MCAT", in: app)
        review.capture(app, "08 History after Goal rename and delete")
    }

    @MainActor
    func testFocusSettingsKeepScreenAwakePersists() throws {
        let suite = "next.uitest.focus-\(UUID().uuidString)"
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_GARDEN", "UITEST_DEFAULTS_SUITE", suite]
        app.launch()

        navigateToFirstRecommendation(in: app)
        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Focus settings"].waitForExistence(timeout: 2))

        tapFocusSettings(in: app)
        let awake = app.switches["keepScreenAwake"]
        XCTAssertTrue(awake.waitForExistence(timeout: 3))
        XCTAssertEqual(awake.value as? String, "0")
        XCTAssertFalse(app.staticTexts["REDUCE DISTRACTIONS"].exists)
        XCTAssertFalse(app.buttons["Reduce Distractions"].exists)
        awake.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(awake.value as? String, "1")
        app.buttons["DONE"].tap()

        app.terminate()
        app.launchArguments = ["UITEST_SEED_GARDEN", "UITEST_DEFAULTS_SUITE", suite]
        app.launch()
        navigateToFirstRecommendation(in: app)
        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        tapFocusSettings(in: app)
        let restored = app.switches["keepScreenAwake"]
        XCTAssertTrue(restored.waitForExistence(timeout: 3))
        XCTAssertEqual(restored.value as? String, "1")
        XCTAssertFalse(app.staticTexts["REDUCE DISTRACTIONS"].exists)
        XCTAssertFalse(app.buttons["Reduce Distractions"].exists)
    }

    @MainActor
    func testFocusExperienceVisualReview() throws {
        let review = FocusExperienceCapture(self)
        let app = launchSeededApp()
        navigateToFirstRecommendation(in: app)
        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Focus settings"].waitForExistence(timeout: 2))
        review.capture(app, "01 Focus screen with settings")

        tapFocusSettings(in: app)
        let awake = app.switches["keepScreenAwake"]
        XCTAssertTrue(awake.waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["REDUCE DISTRACTIONS"].exists)
        review.capture(app, "02 Focus settings")
        review.capture(app, "03 Keep Screen Awake OFF")

        awake.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        if (awake.value as? String) != "1" {
            awake.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertEqual(awake.value as? String, "1")
        review.capture(app, "04 Keep Screen Awake ON")
        review.capture(app, "05 Focus settings after cleanup")
    }

    @MainActor
    func testVisibleTaskManagementOverflow() throws {
        let app = launchManagementApp()
        openGardenGoal("Study for MCAT", in: app)

        XCTAssertTrue(app.buttons["Manage Review amino acids"].waitForExistence(timeout: 2))
        openVisibleTaskMenu("Review amino acids", in: app)
        XCTAssertTrue(app.buttons["Edit Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Delete Review amino acids"].exists)
        tapMenuButton("Edit Review amino acids", in: app)
        XCTAssertTrue(app.staticTexts["EDIT TASK"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.buttons["Reopen Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Manage Review flashcards"].exists)
        openVisibleTaskMenu("Review flashcards", completed: true, in: app)
        XCTAssertTrue(app.buttons["Edit Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Delete Review flashcards"].exists)
        tapMenuButton("Delete Review flashcards", in: app)
        XCTAssertTrue(app.staticTexts["Delete Task?"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()

        openTaskMenu("Review amino acids", in: app)
        tapMenuButton("Edit Review amino acids", in: app)
        XCTAssertTrue(app.staticTexts["EDIT TASK"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testTaskOverflowVisualReview() throws {
        let review = FinalCleanupCapture(self)
        let app = launchManagementApp()
        openGardenGoal("Study for MCAT", in: app)
        XCTAssertTrue(app.buttons["Manage Review amino acids"].waitForExistence(timeout: 2))
        review.capture(app, "01 Goal Detail active Task management")

        openVisibleTaskMenu("Review amino acids", in: app)
        XCTAssertTrue(app.buttons["Edit Review amino acids"].waitForExistence(timeout: 2))
        review.capture(app, "02 Active Task overflow menu")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2)).tap()

        app.swipeUp()
        XCTAssertTrue(app.buttons["Reopen Review flashcards"].waitForExistence(timeout: 2))
        review.capture(app, "03 Goal Detail completed Task management")

        openVisibleTaskMenu("Review flashcards", completed: true, in: app)
        XCTAssertTrue(app.buttons["Edit Review flashcards"].waitForExistence(timeout: 2))
        review.capture(app, "04 Completed Task overflow menu")
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

    @MainActor
    func testCompletionAcknowledgesPlantGrowthForBothAnswers() throws {
        let yesApp = launchGardenEvolutionApp()
        navigateToFirstRecommendation(in: yesApp)
        yesApp.buttons["START SESSION →"].tap()
        XCTAssertTrue(yesApp.buttons["Finish early"].waitForExistence(timeout: 2))
        yesApp.buttons["Finish early"].tap()
        XCTAssertTrue(yesApp.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        yesApp.buttons["YES"].tap()
        let yesLine = yesApp.descendants(matching: .any)["gardenAcknowledgement"]
        XCTAssertTrue(yesLine.waitForExistence(timeout: 2))
        XCTAssertTrue(
            yesLine.label.contains("Study for MCAT")
                || yesApp.staticTexts["This session helped your Study for MCAT plant grow."].exists
                || yesApp.staticTexts["Your Study for MCAT plant has new growth."].exists
        )
        XCTAssertTrue(yesApp.buttons["WHAT'S NEXT? →"].exists)
        XCTAssertTrue(yesApp.buttons["I'M DONE"].exists)
        yesApp.buttons["I'M DONE"].tap()
        XCTAssertTrue(yesApp.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        yesApp.terminate()

        let notYet = launchGardenEvolutionApp()
        navigateToFirstRecommendation(in: notYet)
        notYet.buttons["START SESSION →"].tap()
        XCTAssertTrue(notYet.buttons["Finish early"].waitForExistence(timeout: 2))
        notYet.buttons["Finish early"].tap()
        XCTAssertTrue(notYet.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        notYet.buttons["NOT YET"].tap()
        let notYetLine = notYet.descendants(matching: .any)["gardenAcknowledgement"]
        XCTAssertTrue(notYetLine.waitForExistence(timeout: 2))
        XCTAssertTrue(
            notYetLine.label.contains("Study for MCAT")
                || notYet.staticTexts["This session helped your Study for MCAT plant grow."].exists
        )
        notYet.buttons["I'M DONE"].tap()
        XCTAssertTrue(notYet.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        notYet.tabBars.buttons["Garden"].tap()
        let row = gardenRow("Study for MCAT", in: notYet)
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        XCTAssertTrue(row.label.contains("1 session"))
        XCTAssertTrue(row.label.contains("Beginning") || row.label.contains("Establishing"))
    }

    @MainActor
    func testGardenEvolutionVisualReview() throws {
        let review = GardenEvolutionCapture(self)

        let comparison = XCUIApplication()
        comparison.launchArguments = ["UITEST_PLANT_COMPARISON", "UITEST_IN_MEMORY"]
        comparison.launch()
        XCTAssertTrue(comparison.staticTexts["PLANT COMPARISON"].waitForExistence(timeout: 2))
        XCTAssertTrue(comparison.descendants(matching: .any)["plantComparison"].exists)
        review.capture(comparison, "00 Comparison — all variants and stages")
        comparison.swipeUp()
        review.capture(comparison, "00b Comparison — lower variants")
        comparison.swipeUp()
        comparison.swipeUp()
        review.capture(comparison, "00c Comparison — Rounded Leaf")
        let roundedDeveloping = comparison.descendants(matching: .any)["compare-roundedLeaf-2"]
        if roundedDeveloping.exists {
            roundedDeveloping.swipeLeft()
            roundedDeveloping.swipeLeft()
        }
        review.capture(comparison, "00d Comparison — Rounded Leaf Mature")
        comparison.terminate()
        XCUIDevice.shared.orientation = .portrait

        let app = launchGardenEvolutionApp()
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Study for MCAT"].waitForExistence(timeout: 2))
        XCTAssertEqual(gardenRow("Study for MCAT", in: app).value as? String, "Beginning")
        XCTAssertEqual(gardenRow("Build Next", in: app).value as? String, "Developing")
        XCTAssertEqual(gardenRow("Interview preparation", in: app).value as? String, "Flourishing")
        XCTAssertEqual(gardenRow("Finish book", in: app).value as? String, "Mature")
        review.capture(app, "01 Garden — four plant variants")
        review.capture(app, "01b Garden — Beginning plant")
        app.swipeUp()
        review.capture(app, "02 Garden — mixed growth stages")
        app.swipeDown()
        app.swipeDown()

        openGardenGoal("Study for MCAT", in: app)
        XCTAssertTrue(app.staticTexts["0 MIN FOCUSED"].waitForExistence(timeout: 2))
        review.capture(app, "03 Goal Detail — Beginning plant")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openGardenGoal("Build Next", in: app)
        XCTAssertTrue(app.staticTexts["2H FOCUSED"].waitForExistence(timeout: 2))
        review.capture(app, "04 Goal Detail — Developing plant")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openGardenGoal("Finish book", in: app)
        XCTAssertTrue(app.staticTexts["10H FOCUSED"].waitForExistence(timeout: 2))
        review.capture(app, "05 Goal Detail — Mature plant")
        app.terminate()

        let completion = launchGardenEvolutionApp()
        navigateToFirstRecommendation(in: completion)
        completion.buttons["START SESSION →"].tap()
        XCTAssertTrue(completion.buttons["Finish early"].waitForExistence(timeout: 2))
        completion.buttons["Finish early"].tap()
        XCTAssertTrue(completion.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        completion.buttons["YES"].tap()
        XCTAssertTrue(completion.descendants(matching: .any)["gardenAcknowledgement"].waitForExistence(timeout: 2))
        review.capture(completion, "06 Completion botanical acknowledgement")
        completion.terminate()

        let largeType = XCUIApplication()
        largeType.launchArguments = [
            "UITEST_SEED_GARDEN_EVOLUTION",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        largeType.launch()
        largeType.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(largeType.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(largeType, "07 Garden at large Dynamic Type")
        reveal(gardenRow("Interview preparation", in: largeType), in: largeType)
        review.capture(largeType, "09 Refinement — large DT former overlap")
        largeType.swipeDown()
        largeType.swipeDown()
        openGardenGoal("Study for MCAT", in: largeType)
        XCTAssertTrue(largeType.buttons["+ ADD TASK"].waitForExistence(timeout: 2))
        review.capture(largeType, "08 Goal Detail at large Dynamic Type")
        largeType.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(largeType.staticTexts["GARDEN"].waitForExistence(timeout: 2))

        let lastRow = gardenRow("Finish book", in: largeType)
        let plantGoal = largeType.buttons["+ PLANT A GOAL"]
        reveal(lastRow, in: largeType)
        reveal(plantGoal, in: largeType)
        XCTAssertTrue(lastRow.waitForExistence(timeout: 2))
        XCTAssertTrue(plantGoal.waitForExistence(timeout: 2))
        review.capture(largeType, "10 Refinement — large DT final Goal and CTA")
    }

    @MainActor
    func testLargeDynamicTypeGardenDoesNotCoverGoals() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_SEED_GARDEN_EVOLUTION",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        app.launch()
        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["GARDEN"].waitForExistence(timeout: 3))

        let titles = ["Study for MCAT", "Build Next", "Interview preparation", "Finish book"]
        let cta = app.buttons["+ PLANT A GOAL"]
        if cta.exists && cta.isHittable {
            for title in titles {
                let row = gardenRow(title, in: app)
                if row.exists && row.isHittable {
                    XCTAssertLessThanOrEqual(
                        row.frame.maxY,
                        cta.frame.minY + 1,
                        "\(title) is covered by Plant a Goal"
                    )
                }
            }
        }

        for title in titles {
            let row = gardenRow(title, in: app)
            reveal(row, in: app)
            XCTAssertTrue(row.waitForExistence(timeout: 3), "Missing Garden row \(title)")
            XCTAssertTrue(row.isHittable, "Garden row \(title) is not reachable")
        }

        reveal(cta, in: app)
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        XCTAssertTrue(cta.isHittable, "Plant a Goal is not reachable")

        let last = gardenRow("Finish book", in: app)
        reveal(last, in: app)
        reveal(cta, in: app)
        XCTAssertTrue(cta.isHittable, "Plant a Goal is not reachable after the final Goal")
        XCTAssertLessThan(
            last.frame.minY,
            cta.frame.minY,
            "Final Goal is not above Plant a Goal"
        )
    }

    @MainActor
    func testAppearancePreferencePersistsAcrossRelaunch() throws {
        let first = XCUIApplication()
        first.launchArguments = ["UITEST_SEED_GARDEN", "UITEST_APPEARANCE", "system"]
        first.launch()
        XCTAssertTrue(first.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        first.buttons["appearanceButton"].tap()
        let systemOption = first.descendants(matching: .any)["appearance-system"]
        XCTAssertTrue(systemOption.waitForExistence(timeout: 2))
        XCTAssertEqual(systemOption.value as? String, "Selected")
        first.descendants(matching: .any)["appearance-dark"].tap()
        XCTAssertEqual(first.descendants(matching: .any)["appearance-dark"].value as? String, "Selected")
        first.buttons["DONE"].tap()
        XCTAssertTrue(first.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        first.terminate()

        let second = XCUIApplication()
        second.launchArguments = ["UITEST_SEED_GARDEN"]
        second.launch()
        XCTAssertTrue(second.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        second.buttons["appearanceButton"].tap()
        let darkOption = second.descendants(matching: .any)["appearance-dark"]
        XCTAssertTrue(darkOption.waitForExistence(timeout: 2))
        XCTAssertEqual(darkOption.value as? String, "Selected")
        second.descendants(matching: .any)["appearance-system"].tap()
        second.buttons["DONE"].tap()
    }

    @MainActor
    func testForcedLightAndDarkOverridesSurviveSystemStyle() throws {
        XCUIDevice.shared.appearance = .dark
        let light = XCUIApplication()
        light.launchArguments = ["UITEST_SEED_GARDEN", "UITEST_APPEARANCE", "light"]
        light.launch()
        XCTAssertTrue(light.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        light.buttons["appearanceButton"].tap()
        let lightOption = light.descendants(matching: .any)["appearance-light"]
        XCTAssertTrue(lightOption.waitForExistence(timeout: 2))
        XCTAssertEqual(lightOption.value as? String, "Selected")
        light.buttons["DONE"].tap()
        light.terminate()

        XCUIDevice.shared.appearance = .light
        let dark = XCUIApplication()
        dark.launchArguments = ["UITEST_SEED_GARDEN", "UITEST_APPEARANCE", "dark"]
        dark.launch()
        XCTAssertTrue(dark.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        dark.buttons["appearanceButton"].tap()
        let darkOption = dark.descendants(matching: .any)["appearance-dark"]
        XCTAssertTrue(darkOption.waitForExistence(timeout: 2))
        XCTAssertEqual(darkOption.value as? String, "Selected")
        dark.buttons["DONE"].tap()
        dark.terminate()

        XCUIDevice.shared.appearance = .light
    }

    @MainActor
    func testDynamicAppearanceVisualReview() throws {
        let review = AppearanceCapture(self)

        func launchSeeded(_ appearance: String, extra: [String] = []) -> XCUIApplication {
            let app = XCUIApplication()
            app.launchArguments = ["UITEST_SEED_GARDEN_EVOLUTION", "UITEST_APPEARANCE", appearance] + extra
            app.launch()
            return app
        }

        let homeLight = launchSeeded("light")
        XCTAssertTrue(homeLight.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        review.capture(homeLight, "01 Home — Light")
        homeLight.buttons["appearanceButton"].tap()
        XCTAssertTrue(homeLight.descendants(matching: .any)["appearance-light"].waitForExistence(timeout: 2))
        review.capture(homeLight, "15 Appearance setting — Light")
        homeLight.buttons["DONE"].tap()
        homeLight.buttons["30 min"].tap()
        homeLight.buttons["Good"].tap()
        homeLight.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(homeLight.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        review.capture(homeLight, "03 Recommendation — Light")
        homeLight.buttons["START SESSION →"].tap()
        XCTAssertTrue(homeLight.buttons["Finish early"].waitForExistence(timeout: 2))
        review.capture(homeLight, "05 Focus — Light")
        homeLight.buttons["Finish early"].tap()
        XCTAssertTrue(homeLight.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        homeLight.buttons["YES"].tap()
        review.capture(homeLight, "07 Completion — Light")
        homeLight.terminate()

        let gardenLight = launchSeeded("light")
        gardenLight.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(gardenLight.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(gardenLight, "09 Garden — Light")
        openGardenGoal("Study for MCAT", in: gardenLight)
        XCTAssertTrue(gardenLight.buttons["+ ADD TASK"].waitForExistence(timeout: 2))
        review.capture(gardenLight, "11 Goal Detail — Light")
        gardenLight.navigationBars.buttons.element(boundBy: 0).tap()
        gardenLight.tabBars.buttons["History"].tap()
        XCTAssertTrue(gardenLight.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        review.capture(gardenLight, "13 History — Light")
        gardenLight.terminate()

        let homeDark = launchSeeded("dark")
        XCTAssertTrue(homeDark.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        review.capture(homeDark, "02 Home — Dark")
        homeDark.buttons["appearanceButton"].tap()
        XCTAssertTrue(homeDark.descendants(matching: .any)["appearance-dark"].waitForExistence(timeout: 2))
        review.capture(homeDark, "16 Appearance setting — Dark")
        homeDark.buttons["DONE"].tap()
        homeDark.buttons["30 min"].tap()
        homeDark.buttons["Good"].tap()
        homeDark.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(homeDark.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        review.capture(homeDark, "04 Recommendation — Dark")
        homeDark.buttons["START SESSION →"].tap()
        XCTAssertTrue(homeDark.buttons["Finish early"].waitForExistence(timeout: 2))
        review.capture(homeDark, "06 Focus — Dark")
        homeDark.buttons["Finish early"].tap()
        XCTAssertTrue(homeDark.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        homeDark.buttons["YES"].tap()
        review.capture(homeDark, "08 Completion — Dark")
        homeDark.terminate()

        let gardenDark = launchSeeded("dark")
        gardenDark.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(gardenDark.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(gardenDark, "10 Garden — Dark")
        openGardenGoal("Finish book", in: gardenDark)
        XCTAssertTrue(gardenDark.buttons["+ ADD TASK"].waitForExistence(timeout: 2))
        review.capture(gardenDark, "12 Goal Detail — Dark")
        gardenDark.buttons["+ ADD TASK"].tap()
        XCTAssertTrue(gardenDark.textFields["Task title"].waitForExistence(timeout: 2))
        review.capture(gardenDark, "17 Form — Dark")
        gardenDark.swipeDown()
        gardenDark.tabBars.buttons["History"].tap()
        XCTAssertTrue(gardenDark.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        review.capture(gardenDark, "14 History — Dark")
        gardenDark.terminate()

        let onboarding = XCUIApplication()
        onboarding.launchArguments = [
            "UITEST_IN_MEMORY",
            "UITEST_FRESH_ONBOARDING",
            "UITEST_APPEARANCE",
            "dark",
            "UITEST_DEFAULTS_SUITE",
            "next.uitest.appearance.\(UUID().uuidString)"
        ]
        onboarding.launch()
        XCTAssertTrue(onboarding.buttons["GET STARTED →"].waitForExistence(timeout: 2))
        review.capture(onboarding, "18 Onboarding — Dark")
        onboarding.terminate()

        let largeDark = launchSeeded("dark", extra: [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ])
        largeDark.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(largeDark.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(largeDark, "19 Garden large Dynamic Type — Dark")
        openGardenGoal("Study for MCAT", in: largeDark)
        XCTAssertTrue(largeDark.buttons["+ ADD TASK"].waitForExistence(timeout: 2))
        review.capture(largeDark, "20 Goal Detail large Dynamic Type — Dark")
        largeDark.terminate()

        XCUIDevice.shared.appearance = .light
        let systemLight = launchSeeded("system")
        XCTAssertTrue(systemLight.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        review.capture(systemLight, "21a System preference — device Light")
        systemLight.terminate()

        XCUIDevice.shared.appearance = .dark
        let systemDark = launchSeeded("system")
        XCTAssertTrue(systemDark.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        review.capture(systemDark, "21b System preference — device Dark")
        review.capture(systemDark, "21 System appearance switching demonstration")
        systemDark.terminate()
        XCUIDevice.shared.appearance = .light
    }

    /// Final M6 PM checks only: History titles, large DT Dark, selection contrast Dark.
    @MainActor
    func testM6FinalVisualChecks() throws {
        let review = AppearanceCapture(self)

        // 1. History titles — Light / Dark (garden-evolution seed now includes snapshots)
        let historyLight = XCUIApplication()
        historyLight.launchArguments = ["UITEST_SEED_GARDEN_EVOLUTION", "UITEST_APPEARANCE", "light"]
        historyLight.launch()
        historyLight.tabBars.buttons["History"].tap()
        XCTAssertTrue(historyLight.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        XCTAssertTrue(historyLight.staticTexts["Sketch the garden"].waitForExistence(timeout: 2))
        XCTAssertTrue(historyLight.staticTexts["Practice arrays"].exists)
        XCTAssertTrue(historyLight.staticTexts["Read chapter"].exists)
        XCTAssertFalse(historyLight.staticTexts["Untitled"].exists)
        review.capture(historyLight, "22 History titles — Light")
        historyLight.terminate()

        let historyDark = XCUIApplication()
        historyDark.launchArguments = ["UITEST_SEED_GARDEN_EVOLUTION", "UITEST_APPEARANCE", "dark"]
        historyDark.launch()
        historyDark.tabBars.buttons["History"].tap()
        XCTAssertTrue(historyDark.staticTexts["Sketch the garden"].waitForExistence(timeout: 2))
        XCTAssertFalse(historyDark.staticTexts["Untitled"].exists)
        review.capture(historyDark, "23 History titles — Dark")

        // Snapshot survives task rename + delete
        historyDark.tabBars.buttons["Garden"].tap()
        openGardenGoal("Build Next", in: historyDark)
        openVisibleTaskMenu("Sketch the garden", in: historyDark)
        tapMenuButton("Edit Sketch the garden", in: historyDark)
        let field = historyDark.textFields["Task title"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        replaceText(in: field, with: "Renamed sketch")
        historyDark.buttons["SAVE TASK →"].tap()
        openVisibleTaskMenu("Renamed sketch", in: historyDark)
        tapMenuButton("Delete Renamed sketch", in: historyDark)
        if historyDark.buttons["Delete Task"].waitForExistence(timeout: 2) {
            historyDark.buttons["Delete Task"].tap()
        }
        historyDark.tabBars.buttons["History"].tap()
        XCTAssertTrue(historyDark.staticTexts["Sketch the garden"].waitForExistence(timeout: 2))
        XCTAssertFalse(historyDark.staticTexts["Renamed sketch"].exists)
        review.capture(historyDark, "24 History titles after rename and delete — Dark")
        historyDark.terminate()

        // 2. Large Dynamic Type — Dark
        let large = XCUIApplication()
        large.launchArguments = [
            "UITEST_SEED_GARDEN_EVOLUTION",
            "UITEST_APPEARANCE",
            "dark",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        large.launch()
        large.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(large.staticTexts["GARDEN"].waitForExistence(timeout: 3))
        review.capture(large, "25 Garden large Dynamic Type — Dark")
        reveal(gardenRow("Interview preparation", in: large), in: large)
        review.capture(large, "26 Garden large Dynamic Type scrolled — Dark")
        reveal(gardenRow("Finish book", in: large), in: large)
        reveal(large.buttons["+ PLANT A GOAL"], in: large)
        review.capture(large, "27 Garden large Dynamic Type final Goal and CTA — Dark")
        large.swipeDown()
        large.swipeDown()
        openGardenGoal("Study for MCAT", in: large)
        XCTAssertTrue(large.buttons["+ ADD TASK"].waitForExistence(timeout: 3))
        review.capture(large, "28 Goal Detail large Dynamic Type — Dark")
        reveal(large.buttons["+ ADD TASK"], in: large)
        review.capture(large, "29 Goal Detail large Dynamic Type scrolled CTA — Dark")
        large.terminate()

        // 3. Selection contrast — Dark
        let home = XCUIApplication()
        home.launchArguments = ["UITEST_SEED_GARDEN_EVOLUTION", "UITEST_APPEARANCE", "dark"]
        home.launch()
        XCTAssertTrue(home.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        home.buttons["30 min"].tap()
        home.buttons["Good"].tap()
        XCTAssertTrue(home.buttons["WHAT'S NEXT?"].isEnabled)
        review.capture(home, "30 Home selections — Dark")

        home.tabBars.buttons["Garden"].tap()
        openGardenGoal("Study for MCAT", in: home)
        home.buttons["+ ADD TASK"].tap()
        XCTAssertTrue(home.textFields["Task title"].waitForExistence(timeout: 2))
        home.buttons["30 min"].tap()
        home.buttons["Good"].tap()
        review.capture(home, "31 Add Task selections — Dark")
        home.swipeDown()

        home.tabBars.buttons["Home"].tap()
        XCTAssertTrue(home.buttons["WHAT'S NEXT?"].waitForExistence(timeout: 2))
        if !home.buttons["WHAT'S NEXT?"].isEnabled {
            home.buttons["30 min"].tap()
            home.buttons["Good"].tap()
        }
        home.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(home.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        home.buttons["START SESSION →"].tap()
        XCTAssertTrue(home.buttons["Finish early"].waitForExistence(timeout: 2))
        home.buttons["Finish early"].tap()
        XCTAssertTrue(home.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        home.buttons["YES"].tap()
        XCTAssertEqual(home.buttons["YES"].value as? String, "Selected")
        review.capture(home, "32 Completion YES selected — Dark")
        home.terminate()
    }

    @MainActor
    func testSmartRemindersDefaultsOffAndPersists() throws {
        let first = XCUIApplication()
        first.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "off",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        first.launch()
        XCTAssertTrue(first.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        first.buttons["appearanceButton"].tap()
        XCTAssertTrue(first.descendants(matching: .any)["preferencesSheet"].waitForExistence(timeout: 2))
        XCTAssertTrue(first.staticTexts["REMINDERS"].waitForExistence(timeout: 2))
        let toggle = first.switches["dailyReminderToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.tap()
        XCTAssertEqual(first.switches["dailyReminderToggle"].value as? String, "1")
        XCTAssertTrue(first.descendants(matching: .any)["dailyReminderTime"].waitForExistence(timeout: 2))
        first.buttons["DONE"].tap()
        first.terminate()

        let second = XCUIApplication()
        second.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        second.launch()
        XCTAssertTrue(second.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        second.buttons["appearanceButton"].tap()
        XCTAssertTrue(second.switches["dailyReminderToggle"].waitForExistence(timeout: 2))
        XCTAssertEqual(second.switches["dailyReminderToggle"].value as? String, "1")
        second.switches["dailyReminderToggle"].tap()
        XCTAssertEqual(second.switches["dailyReminderToggle"].value as? String, "0")
        second.buttons["DONE"].tap()
    }

    @MainActor
    func testSmartRemindersDeniedShowsSettingsGuidance() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "off",
            "UITEST_REMINDER_AUTH", "denied"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        app.buttons["appearanceButton"].tap()
        XCTAssertTrue(app.switches["dailyReminderToggle"].waitForExistence(timeout: 2))
        app.switches["dailyReminderToggle"].tap()
        XCTAssertEqual(app.switches["dailyReminderToggle"].value as? String, "0")
        XCTAssertTrue(app.buttons["openNotificationSettings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Notifications are turned off for Next in iOS Settings. Reminders cannot be delivered until you allow them."].exists)
        app.buttons["DONE"].tap()
    }

    // MARK: - V2-M9 QA & Design Refinement

    @MainActor
    func testM9TabsSettingsHistoryAndHomeHeader() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_GARDEN_EVOLUTION", "UITEST_APPEARANCE", "light"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["homeGreeting"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["appearanceButton"].exists)
        XCTAssertFalse(app.buttons["PREFERENCES"].exists)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Garden"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        XCTAssertFalse(app.tabBars.buttons["History"].exists)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["settingsScreen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["APPEARANCE"].exists)
        XCTAssertTrue(app.staticTexts["REMINDERS"].exists)
        XCTAssertFalse(app.staticTexts["Calm Garden by day. Twilight Quiet by night."].exists)
        XCTAssertFalse(app.staticTexts["Soft, never urgent."].exists)

        app.buttons["settingsHistoryLink"].tap()
        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Sketch the garden"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.descendants(matching: .any)["settingsScreen"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testM9AppearanceSwitchesImmediatelyAndPersists() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_GARDEN", "UITEST_APPEARANCE", "light"]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["appearance-light"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.descendants(matching: .any)["appearance-light"].value as? String, "Selected")

        app.descendants(matching: .any)["appearance-dark"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["appearance-dark"].value as? String, "Selected")
        XCTAssertTrue(app.descendants(matching: .any)["settingsScreen"].exists)

        app.descendants(matching: .any)["appearance-light"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["appearance-light"].value as? String, "Selected")

        app.descendants(matching: .any)["appearance-dark"].tap()
        app.terminate()

        let relaunch = XCUIApplication()
        relaunch.launchArguments = ["UITEST_SEED_GARDEN"]
        relaunch.launch()
        relaunch.tabBars.buttons["Settings"].tap()
        XCTAssertEqual(relaunch.descendants(matching: .any)["appearance-dark"].value as? String, "Selected")
        relaunch.descendants(matching: .any)["appearance-system"].tap()
        relaunch.terminate()
    }

    @MainActor
    func testM9ReminderToggleStillWorksFromSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "off",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        let toggle = app.switches["dailyReminderToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.tap()
        XCTAssertEqual(app.switches["dailyReminderToggle"].value as? String, "1")
        XCTAssertTrue(app.descendants(matching: .any)["dailyReminderTime"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testM9LargeDynamicTypeSettingsUsable() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["SETTINGS"].waitForExistence(timeout: 3))
        reveal(app.buttons["settingsHistoryLink"], in: app)
        XCTAssertTrue(app.buttons["settingsHistoryLink"].isHittable)
    }

    @MainActor
    func testM9VisualReview() throws {
        let review = DesignRefinementCapture(self)

        func launch(_ appearance: String, extra: [String] = []) -> XCUIApplication {
            let app = XCUIApplication()
            app.launchArguments = [
                "UITEST_SEED_GARDEN_EVOLUTION",
                "UITEST_APPEARANCE", appearance,
                "UITEST_REMINDER", "off",
                "UITEST_REMINDER_AUTH", "authorized"
            ] + extra
            app.launch()
            return app
        }

        let homeLight = launch("light")
        XCTAssertTrue(homeLight.descendants(matching: .any)["homeGreeting"].waitForExistence(timeout: 3))
        review.capture(homeLight, "01 Home — Light")
        homeLight.terminate()

        let homeDark = launch("dark")
        XCTAssertTrue(homeDark.descendants(matching: .any)["homeGreeting"].waitForExistence(timeout: 3))
        homeDark.buttons["30 min"].tap()
        homeDark.buttons["Good"].tap()
        review.capture(homeDark, "02 Home — Dark")
        homeDark.terminate()

        let settingsLight = launch("light")
        settingsLight.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(settingsLight.staticTexts["SETTINGS"].waitForExistence(timeout: 2))
        review.capture(settingsLight, "03 Settings — Light")
        settingsLight.terminate()

        let settingsDark = launch("dark")
        settingsDark.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(settingsDark.staticTexts["SETTINGS"].waitForExistence(timeout: 2))
        review.capture(settingsDark, "04 Settings — Dark")

        settingsDark.buttons["settingsHistoryLink"].tap()
        XCTAssertTrue(settingsDark.staticTexts["HISTORY"].waitForExistence(timeout: 2))
        review.capture(settingsDark, "05 History from Settings — Dark")
        settingsDark.terminate()

        let gardenLight = launch("light")
        gardenLight.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(gardenLight.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(gardenLight, "06 Garden — Light")
        gardenLight.terminate()

        let gardenDark = launch("dark")
        gardenDark.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(gardenDark.staticTexts["GARDEN"].waitForExistence(timeout: 2))
        review.capture(gardenDark, "07 Garden — Dark")
        gardenDark.terminate()

        let switchApp = launch("light")
        switchApp.tabBars.buttons["Settings"].tap()
        XCTAssertEqual(switchApp.descendants(matching: .any)["appearance-light"].value as? String, "Selected")
        switchApp.descendants(matching: .any)["appearance-dark"].tap()
        XCTAssertEqual(switchApp.descendants(matching: .any)["appearance-dark"].value as? String, "Selected")
        review.capture(switchApp, "08 Settings Light to Dark without relaunch")
        switchApp.terminate()

        let large = launch("light", extra: [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ])
        large.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(large.staticTexts["SETTINGS"].waitForExistence(timeout: 3))
        reveal(large.buttons["settingsHistoryLink"], in: large)
        review.capture(large, "09 Large Dynamic Type Settings")
        large.terminate()
    }

    // MARK: - V3-M2 Focus History Management

    @MainActor
    func testM2DeleteFocusSessionCancelAndConfirm() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_HISTORY", "UITEST_APPEARANCE", "light"]
        app.launch()

        openHistoryFromSettings(in: app)
        XCTAssertTrue(app.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["historyWeeklySummary"].waitForExistence(timeout: 2))

        let row = app.descendants(matching: .any)["historySession-Review amino acids"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeLeft()
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 2))
        delete.tap()

        XCTAssertTrue(app.buttons["Delete Session"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["historySession-Review amino acids"].waitForExistence(timeout: 2))

        let rowAgain = app.descendants(matching: .any)["historySession-Review amino acids"]
        rowAgain.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete Session"].waitForExistence(timeout: 2))
        app.buttons["Delete Session"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["historySession-Review amino acids"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["HISTORY"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["historyWeeklySummary"].exists)
    }

    @MainActor
    func testM2DeleteFocusSessionAccessibilityAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_HISTORY", "UITEST_APPEARANCE", "light"]
        app.launch()
        openHistoryFromSettings(in: app)

        let row = app.descendants(matching: .any)["historySession-Build Next"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        // VoiceOver-style delete affordance.
        row.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["Delete"].label, "Delete")
    }

    @MainActor
    func testM2VisualReview() throws {
        let review = FocusHistoryCapture(self)

        func launch(_ appearance: String, extra: [String] = []) -> XCUIApplication {
            let app = XCUIApplication()
            app.launchArguments = [
                "UITEST_SEED_HISTORY",
                "UITEST_APPEARANCE", appearance,
                "UITEST_REMINDER", "off"
            ] + extra
            app.launch()
            return app
        }

        let light = launch("light")
        openHistoryFromSettings(in: light)
        XCTAssertTrue(light.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        review.capture(light, "01 History — existing sessions Light")

        let row = light.descendants(matching: .any)["historySession-Review amino acids"]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeLeft()
        XCTAssertTrue(light.buttons["Delete"].waitForExistence(timeout: 2))
        review.capture(light, "02 History — delete affordance")

        light.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(light.buttons["Delete Session"].waitForExistence(timeout: 2))
        review.capture(light, "03 History — delete confirmation")

        light.buttons["Delete Session"].tap()
        XCTAssertFalse(light.descendants(matching: .any)["historySession-Review amino acids"].waitForExistence(timeout: 2))
        review.capture(light, "04 History — after deletion")
        light.terminate()

        let dark = launch("dark")
        openHistoryFromSettings(in: dark)
        XCTAssertTrue(dark.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        review.capture(dark, "05 History — Dark")
        dark.terminate()

        let large = launch("light", extra: [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ])
        openHistoryFromSettings(in: large)
        XCTAssertTrue(large.staticTexts["HISTORY"].waitForExistence(timeout: 3))
        reveal(large.descendants(matching: .any)["historyWeeklySummary"], in: large)
        review.capture(large, "06 History — Large Dynamic Type")
        large.terminate()
    }

    private func openHistoryFromSettings(in app: XCUIApplication) {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["settingsScreen"].waitForExistence(timeout: 2))
        let link = app.buttons["settingsHistoryLink"]
        reveal(link, in: app)
        XCTAssertTrue(link.waitForExistence(timeout: 2))
        link.tap()
    }

    // MARK: - V3-M1 Goal Organization & Recommendation Filtering

    @MainActor
    func testM1MultiAreaPlantEditAndScopeFiltering() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_MULTI_AREA", "UITEST_APPEARANCE", "light"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["homeGreeting"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["recommendationScopePicker"].exists)

        // Anything remains available and deterministic.
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Life area without selection → explicit empty, no silent fallback.
        app.segmentedControls.buttons["Life area"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["scopeAreaField"].waitForExistence(timeout: 2))
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["CHOOSE A FOCUS"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["chooseDifferentFocus"].exists)
        app.buttons["chooseDifferentFocus"].tap()

        // Choose Career — multi-area Build Next + Portfolio eligible; no duplicates via Not This One.
        app.descendants(matching: .any)["scopeAreaField"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["scopeAreaSheet"].waitForExistence(timeout: 2))
        app.descendants(matching: .any)["scopeArea-career"].tap()
        XCTAssertTrue(app.staticTexts["Career"].waitForExistence(timeout: 2))
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        var seen = Set<String>()
        for _ in 0..<6 {
            if let title = firstRecommendationTitle(in: app) {
                XCTAssertFalse(seen.contains(title), "Duplicate candidate \(title)")
                seen.insert(title)
            }
            let next = app.buttons["Not this one"]
            if next.exists && next.isEnabled {
                next.tap()
            } else {
                break
            }
        }
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Specific goal sheet uses stable IDs — identical titles remain distinct.
        app.segmentedControls.buttons["Specific goal"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["scopeGoalField"].waitForExistence(timeout: 2))
        app.descendants(matching: .any)["scopeGoalField"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["scopeGoalSheet"].waitForExistence(timeout: 2))
        let twinRows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "scopeGoal-"))
        XCTAssertGreaterThanOrEqual(twinRows.count, 2)
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Build Next"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["EDUCATION · CAREER · CREATIVE"].exists
                      || app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'EDUCATION' AND label CONTAINS 'CAREER'")).firstMatch.exists)
        let buildRows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "gardenGoal-Build Next"))
        XCTAssertEqual(buildRows.count, 1)
    }

    @MainActor
    func testM1LifeAreaSearchKeepsSelection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_IN_MEMORY", "UITEST_ONBOARDING_COMPLETED", "UITEST_APPEARANCE", "light"]
        app.launch()
        app.tabBars.buttons["Garden"].tap()
        app.buttons["+ PLANT A GOAL"].tap()
        let goalField = app.textFields["Goal title"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 2))
        goalField.tap()
        goalField.typeText("Multi Area Goal")

        app.descendants(matching: .any)["lifeAreasField"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["lifeAreasSheet"].waitForExistence(timeout: 2))
        app.descendants(matching: .any)["lifeArea-career"].tap()
        app.descendants(matching: .any)["lifeArea-creative"].tap()
        let search = app.textFields["Search life areas"]
        XCTAssertTrue(search.waitForExistence(timeout: 2))
        search.tap()
        search.typeText("Edu")
        XCTAssertTrue(app.descendants(matching: .any)["lifeArea-education"].waitForExistence(timeout: 2))
        app.descendants(matching: .any)["lifeArea-education"].tap()
        // Career/Creative remain selected even though filtered out of the visible list.
        app.buttons["lifeAreasDone"].tap()
        let areasField = app.descendants(matching: .any)["lifeAreasField"]
        XCTAssertTrue(areasField.waitForExistence(timeout: 2))
        let value = areasField.value as? String ?? ""
        XCTAssertTrue(
            value == "Education · Career · Creative" || (value.contains("Career") && value.contains("Education")),
            "Expected multi-area selection to survive search; got \(value)"
        )
        app.buttons["PLANT GOAL →"].tap()
        XCTAssertTrue(app.staticTexts["Multi Area Goal"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testM1VisualReview() throws {
        let review = GoalOrganizationCapture(self)

        func launch(_ appearance: String, extra: [String] = []) -> XCUIApplication {
            let app = XCUIApplication()
            app.launchArguments = [
                "UITEST_SEED_MULTI_AREA",
                "UITEST_APPEARANCE", appearance,
                "UITEST_REMINDER", "off"
            ] + extra
            app.launch()
            return app
        }

        // 01 — Plant a Goal, multiple areas selected, Light
        let plant = launch("light")
        plant.tabBars.buttons["Garden"].tap()
        plant.buttons["+ PLANT A GOAL"].tap()
        let plantField = plant.textFields["Goal title"]
        XCTAssertTrue(plantField.waitForExistence(timeout: 2))
        plantField.tap()
        plantField.typeText("Ship V3")
        selectLifeAreas(["Creative", "Career", "Education"], in: plant)
        review.capture(plant, "01 Plant a Goal — multiple areas Light")
        plant.terminate()

        // 02 — Edit Goal, multiple areas, Dark
        let edit = launch("dark")
        edit.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(edit.staticTexts["Build Next"].waitForExistence(timeout: 2))
        edit.staticTexts["Build Next"].tap()
        tapGoalOptions(in: edit)
        edit.buttons["Edit Goal"].tap()
        XCTAssertTrue(edit.staticTexts["EDIT GOAL"].waitForExistence(timeout: 2))
        review.capture(edit, "02 Edit Goal — multiple areas Dark")

        // 03 — Searchable multi-select area sheet
        edit.descendants(matching: .any)["lifeAreasField"].tap()
        XCTAssertTrue(edit.descendants(matching: .any)["lifeAreasSheet"].waitForExistence(timeout: 2))
        review.capture(edit, "03 Searchable multi-select area sheet")
        edit.buttons["lifeAreasDone"].tap()
        edit.terminate()

        // 04 — Garden with multi-area goal, Light
        let garden = launch("light")
        garden.tabBars.buttons["Garden"].tap()
        XCTAssertTrue(garden.staticTexts["Build Next"].waitForExistence(timeout: 2))
        review.capture(garden, "04 Garden — multi-area goal Light")
        garden.terminate()

        // 05 — Home, Anything
        let homeAnything = launch("light")
        XCTAssertTrue(homeAnything.descendants(matching: .any)["homeGreeting"].waitForExistence(timeout: 3))
        review.capture(homeAnything, "05 Home — Anything selected")

        // 06 — Home, Life area selected
        homeAnything.segmentedControls.buttons["Life area"].tap()
        homeAnything.descendants(matching: .any)["scopeAreaField"].tap()
        XCTAssertTrue(homeAnything.descendants(matching: .any)["scopeAreaSheet"].waitForExistence(timeout: 2))
        homeAnything.descendants(matching: .any)["scopeArea-career"].tap()
        XCTAssertTrue(homeAnything.staticTexts["Career"].waitForExistence(timeout: 2))
        review.capture(homeAnything, "06 Home — Life area selected")

        // 07 — Searchable goal-selection sheet
        homeAnything.segmentedControls.buttons["Specific goal"].tap()
        homeAnything.descendants(matching: .any)["scopeGoalField"].tap()
        XCTAssertTrue(homeAnything.descendants(matching: .any)["scopeGoalSheet"].waitForExistence(timeout: 2))
        review.capture(homeAnything, "07 Searchable goal-selection sheet")
        let firstGoal = homeAnything.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "scopeGoal-")
        ).element(boundBy: 0)
        XCTAssertTrue(firstGoal.waitForExistence(timeout: 2))
        firstGoal.tap()

        // 08 — Home, Specific goal selected
        XCTAssertTrue(homeAnything.descendants(matching: .any)["scopeGoalField"].waitForExistence(timeout: 2))
        review.capture(homeAnything, "08 Home — Specific goal selected")

        // 09 — Empty filtered recommendation state
        homeAnything.segmentedControls.buttons["Life area"].tap()
        homeAnything.descendants(matching: .any)["scopeAreaField"].tap()
        homeAnything.descendants(matching: .any)["scopeArea-finance"].tap()
        homeAnything.buttons["15 min"].tap()
        homeAnything.buttons["Ready"].tap()
        homeAnything.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(
            homeAnything.staticTexts["NOTHING IN THIS FOCUS"].waitForExistence(timeout: 2)
                || homeAnything.staticTexts["NOTHING FITS RIGHT NOW"].waitForExistence(timeout: 2)
                || homeAnything.staticTexts["CHOOSE A FOCUS"].waitForExistence(timeout: 2)
        )
        review.capture(homeAnything, "09 Empty filtered recommendation state")
        homeAnything.terminate()

        // 10 — Large Dynamic Type selection sheet
        let large = launch("light", extra: [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ])
        large.tabBars.buttons["Garden"].tap()
        large.buttons["+ PLANT A GOAL"].tap()
        XCTAssertTrue(large.descendants(matching: .any)["lifeAreasField"].waitForExistence(timeout: 3))
        reveal(large.descendants(matching: .any)["lifeAreasField"], in: large)
        large.descendants(matching: .any)["lifeAreasField"].tap()
        XCTAssertTrue(large.descendants(matching: .any)["lifeAreasSheet"].waitForExistence(timeout: 2))
        review.capture(large, "10 Large Dynamic Type selection sheet")
        large.terminate()
    }

    private func firstRecommendationTitle(in app: XCUIApplication) -> String? {
        let candidates = ["Sketch the garden", "Update project description", "Review amino acids", "Review flashcards", "Clean your space", "Twin A workout", "Twin B stretch"]
        return candidates.first { app.staticTexts[$0].exists }
    }

    /// Replacement capture for enabled-state DONE safe-area spacing (shot 03 only).
    @MainActor
    func testSmartRemindersEnabledSpacingScreenshot() throws {
        let review = SmartRemindersCapture(self)
        let enabled = XCUIApplication()
        enabled.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "on",
            "UITEST_REMINDER_HOUR", "9",
            "UITEST_REMINDER_MINUTE", "30",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        enabled.launch()
        XCTAssertTrue(enabled.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        enabled.buttons["appearanceButton"].tap()
        XCTAssertTrue(enabled.descendants(matching: .any)["preferencesSheet"].waitForExistence(timeout: 2))
        XCTAssertEqual(enabled.switches["dailyReminderToggle"].value as? String, "1")
        XCTAssertTrue(enabled.descendants(matching: .any)["dailyReminderTime"].waitForExistence(timeout: 2))
        let done = enabled.buttons["DONE"]
        XCTAssertTrue(done.waitForExistence(timeout: 2))
        XCTAssertTrue(done.isHittable)
        // Assert clearance: DONE must sit above the home indicator, not flush to it.
        let doneFrame = done.frame
        let appFrame = enabled.frame
        XCTAssertGreaterThan(
            appFrame.maxY - doneFrame.maxY,
            28,
            "DONE should clear the bottom safe area / home indicator"
        )
        review.capture(enabled, "03 Reminder enabled with selected time")
        enabled.terminate()
    }

    @MainActor
    func testSmartRemindersVisualReview() throws {
        let review = SmartRemindersCapture(self)

        let light = XCUIApplication()
        light.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "off",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        light.launch()
        XCTAssertTrue(light.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        light.buttons["appearanceButton"].tap()
        revealReminders(in: light)
        review.capture(light, "01 Reminder settings — Light")
        light.terminate()

        let dark = XCUIApplication()
        dark.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "dark",
            "UITEST_REMINDER", "off",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        dark.launch()
        XCTAssertTrue(dark.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        dark.buttons["appearanceButton"].tap()
        revealReminders(in: dark)
        review.capture(dark, "02 Reminder settings — Dark")
        dark.terminate()

        let enabled = XCUIApplication()
        enabled.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "on",
            "UITEST_REMINDER_HOUR", "9",
            "UITEST_REMINDER_MINUTE", "30",
            "UITEST_REMINDER_AUTH", "authorized"
        ]
        enabled.launch()
        XCTAssertTrue(enabled.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        enabled.buttons["appearanceButton"].tap()
        revealReminders(in: enabled)
        XCTAssertEqual(enabled.switches["dailyReminderToggle"].value as? String, "1")
        XCTAssertTrue(enabled.descendants(matching: .any)["dailyReminderTime"].waitForExistence(timeout: 2))
        XCTAssertTrue(enabled.staticTexts["dailyReminderTimeSummary"].waitForExistence(timeout: 2))
        review.capture(enabled, "03 Reminder enabled with selected time")
        enabled.terminate()

        let denied = XCUIApplication()
        denied.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "off",
            "UITEST_REMINDER_AUTH", "denied"
        ]
        denied.launch()
        XCTAssertTrue(denied.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        denied.buttons["appearanceButton"].tap()
        revealReminders(in: denied)
        denied.switches["dailyReminderToggle"].tap()
        XCTAssertTrue(denied.buttons["openNotificationSettings"].waitForExistence(timeout: 2))
        reveal(denied.buttons["openNotificationSettings"], in: denied)
        review.capture(denied, "04 Permission denied — open iOS Settings")
        denied.terminate()

        let large = XCUIApplication()
        large.launchArguments = [
            "UITEST_SEED_GARDEN",
            "UITEST_APPEARANCE", "light",
            "UITEST_REMINDER", "on",
            "UITEST_REMINDER_HOUR", "9",
            "UITEST_REMINDER_MINUTE", "0",
            "UITEST_REMINDER_AUTH", "authorized",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityL"
        ]
        large.launch()
        XCTAssertTrue(large.staticTexts["Good afternoon."].waitForExistence(timeout: 3))
        large.buttons["appearanceButton"].tap()
        revealReminders(in: large)
        reveal(large.switches["dailyReminderToggle"], in: large)
        review.capture(large, "05 Large Dynamic Type reminder settings")
        large.terminate()
    }

    private func revealReminders(in app: XCUIApplication) {
        let reminders = app.staticTexts["REMINDERS"]
        XCTAssertTrue(reminders.waitForExistence(timeout: 2))
        reveal(reminders, in: app)
        let toggle = app.switches["dailyReminderToggle"]
        if toggle.waitForExistence(timeout: 1) {
            reveal(toggle, in: app)
        }
    }

    private func launchGardenEvolutionApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_GARDEN_EVOLUTION"]
        app.launch()
        return app
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
        XCTAssertTrue(app.descendants(matching: .any)["homeGreeting"].waitForExistence(timeout: 2))
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
        while attempts < 8 && (!element.exists || !element.isHittable) {
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

    private func addTaskOnCurrentGoal(
        in app: XCUIApplication,
        title: String,
        duration: String,
        energy: String
    ) {
        app.buttons["+ ADD TASK"].tap()
        let taskField = app.textFields["Task title"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText(title)
        app.buttons[duration].tap()
        app.buttons[energy].tap()
        app.buttons["ADD TASK →"].tap()
        XCTAssertTrue(app.buttons["+ ADD TASK"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts[title].exists
                || app.descendants(matching: .any)["goalTask-\(title)"].exists
        )
    }

    @MainActor
    private func completeRecommendedSession(
        in app: XCUIApplication,
        answer: String,
        exit: String
    ) {
        app.buttons["30 min"].tap()
        app.buttons["Good"].tap()
        app.buttons["WHAT'S NEXT?"].tap()
        XCTAssertTrue(app.staticTexts["YOUR NEXT MOVE"].waitForExistence(timeout: 2))
        app.buttons["START SESSION →"].tap()
        XCTAssertTrue(app.buttons["Finish early"].waitForExistence(timeout: 2))
        app.buttons["Finish early"].tap()
        XCTAssertTrue(app.staticTexts["NICE WORK."].waitForExistence(timeout: 2))
        app.buttons[answer].tap()
        app.buttons[exit].tap()
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

    private func launchManagementApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SEED_MANAGEMENT"]
        app.launch()
        return app
    }

    private func openHome(in app: XCUIApplication) {
        app.tabBars.buttons["Home"].tap()
        if app.buttons["START SESSION →"].waitForExistence(timeout: 1) {
            app.buttons["Back"].firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["WHAT'S NEXT?"].waitForExistence(timeout: 3))
    }

    private func assertHistoryRow(task: String, goal: String, in app: XCUIApplication) {
        let row = app.descendants(matching: .any)["historySession-\(task)"]
        XCTAssertTrue(row.waitForExistence(timeout: 3), "Missing history row for \(task)")
        let label = row.label
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains(goal)
                || app.staticTexts[goal.uppercased()].exists
                || app.staticTexts[task].exists,
            "History row missing \(task) / \(goal); label=\(label)"
        )
    }

    private func tapFocusSettings(in app: XCUIApplication) {
        let button = app.buttons["Focus settings"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 2))
        button.tap()
    }

    private func tapGoalOptions(in app: XCUIApplication) {
        let button = app.buttons["goalOptions"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 2))
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func openGardenGoal(_ title: String, in app: XCUIApplication) {
        if !app.buttons["+ ADD TASK"].exists {
            app.tabBars.buttons["Garden"].tap()
            XCTAssertTrue(app.staticTexts["GARDEN"].waitForExistence(timeout: 2))
            let row = gardenRow(title, in: app)
            reveal(row, in: app)
            XCTAssertTrue(row.waitForExistence(timeout: 3), "Missing Garden row \(title)")
            row.tap()
        }
        XCTAssertTrue(app.buttons["+ ADD TASK"].waitForExistence(timeout: 4), "Did not open Goal \(title)")
    }

    private func openVisibleTaskMenu(_ title: String, completed: Bool = false, in app: XCUIApplication) {
        let manage = app.buttons["Manage \(title)"].firstMatch
        XCTAssertTrue(manage.waitForExistence(timeout: 2))
        manage.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(
            app.buttons["Edit \(title)"].waitForExistence(timeout: 2)
                || app.menuItems["Edit \(title)"].waitForExistence(timeout: 2)
        )
    }

    private func openTaskMenu(_ title: String, completed: Bool = false, in app: XCUIApplication) {
        let identifier = completed ? "completedTask-\(title)" : "goalTask-\(title)"
        let row = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        let editTitle = "Edit \(title)"
        if app.buttons[editTitle].exists || app.menuItems[editTitle].exists {
            return
        }
        row.press(forDuration: 1.2)
        XCTAssertTrue(
            app.buttons[editTitle].waitForExistence(timeout: 3)
                || app.menuItems[editTitle].waitForExistence(timeout: 3)
        )
    }

    private func openTaskEditor(_ title: String, completed: Bool = false, in app: XCUIApplication) {
        openTaskMenu(title, completed: completed, in: app)
        tapMenuButton("Edit \(title)", in: app)
    }

    private func tapMenuButton(_ title: String, in app: XCUIApplication) {
        let button = app.buttons[title]
        if button.waitForExistence(timeout: 2) {
            button.tap()
        } else {
            XCTAssertTrue(app.menuItems[title].waitForExistence(timeout: 2))
            app.menuItems[title].tap()
        }
    }

    private func replaceText(in field: XCUIElement, with text: String) {
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        if let value = field.value as? String, !value.isEmpty {
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
            field.typeText(delete)
        }
        field.typeText(text)
    }

    private func dismissKeyboard(in app: XCUIApplication) {
        let toolbarDone = app.toolbars.buttons["Done"]
        if toolbarDone.exists {
            toolbarDone.tap()
        }
    }
}

/// Shared review-shot helper. XCTAttachments always attach; disk writes to Review/
/// only when UITEST_WRITE_REVIEW_SHOTS=1 (keeps regression runs from rewriting
/// completed-milestone PNGs).
private enum ReviewShotStore {
    static var writesToDisk: Bool {
        ProcessInfo.processInfo.environment["UITEST_WRITE_REVIEW_SHOTS"] == "1"
            || ProcessInfo.processInfo.environment["TEST_RUNNER_UITEST_WRITE_REVIEW_SHOTS"] == "1"
            || ProcessInfo.processInfo.arguments.contains("UITEST_WRITE_REVIEW_SHOTS")
    }

    static func capture(
        _ app: XCUIApplication,
        named name: String,
        into directory: URL,
        test: XCTestCase,
        forceDiskWrite: Bool = false
    ) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)

        guard forceDiskWrite || writesToDisk else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: file)
    }
}

private struct AppearanceCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M6-Dynamic-Appearance"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct SmartRemindersCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M7-Smart-Reminders"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct DesignRefinementCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M9-QA-Design-Refinement"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        // Active milestone review: always write M9 shots.
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test, forceDiskWrite: true)
    }
}

private struct GardenEvolutionCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M5-Garden-Evolution"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct FinalCleanupCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M4-Final-Cleanup"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct FocusExperienceCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M4-Focus-Experience"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct ManagementCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M3-Goal-Task-Management"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct RecommendationEngineCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M2-Recommendation-Engine"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct TaskLifecycleCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V2-M1-Task-Lifecycle"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct WalkthroughCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V1-Walkthrough"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test)
    }
}

private struct GoalOrganizationCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V3-M1-Goal-Organization"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test, forceDiskWrite: true)
    }
}

private struct FocusHistoryCapture {
    static let directory = URL(fileURLWithPath:
        "/Users/luachristian/Documents/Personal Projects/Next/Review/V3-M2-Focus-History-Management"
    )
    let test: XCTestCase
    init(_ test: XCTestCase) { self.test = test }
    func capture(_ app: XCUIApplication, _ name: String) {
        ReviewShotStore.capture(app, named: name, into: Self.directory, test: test, forceDiskWrite: true)
    }
}
