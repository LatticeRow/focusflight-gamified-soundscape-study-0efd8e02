import SwiftUI
import SwiftData

struct FlightSessionView: View {
    @Environment(\.modelContext) private var modelContext

    let sessionDraft: AppRouter.SessionDraft
    @ObservedObject var preferences: UserPreferences
    let sessionEngine: SessionEngine
    let sessionRepository: SessionRepository
    let audioPlayerService: AudioPlayerService
    let notificationService: NotificationService
    let onClose: () -> Void

    @State private var startedAt = Date()
    @State private var now = Date()
    @State private var pausedAt: Date?
    @State private var pausedAccumulatedSeconds: TimeInterval = 0
    @State private var sessionRecord: FocusSession?
    @State private var hasCompletedSession = false

    private let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            let snapshot = currentSnapshot

            ScrollView {
                VStack(alignment: .leading, spacing: FFSpacing.lg) {
                    RouteHeader(route: sessionDraft.route)

                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        Text(format(seconds: snapshot.remainingSeconds))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(FFColors.textPrimary)
                            .monospacedDigit()

                        ProgressView(value: snapshot.progress)
                            .tint(FFColors.accent)
                            .scaleEffect(x: 1, y: 2.5, anchor: .center)

                        HStack(spacing: FFSpacing.md) {
                            MetricPill(label: "Flown", value: "\(snapshot.distanceTraveledKm) km")
                            MetricPill(label: "Remaining", value: "\(snapshot.distanceRemainingKm) km")
                        }
                    }
                    .padding(FFSpacing.lg)
                    .background(FFColors.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Text("Sound: \(selectedTrack.title)")
                        .font(FFTypography.body)
                        .foregroundStyle(FFColors.textSecondary)

                    HStack(spacing: FFSpacing.md) {
                        if !hasCompletedSession {
                            Button(pausedAt == nil ? "Pause Flight" : "Resume Flight") {
                                togglePause()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(FFColors.panelRaised)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("session.pauseResume")
                        }

                        Button(hasCompletedSession ? "Done" : "End Flight") {
                            handleClose(snapshot: snapshot)
                        }
                        .buttonStyle(.bordered)
                        .tint(FFColors.accentSoft)
                        .accessibilityIdentifier("session.end")
                    }
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
            .background(FFColors.background.ignoresSafeArea())
            .navigationTitle("In Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        handleClose(snapshot: snapshot)
                    }
                }
            }
        }
        .onAppear {
            startedAt = Date()
            now = startedAt
            persistSessionIfNeeded()
            audioPlayerService.preload(trackID: sessionDraft.selectedAudioTrackID)
            if preferences.notificationsEnabled {
                notificationService.requestAuthorizationIfNeeded()
            }
        }
        .onReceive(sessionTimer) { value in
            guard pausedAt == nil, !hasCompletedSession else { return }
            now = value

            if currentSnapshot.remainingSeconds == 0 {
                completeSessionIfNeeded(at: value)
            }
        }
    }

    private func togglePause() {
        let now = Date()
        if let pausedAt {
            pausedAccumulatedSeconds += now.timeIntervalSince(pausedAt)
            self.pausedAt = nil
            sessionRecord?.pausedAt = nil
            sessionRecord?.pausedAccumulatedSeconds = pausedAccumulatedSeconds
            sessionRecord?.expectedEndAt = sessionEngine.expectedEndDate(
                startedAt: startedAt,
                plannedMinutes: sessionDraft.plannedMinutes,
                pausedAccumulatedSeconds: pausedAccumulatedSeconds
            )
            sessionRecord?.status = .active
        } else {
            pausedAt = now
            sessionRecord?.pausedAt = now
            sessionRecord?.status = .paused
        }

        try? sessionRepository.saveChanges(in: modelContext)
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private var currentSnapshot: SessionSnapshot {
        sessionEngine.snapshot(
            now: pausedAt ?? now,
            startedAt: startedAt,
            plannedMinutes: sessionDraft.plannedMinutes,
            routeDistanceKm: sessionDraft.route.distanceKm,
            pausedAccumulatedSeconds: pausedAccumulatedSeconds
        )
    }

    private var selectedTrack: UserPreferences.AudioTrack {
        UserPreferences.AudioTrack(rawValue: sessionDraft.selectedAudioTrackID) ?? .fallback
    }

    private func persistSessionIfNeeded() {
        guard sessionRecord == nil else { return }

        let session = FocusSession(
            routeID: sessionDraft.route.id,
            routeThemeName: sessionDraft.route.themeName,
            originCode: sessionDraft.route.originCode,
            destinationCode: sessionDraft.route.destinationCode,
            startedAt: startedAt,
            expectedEndAt: sessionEngine.expectedEndDate(
                startedAt: startedAt,
                plannedMinutes: sessionDraft.plannedMinutes
            ),
            plannedMinutes: sessionDraft.plannedMinutes,
            status: .active,
            selectedAudioTrackID: sessionDraft.selectedAudioTrackID
        )

        do {
            try sessionRepository.insert(session, in: modelContext)
            sessionRecord = session
        } catch {
            assertionFailure("Failed to persist session: \(error)")
        }
    }

    private func completeSessionIfNeeded(at completionDate: Date) {
        guard let sessionRecord, !hasCompletedSession else { return }

        sessionRecord.completedAt = completionDate
        sessionRecord.completionPercent = 1
        sessionRecord.status = .completed
        sessionRecord.pausedAt = nil

        do {
            try sessionRepository.saveChanges(in: modelContext)
            _ = try sessionRepository.stamp(for: sessionRecord, in: modelContext)
            hasCompletedSession = true
        } catch {
            assertionFailure("Failed to complete session: \(error)")
        }
    }

    private func handleClose(snapshot: SessionSnapshot) {
        if hasCompletedSession {
            onClose()
            return
        }

        if snapshot.remainingSeconds == 0 {
            completeSessionIfNeeded(at: now)
            onClose()
            return
        }

        sessionRecord?.status = .cancelled
        sessionRecord?.cancelledAt = Date()
        sessionRecord?.completionPercent = snapshot.progress
        try? sessionRepository.saveChanges(in: modelContext)
        onClose()
    }
}
