import XCTest
@testable import Aureline

final class SessionEngineTests: XCTestCase {
    private let engine = SessionEngine()
    private let route = FlightRoute.placeholder

    func testStartSessionComputesExpectedEndTimeAndInitialDistance() {
        let startedAt = Date(timeIntervalSince1970: 1_000)

        let session = engine.startSession(
            route: route,
            plannedMinutes: 25,
            selectedAudioTrackID: UserPreferences.AudioTrack.steady.id,
            startedAt: startedAt
        )

        XCTAssertEqual(session.startedAt, startedAt)
        XCTAssertEqual(session.expectedEndAt.timeIntervalSince(startedAt), 1_500, accuracy: 0.001)
        XCTAssertEqual(session.remainingDistanceKm, route.distanceKm)
        XCTAssertEqual(session.traveledDistanceKm, 0)
    }

    func testProgressMathAcrossSession() {
        let startedAt = Date(timeIntervalSince1970: 0)

        XCTAssertEqual(engine.progress(now: startedAt, startedAt: startedAt, plannedMinutes: 50), 0, accuracy: 0.001)
        XCTAssertEqual(
            engine.progress(now: startedAt.addingTimeInterval(1_500), startedAt: startedAt, plannedMinutes: 50),
            0.5,
            accuracy: 0.001
        )
        XCTAssertEqual(
            engine.progress(now: startedAt.addingTimeInterval(3_000), startedAt: startedAt, plannedMinutes: 50),
            1,
            accuracy: 0.001
        )
    }

    func testPauseAndResumeAdjustRemainingTime() {
        let startedAt = Date(timeIntervalSince1970: 10_000)
        let session = engine.startSession(
            route: route,
            plannedMinutes: 25,
            selectedAudioTrackID: UserPreferences.AudioTrack.steady.id,
            startedAt: startedAt
        )

        let pausedSnapshot = engine.pause(
            session,
            at: startedAt.addingTimeInterval(600),
            routeDistanceKm: route.distanceKm
        )
        XCTAssertEqual(session.status, .paused)
        XCTAssertEqual(pausedSnapshot.elapsedSeconds, 600)
        XCTAssertEqual(pausedSnapshot.remainingSeconds, 900)

        let restoredWhilePaused = engine.restore(
            session,
            routeDistanceKm: route.distanceKm,
            now: startedAt.addingTimeInterval(1_200)
        )
        XCTAssertEqual(restoredWhilePaused.elapsedSeconds, 600)
        XCTAssertEqual(restoredWhilePaused.remainingSeconds, 900)

        _ = engine.resume(
            session,
            at: startedAt.addingTimeInterval(1_200),
            routeDistanceKm: route.distanceKm
        )

        let afterResume = engine.restore(
            session,
            routeDistanceKm: route.distanceKm,
            now: startedAt.addingTimeInterval(1_500)
        )
        XCTAssertEqual(session.status, .active)
        XCTAssertEqual(afterResume.elapsedSeconds, 900)
        XCTAssertEqual(afterResume.remainingSeconds, 600)
        XCTAssertEqual(session.expectedEndAt.timeIntervalSince(startedAt), 2_100, accuracy: 0.001)
    }

    func testDistanceSnapshotUsesNormalizedProgress() {
        let snapshot = engine.snapshot(
            now: Date(timeIntervalSince1970: 750),
            startedAt: Date(timeIntervalSince1970: 0),
            plannedMinutes: 25,
            routeDistanceKm: 2_001
        )

        XCTAssertEqual(snapshot.progress, 0.5, accuracy: 0.001)
        XCTAssertEqual(snapshot.distanceTraveledKm, 1_000)
        XCTAssertEqual(snapshot.distanceRemainingKm, 1_001)
    }

    func testRestoreCompletesOverdueActiveSession() {
        let startedAt = Date(timeIntervalSince1970: 20_000)
        let session = engine.startSession(
            route: route,
            plannedMinutes: 25,
            selectedAudioTrackID: UserPreferences.AudioTrack.steady.id,
            startedAt: startedAt
        )

        let restored = engine.restore(
            session,
            routeDistanceKm: route.distanceKm,
            now: startedAt.addingTimeInterval(1_800)
        )

        XCTAssertEqual(restored.progress, 1, accuracy: 0.001)
        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.elapsedFocusSeconds, 1_500)
        XCTAssertEqual(session.traveledDistanceKm, route.distanceKm)
        XCTAssertEqual(session.remainingDistanceKm, 0)
        XCTAssertNotNil(session.completedAt)
    }
}
