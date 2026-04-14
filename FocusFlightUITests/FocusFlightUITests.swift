import XCTest

final class AurelineUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testShellFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTestingInMemory")
        app.launch()

        app.buttons["home.changeRoute"].tap()
        app.buttons["route.sea-ord"].tap()
        app.buttons["50m"].tap()
        app.buttons["home.startFlight"].tap()

        XCTAssertTrue(app.staticTexts["In Flight"].waitForExistence(timeout: 2))

        app.buttons["session.soundToggle"].tap()
        app.buttons["session.soundToggle"].tap()
        app.sliders["session.volume"].adjust(toNormalizedSliderPosition: 0.35)

        app.buttons["session.pauseResume"].tap()
        app.buttons["session.pauseResume"].tap()
        app.buttons["session.cancel"].tap()
        app.buttons["Cancel Flight"].tap()
    }

    @MainActor
    func testActiveSessionRestoresAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launchEnvironment["AURELINE_STORE_NAME"] = "UITestRestore-\(UUID().uuidString)"
        app.launch()

        app.buttons["home.startFlight"].tap()
        XCTAssertTrue(app.staticTexts["session.remainingTime"].waitForExistence(timeout: 2))

        app.terminate()
        app.launch()

        XCTAssertTrue(app.staticTexts["session.remainingTime"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["session.pauseResume"].exists)
        app.buttons["session.cancel"].tap()
        app.buttons["Cancel Flight"].tap()
    }
}
