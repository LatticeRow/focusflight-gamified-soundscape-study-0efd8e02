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
    @State private var isCancelConfirmationPresented = false

    private let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            let snapshot = currentSnapshot

            ScrollView {
                VStack(alignment: .leading, spacing: FFSpacing.lg) {
                    headerCard

                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        Text(isCompleted ? "Arrived" : "Time Left")
                            .font(FFTypography.eyebrow)
                            .foregroundStyle(FFColors.textSecondary)

                        Text(format(seconds: snapshot.remainingSeconds))
                            .font(FFTypography.displayMetric)
                            .foregroundStyle(FFColors.textPrimary)
                            .monospacedDigit()
                            .accessibilityIdentifier("session.remainingTime")

                        flightProgressBar(progress: snapshot.progress)

                        HStack {
                            airportLabel(code: route.originCode, city: route.originCity, alignment: .leading)
                            Spacer()
                            airportLabel(code: route.destinationCode, city: route.destinationCity, alignment: .trailing)
                        }
                    }
                    .padding(FFSpacing.lg)
                    .ffCardSurface()

                    HStack(spacing: FFSpacing.md) {
                        MetricPill(label: "Done", value: "\(Int(snapshot.progress * 100))%")
                        MetricPill(label: "Flown", value: "\(snapshot.distanceTraveledKm) km")
                        MetricPill(label: "Left", value: "\(snapshot.distanceRemainingKm) km")
                    }

                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cabin Audio")
                                    .font(FFTypography.sectionTitle)
                                    .foregroundStyle(FFColors.textPrimary)

                                Text(selectedTrack.title)
                                    .font(FFTypography.body)
                                    .foregroundStyle(FFColors.textSecondary)
                            }

                            Spacer()

                            Button(audioPlayerService.isPlaybackEnabled ? "Sound Off" : "Sound On") {
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
                            Text("Resume to bring the cabin back.")
                                .font(FFTypography.detail)
                                .foregroundStyle(FFColors.textSecondary)
                        } else if let error = audioPlayerService.lastErrorDescription {
                            Text(error)
                                .font(FFTypography.detail)
                                .foregroundStyle(FFColors.textSecondary)
                        }
                    }
                    .padding(FFSpacing.lg)
                    .ffCardSurface()

                    VStack(spacing: FFSpacing.md) {
                        if isCompleted {
                            PrimaryButton(title: "Close", systemImage: "checkmark.circle.fill") {
                                handleDone()
                            }
                            .accessibilityIdentifier("session.complete")
                        } else {
                            HStack(spacing: FFSpacing.md) {
                                Button(isPaused ? "Resume" : "Pause") {
                                    togglePause()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(FFColors.panelRaised)
                                .foregroundStyle(FFColors.textPrimary)
                                .accessibilityIdentifier("session.pauseResume")

                                Button("Cancel") {
                                    isCancelConfirmationPresented = true
                                }
                                .buttonStyle(.bordered)
                                .tint(FFColors.accentSoft)
                                .accessibilityIdentifier("session.cancel")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
            .background(FFScreenBackground())
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
        }
        .confirmationDialog(
            "Cancel this flight?",
            isPresented: $isCancelConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Cancel Flight", role: .destructive) {
                cancelFlight()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress for this flight will be lost.")
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

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            Text("AURELINE SESSION")
                .font(FFTypography.eyebrow)
                .tracking(1.3)
                .foregroundStyle(FFColors.accentSoft)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: FFSpacing.xs) {
                    Text(route.themeName)
                        .font(FFTypography.detail)
                        .foregroundStyle(FFColors.accentSoft)
                    RouteHeader(route: route)
                }

                Spacer()

                Text(statusTitle)
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textPrimary)
                    .padding(.horizontal, FFSpacing.sm)
                    .padding(.vertical, 8)
                    .background(FFColors.panelRaised)
                    .clipShape(Capsule())
            }

            HStack(spacing: FFSpacing.md) {
                MetricPill(label: "Focus", value: "\(session.plannedMinutes)m")
                MetricPill(label: "Sound", value: selectedTrack.title)
            }
        }
        .padding(FFSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ffCardSurface(elevated: true)
    }

    private func flightProgressBar(progress: Double) -> some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)
            let trackWidth = geometry.size.width
            let fillWidth = max(30, trackWidth * clampedProgress)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FFColors.panelRaised.opacity(0.9))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [FFColors.accent, FFColors.accentSoft],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)

                Image(systemName: "airplane")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(FFColors.accentSoft)
                    .clipShape(Circle())
                    .offset(x: min(max(fillWidth - 20, 0), max(trackWidth - 28, 0)))
            }
        }
        .frame(height: 28)
        .accessibilityIdentifier("session.progress")
    }

    private func airportLabel(code: String, city: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(code)
                .font(FFTypography.code)
                .foregroundStyle(FFColors.textPrimary)
            Text(city)
                .font(FFTypography.detail)
                .foregroundStyle(FFColors.textSecondary)
        }
    }

    private var statusTitle: String {
        switch session.status {
        case .active:
            return "In Flight"
        case .paused:
            return "Paused"
        case .completed:
            return "Arrived"
        case .cancelled:
            return "Closed"
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

    private func handleDone() {
        if !isCompleted, currentSnapshot.isComplete {
            _ = sessionEngine.complete(session, at: now, routeDistanceKm: route.distanceKm)
            finalizeCompletion()
        }

        onClose()
    }

    private func cancelFlight() {
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
