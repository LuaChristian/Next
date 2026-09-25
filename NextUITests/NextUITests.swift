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
        let app = XCUIApplication()
        app.launch()

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
        XCTAssertTrue(app.staticTexts["Clean your space"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Review amino acids"].exists)

        notThisOne.tap()
        XCTAssertTrue(app.staticTexts["Review flashcards"].waitForExistence(timeout: 2))
        XCTAssertFalse(notThisOne.isEnabled)

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["Good afternoon."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["30 min"].isSelected)
        XCTAssertTrue(app.buttons["Good"].isSelected)
        XCTAssertTrue(whatsNext.isEnabled)
    }
}
