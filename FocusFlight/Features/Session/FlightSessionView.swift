import SwiftData
import SwiftUI

struct FlightSessionView: View {
    @Environment(\.modelContext) private var modelContext

    let session: FocusSession
    let route: FlightRoute
    @ObservedObject var preferences: UserPreferences
    let sessionEngine: SessionEngine
    let sessionRepository: SessionRepository
    let audioPlayerService: AudioPlayerService
    let notificationService: NotificationService
    let onClose: () -> Void

    @State private var now = Date()
    @State private var hasLoaded = false

    private let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            let snapshot = currentSnapshot

            ScrollView {
                VStack(alignment: .leading, spacing: FFSpacing.lg) {
                    RouteHeader(route: route)

                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        Text(format(seconds: snapshot.remainingSeconds))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(FFColors.textPrimary)
                            .monospacedDigit()

                        ProgressView(value: snapshot.progress)
                            .tint(FFColors.accent)
                            .scaleEffect(x: 1, y: 2.5, anchor: .center)

                        HStack(spacing: FFSpacing.md) {
                            MetricPill(label: "Done", value: "\(Int(snapshot.progress * 100))%")
                            MetricPill(label: "Flown", value: "\(snapshot.distanceTraveledKm) km")
                            MetricPill(label: "Left", value: "\(snapshot.distanceRemainingKm) km")
                        }
                    }
                    .padding(FFSpacing.lg)
                    .background(FFColors.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Text(selectedTrack.title)
                        .font(FFTypography.body)
                        .foregroundStyle(FFColors.textSecondary)

                    HStack(spacing: FFSpacing.md) {
                        if !isTerminal {
                            Button(isPaused ? "Resume" : "Pause") {
                                togglePause()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(FFColors.panelRaised)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("session.pauseResume")
                        }

                        Button(isCompleted ? "Done" : "End") {
                            handleClose()
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
                        handleClose()
                    }
                }
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            refresh(at: .now)
            audioPlayerService.preload(trackID: session.selectedAudioTrackID)
            if preferences.notificationsEnabled, session.status == .active {
                notificationService.requestAuthorizationIfNeeded()
                notificationService.scheduleCompletionNotification(for: session, route: route)
            }
        }
        .onReceive(sessionTimer) { value in
            guard session.status == .active else { return }
            refresh(at: value)
        }
    }

    private var currentSnapshot: SessionSnapshot {
        sessionEngine.snapshot(for: session, routeDistanceKm: route.distanceKm, now: now)
    }

    private var isPaused: Bool {
        session.status == .paused
    }

    private var isCompleted: Bool {
        session.status == .completed
    }

    private var isTerminal: Bool {
        session.status == .completed || session.status == .cancelled
    }

    private var selectedTrack: UserPreferences.AudioTrack {
        UserPreferences.AudioTrack(rawValue: session.selectedAudioTrackID) ?? .fallback
    }

    private func refresh(at date: Date) {
        now = date
        let previousStatus = session.status
        _ = sessionEngine.restore(session, routeDistanceKm: route.distanceKm, now: date)

        if previousStatus != .completed, session.status == .completed {
            finalizeCompletion()
        } else {
            persistChanges()
        }
    }

    private func togglePause() {
        let eventDate = Date()
        now = eventDate

        if isPaused {
            _ = sessionEngine.resume(session, at: eventDate, routeDistanceKm: route.distanceKm)
            if preferences.notificationsEnabled {
                notificationService.scheduleCompletionNotification(for: session, route: route)
            }
        } else {
            _ = sessionEngine.pause(session, at: eventDate, routeDistanceKm: route.distanceKm)
            notificationService.cancelNotification(for: session.id)
        }

        persistChanges()
    }

    private func finalizeCompletion() {
        notificationService.cancelNotification(for: session.id)

        do {
            try sessionRepository.saveChanges(in: modelContext)
            _ = try sessionRepository.stamp(for: session, in: modelContext)
        } catch {
            assertionFailure("Failed to complete session: \(error)")
        }
    }

    private func handleClose() {
        if isCompleted {
            onClose()
            return
        }

        if currentSnapshot.isComplete {
            _ = sessionEngine.complete(session, at: now, routeDistanceKm: route.distanceKm)
            finalizeCompletion()
            onClose()
            return
        }

        _ = sessionEngine.cancel(session, at: .now, routeDistanceKm: route.distanceKm)
        notificationService.cancelNotification(for: session.id)
        persistChanges()
        onClose()
    }

    private func persistChanges() {
        do {
            try sessionRepository.saveChanges(in: modelContext)
        } catch {
            assertionFailure("Failed to save session state: \(error)")
        }
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
