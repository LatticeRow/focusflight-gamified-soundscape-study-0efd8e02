import SwiftData
import XCTest
@testable import FocusFlight

final class PersistenceTests: XCTestCase {
    @MainActor
    func testInMemoryContainerCanSaveSessionAndStamp() throws {
        let container = SwiftDataContainer.makeDefaultContainer(inMemory: true)
        let context = ModelContext(container)

        let session = FocusSession(
            routeID: "sfo-jfk",
            startedAt: Date(),
            expectedEndAt: Date().addingTimeInterval(1_500),
            plannedMinutes: 25,
            statusRawValue: "completed",
            selectedAudioTrackID: "steady",
            completionPercent: 1
        )

        let stamp = PassportStamp(
            sessionID: session.id,
            awardedAt: Date(),
            title: "Coastal Red-Eye",
            originCode: "SFO",
            destinationCode: "JFK",
            minutesFlown: 25,
            badgeStyle: "gold"
        )

        context.insert(session)
        context.insert(stamp)
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<FocusSession>())
        let stamps = try context.fetch(FetchDescriptor<PassportStamp>())

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(stamps.count, 1)
    }
}
