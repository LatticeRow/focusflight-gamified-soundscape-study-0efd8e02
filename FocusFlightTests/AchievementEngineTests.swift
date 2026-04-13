import XCTest
@testable import FocusFlight

final class AchievementEngineTests: XCTestCase {
    func testUnlocksFirstFlightAndLongHaul() {
        let engine = AchievementEngine()
        let unlocked = engine.unlockedAchievements(
            sessionCount: 5,
            totalMinutes: 320,
            latestCompletion: nil
        )

        XCTAssertTrue(unlocked.contains("first-flight"))
        XCTAssertTrue(unlocked.contains("frequent-flyer"))
        XCTAssertTrue(unlocked.contains("long-haul"))
    }

    func testUnlocksRedEyeAfterNinePM() {
        let engine = AchievementEngine()
        let date = Calendar.current.date(
            from: DateComponents(year: 2026, month: 4, day: 13, hour: 22, minute: 15)
        )

        let unlocked = engine.unlockedAchievements(sessionCount: 1, totalMinutes: 25, latestCompletion: date)
        XCTAssertTrue(unlocked.contains("red-eye"))
    }
}
