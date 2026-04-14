import Foundation

struct SessionSnapshot: Equatable {
    let progress: Double
    let elapsedSeconds: Int
    let remainingSeconds: Int
    let distanceTraveledKm: Int
    let distanceRemainingKm: Int

    var isComplete: Bool {
        progress >= 1 || remainingSeconds == 0
    }
}

struct SessionEngine {
    func startSession(
        route: FlightRoute,
        plannedMinutes: Int,
        selectedAudioTrackID: String,
        startedAt: Date = .now
    ) -> FocusSession {
        FocusSession(
            routeID: route.id,
            routeThemeName: route.themeName,
            originCode: route.originCode,
            destinationCode: route.destinationCode,
            startedAt: startedAt,
            expectedEndAt: expectedEndDate(startedAt: startedAt, plannedMinutes: plannedMinutes),
            plannedMinutes: plannedMinutes,
            status: .active,
            selectedAudioTrackID: selectedAudioTrackID,
            remainingDistanceKm: route.distanceKm
        )
    }

    func expectedEndDate(
        startedAt: Date,
        plannedMinutes: Int,
        pausedAccumulatedSeconds: TimeInterval = 0
    ) -> Date {
        startedAt.addingTimeInterval(Double(plannedMinutes * 60) + pausedAccumulatedSeconds)
    }

    func elapsedSeconds(
        now: Date,
        startedAt: Date,
        pausedAccumulatedSeconds: TimeInterval = 0
    ) -> TimeInterval {
        max(0, now.timeIntervalSince(startedAt) - pausedAccumulatedSeconds)
    }

    func progress(
        now: Date,
        startedAt: Date,
        plannedMinutes: Int,
        pausedAccumulatedSeconds: TimeInterval = 0
    ) -> Double {
        let totalSeconds = max(Double(plannedMinutes * 60), 1)
        let value = elapsedSeconds(
            now: now,
            startedAt: startedAt,
            pausedAccumulatedSeconds: pausedAccumulatedSeconds
        ) / totalSeconds
        return min(max(value, 0), 1)
    }

    func snapshot(
        now: Date,
        startedAt: Date,
        plannedMinutes: Int,
        routeDistanceKm: Int,
        pausedAccumulatedSeconds: TimeInterval = 0
    ) -> SessionSnapshot {
        let normalizedProgress = progress(
            now: now,
            startedAt: startedAt,
            plannedMinutes: plannedMinutes,
            pausedAccumulatedSeconds: pausedAccumulatedSeconds
        )
        let elapsed = min(
            Int(elapsedSeconds(now: now, startedAt: startedAt, pausedAccumulatedSeconds: pausedAccumulatedSeconds)),
            plannedMinutes * 60
        )
        let remaining = max(0, plannedMinutes * 60 - elapsed)
        let distanceTraveled = min(routeDistanceKm, Int((Double(routeDistanceKm) * normalizedProgress).rounded(.down)))

        return SessionSnapshot(
            progress: normalizedProgress,
            elapsedSeconds: elapsed,
            remainingSeconds: remaining,
            distanceTraveledKm: distanceTraveled,
            distanceRemainingKm: max(0, routeDistanceKm - distanceTraveled)
        )
    }

    func snapshot(for session: FocusSession, routeDistanceKm: Int, now: Date = .now) -> SessionSnapshot {
        snapshot(
            now: effectiveNow(for: session, now: now),
            startedAt: session.startedAt,
            plannedMinutes: session.plannedMinutes,
            routeDistanceKm: routeDistanceKm,
            pausedAccumulatedSeconds: session.pausedAccumulatedSeconds
        )
    }

    func pause(_ session: FocusSession, at now: Date = .now, routeDistanceKm: Int) -> SessionSnapshot {
        let snapshot = snapshot(for: session, routeDistanceKm: routeDistanceKm, now: now)

        session.pausedAt = now
        session.status = .paused
        apply(snapshot: snapshot, to: session)
        return snapshot
    }

    func resume(_ session: FocusSession, at now: Date = .now, routeDistanceKm: Int) -> SessionSnapshot {
        let pausedAt = session.pausedAt ?? now
        session.pausedAccumulatedSeconds += now.timeIntervalSince(pausedAt)
        session.pausedAt = nil
        session.expectedEndAt = expectedEndDate(
            startedAt: session.startedAt,
            plannedMinutes: session.plannedMinutes,
            pausedAccumulatedSeconds: session.pausedAccumulatedSeconds
        )
        session.status = .active

        let snapshot = snapshot(for: session, routeDistanceKm: routeDistanceKm, now: now)
        apply(snapshot: snapshot, to: session)
        return snapshot
    }

    func cancel(_ session: FocusSession, at now: Date = .now, routeDistanceKm: Int) -> SessionSnapshot {
        let snapshot = snapshot(for: session, routeDistanceKm: routeDistanceKm, now: now)

        session.cancelledAt = now
        session.completedAt = nil
        session.pausedAt = nil
        session.status = .cancelled
        apply(snapshot: snapshot, to: session)
        return snapshot
    }

    func complete(_ session: FocusSession, at now: Date = .now, routeDistanceKm: Int) -> SessionSnapshot {
        let completionDate = max(now, session.expectedEndAt)
        let snapshot = snapshot(for: session, routeDistanceKm: routeDistanceKm, now: completionDate)

        session.completedAt = completionDate
        session.cancelledAt = nil
        session.pausedAt = nil
        session.status = .completed
        apply(
            snapshot: SessionSnapshot(
                progress: 1,
                elapsedSeconds: session.plannedDurationSeconds,
                remainingSeconds: 0,
                distanceTraveledKm: routeDistanceKm,
                distanceRemainingKm: 0
            ),
            to: session
        )
        return snapshot
    }

    func shouldComplete(_ session: FocusSession, now: Date = .now) -> Bool {
        session.status == .active && now >= session.expectedEndAt
    }

    @discardableResult
    func restore(_ session: FocusSession, routeDistanceKm: Int, now: Date = .now) -> SessionSnapshot {
        if shouldComplete(session, now: now) {
            return complete(session, at: now, routeDistanceKm: routeDistanceKm)
        }

        let snapshot = snapshot(for: session, routeDistanceKm: routeDistanceKm, now: now)
        apply(snapshot: snapshot, to: session)
        return snapshot
    }

    private func effectiveNow(for session: FocusSession, now: Date) -> Date {
        session.pausedAt ?? now
    }

    private func apply(snapshot: SessionSnapshot, to session: FocusSession) {
        session.completionPercent = snapshot.progress
        session.elapsedFocusSeconds = snapshot.elapsedSeconds
        session.traveledDistanceKm = snapshot.distanceTraveledKm
        session.remainingDistanceKm = snapshot.distanceRemainingKm
    }
}
