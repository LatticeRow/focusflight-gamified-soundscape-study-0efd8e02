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
    var elapsedFocusSeconds: Int
    var traveledDistanceKm: Int
    var remainingDistanceKm: Int

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
        completionPercent: Double = 0,
        elapsedFocusSeconds: Int = 0,
        traveledDistanceKm: Int = 0,
        remainingDistanceKm: Int = 0
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
        self.elapsedFocusSeconds = elapsedFocusSeconds
        self.traveledDistanceKm = traveledDistanceKm
        self.remainingDistanceKm = remainingDistanceKm
    }

    var status: Status {
        get { Status(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }

    var plannedDurationSeconds: Int {
        plannedMinutes * 60
    }

    var isActiveLike: Bool {
        status == .active || status == .paused
    }

    struct Result: Equatable {
        let completionPercent: Double
        let elapsedFocusSeconds: Int
        let traveledDistanceKm: Int
        let remainingDistanceKm: Int
    }

    var result: Result? {
        guard status == .completed else { return nil }
        return Result(
            completionPercent: completionPercent,
            elapsedFocusSeconds: elapsedFocusSeconds,
            traveledDistanceKm: traveledDistanceKm,
            remainingDistanceKm: remainingDistanceKm
        )
    }
}

extension FocusSession: Identifiable {}
