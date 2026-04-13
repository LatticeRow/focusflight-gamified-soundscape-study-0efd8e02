import XCTest
@testable import FocusFlight

final class SessionEngineTests: XCTestCase {
    func testExpectedEndDateUsesPlannedMinutes() {
        let engine = SessionEngine()
        let start = Date(timeIntervalSince1970: 1_000)

        let end = engine.expectedEndDate(startedAt: start, plannedMinutes: 25)

        XCTAssertEqual(end.timeIntervalSince(start), 1_500, accuracy: 0.001)
    }

    func testProgressMathAcrossSession() {
        let engine = SessionEngine()
        let start = Date(timeIntervalSince1970: 0)

        XCTAssertEqual(engine.progress(now: start, startedAt: start, plannedMinutes: 50), 0, accuracy: 0.001)
        XCTAssertEqual(
            engine.progress(now: start.addingTimeInterval(1_500), startedAt: start, plannedMinutes: 50),
            0.5,
            accuracy: 0.001
        )
        XCTAssertEqual(
            engine.progress(now: start.addingTimeInterval(3_000), startedAt: start, plannedMinutes: 50),
            1,
            accuracy: 0.001
        )
    }
}
