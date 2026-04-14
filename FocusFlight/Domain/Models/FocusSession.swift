import Foundation
import SwiftData

@Model
final class FocusSession {
    enum Status: String, Codable, CaseIterable {
        case active
        case paused
        case completed
        case cancelled
    }

    @Attribute(.unique) var id: UUID
    var routeID: String
    var routeThemeName: String
    var originCode: String
    var destinationCode: String
    var createdAt: Date
    var startedAt: Date
    var expectedEndAt: Date
    var pausedAt: Date?
    var completedAt: Date?
    var cancelledAt: Date?
    var plannedMinutes: Int
    var statusRawValue: String
    var pausedAccumulatedSeconds: Double
    var selectedAudioTrackID: String
    var completionPercent: Double

    init(
        id: UUID = UUID(),
        routeID: String,
        routeThemeName: String,
        originCode: String,
        destinationCode: String,
        createdAt: Date = .now,
        startedAt: Date,
        expectedEndAt: Date,
        pausedAt: Date? = nil,
        completedAt: Date? = nil,
        cancelledAt: Date? = nil,
        plannedMinutes: Int,
        status: Status,
        pausedAccumulatedSeconds: Double = 0,
        selectedAudioTrackID: String,
        completionPercent: Double = 0
    ) {
        self.id = id
        self.routeID = routeID
        self.routeThemeName = routeThemeName
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.expectedEndAt = expectedEndAt
        self.pausedAt = pausedAt
        self.completedAt = completedAt
        self.cancelledAt = cancelledAt
        self.plannedMinutes = plannedMinutes
        self.statusRawValue = status.rawValue
        self.pausedAccumulatedSeconds = pausedAccumulatedSeconds
        self.selectedAudioTrackID = selectedAudioTrackID
        self.completionPercent = completionPercent
    }

    var status: Status {
        get { Status(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }
}
