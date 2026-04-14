import SwiftData
import SwiftUI

struct FlightSessionView: View {
    @Environment(\.modelContext) private var modelContext

    let session: FocusSession
    let route: FlightRoute
    @ObservedObject var preferences: UserPreferences
    let sessionEngine: SessionEngine
    let sessionRepository: SessionRepository
    @ObservedObject var audioPlayerService: AudioPlayerService
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
                            .accessibilityIdentifier("session.remainingTime")

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

                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cabin Sound")
                                    .font(FFTypography.sectionTitle)
                                    .foregroundStyle(FFColors.textPrimary)

                                Text(selectedTrack.title)
                                    .font(FFTypography.body)
                                    .foregroundStyle(FFColors.textSecondary)
                            }

                            Spacer()

                            Button(audioPlayerService.isPlaybackEnabled ? "Pause Sound" : "Play Sound") {
                                toggleAudio()
                            }
                            .buttonStyle(.bordered)
                            .tint(FFColors.accentSoft)
                            .disabled(isTerminal)
                            .accessibilityIdentifier("session.soundToggle")
                        }

                        VStack(alignment: .leading, spacing: FFSpacing.sm) {
                            HStack {
                                Text("Level")
                                    .font(FFTypography.detail)
                                    .foregroundStyle(FFColors.textSecondary)
                                Spacer()
                                Text("\(Int(preferences.audioVolume * 100))%")
                                    .font(FFTypography.detail)
                                    .foregroundStyle(FFColors.textSecondary)
                            }

                            Slider(value: $preferences.audioVolume, in: 0...1)
                                .tint(FFColors.accent)
                                .accessibilityIdentifier("session.volume")
                        }

                        if isPaused {
                            Text("Sound resumes with the timer.")
                                .font(FFTypography.detail)
                                .foregroundStyle(FFColors.textSecondary)
                        } else if let error = audioPlayerService.lastErrorDescription {
                            Text(error)
                                .font(FFTypography.detail)
                                .foregroundStyle(.red.opacity(0.85))
                        }
                    }
                    .padding(FFSpacing.lg)
                    .background(FFColors.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

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
            audioPlayerService.synchronizePlayback(for: session)
            synchronizeNotification(promptIfNeeded: false)
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
        if sessionEngine.shouldComplete(session, now: date) {
            _ = sessionEngine.complete(session, at: date, routeDistanceKm: route.distanceKm)
            finalizeCompletion()
        }
    }

    private func togglePause() {
        let eventDate = Date()
        now = eventDate

        if isPaused {
            _ = sessionEngine.resume(session, at: eventDate, routeDistanceKm: route.distanceKm)
        } else {
            _ = sessionEngine.pause(session, at: eventDate, routeDistanceKm: route.distanceKm)
        }

        audioPlayerService.synchronizePlayback(for: session)
        synchronizeNotification(promptIfNeeded: false)
        persistChanges()
    }

    private func toggleAudio() {
        audioPlayerService.togglePlaybackIntent(trackID: session.selectedAudioTrackID)
        audioPlayerService.synchronizePlayback(for: session)
    }

    private func finalizeCompletion() {
        notificationService.cancelNotification(for: session.id)
        audioPlayerService.synchronizePlayback(for: session)

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
        audioPlayerService.synchronizePlayback(for: session)
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

    private func synchronizeNotification(promptIfNeeded: Bool) {
        Task {
            _ = await notificationService.synchronizeCompletionNotification(
                for: session,
                route: route,
                notificationsEnabled: preferences.notificationsEnabled,
                promptIfNeeded: promptIfNeeded
            )
        }
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
