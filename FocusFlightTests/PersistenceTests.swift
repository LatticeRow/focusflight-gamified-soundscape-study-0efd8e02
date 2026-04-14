import SwiftData
import XCTest
@testable import Aureline

final class PersistenceTests: XCTestCase {
    @MainActor
    func testInMemoryContainerCanSaveActiveAndCompletedSessionsWithStamp() throws {
        let container = SwiftDataContainer.makeDefaultContainer(inMemory: true)
        let context = ModelContext(container)

        let activeSession = FocusSession(
            routeID: "sea-ord",
            routeThemeName: "Cloudline",
            originCode: "SEA",
            destinationCode: "ORD",
            startedAt: Date(),
            expectedEndAt: Date().addingTimeInterval(3_000),
            plannedMinutes: 50,
            status: .active,
            selectedAudioTrackID: "rain",
            completionPercent: 0.35,
            elapsedFocusSeconds: 1_050,
            traveledDistanceKm: 973,
            remainingDistanceKm: 1_807
        )

        let completedSession = FocusSession(
            routeID: "sfo-jfk",
            routeThemeName: "Coastal Red-Eye",
            originCode: "SFO",
            destinationCode: "JFK",
            startedAt: Date(),
            expectedEndAt: Date().addingTimeInterval(1_500),
            completedAt: Date(),
            plannedMinutes: 25,
            status: .completed,
            selectedAudioTrackID: "steady",
            completionPercent: 1,
            elapsedFocusSeconds: 1_500,
            traveledDistanceKm: 4_162,
            remainingDistanceKm: 0
        )

        let stamp = PassportStamp(
            sessionID: completedSession.id,
            awardedAt: Date(),
            title: "Coastal Red-Eye",
            originCode: "SFO",
            destinationCode: "JFK",
            minutesFlown: 25,
            badgeStyle: "gold"
        )

        context.insert(activeSession)
        context.insert(completedSession)
        context.insert(stamp)
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let stamps = try context.fetch(FetchDescriptor<PassportStamp>())

        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(stamps.count, 1)
        XCTAssertEqual(sessions.first(where: { $0.routeID == "sea-ord" })?.status, .active)
        XCTAssertEqual(sessions.first(where: { $0.routeID == "sfo-jfk" })?.status, .completed)
        XCTAssertEqual(sessions.first(where: { $0.routeID == "sfo-jfk" })?.traveledDistanceKm, 4_162)
        XCTAssertEqual(sessions.first(where: { $0.routeID == "sfo-jfk" })?.remainingDistanceKm, 0)
    }

    @MainActor
    func testSeedRoutesLoadWithSupportedBundledTracks() {
        let routes = SeedDataLoader.loadRoutes()
        let trackIDs = Set(SeedDataLoader.bundledAudioTracks.map(\.id))

        XCTAssertGreaterThanOrEqual(routes.count, 8)
        XCTAssertTrue(routes.allSatisfy { trackIDs.contains($0.audioTrackID) })
    }

    @MainActor
    func testPreferencesPersistDurationTrackVolumeAndHaptics() {
        let suiteName = "PersistenceTests.\(#function)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let preferences = UserPreferences(defaults: defaults)
        preferences.defaultDurationMinutes = 50
        preferences.defaultAudioTrackID = UserPreferences.AudioTrack.night.id
        preferences.audioVolume = 0.41
        preferences.hapticsEnabled = false

        let reloaded = UserPreferences(defaults: defaults)
        XCTAssertEqual(reloaded.defaultDurationMinutes, 50)
        XCTAssertEqual(reloaded.defaultAudioTrackID, UserPreferences.AudioTrack.night.id)
        XCTAssertEqual(reloaded.audioVolume, 0.41, accuracy: 0.001)
        XCTAssertFalse(reloaded.hapticsEnabled)
    }

    @MainActor
    func testStampCreationIsIdempotentInMemory() throws {
        let container = SwiftDataContainer.makeDefaultContainer(inMemory: true)
        let context = ModelContext(container)
        let repository = SessionRepository()
        let completedSession = FocusSession(
            routeID: "bos-mia",
            routeThemeName: "Sunset Runway",
            originCode: "BOS",
            destinationCode: "MIA",
            startedAt: Date(timeIntervalSince1970: 10_000),
            expectedEndAt: Date(timeIntervalSince1970: 11_500),
            completedAt: Date(timeIntervalSince1970: 11_500),
            plannedMinutes: 25,
            status: .completed,
            selectedAudioTrackID: "steady",
            completionPercent: 1,
            elapsedFocusSeconds: 1_500,
            traveledDistanceKm: 2_025,
            remainingDistanceKm: 0
        )

        try repository.insert(completedSession, in: context)

        let firstStamp = try repository.stamp(for: completedSession, in: context)
        let secondStamp = try repository.stamp(for: completedSession, in: context)
        let savedStamps = try context.fetch(FetchDescriptor<PassportStamp>())

        XCTAssertEqual(firstStamp.id, secondStamp.id)
        XCTAssertEqual(savedStamps.count, 1)
        XCTAssertEqual(savedStamps.first?.sessionID, completedSession.id)
    }

    @MainActor
    func testInMemoryContainerRestoresPausedSessionStateAcrossContexts() throws {
        let container = SwiftDataContainer.makeDefaultContainer(inMemory: true)
        let writerContext = ModelContext(container)

        let pausedSession = FocusSession(
            routeID: "lax-hnl",
            routeThemeName: "Pacific Dusk",
            originCode: "LAX",
            destinationCode: "HNL",
            startedAt: Date(timeIntervalSince1970: 20_000),
            expectedEndAt: Date(timeIntervalSince1970: 25_400),
            pausedAt: Date(timeIntervalSince1970: 20_900),
            plannedMinutes: 90,
            status: .paused,
            pausedAccumulatedSeconds: 600,
            selectedAudioTrackID: "night",
            completionPercent: 0.33,
            elapsedFocusSeconds: 1_800,
            traveledDistanceKm: 1_345,
            remainingDistanceKm: 2_811
        )

        writerContext.insert(pausedSession)
        try writerContext.save()

        let readerContext = ModelContext(container)
        let restoredSessions = try readerContext.fetch(FetchDescriptor<FocusSession>())
        let restored = try XCTUnwrap(restoredSessions.first)

        XCTAssertEqual(restored.status, .paused)
        XCTAssertEqual(restored.pausedAccumulatedSeconds, 600, accuracy: 0.001)
        XCTAssertEqual(restored.pausedAt, Date(timeIntervalSince1970: 20_900))
        XCTAssertEqual(restored.elapsedFocusSeconds, 1_800)
        XCTAssertEqual(restored.remainingDistanceKm, 2_811)
    }
}
