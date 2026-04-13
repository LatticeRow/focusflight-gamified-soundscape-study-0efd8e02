import Foundation
import SwiftData

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var routeID: String
    var startedAt: Date
    var expectedEndAt: Date
    var completedAt: Date?
    var plannedMinutes: Int
    var statusRawValue: String
    var pausedAccumulatedSeconds: Double
    var selectedAudioTrackID: String
    var completionPercent: Double

    init(
        id: UUID = UUID(),
        routeID: String,
        startedAt: Date,
        expectedEndAt: Date,
        completedAt: Date? = nil,
        plannedMinutes: Int,
        statusRawValue: String,
        pausedAccumulatedSeconds: Double = 0,
        selectedAudioTrackID: String,
        completionPercent: Double = 0
    ) {
        self.id = id
        self.routeID = routeID
        self.startedAt = startedAt
        self.expectedEndAt = expectedEndAt
        self.completedAt = completedAt
        self.plannedMinutes = plannedMinutes
        self.statusRawValue = statusRawValue
        self.pausedAccumulatedSeconds = pausedAccumulatedSeconds
        self.selectedAudioTrackID = selectedAudioTrackID
        self.completionPercent = completionPercent
    }
}
