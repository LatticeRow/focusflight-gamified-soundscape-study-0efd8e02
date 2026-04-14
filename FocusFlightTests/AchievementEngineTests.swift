import XCTest
@testable import Aureline

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

    func testAchievementProgressUsesStoredSessionsDeterministically() {
        let engine = AchievementEngine()
        let sessions = [
            makeCompletedSession(minutes: 25, completedAtHour: 10, dayOffset: 0),
            makeCompletedSession(minutes: 50, completedAtHour: 12, dayOffset: 1),
            makeCompletedSession(minutes: 90, completedAtHour: 14, dayOffset: 2),
            makeCompletedSession(minutes: 50, completedAtHour: 16, dayOffset: 3),
            makeCompletedSession(minutes: 100, completedAtHour: 22, dayOffset: 4),
        ]

        let progress = Dictionary(
            uniqueKeysWithValues: engine.achievementProgress(for: sessions).map { ($0.id, $0) }
        )

        XCTAssertEqual(progress["first-flight"]?.progressLabel, "1/1")
        XCTAssertTrue(progress["first-flight"]?.isUnlocked == true)
        XCTAssertTrue(progress["frequent-flyer"]?.isUnlocked == true)
        XCTAssertEqual(progress["long-haul"]?.progressLabel, "300/300m")
        XCTAssertTrue(progress["long-haul"]?.isUnlocked == true)
        XCTAssertTrue(progress["red-eye"]?.isUnlocked == true)
        XCTAssertNotNil(progress["frequent-flyer"]?.unlockedAt)
    }

    func testAchievementProgressIgnoresIncompleteSessions() {
        let engine = AchievementEngine()
        let sessions = [
            makeCompletedSession(minutes: 25, completedAtHour: 10, dayOffset: 0),
            makeSession(minutes: 50, status: .active, completedAtHour: 22, dayOffset: 1),
            makeSession(minutes: 90, status: .cancelled, completedAtHour: 23, dayOffset: 2),
        ]

        let progress = Dictionary(
            uniqueKeysWithValues: engine.achievementProgress(for: sessions).map { ($0.id, $0) }
        )

        XCTAssertTrue(progress["first-flight"]?.isUnlocked == true)
        XCTAssertFalse(progress["frequent-flyer"]?.isUnlocked == true)
        XCTAssertEqual(progress["long-haul"]?.progressLabel, "25/300m")
        XCTAssertFalse(progress["red-eye"]?.isUnlocked == true)
    }

    func testAchievementUnlockedDatesReflectEarliestQualifyingCompletion() {
        let engine = AchievementEngine()
        let sessions = [
            makeCompletedSession(minutes: 25, completedAtHour: 9, dayOffset: 0),
            makeCompletedSession(minutes: 50, completedAtHour: 10, dayOffset: 1),
            makeCompletedSession(minutes: 90, completedAtHour: 11, dayOffset: 2),
            makeCompletedSession(minutes: 50, completedAtHour: 12, dayOffset: 3),
            makeCompletedSession(minutes: 100, completedAtHour: 22, dayOffset: 4),
        ]

        let progress = Dictionary(
            uniqueKeysWithValues: engine.achievementProgress(for: sessions).map { ($0.id, $0) }
        )

        XCTAssertEqual(
            progress["first-flight"]?.unlockedAt,
            sessions[0].completedAt
        )
        XCTAssertEqual(
            progress["frequent-flyer"]?.unlockedAt,
            sessions[4].completedAt
        )
        XCTAssertEqual(
            progress["long-haul"]?.unlockedAt,
            sessions[4].completedAt
        )
        XCTAssertEqual(
            progress["red-eye"]?.unlockedAt,
            sessions[4].completedAt
        )
    }

    private func makeCompletedSession(minutes: Int, completedAtHour: Int, dayOffset: Int) -> FocusSession {
        makeSession(
            minutes: minutes,
            status: .completed,
            completedAtHour: completedAtHour,
            dayOffset: dayOffset
        )
    }

    private func makeSession(
        minutes: Int,
        status: FocusSession.Status,
        completedAtHour: Int,
        dayOffset: Int
    ) -> FocusSession {
        let calendar = Calendar.current
        let completedAt = calendar.date(
            from: DateComponents(year: 2026, month: 4, day: 13 + dayOffset, hour: completedAtHour, minute: 0)
        )!

        return FocusSession(
            routeID: "route-\(dayOffset)",
            routeThemeName: "Route \(dayOffset)",
            originCode: "SFO",
            destinationCode: "JFK",
            startedAt: completedAt.addingTimeInterval(TimeInterval(-minutes * 60)),
            expectedEndAt: completedAt,
            completedAt: status == .completed ? completedAt : nil,
            cancelledAt: status == .cancelled ? completedAt : nil,
            plannedMinutes: minutes,
            status: status,
            selectedAudioTrackID: UserPreferences.AudioTrack.steady.id,
            completionPercent: status == .completed ? 1 : 0.25,
            elapsedFocusSeconds: status == .completed ? minutes * 60 : 300,
            traveledDistanceKm: status == .completed ? 4_162 : 900,
            remainingDistanceKm: status == .completed ? 0 : 3_262
        )
    }
}
