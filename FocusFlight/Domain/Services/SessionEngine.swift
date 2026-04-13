import Foundation

struct SessionSnapshot {
    let progress: Double
    let remainingSeconds: Int
    let distanceTraveledKm: Int
    let distanceRemainingKm: Int
}

struct SessionEngine {
    func expectedEndDate(startedAt: Date, plannedMinutes: Int, pausedAccumulatedSeconds: TimeInterval = 0) -> Date {
        startedAt.addingTimeInterval(Double(plannedMinutes * 60) + pausedAccumulatedSeconds)
    }

    func elapsedSeconds(now: Date, startedAt: Date, pausedAccumulatedSeconds: TimeInterval = 0) -> TimeInterval {
        max(0, now.timeIntervalSince(startedAt) - pausedAccumulatedSeconds)
    }

    func progress(now: Date, startedAt: Date, plannedMinutes: Int, pausedAccumulatedSeconds: TimeInterval = 0) -> Double {
        let total = max(Double(plannedMinutes * 60), 1)
        let value = elapsedSeconds(now: now, startedAt: startedAt, pausedAccumulatedSeconds: pausedAccumulatedSeconds) / total
        return min(max(value, 0), 1)
    }

    func snapshot(
        now: Date,
        startedAt: Date,
        plannedMinutes: Int,
        routeDistanceKm: Int,
        pausedAccumulatedSeconds: TimeInterval = 0
    ) -> SessionSnapshot {
        let progress = progress(
            now: now,
            startedAt: startedAt,
            plannedMinutes: plannedMinutes,
            pausedAccumulatedSeconds: pausedAccumulatedSeconds
        )
        let totalSeconds = plannedMinutes * 60
        let remaining = max(0, totalSeconds - Int(elapsedSeconds(now: now, startedAt: startedAt, pausedAccumulatedSeconds: pausedAccumulatedSeconds)))
        let distanceTraveled = Int((Double(routeDistanceKm) * progress).rounded())
        return SessionSnapshot(
            progress: progress,
            remainingSeconds: remaining,
            distanceTraveledKm: distanceTraveled,
            distanceRemainingKm: max(0, routeDistanceKm - distanceTraveled)
        )
    }
}
